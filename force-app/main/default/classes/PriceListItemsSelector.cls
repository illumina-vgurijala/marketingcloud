/**
*    @author Govind Dubey
*    @date   21st Aug 2018
*    @description    DCP-1063: priceListItem Selector class
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                 Date                    Description
*    Govind Dubey              21st Aug 2018           priceListItem Selector class
*    Saswati Prusty            20th Jan 2020           DCP-31789
*    Joshith K                 4th  Jan 2021           INC0302480- updated selectByProductIdsAndPriceList to query only Active records
*    Todd                      15th Apr 2021           DCP-45737: Add quote instrumentation (with feature flag)
*    Aman Tyagi                31 March 2022           CodeScan Fixes
*    Akshay Hedaoo             16 Aug 2024             CMCM-9780 : Quotation Line Item : Update Hide Contract Dates if PriceType is OneTime
*    ------------------------------------------------------------------------------------ 
*/
public with sharing class PriceListItemsSelector extends ilib_SObjectSelector {

    private final String LOG_TITLE = 'PriceListItemsSelector';
    private static final string QUERY_LOGS_SALES = 'SalesQueryLogs';

    /*
    * @Author: Govind Dubey 
    * @Description : method to return the SObject type
    * @param : null
    */
    public Schema.SObjectType getSObjectType()
    {
        return Apttus_Config2__PriceListItem__c.sObjectType;
    }
    
     /**
     *  @author  Indra Ganesan 
     *  @description Retrieve list of fields for Product2 sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
           Apttus_Config2__PriceListItem__c.Id,
           Apttus_Config2__PriceListItem__c.Apttus_Config2__PriceType__c,
           Apttus_Config2__PriceListItem__c.Apttus_Config2__ProductId__c,
           Apttus_Config2__PriceListItem__c.Apttus_Config2__IsQuantityReadOnly__c,
           Apttus_Config2__PriceListItem__c.Customer_Specific_Price__c,
           Apttus_Config2__PriceListItem__c.Apttus_Config2__ListPrice__c,
           Apttus_Config2__PriceListItem__c.name,
           // Below fields are added for DCP-31789
           Apttus_Config2__PriceListItem__c.Apttus_Config2__PriceListId__c,
           Apttus_Config2__PriceListItem__c.Apttus_Config2__EffectiveDate__c,
           Apttus_Config2__PriceListItem__c.Apttus_Config2__ExpirationDate__c,
           Apttus_Config2__PriceListItem__c.Apttus_Config2__ProductId__c //INC0269173
       };
    }

     /**
     *  @author Govind Dubey
     *  @description Fetch the Price List Items based on Product ids
     *  @param recordIds Set of Product Ids
     *  @return List of Apttus_Config2__PriceListItem__c  
    **/
    public List<Apttus_Config2__PriceListItem__c> selectByProductIds(Set<Id> setProductIds)
    {
        ilib_LogQuery logger;
        if (Feature.isOn(QUERY_LOGS_SALES)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectByProductIds',
            UtilsCollection.serializeIds(setProductIds)
        );

        List<Apttus_Config2__PriceListItem__c> res = (List<Apttus_Config2__PriceListItem__c>) Database.query(
            newQueryFactory()
            .selectfield('Apttus_Config2__PriceListId__r.Name')
            .setCondition('Apttus_Config2__ProductId__c IN :setProductIds').toSOQL()
        );

        if (Feature.isOn(QUERY_LOGS_SALES)) logger.stop(res.size());
        return res;
    }

    /**
     *  @author Saswati 
     *  @description Fetch the Price List Items based on Product ids
     *  @param recordIds Set of Product Ids
     *  @return List of Apttus_Config2__PriceListItem__c  
    **/
    public List<Apttus_Config2__PriceListItem__c> selectByProductIdsAndPriceList(Set<Id> setProductIds, set<string> strPriceListName)
    {
        ilib_LogQuery logger;
        if (Feature.isOn(QUERY_LOGS_SALES)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectByProductIdsAndPriceList',
            UtilsCollection.serializeIds(setProductIds) + '--' + UtilsCollection.serializeIds(strPriceListName)
        );

        List<Apttus_Config2__PriceListItem__c> res = (List<Apttus_Config2__PriceListItem__c>) Database.query(
            newQueryFactory()
            .selectfield('Apttus_Config2__PriceListId__r.Name')
            .setCondition('Apttus_Config2__ProductId__c IN :setProductIds AND Apttus_Config2__PriceListId__r.Name IN :strPriceListName AND Apttus_Config2__Active__c = TRUE').toSOQL()
        );

        if (Feature.isOn(QUERY_LOGS_SALES)) logger.stop(res.size());
        return res;
    }
    
    /* Created By : Akshay Hedaoo
     * Description : CMCM-9780 : Quotation Line Item : Update Hide Contract Dates if PriceType is OneTime
     * @Parameter lstProposalLineItems
     * @return null
     */ 
    public List<Apttus_Config2__PriceListItem__c> fetchPriceTypeFromPriceListItem(Set<Id> priceListIds)
    {
        ilib_LogQuery logger; 
        if (Feature.isOn(QUERY_LOGS_SALES)) logger = new ilib_LogQuery(
            LOG_TITLE + '.fetchPriceTypeFromPriceListItem',
            UtilsCollection.serializeIds(priceListIds)
        );

        List<Apttus_Config2__PriceListItem__c> res = (List<Apttus_Config2__PriceListItem__c>) Database.query(
        newQueryFactory()
        .setCondition('Id IN: priceListIds')
        .toSOQL()
        );

        if (Feature.isOn(QUERY_LOGS_SALES)) logger.stop(res.size());
        return res;
    }

}