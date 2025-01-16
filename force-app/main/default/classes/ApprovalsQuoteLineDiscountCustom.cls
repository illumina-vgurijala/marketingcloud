/**
*    @author Satya Swain
*    @date   2021-08-11
*    @description    DCP-48131: This class contains logic for handling Discount approval for Custom Flow in Quote Lines
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Satya Swain                 2021-08-11           Initial Version
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class ApprovalsQuoteLineDiscountCustom extends ApprovalsStepBase {
    
    // NOTE: these are in base class
    // protected Approvals.SupportData data;
    // protected Approvals.StepName stepName;
    // protected Approvals.StepResults stepResults;
    // protected Approvals.Outputs outputs;

    public static final string CUSTOM ='Custom';
    private Apttus_Proposal__Proposal_Line_Item__c quoteLine;
    
    /*
    *  @author:         Satya Swain
    *  @description:    Constructor
    */
    public ApprovalsQuoteLineDiscountCustom(Approvals.SupportData data) {
        super(Approvals.StepName.CPQ_DISCOUNT_CUSTOM, data);
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
    *  @description:    Checks whether the logic for discount custom flow approvals should run or not, if not eligible then exit the flow
    */
    public override Boolean isStepAppropriateForRecord() {
        Boolean boolRecordOwnerApprovalFound = outputs.approvalsResults.isHierarchyFound.materialNumber || outputs.approvalsResults.isHierarchyFound.materialGroup || outputs.approvalsResults.isHierarchyFound.discount;
        
        Boolean boolCustomApprovalFoundSoFar = !outputs.approvalsResults.isHierarchyFound.customMaterialNumber && !outputs.approvalsResults.isHierarchyFound.customMaterialGroup;
        
        return boolRecordOwnerApprovalFound && boolCustomApprovalFoundSoFar && getIsDiscountTypeSalesDiscretionary(quoteLine) && !getIsQuoteLineFixedBundle(quoteLine);
    }

    /*
    *  @author:         Satya Swain
    *  @description:    Checks for Discount Custom Flow Approvals
    */
    public override void calculate() {       
        Approvals.HierarchyAndLevel hierarchyAndLevel = findHierarchyAndLevel();
        stepResults.approvalFound = hierarchyAndLevel.isValidHierarchyFound;
        stepResults.discount = hierarchyAndLevel;
    }

    /*
    *  @author:         Satya Swain
    *  @description:    calculates final approval hierarchy, level and matrix for discount custom flow approval scenario
    */
    private Approvals.HierarchyAndLevel findHierarchyAndLevel() {
        // output values
        Boolean isHierarchyFound = false;
        Id hierarchyId = null;
        Integer approvalLevel = null;

        // find highest ranking discount matrix for this line item (actually highest here means lowest priority number)
        Approvals.MatrixWrapper highestPriorityMatrix = findHighestPriorityMatrix(quoteLine, Approvals.APPROVAL_TYPE_DISCOUNT, false,CUSTOM);

        hierarchyId = highestPriorityMatrix.record == null ? null : highestPriorityMatrix.record.Approval_Hierarchy__c;        
        approvalLevel = highestPriorityMatrix.approvalLevel;
        
        if(hierarchyId != null && approvalLevel != null) {
            isHierarchyFound = true;
            stepResults.approvalCategories.add(Approvals.Category.CPQ_DISCOUNT_CUSTOM.name());
        }

        return new Approvals.HierarchyAndLevel(isHierarchyFound, hierarchyId, approvalLevel);
    }
}