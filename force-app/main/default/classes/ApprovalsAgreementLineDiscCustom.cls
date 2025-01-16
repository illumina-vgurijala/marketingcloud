/**
*    @author Bharath Varma
*    @date   2021-12-07
*    @description    DCP-50961: This class contains logic for handling Discount approval for Custom Flow in Agreement Lines
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Bharath Varma                2021-12-07           Initial Version
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class ApprovalsAgreementLineDiscCustom extends ApprovalsStepBase {
    // NOTE: these are in base class
    // protected Approvals.SupportData data;
    // protected Approvals.StepName stepName;
    // protected Approvals.StepResults stepResults;
    // protected Approvals.Outputs outputs;

    private Apttus__AgreementLineItem__c agreementLine;
    private Custom_Approval_Matrix__c matrixRecord; // DGP-52
    private static final String QUOTA ='Quota';

    /*
    *  @author:         Bharath Varma
    *  @description:    Constructor
    */
    public ApprovalsAgreementLineDiscCustom(Approvals.SupportData data) {
        super(Approvals.StepName.CLM_DISCOUNT_CUSTOM, data);
    }

    /*
    *  @author:         Bharath Varma
    *  @description:    Setter method for initializing the agreement line item record's value
    */
    public override void setRecord(Object record)
    {
        this.agreementLine = (Apttus__AgreementLineItem__c)record;
    }

    /*
    *  @author:         Bharath Varma
    *  @description:    Checks whether the logic for discount custom approvals should run or not, if not eligible then exit the flow
    */
    public override Boolean isStepAppropriateForRecord()
    {   
        System.debug('Inside isStepAppropriate Disc Custom');
        Boolean boolRecordOwnerApprovalFound = outputs.approvalsResults.isHierarchyFound.materialNumber || outputs.approvalsResults.isHierarchyFound.materialGroup || outputs.approvalsResults.isHierarchyFound.discount;
        Boolean boolPreviousCustomApprovalFound = !outputs.approvalsResults.isHierarchyFound.customMaterialNumber && !outputs.approvalsResults.isHierarchyFound.customMaterialGroup;
        Boolean boolLineLevelCriteriaSatisfied = agreementLine.Discount_In_Percent__c != null && agreementLine.Line_Type__c != QUOTA && agreementLine.Line_Type_1__c != QUOTA;

        return boolRecordOwnerApprovalFound && boolPreviousCustomApprovalFound && boolLineLevelCriteriaSatisfied;
    }

    /*
    *  @author:         Bharath Varma
    *  @description:    Checks for Discount Custom Flow Approvals
    */
    public override void calculate()
    {
        Approvals.HierarchyAndLevel hierarchyAndLevel = findHierarchyAndLevel();
        stepResults.approvalFound = hierarchyAndLevel.isValidHierarchyFound;
        stepResults.discount = hierarchyAndLevel;
        outputs.discountCustomMatrix = matrixRecord; // DGP-52
    }

    private Approvals.HierarchyAndLevel findHierarchyAndLevel()
    {
        // output values
        Boolean isHierarchyFound = false;
        Id hierarchyId = null;
        Integer approvalLevel = null;
        
        // find highest ranking material number matrix for this line item (actually highest here means lowest priority number)
        Approvals.MatrixWrapper highestPriorityMatrix = findHighestPriorityMatrix(agreementLine, Approvals.APPROVAL_TYPE_DISCOUNT, null, ApprovalsAgreementLineStepBase.CUSTOM); //last parameter is for hierachy type(custom approval matrix)
        System.debug('@@@ highestPriorityMatrix --> ' + highestPriorityMatrix.record);

        approvalLevel = highestPriorityMatrix.approvalLevel;
        hierarchyId = (highestPriorityMatrix.record == null ? null : highestPriorityMatrix.record.Approval_Hierarchy__c);

        if(hierarchyId!=null && approvalLevel!=null && !highestPriorityMatrix.isDiscountUnderLevel1){
            stepResults.approvalCategories.add(Approvals.Category.DISCOUNT_CUSTOM.name());
            isHierarchyFound = true;
        }
        if(highestPriorityMatrix.isDiscountUnderLevel1)
        {
            stepResults.agreementstoRevert.add(agreementLine.Apttus__AgreementId__c);
            isHierarchyFound = false;
        }
        
        matrixRecord = highestPriorityMatrix.record; // DGP-52
        
        return new Approvals.HierarchyAndLevel(isHierarchyFound, hierarchyId, approvalLevel);
    }
}