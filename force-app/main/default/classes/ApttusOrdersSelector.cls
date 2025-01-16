/**
 *    @author Shashank Singhal
 *    @date   2018-08-24
 *    @description  DCP-844: Apttus Order Selector 
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Shashank                        2018-08-24         Initial Version
 *    Rahul Sharma                    2019-07-03         DCP-25384 Added selectOrdersBySoldToAndUC 
 *    Shivani Jain                    2022-02-08         DCP-51266 - Relocation Order should not trigger 
 *                                                                   Install WO Creation
 *    Shivani Jain                    2022-04-25         DCP-51484 No CP WOs should have Associated SR case
 *    Sudarshan                       05-Dec-2023        CMCM-1354  EOL WO Changes
 *    Arquimidez Mora                 10-Aug-2024        CMCM-9645 Added a new method fetchOrderByRelatedOpportunity
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class ApttusOrdersSelector extends ilib_SObjectSelector{
	/**
    *  @author Shashank Singhal 
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the Order
    **/
   public Schema.SObjectType getSObjectType()
   {
        return Apttus_Config2__Order__c.sObjectType;
   }
    
    /**
     *  @author  Shashank Singhal
     *  @description Retrieve list of fields for Order sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList(){
    	return new List<Schema.SObjectField> {
        	Apttus_Config2__Order__c.id, 
                Apttus_Config2__Order__c.Apttus_Config2__OrderReferenceNumber__c, 
                Apttus_Config2__Order__c.Apttus_QPConfig__ProposalId__c,
                Apttus_Config2__Order__c.ASOP_Number__c,
                Apttus_Config2__Order__c.Apttus_Config2__Status__c,
                Apttus_Config2__Order__c.Order_Status__c,
                Apttus_Config2__Order__c.Order_Line_Not_Activated__c
        };
    }
    
    /**
     *  @author Shashank Singhal 
     *  @description Fetch Orders for related quotes
     *  @param quoteIds Set of quote Ids
     *  @return orderList List
     **/
    /*public List<Apttus_Config2__Order__c> selectOrdersForQuotes(Set<Id> setQuoteIds) 
    {
        return (List<Apttus_Config2__Order__c>) Database.query(
            newQueryFactory().setCondition('Apttus_QPConfig__ProposalId__c IN :setQuoteIds').toSOQL()
        );
    }*/
 
    /*
     * @Author : Sravan Panchangam
     * @Decription : DCP-13048
     * @Param ASOP Number
     * @return  Order with ASOP Number
     */
    public List<Apttus_Config2__Order__c> fetchOrdersbySalesOrderUnique(Set<String> salesorderNumbers){
        return (List<Apttus_Config2__Order__c>) Database.query(
            newQueryFactory().setCondition('Sales_Order_Number_Unique__c IN :salesorderNumbers').toSOQL());
    }

    /*
     * @Author : Ritika M
     * @Decription : Fetch Order records by thier ids
     * @Param Set Apprus Order Ids
     * @return  List of Apptus Orders
     */
    public List<Apttus_Config2__Order__c> selectOrdersByIds(Set<Id> setOrderIdsIds){
        return (List<Apttus_Config2__Order__c>)  Database.query(
            newQueryFactory().selectField('Apttus_Config2__RelatedOpportunityId__c')
            				.selectField('Ultimate_Consignee__c')
                            .selectField('Name') //DCP - 47704
                            .selectField('Contact_Email__c')
                            .selectField('ASOP_Number_Link__c')
							.selectField('Apttus_Config2__SoldToAccountId__c')
            				.selectField('Apttus_Config2__SoldToAccountId__r.RecordTypeId')
            				.selectField('Apttus_Config2__SoldToAccountId__r.Channel_Partner_Type__c')
                            .selectField('Apttus_Config2__Type__c')//PM-122
                            .selectField('Apttus_Config2__SoldToAccountId__r.Account_Group__c')//PM-122
                            .selectField('Apttus_Config2__SoldToAccountId__r.BillingCountryCode')//CMCM-698
                            .selectField('Distributor__c')//PM-122
                            .selectField('Apttus_QPConfig__ProposalId__c') //CMCM-1354
                            .selectField('Distributor__r.Account_Group__c')//PM-122
                            .selectField('Apttus_Config2__RelatedOpportunityId__r.Product_Interest__c') //DCP-51266
                            .selectField('Ultimate_Consignee__r.VAD_Channel_Partner_Territory__c') //DCP-51484
            				.selectField('Distributor__r.BillingCountry') //CMCM-2266
                            .selectField('Distributor__r.BillingCountryCode') //CMCM-2266
                            .selectField('Apttus_Config2__SoldToAccountId__r.BillingCountry')//CMCM-2266
            				.setCondition('ID IN :setOrderIdsIds').toSOQL());
    }
	/*
     * @Author : Sravan Panchangam
     * @Decription : DCP-9865
     * @Param ASOP Number
     * @return  Order with ASOP Number
     */
    public Apttus_Config2__Order__c fetchRecordForSalesOrderNumber(String salesOrderNumber){
        return (Apttus_Config2__Order__c)  Database.query(
            newQueryFactory().setCondition('Sales_Order_Number_Unique__c = :salesOrderNumber').toSOQL());
    }
    
    /*
     * @Author : Sravan Panchangam
     * @Decription : DCP-13048 latest change
     * @Param ASOP Number
     * @return  Order with ASOP Number
     */
    public List<Apttus_Config2__Order__c> fetchRecordForASOPLink(Set<String> asopNumber){
        return (List<Apttus_Config2__Order__c>)  Database.query(
            newQueryFactory().setCondition('Sales_Order_Number_Unique__c = :asopNumber').toSOQL());
    }

    /*
     * @Author : Rahul Sharma
     * @Decription : DCP-25384 To fetch orders by Sold To and UC
     * @Param Set of Account Ids
     * @return  Order List
     */
    public List<Apttus_Config2__Order__c> selectOrdersBySoldToAndUC(Set<id> setAccountIds){
        return (List<Apttus_Config2__Order__c>)  Database.query(
            newQueryFactory().setCondition('Apttus_Config2__SoldToAccountId__c IN :setAccountIds OR Ultimate_Consignee__c IN :setAccountIds').toSOQL());
    }

    /*
     * @Author : Arquimidez Mora
     * @Decription : Fetch Orders by Opportunity
     * @return  Order List
     */
    public List<Apttus_Config2__Order__c> fetchOrderByRelatedOpportunity(Set<Id> setOpportunityIds)
    {
        List<Apttus_Config2__Order__c> res = (List<Apttus_Config2__Order__c>) Database.query(
            newQueryFactory()
            .selectField('Id')
            .setCondition('Apttus_Config2__RelatedOpportunityId__c IN :setOpportunityIds')
            .toSOQL()
        );

        return res;
    }
}