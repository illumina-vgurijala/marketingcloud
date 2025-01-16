/*
*  @Author: Sudarshan Kataria
*  @Date: 2023-11-29
*  @Description: TradeInProducts Selector
*  @Test Class
   - TestTradeInProductsSelector
*  Modification Log:
*  ---------------------------------------------------------------------------------------------------------------------------
*       Developer                       Date(YY-MM-DD)                  Description
*       Sudarshan Kataria               2023-11-29                      Initial Version CMCM-1354
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class TradeInProductsSelector extends ilib_SObjectSelector {
    private static final String LOG_TITLE = 'TradeInProductsSelector';
	private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';

    /**
    *  @author Sudarshan Kataria
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the Order
    **/
    public Schema.SObjectType getSObjectType()
    {
         return Trade_In_Product__c.sObjectType;
    }

    /**
    *  @author  Sudarshan Kataria
    *  @description Retrieve list of fields for Trade_In_Product__c sObject 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
        return new List<Schema.SObjectField> {
            Trade_In_Product__c.id,
            Code_Library__c.Name 
            };
    }
 
    /**
    *  @author Sudarshan Kataria
    *  @description Fetch code Library records on basis of code title
    *  @param code title
    *  @return List of Code Library
    **/
    public List<Trade_In_Product__c> selectTradeInProductsForQuotes(Set<Id> quoteIds) 
    {
        ilib_LogQuery logger=null; 
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectTradeInProductsForQuotes', UtilsCollection.serializeIds(quoteIds));
        }
		
        List<Trade_In_Product__c> res = (List<Trade_In_Product__c>) Database.query(
            newQueryFactory()
            .selectField('Id')
            .selectField('Quote_Proposal__c')
            .selectField('Installed_Product__c') 
            .selectField('Installed_Product__r.SVMXC__Company__c')
            .selectField('Installed_Product__r.SVMXC__Contact__c')
            .selectField('Installed_Product__r.SVMXC__Site__c') 
            .selectField('Installed_Product__r.SVMXC__Product__c')  
            .selectField('Installed_Product__r.SVMXC__Serial_Lot_Number__c') 
            .selectField('Installed_Product__r.SVMXC__Product__r.Name')
            .setCondition('Quote_Proposal__c IN : quoteIds').toSOQL()
        );
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
}