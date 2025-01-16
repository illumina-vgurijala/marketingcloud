/**
*    @author Govind Dubey
*    @date   2018-06-28
*    @description    DCP-2433: OpportunityLineItems Selector class
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*             Developer                      Date                Description
*             Govind Dubey            		28 June 2018         OpportunityLineItems Selector Class
*             Shashank Singhal              24 Aug 2018         Add method to query Opportunity Line Items for DCP-844
*             Milan Savalitya               23 OCT 2018         Added selectOpportunityLineItems Method, Used in BatchToCloneOppLineToCart
*             Milan Savalitya               30 OCT 2018         Added fields in selectOpportunityLineItems
*             Arnab Modak                   28 AUG 2019         Added fields in selectOpportunityLineItems - Product2.Apttus_Config2__ConfigurationType__c,
*             Rahul Bishnoi                 05 DEC 2019         Added fields in selectOpportunityLineItems - End_Date__c, Start_Date__c
*             Rahul Bishnoi                 15 Jan 2020         Added Fields in selectOpportunityLineItems - Has_Informatics_Product__c
*             Rahul Bishnoi                 27 Jan 2020         Added Fields in selectOpportunityLineItems - Quote_Line_Item__r.Existing_Subscription__r.ERP_Line_Number_Id__c
*             Saurav Bhandari               08 NOV 2019         Added fields in selectOpportunityLineItems - Product2.IsActive , Product2.Service_Product_Type__c , Product2.Auto_Create_Install_Work_Order__c
*             Adyasha Satapathy             14 Sep 2020         Added fields in selectOpportunityLineItems - Product2.Material_Class__c
*             Todd                          13 Apr 2021         DCP-45737: Add quote instrumentation (with feature flag)
*             Adyasha Satapathy             06 May 2021         DCP-38809: Added field in selectOpportunityLineItems -Work Detail Line
*             Prem Ranjan                   09 June 2021        Added fields in selectOpportunityLineItems
*             Rishab Wali                   25 June 2021        DCP-45399 : Added Product Level Indicator Field
*             Adithi Acharya                18 August 2022      DCP-56258- Auto Population of Informatics
*    ------------------------------------------------------------------------------------ 
*/
public with sharing class OpportunityLineItemsSelector extends ilib_SObjectSelector{

    private final static String LOG_TITLE = 'OpportunityLineItemsSelector';

    /* Method to return SObjectType */
    public Schema.SObjectType getSObjectType()
    {
        return OpportunityLineItem.sObjectType;
    }
    
    /**
    *  @author  Govind Dubey
    *  @description Retrieve list of fields for OpportunityLineItems sObject 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            OpportunityLineItem.id,
                OpportunityLineItem.OpportunityId,
                OpportunityLineItem.Product2Id
        };
    }
    
    /**
    *  @author Govind Dubey
    *  @description Fetch the OpportunityLineItems
    *  @param Set of opportunity Ids
    *  @return List of OpportunityLineItem  
    **/
    public List<OpportunityLineItem> selectOpportunityLineItems(Set<Id> opportunityIds) 
    {
        ilib_LogQuery logger = null;
        if (Feature.isOn('SalesQueryLogs')) {logger = new ilib_LogQuery(
            LOG_TITLE + '.selectOpportunityLineItems',
            UtilsCollection.serializeIds(opportunityIds)
        );}

        List<OpportunityLineItem> res = (List<OpportunityLineItem>) Database.query(
        							newQueryFactory()                                    
                                    .selectField('Product2.Name')
                                    .selectField('Product2.ProductCode')
                                    .selectField('Product2.Apttus_Config2__ConfigurationType__c')
                                    .selectField('Product2.Material_Class_Type__c')
                                    .selectField('Product2.IsActive')
                                    .selectField('Product2.Service_Product_Type__c')
                                    .selectField('Product2.Auto_Create_Installation_Workflow__c') // CMCM-1662
                                    .selectField('OptionId__c')
                                    .selectField('UnitPrice')
                                    .selectField('Quantity')
            						.selectField('ProductCode')
                                    .selectField('TotalPrice')
                                    .selectField('Shipping_In_Close_Quarter__c')
                                    .selectField('Shipping_In_1Q_After_Close_Quarter__c')
                                    .selectField('Shipping_In_2Q_After_Close_Quarter__c')
                                    .selectField('Quote_Line_Item__c')
            						.selectField('End_Date__c')
            						.selectField('Start_Date__c')
                                    .selectField('PricebookEntryId')
                                    .selectField('Has_Informatics_Product__c')
                                    .selectField('ERP_Line_Number_Id__c')
                                    .selectField('Serial_Number__c')
                                    .selectField('Quote_Line_Item__r.Existing_Subscription__r.ERP_Line_Number_Id__c')
                                    .selectField('Product2.Material_Class__c') // Added as part of DCP-40052
                                    .selectField('Work_Detail_Line__c') // Added as part of DCP-38809
                                    .selectField('List_Price__c') // Added as part of DCP-47880
                                    .selectField('Customer_Specific_Price__c')// Added as part of DCP-47880
									.selectField('Product2.Product_Level_Indicator__c')//Added as part of DCP-45399
                                    .selectField('Quote_Line_Item__r.Registrant_Contact__c')//DCP-56258       
                                    .selectField('By_Pass_Sync_To_Opportunity__c')//CMCM-9986       
                                    .setCondition('OpportunityId IN :opportunityIds').toSOQL()
        );

        if (Feature.isOn('SalesQueryLogs')) {logger.stop(res.size());}
        return res;
    } 

}