/**
 *    @author Avina
 *    @date   29-08-2022
 *    @description    Class to get the Custom Quick Text records based on different conditions
 *    Modification Log:
 *    -------------------------------------------------------------------------------------------------------------------
 *      Developer                      Date                Description
 *      Avina                        29-08-2022          Initial Version
 * */
public with sharing class CustomQuickTextSelector extends ilib_SObjectSelector {
    private static final string  LOG_TITLE = 'CustomQuickTextSelector';
    private static final  string SERVICE_QUERY_LOGS = 'ServiceQueryLogs';

    /**
    *  @author Avina 
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the proposal
    **/
    public Schema.SObjectType getSObjectType()
    {
        return Custom_Quick_Text__c.sObjectType;
    }
    /**
     *  @author  Avina 
     *  @description Retrieve list of fields for Custom Quick Text sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     */
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
        return new List<Schema.SObjectField> {
            Custom_Quick_Text__c.Name,
            Custom_Quick_Text__c.Template__c,
            Custom_Quick_Text__c.Related_Object__c
        };
    }
 /**
     *  @author Avina
     *  @description Fetch the custom Quick Text records by object name
     *  @param objectName
     *  @return List of custom Quick Text
     */
    public List<Custom_Quick_Text__c> selectCustomQuickTextbyObject(String objectName) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCustomQuickTextbyObject', objectName);

            List<Custom_Quick_Text__c> res = (List<Custom_Quick_Text__c>) Database.query(
            newQueryFactory()
            .selectField('Name')
            .selectField('Template__c')
            .setCondition('Related_Object__c = : objectName')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger.stop(res == null ? 0 : 1);

        return res;
    }
}