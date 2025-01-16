/**
*    @author Prashanth
*    @date   2019-10-04
*    @description PMScheduleSelector class,DCP-28201
*    Modification Log:
*    -------------------------------------------------------------------------------------------------- 
*    Developer                  Date                   Description
*    Prashanth                  10 Oct 2019            SVMXC__PM_Schedule__c Selector Class
*    ---------------------------------------------------------------------------------------------------                  
*/
public with sharing class PMScheduleSelector extends ilib_SObjectSelector 
{
    private static final String LOG_TITLE = 'PMScheduleSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    
	/**
     *  @author - Prashanth 
     *  @return - SObjectType The Schema.SObjectType of the PM Schedule 
     **/
    public Schema.SObjectType getSObjectType(){
        return SVMXC__PM_Schedule__c.sObjectType;
    }   
    /**
     *  @author  Prashanth 
     *  @description Retrieve list of fields for SVMXC__PM_Schedule__c sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
           SVMXC__PM_Schedule__c.Id,
           SVMXC__PM_Schedule__c.SVMXC__PM_Plan__c,
           SVMXC__PM_Schedule__c.SVMXC__Last_Run_Date__c,
           SVMXC__PM_Schedule__c.SVMXC__Scheduled_On__c
        };
    }   
    /**
     *  @author Prashanth
     *  @description fetch the PM Schedules on basis of PM Plans, DCP-28201
     *  @param Set of PM Plans
     *  @return List<SVMXC__PM_Schedule__c>
    **/
    public List<SVMXC__PM_Schedule__c> selectSchsForPMPlans(Set<Id> setPMPlans)
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectSchsForPMPlans', UtilsCollection.serializeIds(setPMPlans));
		
        List<SVMXC__PM_Schedule__c> res = (List<SVMXC__PM_Schedule__c>) Database.query(
            newQueryFactory().setCondition('SVMXC__PM_Plan__c IN :setPMPlans')
            .toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
}