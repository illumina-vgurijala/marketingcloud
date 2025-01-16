/**
*    @author Kushal Shah
*    @date   2021-09-27
*    @description    DCP-49429: This class contains logic for handling MFN approval in Quote Lines
*    Modification Log: Test
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Kushal Shah                 2021-09-27           Initial Version
*    ---------------------------------------------------------------------------------------------------------------------------
**/


public with sharing class ApprovalsQuoteLineMFN extends ApprovalsStepBase {
    
    // NOTE: these are in base class
    // protected Approvals.SupportData data;
    // protected Approvals.StepName stepName;
    // protected Approvals.StepResults stepResults;
    // protected Approvals.Outputs outputs;

    private Apttus_Proposal__Proposal_Line_Item__c quoteLine;
    
    /*
    *  @author:         Kushal Shah
    *  @description:    Constructor
    */
    public ApprovalsQuoteLineMFN(Approvals.SupportData data) {
        super(Approvals.StepName.CPQ_MFN, data);
    }

    /*
    *  @author:         Kushal Shah
    *  @description:    Setter method for initializing the proposal line item record's value
    */
    public override void setRecord(Object record) {
        this.quoteLine = (Apttus_Proposal__Proposal_Line_Item__c)record;
    }

    /*
    *  @author:         Kushal Shah
    *  @description:    Checks whether the logic for MFN approvals should run or not, if not eligible then exit the flow
    */
    public override Boolean isStepAppropriateForRecord() {
        return true;
    }

    /*
    *  @author:         Kushal Shah
    *  @description:    Checks for MFN Flow Approvals
    */
    public override void calculate() { 
        System.debug('Kush *** MFN Calc Called!');  
        String discountTypePercentage = '% Discount';
        Apttus_Proposal__Proposal__c quote = data.idToQuote.get(quoteLine.Apttus_Proposal__Proposal__c);
        if(quote.Ultimate_Consignee__r.Oncology_Lab_Manufacturer_Comparison__c == System.Label.Yes || quote.Apttus_Proposal__Account__r.Oncology_Lab_Manufacturer_Comparison__c == System.Label.Yes)
        {
            if(quote.Apttus_Proposal__Account__r.BillingCountry == 'USA' || quote.Ultimate_Consignee__r.BillingCountry == 'USA')
            {
                if(quoteLine.Is_MFN_NovaSeq_Consumable__c == TRUE && quoteLine.Sales_Discretionary_Type__c == discountTypePercentage && quoteLine.Sales_Discretionary_Discount__c > 13)
                {
                    //stepResults.requiresApprovalWithoutCategory = true;
                    stepResults.approvalFound = true;
                    stepResults.isMFNApprovalLine = true;
                }
                else if(quoteLine.Is_MFN_NextSeq_RUO_Consumable__c == TRUE && quoteLine.Sales_Discretionary_Type__c == discountTypePercentage && quoteLine.Sales_Discretionary_Discount__c > 35)
                {
                    //stepResults.requiresApprovalWithoutCategory = true;
                    stepResults.approvalFound = true;
                    stepResults.isMFNApprovalLine = true;
                }
                else if(quoteLine.Is_MFN_TG_NextSeq_Consumable__c == TRUE && quoteLine.Sales_Discretionary_Type__c == discountTypePercentage && quoteLine.Sales_Discretionary_Discount__c > 43.48)
                {
                    //stepResults.requiresApprovalWithoutCategory = true;
                    stepResults.approvalFound = true;
                    stepResults.isMFNApprovalLine = true;
                }
            }
            else if(quote.Apttus_Proposal__Account__r.BillingCountry == 'Germany' || quote.Ultimate_Consignee__r.BillingCountry == 'Germany')  
            {
                if(quoteLine.Is_MFN_NovaSeq_Consumable__c == TRUE && quoteLine.Sales_Discretionary_Type__c == discountTypePercentage && quoteLine.Sales_Discretionary_Discount__c > 0)
                {
                    //stepResults.requiresApprovalWithoutCategory = true;
                    stepResults.approvalFound = true;
                    stepResults.isMFNApprovalLine = true;
                }
                else if(quoteLine.Is_MFN_NextSeq_RUO_Consumable__c == TRUE && quoteLine.Sales_Discretionary_Type__c == discountTypePercentage && quoteLine.Sales_Discretionary_Discount__c > 35)
                {
                    //stepResults.requiresApprovalWithoutCategory = true;
                    stepResults.approvalFound = true;
                    stepResults.isMFNApprovalLine = true;
                }
                else if(quoteLine.Is_MFN_TG_NextSeq_Consumable__c == TRUE && quoteLine.Sales_Discretionary_Type__c == discountTypePercentage && quoteLine.Sales_Discretionary_Discount__c > 35)
                {
                    //stepResults.requiresApprovalWithoutCategory = true;
                    stepResults.approvalFound = true;
                    stepResults.isMFNApprovalLine = true;
                }
            }
        }
    }
}