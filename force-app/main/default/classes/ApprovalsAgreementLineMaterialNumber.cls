/**
*    @author Bharath Varma
*    @date   2021-12-07
*    @description    DCP-50961: This class contains logic for handling Material Number approval for Record Owner Flow in Agreement Lines
*    Modification Log:
*    ----------------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Bharath Varma               2021-12-07            Initial Version
*         Sudarshan Kataria           2024-06-06            Changes for DGP 302
*    ----------------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class ApprovalsAgreementLineMaterialNumber extends ApprovalsStepBase {

    // NOTE: these are in base class
    // protected Approvals.SupportData data;
    // protected Approvals.StepName stepName;
    // protected Approvals.StepResults stepResults;
    // protected Approvals.Outputs outputs;

    private Apttus__AgreementLineItem__c agreementLine;
    private Custom_Approval_Matrix__c matrixRecord; // DGP-52
    private static final String QUOTA ='Quota';
    private static final String YES ='Yes';

    /*
    *  @author:         Bharath Varma
    *  @description:    Constructor
    */
    public ApprovalsAgreementLineMaterialNumber(Approvals.SupportData data) {
        super(Approvals.StepName.CLM_MATERIAL_NUMBER, data);
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
    *  @description:    Checks whether the logic for material number approvals should run or not, if not eligible then exit the flow
    */
    public override Boolean isStepAppropriateForRecord()
    {   
        System.debug('Inside isStepAppropriate');
        Boolean boolLineLevelCriteriaSatisfied =  agreementLine.Material_Number__c!=null && agreementLine.Line_Type__c!=QUOTA && agreementLine.Line_Type_1__c!=QUOTA && agreementLine.Discontinued__c!=YES;

        // this step only relevant for service or option line items   
        return boolLineLevelCriteriaSatisfied && getIsMaterialNumberInProducts(agreementLine);
    }

    /*
    *  @author:         Bharath Varma
    *  @description:    Checks for Material Number Approvals
    */
    public override void calculate()
    {
        Approvals.HierarchyAndLevel hierarchyAndLevel = findHierarchyAndLevel();
        stepResults.approvalFound = hierarchyAndLevel.isValidHierarchyFound;
        stepResults.discount = hierarchyAndLevel;
        outputs.materialNumberRecordOwnerMatrix = matrixRecord; // DGP-52
    }

    private Boolean getIsMaterialNumberInProducts(Apttus__AgreementLineItem__c agreementLine) 
    {
        return data.materialNumbers.contains(agreementLine.Material_Number__c);
    }

    private Approvals.HierarchyAndLevel findHierarchyAndLevel()
    {
        // output values
        Boolean isHierarchyFound = false;
        Id hierarchyId = null;
        Integer approvalLevel = null;
        
        // find highest ranking material number matrix for this line item (actually highest here means lowest priority number)
        Approvals.MatrixWrapper highestPriorityMatrix = findHighestPriorityMatrix(agreementLine, Approvals.APPROVAL_TYPE_MATNUM, null, ApprovalsAgreementLineStepBase.RECORD_OWNER); //last parameter is for hierachy type(custom approval matrix)
        System.debug('@@@ highestPriorityMatrix --> ' + highestPriorityMatrix.record);

        // for custom approval matrices, the approver is stamped in level 1
        Id level1Approver = highestPriorityMatrix.ownerId;
        System.debug('@@@ level1Approver --> ' + level1Approver);
        hierarchyId = (data.userIdToApprovalHierarcy.containsKey(level1Approver) ? data.userIdToApprovalHierarcy.get(level1Approver).Id : null);
        System.debug('@@@ hierarchyId --> ' + hierarchyId);
        System.debug('@@@ approval Level --> ' + highestPriorityMatrix.approvalLevel);

        if(highestPriorityMatrix.record == null) 
        {
            stepResults.agreementsWithMatrixError.add(agreementLine.Apttus__AgreementId__c);
            isHierarchyFound = false;
        }

        if(highestPriorityMatrix.isDiscountUnderLevel1)
        {
            stepResults.agreementstoRevert.add(agreementLine.Apttus__AgreementId__c);
            isHierarchyFound = false;
        }
        else if(highestPriorityMatrix.approvalLevel != null)
        {
            if(hierarchyId == null)
            {
                stepResults.agreementsWithHierarchyError.add(agreementLine.Apttus__AgreementId__c);
            }
            approvalLevel = highestPriorityMatrix.approvalLevel;
            if(!highestPriorityMatrix.isDiscountUnderLevel1)
            {
                stepResults.approvalCategories.add(Approvals.Category.MATERIAL_NUMBER.name());
                isHierarchyFound = true;
            }
        }
        
        matrixRecord = highestPriorityMatrix.record; // DGP-52

        return new Approvals.HierarchyAndLevel(isHierarchyFound, hierarchyId, approvalLevel);
    }
    
}