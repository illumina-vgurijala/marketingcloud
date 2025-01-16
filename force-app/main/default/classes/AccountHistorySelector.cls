/**
*    Description - Class to get the AccountHistory records 
*    Modification Log:
*   ------------------------------------------------------------------------------------------------
*    Developer                      Date                		Description
*	 Maruthi						20th MAY 2022				RITM0638393 added  
*    -----------------------------------------------------------------------------------------------
*/
public with sharing class AccountHistorySelector extends ilib_SObjectSelector{
    private static final string  LOG_TITLE = 'AccountHistorySelector';
    private static final  string SALES_QUERY_LOGS = 'SalesQueryLogs';
    

    /**
    *  @author Maruthi B 
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the Object History
    **/
   public Schema.SObjectType getSObjectType() {
        return AccountHistory.sObjectType;
   }

   /**
     *  @author  Maruthi
     *  @description Retrieve list of fields for Object History sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList() { 
    	return new List<Schema.SObjectField> {            
        	AccountHistory.Field, 
            AccountHistory.OldValue, 
            AccountHistory.NewValue,
            AccountHistory.AccountId            
        };
    }
    /*
     * @Author : Maruthi B
     * @Decription : Fetch Account History reocrds
     * @Param Set Account id and field name
     * @return  List of AccountHistory
    */
    public List<AccountHistory> selectObjectHistory(Set<Id> setAccountIds, String strField) {        
        ilib_LogQuery logger=null;
        if(Feature.isOn(SALES_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectObjectHistory', UtilsCollection.serializeIds(setAccountIds));
        List<AccountHistory> res = (List<AccountHistory>) Database.query(
                                    newQueryFactory()
                                    .selectField('Field')
                                    .selectField('OldValue')
                                    .selectField('NewValue')
                                    .selectField('AccountId')                                
                                    .setCondition('Field =: strField  AND AccountId IN :setAccountIds')
                                    .toSOQL()
                                   );
                                  
        if(Feature.isOn(SALES_QUERY_LOGS))
        logger.stop(res.size());

        return res;
    } 
    
}