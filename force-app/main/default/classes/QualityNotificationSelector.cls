/**
 *    @author Preetha
 *    @date   03-Sep-2022
 *    @description    Class to get the Quality Notification records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *   ------------------------------------------------------------------------------------ 
 */
public with sharing class QualityNotificationSelector extends ilib_SObjectSelector {
    private static final String LOG_TITLE = 'QualityNotificationSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    /**
    *  @author Preetha
    *  @description : Initialization of the Quality Notification object
    *  @return SObjectType The Schema.SObjectType of the proposal
    */
    public Schema.SObjectType getSObjectType() {
        return Quality_Notification__c.sObjectType;
    }
    /**
    *  @author  Preetha
    *  @description Retrieve list of fields for Quality Notification sObject 
    *  @return sObjectFieldList list of Schema.SObjectField
    */
    public List<Schema.SObjectField> getSObjectFieldList() { 
        return new List<Schema.SObjectField> {
            Quality_Notification__c.id,
            Quality_Notification__c.Name,
            Quality_Notification__c.ERP_Sales_Order__c,
            Quality_Notification__c.ERP_Sales_Order_Item__c,
            Quality_Notification__c.Parts_Order__c,
            Quality_Notification__c.Parts_Order_Line__c,
            Quality_Notification__c.Quality_Notification_Number__c
        };
    }
     /**
     *  @author Preetha
     *  @description Fetch Quality Notification associated with Parts Order 
     *  @param Parts order ids
     *  @return Quality Notification
     */
    public List<Quality_Notification__c> selectQNwithPO(Set<Id> setPartsOrderIds) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectQNwithPO', UtilsCollection.serializeIds(setPartsOrderIds));
        }
        String strQuery = newQueryFactory()
            .selectField('id')
            .selectField('Parts_Order__c')
            .selectField('Parts_Order__r.Name')
            .selectField('Parts_Order_Line__c')  
            .selectField('Parts_Order_Line__r.Name')  
            .selectField('Quality_Notification_Number__c')  
            .selectField('ERP_Sales_Order__c')  
            .selectField('ERP_Sales_Order_Item__c')   
            .setCondition('Parts_Order__c IN: setPartsOrderIds')
            .toSOQL();
        List<Quality_Notification__c> res = (List<Quality_Notification__c>) Database.query(strQuery);
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;
    }
}