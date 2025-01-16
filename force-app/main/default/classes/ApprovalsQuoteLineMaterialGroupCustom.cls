/**
*    @author Satya Swain
*    @date   2021-08-11
*    @description    DCP-48131: This class contains logic for handling Material Group approval for Custom Flow in Quote Lines
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Satya Swain                 2021-08-11           Initial Version
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class ApprovalsQuoteLineMaterialGroupCustom extends ApprovalsStepBase {
    
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
    public ApprovalsQuoteLineMaterialGroupCustom(Approvals.SupportData data) {
        super(Approvals.StepName.CPQ_MATERIAL_GROUP_CUSTOM, data);
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
    *  @description:    Checks whether the logic for material group custom flow approvals should run or not, if not eligible then exit the flow
    */
    public override Boolean isStepAppropriateForRecord() {
        Id productId = (quoteLine.Apttus_QPConfig__OptionId__c == null) ? quoteLine.Apttus_Proposal__Product__c : quoteLine.Apttus_QPConfig__OptionId__c;

        Boolean boolRecordOwnerApprovalFound = (outputs.approvalsResults.isHierarchyFound.materialNumber || outputs.approvalsResults.isHierarchyFound.materialGroup || outputs.approvalsResults.isHierarchyFound.discount) && !outputs.approvalsResults.isHierarchyFound.customMaterialNumber;
        
        Boolean boolLineLevelCriteriaSatisfied = data.idToProduct.get(productId).Material_Group_1_Code__c != null;
        
        return boolRecordOwnerApprovalFound && boolLineLevelCriteriaSatisfied && getIsDiscountTypeSalesDiscretionary(quoteLine) && !getIsQuoteLineFixedBundle(quoteLine);
    }

    /*
    *  @author:         Satya Swain
    *  @description:    Checks for Material Group Custom Flow Approvals
    */
    public override void calculate() {       
        Approvals.HierarchyAndLevel hierarchyAndLevel = findHierarchyAndLevel();
        stepResults.approvalFound = hierarchyAndLevel.isValidHierarchyFound;
        stepResults.discount = hierarchyAndLevel;
    }

    /*
    *  @author:         Satya Swain
    *  @description:    calculates final approval hierarchy, level and matrix for material group custom flow approval scenario
    */
    private Approvals.HierarchyAndLevel findHierarchyAndLevel() {
        // output values
        Boolean isHierarchyFound = false;
        Id hierarchyId = null;
        Integer approvalLevel = null;

        // find highest ranking material group matrix for this line item (actually highest here means lowest priority number)
        Approvals.MatrixWrapper highestPriorityMatrix = findHighestPriorityMatrix(quoteLine, Approvals.APPROVAL_TYPE_MATGRP, false,CUSTOM);
        
        hierarchyId = highestPriorityMatrix.record == null ? null : highestPriorityMatrix.record.Approval_Hierarchy__c;        
        approvalLevel = highestPriorityMatrix.approvalLevel;
        
        if (hierarchyId != null && approvalLevel != null) {
            isHierarchyFound = true;
            stepResults.approvalCategories.add(Approvals.Category.CPQ_MATERIAL_GROUP_CUSTOM.name());
        }

        return new Approvals.HierarchyAndLevel(isHierarchyFound, hierarchyId, approvalLevel);
    }
}