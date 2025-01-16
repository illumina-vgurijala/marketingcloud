/**
*    @author Ashwin
*    @date   2021
*    @description  TAPS Deferred Record Selector
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                     Date                    Description
*         Ashwin                        31-Mar-2022             DCP-52339
*         Gerardo Garcia                09-01-2023              CMCM-3106
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public without sharing class CronTriggerSelector extends ilib_SObjectSelector {
    
    private static final String LOG_TITLE = 'CronTriggerSelector';
    private static final String SALES_QUERY_LOGS = 'SalesQueryLogs';

    public static final String STATE_WAITING  = 'WAITING';
    public static final String STATE_ACQUIRED = 'ACQUIRED';
    public static final String STATE_EXECUTING = 'EXECUTING';
    public static final String STATE_COMPLETE = 'COMPLETE';
    public static final String STATE_BLOCKED = 'BLOCKED';
    public static final String STATE_ERROR = 'ERROR';
    public static final String STATE_PAUSED = 'PAUSED';
    public static final String STATE_PAUSED_BLOCKED = 'PAUSED_BLOCKED';
    public static final String STATE_DELETED  = 'DELETED';

    /**
     *  @author Ashwin Kumar
     *  @description
     *  @return SObjectType The Schema.SObjectType of CronTrigger
    **/
    public Schema.SObjectType getSObjectType() {
        return CronTrigger.sObjectType;
    }

    /**
    *  @author  Ashwin Kumar
    *  @description Retrieve list of fields for CronTrigger
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            CronTrigger.Id
        };
    }

    /**
     *  @author Ashwin
     *  @description Get Jobs by JobType
     *  @return List of CronTrigger 
     **/
    public List<CronTrigger> getJobsByJobType(Set<String> setScheduledJobTypes) {
        
        ilib_LogQuery logger;
        if (Feature.isOn(SALES_QUERY_LOGS)) { 
            logger = new ilib_LogQuery(LOG_TITLE + '.getJobsByJobType', setScheduledJobTypes.toString());
        }

        List<CronTrigger> lstCronJobs = (List<CronTrigger>) Database.query(
            newQueryFactory()
            .setCondition('CronJobDetail.JobType IN :setScheduledJobTypes AND NextFireTime != null')
            .toSOQL()
        );

        if (Feature.isOn(SALES_QUERY_LOGS)) { logger.stop(lstCronJobs.size()); }
        return lstCronJobs;
    }

    /**
     *  @author Ashwin
     *  @description Get Jobs by jobName and job type
     *  @return List of CronTrigger 
     **/
    public List<CronTrigger> getJobsByNameAndJobType(String jobName, String scheduledApexJobType) {
        
        ilib_LogQuery logger;
        if (Feature.isOn(SALES_QUERY_LOGS)) { 
            logger = new ilib_LogQuery(LOG_TITLE + '.getJobsByNameAndJobType', jobName+'|'+scheduledApexJobType);
        }

        List<CronTrigger> lstCronJobs = (List<CronTrigger>) Database.query(
            newQueryFactory()
            .setCondition('CronJobDetail.Name LIKE :jobName AND CronJobDetail.JobType =:scheduledApexJobType AND NextFireTime != null')
            .toSOQL()
        );

        if (Feature.isOn(SALES_QUERY_LOGS)) { logger.stop(lstCronJobs.size()); }
        return lstCronJobs;
    }

    /**
     *  @author Gerardo Garcia
     *  @description Gets jobs by name and state. Max 150 results.
     *  @return List of CronTrigger
     **/
    public List<CronTrigger> getJobsByNameAndState(String jobName, String state) {
        
        ilib_LogQuery logger;
        if (Feature.isOn(SALES_QUERY_LOGS)) { 
            logger = new ilib_LogQuery(LOG_TITLE + '.getDeletedJobsByName', jobName);
        }
        
        List<CronTrigger> lstCronJobs = (List<CronTrigger>) Database.query(
            newQueryFactory()
            .setCondition('CronJobDetail.Name LIKE :jobName AND State =:state')
            .setLimit(150)
            .toSOQL()
        );

        if (Feature.isOn(SALES_QUERY_LOGS)) { logger.stop(lstCronJobs.size()); }
        return lstCronJobs;
    }

}