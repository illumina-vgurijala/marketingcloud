/**
*    @author Vaibhav
*    @date   15 Oct 2018
*    @description  Stocked Serial Selector class
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                  Date                   Description
*    KD                     25-June-2021            DCP-46257 : New method selectStockedSerialByExternalId
* 	 Vineeta Verma          9-Jan-2025              PRB0047876: To add logic for Serialized+Batched Products
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class StockedSerialSelector extends ilib_SObjectSelector{
    private static final String LOG_TITLE = 'StockedSerialSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    public static final String SVMCX_PRODUCT = 'SVMXC__Product__c';
    public static final String SVMX_PS_VS_PRODUCT_TRACKING = 'SVMX_PS_VS_Product_Tracking__c';
    public static final String BATCH_NUMBER = 'Batch_Number__c';
    public static final String QUANTITY = 'Quantity__c';
    public static final String SVMX_VS_LINKED_INSTALLED_PRODUCT = 'SVMX_PS_VS_Linked_Installed_Product__c';
	
    /**
    *  @author - Vaibhav 
    *  @return - SObjectType The Schema.SObjectType of the Product Serial
    **/
	
    public Schema.SObjectType getSObjectType()
    {
        return SVMXC__Product_Serial__c.sObjectType;
    }
    
    /**
     *  @author  Vaibhav 
     *  @description Retrieve list of fields for SVMXC__Product_Serial__c sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
           SVMXC__Product_Serial__c.Id,
           SVMXC__Product_Serial__c.Name,
           SVMXC__Product_Serial__c.SVMXC__Product_Stock__c,
           SVMXC__Product_Serial__c.SVMX_PS_External_ID__c
       };
    }
    
    
    
      /**
     *  @author Vaibhav
     *  @description Fetch Stocked Serial based on Product Stock Id.
     *  @param 
     *  @return 
     **/
    public List<SVMXC__Product_Serial__c> selectStockedSerialByProductStockExtId(Set<Id> productStockIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
			logger = new ilib_LogQuery(LOG_TITLE + '.selectStockedSerialByProductStockExtId', UtilsCollection.serializeIds(productStockIds));
		}
        //PRB0047876: adding more fields
        List<SVMXC__Product_Serial__c> res =  Database.query(
           newQueryFactory().selectField('SVMXC__Product_Stock__r.SVMXC__Location__c')
                     .selectField(SVMCX_PRODUCT)
            		 .selectField(SVMX_PS_VS_PRODUCT_TRACKING)
                     .selectField(BATCH_NUMBER)
            		 .selectField('SVMXC__Product_Stock__r.SVMXC__Status__c')
            		 .selectField(QUANTITY)
            		 .selectField('Location__r.ERP_Customer_ID__c')
                     .selectField('Product_Code__c')
            		 .selectField('SVMXC__Product__r.ProductCode')
                     .setCondition('SVMXC__Product_Stock__c IN :productStockIds').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
			logger.stop(res.size());
		}
		return res;
    }
    
	 /**
     *  @author : Mandeep
     *  @description : Fetch Stocked Serial based on Consumed Product and Product.
     *  @param : Set of Consumed Product and Set of Product.
     *  @return : List of Stocked Serial
     **/
    public List<SVMXC__Product_Serial__c> selectStockedSerialByConProductAndProduct(Set<Id> productStockIds , Set<Id> setProducts) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
			logger = new ilib_LogQuery(LOG_TITLE + '.selectStockedSerialByConProductAndProduct', UtilsCollection.serializeIds(productStockIds)+'|'+UtilsCollection.serializeIds(setProducts));
		}
        List<SVMXC__Product_Serial__c> res = Database.query(
           newQueryFactory().selectField(SVMCX_PRODUCT)
							 .selectField(SVMX_VS_LINKED_INSTALLED_PRODUCT)
                             .selectField(BATCH_NUMBER)
                             .setCondition('SVMXC__Product_Stock__c IN :productStockIds AND SVMXC__Product__c IN:setProducts').toSOQL()
           
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
			logger.stop(res.size());
		}
		return res;
    }

    /**
     *  @author : Ritika 
     *  @description : Fetch Stocked Serial based on Consumed Product and Product.
     *  @param : Set of Consumed Product and Set of Product.
     *  @return : List of Stocked Serial
     **/
    public List<SVMXC__Product_Serial__c> selectStockedSerialByProductStockAndProduct(Set<Id> lstConsumedProduct , List<Id> lstProducts) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
			logger = new ilib_LogQuery(LOG_TITLE + '.selectStockedSerialByProductStockAndProduct', UtilsCollection.serializeIds(lstConsumedProduct)+'|'+UtilsCollection.serializeIds(new Set<Id>(lstProducts)));
		}
        List<SVMXC__Product_Serial__c> res = Database.query(
           newQueryFactory().selectField('Name')
                             .selectField(SVMCX_PRODUCT)
            				 .selectField('SVMXC__Product_Stock__c')
            				 .selectField('SVMXC__Product_Stock__r.SVMXC__Location__c')
                             .selectField('SVMXC__Product_Stock__r.SVMXC__Status__c')
            				 .selectField(SVMX_VS_LINKED_INSTALLED_PRODUCT)
            				 .selectField('SVMX_PS_VS_Linked_Installed_Product__r.SVMXC__Serial_Lot_Number__c')
                             .selectField(QUANTITY)
                             .selectField('SVMX_PS_External_ID__c')
                             .selectField(SVMX_PS_VS_PRODUCT_TRACKING)
                             .selectField(BATCH_NUMBER)
                             .setCondition('SVMXC__Product_Stock__c IN :lstConsumedProduct AND SVMXC__Product__c IN:lstProducts').toSOQL()
            
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
			logger.stop(res.size());
		}
		return res;
    }
    
    /**
     *  @author Sravan
     *  @description DCP-33467: Fetch Stocked Serial with Id.
     *  @param Set of Stock Serial ids
     *  @return List of Stock Serials
     **/
    public List<SVMXC__Product_Serial__c> selectStockedSerialById(Set<Id> stockedSerialIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
			logger = new ilib_LogQuery(LOG_TITLE + '.selectStockedSerialById', UtilsCollection.serializeIds(stockedSerialIds));
		}
        List<SVMXC__Product_Serial__c> res =  Database.query(
           newQueryFactory()
            .selectField(QUANTITY)
            .selectField(SVMX_PS_VS_PRODUCT_TRACKING)
            .selectField('Product_Code__c')//DCP-44981 
            .selectField(SVMX_VS_LINKED_INSTALLED_PRODUCT)//DCP-44981 
            .setCondition('Id IN :stockedSerialIds').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
			logger.stop(res.size());
		}
		return res;
    }
    /**
     *  @author : KD 
     *  @description :DCP-46257 :  Fetch Stocked Serial based on external id
     *  @param : Set of Consumed Product and Set of Product.
     *  @return : List of Stocked Serial
     **/
    public List<SVMXC__Product_Serial__c> selectStockedSerialByExternalId(Set<String> setExternalId) 
    {
        ilib_LogQuery logger = null;
        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(
            LOG_TITLE + '.selectStockedSerialByExternalId',
            UtilsCollection.serializeIds(setExternalId)
            );
        }
        String strQuery = newQueryFactory().selectField('Name')
                        .selectField('SVMXC__Product__c')
                        .selectField('SVMXC__Product_Stock__c')
                        .selectField('SVMXC__Product_Stock__r.SVMXC__Location__c')
                        .selectField('SVMXC__Product_Stock__r.SVMXC__Status__c')
                        .selectField('SVMX_PS_VS_Linked_Installed_Product__c')
                        .selectField('SVMX_PS_VS_Linked_Installed_Product__r.SVMXC__Serial_Lot_Number__c')
                        .selectField('Quantity__c')
                        .selectField('SVMX_PS_External_ID__c')
                        .selectField('SVMX_PS_VS_Product_Tracking__c')
                        .selectField('Batch_Number__c')
                        .setCondition('SVMX_PS_External_ID__c IN :setExternalId').toSOQL();
        List<SVMXC__Product_Serial__c> res = (List<SVMXC__Product_Serial__c>) Database.query(strQuery);
        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;
    }
 }