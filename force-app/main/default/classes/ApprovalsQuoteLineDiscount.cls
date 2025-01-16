/**
*    @author Satya Swain
*    @date   2021-08-11
*    @description    DCP-48131: This class contains logic for handling Discount approval for Record Owner Flow in Quote Lines
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Satya Swain                 2021-08-11           Initial Version
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class ApprovalsQuoteLineDiscount extends ApprovalsStepBase {
    
    // NOTE: these are in base class
    // protected Approvals.SupportData data;
    // protected Approvals.StepName stepName;
    // protected Approvals.StepResults stepResults;
    // protected Approvals.Outputs outputs;
      
    public static final string RECORD_OWNER ='Record Owner';
    private Apttus_Proposal__Proposal_Line_Item__c quoteLine;
    
    /*
    *  @author:         Satya Swain
    *  @description:    Constructor
    */
    public ApprovalsQuoteLineDiscount(Approvals.SupportData data) {
        super(Approvals.StepName.CPQ_DISCOUNT, data);
    }

    /*
    *  @author:         Satya Swain
    *  @description:    Setter method for initializing the proposal line item record's value
    */
    public override void setRecord(Object record) {
        this.quoteLine = (Apttus_Proposal__Proposal_Line_Item__c)record;
    }

    /*
    *  @author:         Satya Swain
    *  @description:    Checks whether the logic for discount approvals should run or not, if not eligible then exit the flow
    */
    public override Boolean isStepAppropriateForRecord() {  
        // this step is only relevant if there was no material number approval nor material group approval
        Boolean boolPreviousRecordOwnerApprovalsNotFound = !outputs.approvalsResults.isHierarchyFound.materialNumber && !outputs.approvalsResults.isHierarchyFound.materialGroup;
        
        return boolPreviousRecordOwnerApprovalsNotFound && getIsDiscountTypeSalesDiscretionary(quoteLine) && !getIsQuoteLineFixedBundle(quoteLine);
    }
    
    /*
    *  @author:         Satya Swain
    *  @description:    Checks for Discount Approvals
    */
    public override void calculate() {
        // find best hierarchy fit for sold to (direct) or distributor (indirect)
        Approvals.HierarchyAndLevel hierarchyAndLevel = findHierarchyAndLevel();
        stepResults.approvalFound = hierarchyAndLevel.isValidHierarchyFound;
        stepResults.discount = hierarchyAndLevel;

        Apttus_Proposal__Proposal__c quote = data.idToQuote.get(quoteLine.Apttus_Proposal__Proposal__c);
        if (quote.Apttus_Proposal__Opportunity__r.Transborder_Flag__c || quote.Indirect_Transregion_Flag__c) {
            // for transborder, find best hierarchy fit for UC
            Approvals.HierarchyAndLevel transborderHierarchyAndLevel = findTransborderHierarchyAndLevel();
            stepResults.approvalFound = transborderHierarchyAndLevel.isValidHierarchyFound;
            stepResults.discountUC = transborderHierarchyAndLevel;
        }
    }

    /*
    *  @author:         Satya Swain
    *  @description:    calls findHierarchyAndLevel for non-transborder scenario
    */
    private Approvals.HierarchyAndLevel findHierarchyAndLevel() {
        return findHierarchyAndLevel(false);
    }

    /*
    *  @author:         Satya Swain
    *  @description:    calls findHierarchyAndLevel() for transborder scenario
    */
    private Approvals.HierarchyAndLevel findTransborderHierarchyAndLevel() {
        return findHierarchyAndLevel(true);
    }

    /*
    *  @author:         Satya Swain
    *  @description:    calculates final approval hierarchy, level and matrix for discount approval scenario
    */
    private Approvals.HierarchyAndLevel findHierarchyAndLevel(Boolean isTransborder) {
        // output values
        Boolean isHierarchyFound = false;
        Id hierarchyId = null;
        Integer approvalLevel = null;

        // find highest ranking discount matrix for this line item (actually highest here means lowest priority number)
        Approvals.MatrixWrapper highestPriorityMatrix = findHighestPriorityMatrix(quoteLine, Approvals.APPROVAL_TYPE_DISCOUNT, isTransborder,RECORD_OWNER);

        // for custom approval matrices, the approver is stamped in level 1
        Id level1Approver = highestPriorityMatrix.ownerId;
        hierarchyId = (data.userIdToApprovalHierarcy.containsKey(level1Approver) ? data.userIdToApprovalHierarcy.get(level1Approver).Id : null);
        
        System.debug('highestPriorityMatrix received finally for Quote Line Discount Approvals: '+JSON.serialize(highestPriorityMatrix));

        if (highestPriorityMatrix.isDiscountUnderLevel1) {
            // no error possible, no hierarchy needed
            isHierarchyFound = false;
            removeRecordIdFromMatrixErrorSet(quoteLine.Apttus_Proposal__Proposal__c);
        } else {
            // discount >= level 1
            // if the matrix says we've exceeded level 1 and we couldn't find a hierachy for the account owner
            if (hierarchyId == null) {
                addIdToValueSet(stepResults.erroredQuoteIdToOwnerIds, quoteLine.Apttus_Proposal__Proposal__c, highestPriorityMatrix.ownerId);
                // returns whether a matrix was found since we know there is no hierarcy
                isHierarchyFound = addCategoryIfMatrixFound(highestPriorityMatrix);
            } else {
                if (highestPriorityMatrix.approvalLevel != null) {
                    approvalLevel = highestPriorityMatrix.approvalLevel;
                    stepResults.approvalCategories.add(Approvals.Category.CPQ_DISCOUNT.name());
                    removeRecordIdFromMatrixErrorSet(quoteLine.Apttus_Proposal__Proposal__c);
                    isHierarchyFound = true;
                }
            }

            isHierarchyFound = noteErrorIfNoMatrixFound(highestPriorityMatrix, quoteLine.Apttus_Proposal__Proposal__c, isHierarchyFound);
        }
        return new Approvals.HierarchyAndLevel(isHierarchyFound, hierarchyId, approvalLevel);        
    }
    
    /*
    *  @author:         Satya Swain
    *  @description:    calculates category if approval matrix is found in this flow
    */
    private Boolean addCategoryIfMatrixFound(Approvals.MatrixWrapper matrixWrapper) {
        Boolean isMatrixFound = false;
        if (matrixWrapper.record != null) {
            isMatrixFound = true;
            stepResults.approvalCategories.add(Approvals.Category.CPQ_DISCOUNT.name());
            removeRecordIdFromMatrixErrorSet(quoteLine.Apttus_Proposal__Proposal__c);
        }

        return isMatrixFound;
    }

    /*
    *  @author:         Satya Swain
    *  @description:    if matrix is not found then error quote should be registered in a set to be used later while stamping
    */
    private Boolean noteErrorIfNoMatrixFound(Approvals.MatrixWrapper matrixWrapper, Id quoteId, Boolean isApprovalFound) {
        if (matrixWrapper.record == null) {            
            stepResults.quotesWithMatrixError.add(quoteId);
            return false;
        }
        return isApprovalFound;
    }

    /*
    *  @author:         Satya Swain
    *  @description:    if appproval matrix is found then quote record should be removed from set of matrix error quotes
    */
    private void removeRecordIdFromMatrixErrorSet(Id recordId) {

        if(stepResults.quotesWithMatrixError.contains(recordId)) {
            stepResults.quotesWithMatrixError.remove(recordId);            
        }

        // Added temporarily for testing
        if(outputs.quotesWithMatrixError != null  && outputs.quotesWithMatrixError.contains(recordId)) {
            outputs.quotesWithMatrixError.remove(recordId);
        }          
    }

    // for UtilsCollection?
    private void addIdToValueSet(Map<Id, Set<Id>> mp, Id key, Id value) {
        if (!mp.containsKey(key)) { mp.put(key, new Set<Id>()); }

        mp.get(key).add(value);
    }
}