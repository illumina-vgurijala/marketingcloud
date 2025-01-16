/**
*    @author Vaibhav
*    @date   15 Oct 2018
*    @description  Product Stock Selector class
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                  Date                   Description
*    KD                     25-June-2021            DCP-46257 : New method selectProductStocksByExternalId
*    Gladis                 22-Sep-2022         Added Query Instrumentation 
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class ProductStockSelector extends ilib_SObjectSelector{
    private static final String LOG_TITLE = 'ProductStockSelector';
    private static final  string SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    /**
     * @description: get the sobject type of SVMXC__Product_Stock__c.
     */
    public Schema.SObjectType getSObjectType()
    {
        return SVMXC__Product_Stock__c.sObjectType;
    }
    
    /**
     *  @author  Vaibhav
     *  @description Retrieve list of fields for SVMXC__Product_Stock__c sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
           SVMXC__Product_Stock__c.Id,
           SVMXC__Product_Stock__c.Name,
           SVMXC__Product_Stock__c.SVMXC__Location__c,
           SVMXC__Product_Stock__c.SVMX_PS_External_ID__c
       };
    }
    
   
   /**
     *  @author Vaibhav
     *  @description Fetch Product Stock based on Location External Id.
     *  @param 
     *  @return 
     **/
    public List<SVMXC__Product_Stock__c> selectProductStockByLocationExtId(Set<String> locationExtId) 
    {   
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectProductStockByLocationExtId', UtilsCollection.serializeIds(locationExtId));
        }
        List<SVMXC__Product_Stock__c> res = (List<SVMXC__Product_Stock__c>) Database.query(
            newQueryFactory().selectField('SVMXC__Location__r.SVMX_PS_External_ID__c')
                     .selectField('SVMXC__Quantity2__c')
                     .selectField('SVMXC__Status__c')
                     .selectField('SVMXC__Product__c')
                     .selectField('SVMX_PS_VS_Product_Tracking__c')
                     .setCondition('SVMXC__Location__r.SVMX_PS_External_ID__c IN :locationExtId').toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }
	
	 /**
     *  @author : Mandeep
     *  @description : Fetch Product Stock based on Location and Product.
     *  @param : Set of Location and Set of Product.
     *  @return : List of Product Stock
     **/
    public List<SVMXC__Product_Stock__c> selectProductStockByLocationAndProduct(Set<Id> setFromLocations , Set<Id> setProducts) 
    {
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectProductStockByLocationAndProduct', UtilsCollection.serializeIds(setFromLocations));
        }
        List<SVMXC__Product_Stock__c> res = (List<SVMXC__Product_Stock__c>) Database.query(
            newQueryFactory().selectField('SVMXC__Location__c')
                             .selectField('SVMXC__Product__c')
                             .setCondition('SVMXC__Location__c IN :setFromLocations AND SVMXC__Product__c IN : setProducts AND SVMXC__Status__c = \'Available\'').toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }
    
    /**
     *  @author : Ritika
     *  @description : Fetch Product Stock based on Location and Product.
     *  @param : Set of Location and Set of Product.
     *  @return : List of Product Stock
     **/ 
    public List<SVMXC__Product_Stock__c> selectProductStockByToFromLocationAndProduct(Set<Id> setFromLocations, Set<Id> setToLocation , List<Id> lstProducts, Set<String> setStatus) 
    { 
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectProductStockByToFromLocationAndProduct', UtilsCollection.serializeIds(setFromLocations));
        }
        List<SVMXC__Product_Stock__c> res = (List<SVMXC__Product_Stock__c>) Database.query(
            newQueryFactory().selectField('SVMXC__Location__c')
                             .selectField('SVMXC__Product__c')
            				 .selectField('SVMXC__Quantity2__c')
                              .selectField('SVMXC__Status__c')
                             .setCondition('(SVMXC__Location__c IN :setFromLocations OR SVMXC__Location__c IN: setToLocation) ' +
                                           ' AND SVMXC__Product__c IN : lstProducts AND SVMXC__Status__c =:setStatus').toSOQL()
        );
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }
	
	/**
     *  @author Sravan
     *  @description DCP-33467: Fetch Product Stock based on Id.
     *  @param product stock id
     *  @return Product Stock list
     **/
    public List<SVMXC__Product_Stock__c> selectProductStocksByIds(Set<Id> productStockIds) 
    {
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectProductStocksByIds', UtilsCollection.serializeIds(productStockIds));
        }
        List<SVMXC__Product_Stock__c> res = (List<SVMXC__Product_Stock__c>) Database.query(
            newQueryFactory().selectField('SVMXC__Quantity2__c').setCondition('Id IN :productStockIds').toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }
    /**
     *  @author KD
     *  @description DCP-46257 : Fetch by External id
     *  @param product stock id
     *  @return Product Stock list
     **/
    public List<SVMXC__Product_Stock__c> selectProductStocksByExternalId(Set<String> productStockExternalIds) 
    {
        ilib_LogQuery logger = new ilib_LogQuery();
        if (Feature.isOn('ServiceQueryLogs')){
            logger = new ilib_LogQuery(
            LOG_TITLE + '.selectProductStocksByExternalId',
            UtilsCollection.serializeIds(productStockExternalIds)
            );
        }
        String strQuery = newQueryFactory()
                        .selectField('SVMXC__Quantity2__c')
                        .setCondition('SVMX_PS_External_ID__c IN :productStockExternalIds')
                        .toSOQL();
        List<SVMXC__Product_Stock__c> res = (List<SVMXC__Product_Stock__c>) Database.query(strQuery);
        if (Feature.isOn('ServiceQueryLogs')){
            logger.stop(res.size());
        }
        return res;
    }
    
 }