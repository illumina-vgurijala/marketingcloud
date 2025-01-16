/*
*    @author: Pankaj Singla
*    @date:   12-Aug-2020
*    @description:  Selector class for KeyOpinionLeader Object
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla		        12-Aug-2020		       Initial Build
*             Rishab Wali               07-June-2022           [DCP-53883] Adding Query Instrumentation		
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class KeyOpinionLeaderSelector extends ilib_SObjectSelector{
	
    public static final string LOG_TITLE = 'KeyOpinionLeaderSelector';
    public static final String MARKETING_QUERY_LOGS = 'MarketingQueryLogs';

    /**Method - Get sobjectType */
    public Schema.SObjectType getSObjectType()
    {
        return Key_Opinion_Leader_Data__c.sObjectType;
    }
    
	/*
    *  @author  Pankaj singla
    *  @description Retrieve list of fields for KeyOpinionLeader Object 
    *  @return sObjectFieldList list of Schema.SObjectField
    */
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField>{
            Key_Opinion_Leader_Data__c.Id,
            Key_Opinion_Leader_Data__c.Name,
            Key_Opinion_Leader_Data__c.KOL__c,
            Key_Opinion_Leader_Data__c.Last_Interaction_Date__c,
			Key_Opinion_Leader_Data__c.Last_Interaction_Name__c,
			Key_Opinion_Leader_Data__c.Last_Interaction_Type__c,
			Key_Opinion_Leader_Data__c.MainLMNContact__c                
         };
    }
    
	/*
    *  @author Pankaj singla
    *  @description Fetch the KeyOpinionLeader
    *  @param lst of KeyOpinionLeader
    *  @return List of KeyOpinionLeader  
    */
    public List<Key_Opinion_Leader_Data__c> selectKOLByContactIds(Set<Id> setContactIds){
        ilib_LogQuery logger = null;

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectKOLByContactIds',UtilsCollection.serializeIds(setContactIds));
        }

        List<Key_Opinion_Leader_Data__c> res = (List<Key_Opinion_Leader_Data__c>) Database.query(
                                                newQueryFactory()                  
                                                .setCondition('MainLMNContact__c in:setContactIds').toSOQL()    
                                                );
        if (Feature.isOn(MARKETING_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }
}