/**
*    @author Todd Newman
*    @date   2021-07-27
*    @description    DCP-48131: This class contains logic for handling Material Number approval for Record Owner Flow in Quote Lines
*    Modification Log:
*    ----------------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Todd Newman                 2021-07-27            Initial Version
*    ----------------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class ApprovalsQuoteLineMaterialNumber extends ApprovalsStepBase 
{
    private static final String PRODUCT_TYPE_PRODUCT_SERVICE = 'Product/Service';
    private static final String PRODUCT_TYPE_OPTION = 'Option';

    // NOTE: these are in base class
    // protected Approvals.SupportData data;
    // protected Approvals.StepName stepName;
    // protected Approvals.StepResults stepResults;
    // protected Approvals.Outputs outputs;

    public static final string RECORD_OWNER ='Record Owner';
    private Apttus_Proposal__Proposal_Line_Item__c quoteLine;

    /*
    *  @author:         Todd Newman
    *  @description:    Constructor
    */
    public ApprovalsQuoteLineMaterialNumber(Approvals.SupportData data)
    {
        super(Approvals.StepName.CPQ_MATERIAL_NUMBER, data);
    }
    /*
    *  @author:         Todd Newman
    *  @description:    Setter method for initializing the proposal line item record's value
    */
    public override void setRecord(Object record)
    {
        this.quoteLine = (Apttus_Proposal__Proposal_Line_Item__c)record;
    }
    /*
    *  @author:         Todd Newman
    *  @description:    Checks whether the logic for material number approvals should run or not, if not eligible then exit the flow
    */
    public override Boolean isStepAppropriateForRecord()
    {   
        // this step only relevant for service or option line items   
        Boolean boolLineLevelCriteriaSatisfied = (quoteLine.Apttus_QPConfig__LineType__c == PRODUCT_TYPE_PRODUCT_SERVICE && quoteLine.Apttus_QPConfig__IsPrimaryLine__c) || quoteLine.Apttus_QPConfig__LineType__c == PRODUCT_TYPE_OPTION;
        
        return boolLineLevelCriteriaSatisfied && getIsDiscountTypeSalesDiscretionary(quoteLine) && !getIsQuoteLineFixedBundle(quoteLine);
    }
    /*
    *  @author:         Todd Newman
    *  @description:    Checks for Material Number Approvals
    */
    public override void calculate()
    {
        // find best hierarchy fit for sold to (direct) or distributor (indirect)
        Approvals.HierarchyAndLevel hierarchyAndLevel = findHierarchyAndLevel();
        stepResults.approvalFound = hierarchyAndLevel.isValidHierarchyFound;
        stepResults.discount = hierarchyAndLevel;

        Apttus_Proposal__Proposal__c quote = data.idToQuote.get(quoteLine.Apttus_Proposal__Proposal__c);
        if (quote.Apttus_Proposal__Opportunity__r.Transborder_Flag__c || quote.Indirect_Transregion_Flag__c)
        {
            // for transborder, find best hierarchy fit for UC
            Approvals.HierarchyAndLevel transborderHierarchyAndLevel = findTransborderHierarchyAndLevel();
            stepResults.approvalFound = transborderHierarchyAndLevel.isValidHierarchyFound;
            stepResults.discountUC = transborderHierarchyAndLevel;
        }
    }

    /*
    *  @author:         Todd Newman
    *  @description:    calls findHierarchyAndLevel() for non-transborder scenario
    */
    private Approvals.HierarchyAndLevel findHierarchyAndLevel()
    {
        return findHierarchyAndLevel(false);
    }

    /*
    *  @author:         Todd Newman
    *  @description:    calls findHierarchyAndLevel() for transborder scenario
    */
    private Approvals.HierarchyAndLevel findTransborderHierarchyAndLevel()
    {
        return findHierarchyAndLevel(true);
    }

    /*
    *  @author:         Todd Newman
    *  @description:    calculates final approval hierarchy, level and matrix for material number approval scenario
    */
    private Approvals.HierarchyAndLevel findHierarchyAndLevel(Boolean isTransborder)
    {
        // output values
        Boolean isHierarchyFound = false;
        Id hierarchyId = null;
        Integer approvalLevel = null;

        System.debug('Transborder Scenario : '+isTransborder);
        
        // find highest ranking material number matrix for this line item (actually highest here means lowest priority number)
        Approvals.MatrixWrapper highestPriorityMatrix = findHighestPriorityMatrix(quoteLine, Approvals.APPROVAL_TYPE_MATNUM, isTransborder,RECORD_OWNER);

        // for custom approval matrices, the approver is stamped in level 1
        Id level1Approver = highestPriorityMatrix.ownerId;
        hierarchyId = (data.userIdToApprovalHierarcy.containsKey(level1Approver) ? data.userIdToApprovalHierarcy.get(level1Approver).Id : null);

        if (highestPriorityMatrix.isDiscountUnderLevel1)
        {
            // no error possible, no hierarchy needed
            isHierarchyFound = false;
            stepResults.quotesWithMatrixError.remove(quoteLine.Apttus_Proposal__Proposal__c);
        }
        else  // discount >= level 1
        {
            // if the matrix says we've exceeded level 1 and we couldn't find a hierachy for the account owner
            if (hierarchyId == null)
            {
                addIdToValueSet(stepResults.erroredQuoteIdToOwnerIds, quoteLine.Apttus_Proposal__Proposal__c, highestPriorityMatrix.ownerId);
                // returns whether a matrix was found since we know there is no hierarcy
                isHierarchyFound = addCategoryIfMatrixFound(highestPriorityMatrix);
            }
            else
            {
                // QUESTION: is it possible to have an ID and not a level for a MATNUM approval record?
                if (highestPriorityMatrix.approvalLevel != null)
                {
                    approvalLevel = highestPriorityMatrix.approvalLevel;
                    stepResults.approvalCategories.add(Approvals.Category.CPQ_MATERIAL_NUMBER.name());
                    isHierarchyFound = true;
                }
            }

            isHierarchyFound = noteErrorIfNoMatrixFound(highestPriorityMatrix, quoteLine.Apttus_Proposal__Proposal__c, isHierarchyFound);
        }

        return new Approvals.HierarchyAndLevel(isHierarchyFound, hierarchyId, approvalLevel);
    }

    /*
    *  @author:         Todd Newman
    *  @description:    calculates category if approval matrix is found in this flow
    */
    private Boolean addCategoryIfMatrixFound(Approvals.MatrixWrapper matrixWrapper)
    {
        Boolean isMatrixFound = false;

        if (matrixWrapper.record != null)
        {
            isMatrixFound = true;
            stepResults.approvalCategories.add(Approvals.Category.CPQ_MATERIAL_NUMBER.name());
        }

        return isMatrixFound;
    }

    /*
    *  @author:         Todd Newman
    *  @description:    if matrix is not found then error quote should be registered in a set to be used later while stamping
    */
    private Boolean noteErrorIfNoMatrixFound(Approvals.MatrixWrapper matrixWrapper, Id quoteId, Boolean isApprovalFound)
    {
        if (matrixWrapper.record == null)
        {
            stepResults.quotesWithMatrixError.add(quoteId);
            return false;
        }

        return isApprovalFound;
    }

    // for UtilsCollection?
    private void addIdToValueSet(Map<Id, Set<Id>> mp, Id key, Id value)
    {
        if (!mp.containsKey(key)) { mp.put(key, new Set<Id>()); }

        mp.get(key).add(value);
    }

}