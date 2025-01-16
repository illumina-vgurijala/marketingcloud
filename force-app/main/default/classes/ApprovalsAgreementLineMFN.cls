/**
*    @author Bharath Varma
*    @date   2021-12-07
*    @description    DCP-50961: This class contains logic for handling MFN approvals in Agreement Lines
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Bharath Varma                2021-12-07           Initial Version
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class ApprovalsAgreementLineMFN extends ApprovalsStepBase{
    // NOTE: these are in base class
    // protected Approvals.SupportData data;
    // protected Approvals.StepName stepName;
    // protected Approvals.StepResults stepResults;
    // protected Approvals.Outputs outputs;

    private Apttus__AgreementLineItem__c agreementLine;

    /*
    *  @author:         Bharath Varma
    *  @description:    Constructor
    */
    public ApprovalsAgreementLineMFN(Approvals.SupportData data) {
        super(Approvals.StepName.CLM_MFN, data);
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
    *  @description:    Checks whether the logic for mfn approvals should run or not, if not eligible then exit the flow
    */
    public override Boolean isStepAppropriateForRecord()
    {   
        System.debug('Inside isStepAppropriate for MFN');
        String oncologyLabManufacturerComparison = data.idToAgreement.get(agreementLine.Apttus__AgreementId__c).Apttus__Account__r.Oncology_Lab_Manufacturer_Comparison__c;
        return oncologyLabManufacturerComparison == null ? false : System.Label.Yes.contains(oncologyLabManufacturerComparison);
    }

    /*
    *  @author:         Bharath Varma
    *  @description:    Checks for MFN Approvals
    */
    public override void calculate()
    {
        Boolean mfnLineItem = false;

        if(agreementLine.Is_MFN_NovaSeq_Consumable__c && data.idToAgreement.get(agreementLine.Apttus__AgreementId__c).Country_On_Account_Approvals__c == System.Label.Country_USA && agreementLine.Discount__c > decimal.valueOf(System.Label.MFN_USA_NovaSeq_Discount)) {
            mfnLineItem = true;
        }
        else if(agreementLine.Is_MFN_NextSeq_RUO_Consumable__c && data.idToAgreement.get(agreementLine.Apttus__AgreementId__c).Country_On_Account_Approvals__c == System.Label.Country_USA && agreementLine.Discount__c > decimal.valueOf(System.Label.MFN_USA_NextSeq_Discount)) {
            mfnLineItem = true;
        }
        else if(agreementLine.Is_MFN_TG_NextSeq_Consumable__c && data.idToAgreement.get(agreementLine.Apttus__AgreementId__c).Country_On_Account_Approvals__c == System.Label.Country_USA && agreementLine.Discount__c > decimal.valueOf(System.Label.MFN_USA_TG_NextSeq_Discount)) {
            mfnLineItem = true;
        }
        else if(agreementLine.Is_MFN_NovaSeq_Consumable__c && data.idToAgreement.get(agreementLine.Apttus__AgreementId__c).Country_On_Account_Approvals__c == System.Label.Country_Germany && agreementLine.Discount__c > decimal.valueOf(System.Label.MFN_Germany_NovaSeq_Discount)) {
            mfnLineItem = true;
        }
        else if(agreementLine.Is_MFN_NextSeq_RUO_Consumable__c && data.idToAgreement.get(agreementLine.Apttus__AgreementId__c).Country_On_Account_Approvals__c == System.Label.Country_Germany && agreementLine.Discount__c > decimal.valueOf(System.Label.MFN_Germany_NextSeq_Discount)) {
            mfnLineItem = true;
        }

        if(mfnLineItem) {
            stepResults.approvalFound = true;
            stepResults.isMFNApprovalLine = true;
            stepResults.approvalCategories.add(Approvals.Category.MFN_APPROVALS.name());
        }
        
    }

}