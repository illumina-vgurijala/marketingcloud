/**
 *    @author Kushagra Desai
 *    @date   9-Sept-2019
 *    @description   
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Bharath Varma                07-Sep-2021           DCP-46117 : Added method to return tasks from a set of Ids
 *    Nishan Shetty                07-Dec-2021           DCP-50978 : Added new Fields and Query Instrumentation for getAllTaskByWhoId.
 *	  Maruthi Bharath				23-Feb-2022			 PM-36: Added getAllTaskByWhoIdWithStatus
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class TaskSelector extends ilib_SObjectSelector{
    private static final String LOG_TITLE = 'TaskSelector';
    private static final String FEATURE_SALES_QUERY_LOGS = 'SalesQueryLogs';
	ilib_LogQuery logger;
   /*
    * @author Kushagra Desai
    * @date   8-Aug-2019   
    * @description  set select fields
    */
    public List<Schema.SObjectField> getSObjectFieldList()
    {   
        return new List<Schema.SObjectField> {
           Task.id,
           Task.Subject,
           Task.ActivityDate,
           Task.Status,
           Task.Description,
           Task.Priority,
           Task.OwnerId,
           Task.WhatId,
           Task.Owner_Full_Name__c,
           Task.WhoId
        };
    }

    /*
    * @author Kushagra Desai
    * @date   8-Aug-2019 
    * @description  describe the object
    *
    */
    public Schema.SObjectType getSObjectType()
    { 
        return Task.sObjectType;
    }
    /**
     * @author : Kushagra Desai
     * @description return all Task by WhatId
     * Returns  
     **/
    public List<Task> getAllTaskByWhoId(List<String> parentid)
    {   ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
           logger = new ilib_LogQuery(LOG_TITLE +'.getAllTaskByWhoId',UtilsCollection.serializeIds(new Set<String>(parentid)));
        }
        List<Task> res = (List<Task>)Database.query(
            newQueryFactory()
            .selectField('Owner.Name')
            .selectField('RecordType.DeveloperName')
            .selectField('Call_Result__c')
            .setCondition('WhatId IN :parentid').toSOQL());

        if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
            logger.stop(res == null ? 0 : 1);
        }
        return res;
    }
    /**
     * @author : Kushagra Desai
     * @description return all Task
     * Returns  
     **/
    public List<Task> getAllTask(String recordId)
    {
        return (List<Task>)Database.query(newQueryFactory().setCondition('Id =: recordId').toSOQL());
    }

    /**
     * @author : Bharath Varma
     * @description return all Tasks from the set
     * Returns  
     **/
    public List<Task> getTasksById(Set<Id> setTaskId)
    {
        return (List<Task>)Database.query(newQueryFactory().setCondition('Id in :setTaskId').toSOQL());
    }
		  
    /**
     * @author : Maruthi
     * @description return all Task by Set Of WhatId with Open Status
     * Returns  
     **/    
    public List<Task> getAllTaskByWhoIdWithStatus(Set<Id> parentIdSet, String strStatus) {        
        if (Feature.isOn('SalesQueryLogs')) logger  = new ilib_LogQuery(
            LOG_TITLE + '.getAllTaskByWhoIdWithStatus',
            UtilsCollection.serializeIds(parentIdSet)
        );
        List<Task> res = (List<Task>)Database.query(
            newQueryFactory().selectField('OwnerId')
            .selectField('WhatId')                            
            .setCondition('WhatId IN :parentIdSet and Status =: strStatus')
            .toSOQL()
        );        
        if (Feature.isOn('SalesQueryLogs')) logger.stop(res.size());

        return res;
    }
    
}