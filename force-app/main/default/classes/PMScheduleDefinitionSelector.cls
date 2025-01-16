/**
*    @author Prashanth
*    @date   2019-08-14
*    @description PMScheduleDefinitionSelector class,DCP-28201
*    Modification Log:
*    -------------------------------------------------------------------------------------------------- 
*    Developer                  Date                   Description
*    Prashanth                  14 Aug 2019            SVMXC__PM_Schedule_Definition__c Selector Class
*    ---------------------------------------------------------------------------------------------------                  
*/
public with sharing class PMScheduleDefinitionSelector extends ilib_SObjectSelector 
{
    private static final String LOG_TITLE = 'PMScheduleDefinitionSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    
	/**
     *  @author - Prashanth
     *  @description - SObjectType The Schema.SObjectType of the PM Schedule Definition
     **/
    public Schema.SObjectType getSObjectType(){
        return SVMXC__PM_Schedule_Definition__c.sObjectType;
    }   
    /**
     *  @author  Prashanth 
     *  @description Retrieve list of fields for SVMXC__PM_Schedule_Definition__c sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
           SVMXC__PM_Schedule_Definition__c.Id,
           SVMXC__PM_Schedule_Definition__c.SVMXC__PM_Plan__c,
           SVMXC__PM_Schedule_Definition__c.SVMXC__Frequency__c,
           SVMXC__PM_Schedule_Definition__c.SVMXC__Frequency_Unit__c
        };
    }   
    /**
     *  @author Prashanth
     *  @description fetch the PM Scheduled Definitions on basis of PM Plans, DCP-28201
     *  @param Set of PM Plans
     *  @return SVMXC__PM_Schedule_Definition__c List
    **/
    public List<SVMXC__PM_Schedule_Definition__c> selectSchDefsForPMPlans(Set<Id> setPMPlans)
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectSchDefsForPMPlans', UtilsCollection.serializeIds(setPMPlans));
		
        List<SVMXC__PM_Schedule_Definition__c> res = (List<SVMXC__PM_Schedule_Definition__c>) Database.query(
            newQueryFactory().selectField('SVMXC__PM_Plan__r.SVMXC__Service_Contract__c')
            .selectField('SVMXC__PM_Plan__r.SVMXC__Service_Contract__r.SVMXC__End_Date__c')
            .selectField('SVMXC__PM_Plan__r.SVMXC__Service_Contract__r.SVMXC__Start_Date__c')
            .setCondition('SVMXC__PM_Plan__c IN :setPMPlans')
            .toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
}