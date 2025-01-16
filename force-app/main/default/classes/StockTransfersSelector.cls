/**
*    @author Vaibhav
*    @date   15 Oct 2018
*    @description  StockedTransfer Selector class
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                  Date                   Description
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class StockTransfersSelector extends ilib_SObjectSelector{
    private static final String LOG_TITLE = 'StockTransfersSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    /**
    *  @author  Sandeep Ram Ch.
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the stock transfer
    **/
    public Schema.SObjectType getSObjectType()
    {
        return SVMXC__Stock_Transfer__c.sObjectType;
    }
    
    /**
     *  @author  Vaibhav 
     *  @description Retrieve list of fields for SVMXC__Stock_Transfer__c sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
           SVMXC__Product_Serial__c.Id,
           SVMXC__Product_Serial__c.Name
       };
    }
    
    /**
     *  @author Vaibhav
     *  @description Fetch Stocked Serial based on External Id.
     *  @param :Set of Stock Transfer Ids.
     *  @return List of Stock Transfer Records.
     **/
    public List<SVMXC__Stock_Transfer__c> selectStockTransferById(Set<Id> setStockTransferIds) 
    {
        ilib_LogQuery logger=null;
		if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
			logger = new ilib_LogQuery(LOG_TITLE + '.selectStockTransferById', UtilsCollection.serializeIds(setStockTransferIds));
		}
        List<SVMXC__Stock_Transfer__c> res = Database.query(
           newQueryFactory().setCondition('Id IN :setStockTransferIds').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
			logger.stop(res.size());
		}
		return res;
    }
    
   
    
 }