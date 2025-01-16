/**
*    @author Rishi Sharma
*    @date   24th September 2021
*    @description    Class to get the Custom Metadata records for Product Code to Subscription mapping 
*    @ Test class Coverage: 100% - TestApprovalsQuoteLine,TestApprovalsQuoteLineDiscount,TestApprovalsQuoteLineMaterialGroup,TestApprovalsQuoteLineMaterialNumber,TestApprovalsQuoteLinePromotions
                            TestApttusApprovals,TestApttusAssetLineItems,TestApttusPreviewApprovals,TestBatchToPopulateAppliedDisPer,TestSubmitForApprovalEmail
*    @ Test class Coverage: 75% - TestApprovalsQuoteLine
*    Modification Log:
*   ------------------------------------------------------------------------------------------------
*    Developer                      Date                			 Description
*    Rishi Sharma                   24th September 2021              Initial Version
*    Adithi Acharya                 10th October 2022                Test class Coverage changes
*    -----------------------------------------------------------------------------------------------
*/
public with sharing class ProductCodetoSubscriptionSelector extends ilib_SObjectSelector{
    /* getSObjectType method*/
    public Schema.SObjectType getSObjectType()
    {
        return Product_Code_to_Subscription_Map__mdt.sObjectType;
    } 

/**
*  @author - Rishi Sharma
*  @description - Retrieve list of fields for Product Code to Subscription Metadata 
*  @return - sObjectFieldList list of Schema.SObjectField
**/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Product_Code_to_Subscription_Map__mdt.Product_Code__c,
            Product_Code_to_Subscription_Map__mdt.Subscription__c
     };
    }


    /**
    *  @author Rishi Sharma
    *  @description Fetch Product Code to Subscription Map According to Product Code
    *  @return list of Product Code to Subscription mapping metadata records
    **/
    public List<Product_Code_to_Subscription_Map__mdt> selectAllRecords(Set<String>strCondition){
        return (List<Product_Code_to_Subscription_Map__mdt>) Database.query(
            newQueryFactory()
            .selectField('Product_Code__c')
            .selectField('Subscription__c')
            .setCondition('Product_Code__c IN: strCondition')
            .toSOQL()
        );
    }

}