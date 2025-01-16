/**
*    @author 
*    @date   
*    @description JobManagerController sharing class
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    -----------------------------------------------------------------------------------------------------------------------------------
*            Aman Tyagi                     7th Oct 2022        Codescan fixes
*/
public with sharing class JobManagerController {
    public static final Integer TWELVE = 12;
    /**
     *  @author   
     *  @description static method to get job details
     *  @param NA
     *  @return List<JobDetails> 
     **/
    @AuraEnabled
    public static List<JobDetails> getJobDetails()
    {
        List<Job_Detail__mdt> mdtDetails =
            [SELECT MasterLabel, Batchable_Class_Name__c, Schedulable_Class_Name__c, Batch_Size__c, Cron_String__c, Production_Only__c
             FROM Job_Detail__mdt
             ORDER BY MasterLabel LIMIT 1000];

        List<JobDetails> lstJobDetails = new List<JobDetails>();
        for (Job_Detail__mdt d : mdtDetails)
            lstJobDetails.add(new JobDetails(d));

        findJobsAlreadyScheduled(lstJobDetails);

        return lstJobDetails;
    }

    @TestVisible private static void findJobsAlreadyScheduled(List<JobDetails> lstJobDetails)
    {
        // collect scheduled job names
        Set<String> jobNames = new Set<String>();
        for (JobDetails j : lstJobDetails)
            jobNames.add(j.scheduleName);

        // query for those names
        List<CronTrigger> cronsByName =
            [SELECT Id, CronJobDetail.Name
             FROM CronTrigger
             WHERE CronJobDetail.Name IN :jobNames];

        Set<String> scheduledJobNames = new Set<String>();
        for (CronTrigger ct : cronsByName)
            scheduledJobNames.add(ct.CronJobDetail.Name);

        // set scheduled flag on each row
        for (JobDetails j : lstJobDetails)
            j.currentlyScheduled = scheduledJobNames.contains(j.scheduleName);
    }

    /**
     *  @author   
     *  @description static method executeBatchNow
     *  @param String strJson
     *  @return NA
     **/
    @AuraEnabled
    public static void executeBatchNow(String strJson)
    {
        Map<String, Object> deserialized = (Map<String, Object>)JSON.deserializeUntyped(strJson);
        if (deserialized == null) return;

        String batchClassName = (String)deserialized.get('batchClassName');
        Integer batchSize = (Integer)deserialized.get('batchSize');
        System.debug('batchClassName ' + batchClassName);

        if (!String.isBlank(batchClassName))
        {
            Database.executebatch(getInstance(batchClassName), batchSize);
            return;
        }

        // if it was blank, must be scheduleable instead
        String schedClassName = (String)deserialized.get('scheduleClassName');
        System.debug('schedClassName ' + schedClassName);

        getInstance(schedClassName).execute(null);
    }

    /**
     *  @author   
     *  @description static method to schedule job
     *  @param String strJson
     *  @return Boolean
     **/
    @AuraEnabled
    public static boolean scheduleJob(String strJsonArray)
    {
        List<String> lstJson = strJsonArray.removeStartIgnoreCase('undefined').split(';');
        if (lstJson.size() == 0) return false;

        for (String strJson : lstJson)
        {
            if (String.isBlank(strJson)) return false;

            Map<String, Object> deserialized = (Map<String, Object>)JSON.deserializeUntyped(strJson);
            if (deserialized == null) return null;

            String scheduleName = (String)deserialized.get('scheduleName');
            String scheduleClassName = (String)deserialized.get('scheduleClassName');
            String cronString = (String)deserialized.get('cronString');

            if (getScheduledJobId(scheduleName) != null) return false; // already scheduled

            System.schedule(scheduleName, cronString, getInstance(scheduleClassName));
        }

        return true;
    }

    /**
     *  @author   
     *  @description static method to unschedule job
     *  @param String strJsonArray
     *  @return Boolean
     **/
    @AuraEnabled
    public static Boolean unscheduleJob(String strJsonArray)
    {
        System.debug(strJsonArray);
        List<String> lstJson = strJsonArray.removeStartIgnoreCase('undefined').split(';');
        if (lstJson.size() == 0) return false;

        for (String strJson : lstJson)
        {
            if (String.isBlank(strJson)) return false;

            Map<String, Object> deserialized = (Map<String, Object>)System.JSON.deserializeUntyped(strJson);

            String scheduleName = (String)deserialized.get('scheduleName');

            Id jobId = getScheduledJobId(scheduleName);

            if (jobId != null)
                System.abortJob(jobId);
        }

        return true;
    }

    private static Id getScheduledJobId(String scheduleName)
    {
        List<CronTrigger> cronsByName =
            [SELECT Id, CronJobDetail.Id, CronJobDetail.JobType, CronJobDetail.Name
             FROM CronTrigger
             WHERE CronJobDetail.Name = :scheduleName];
        System.debug('cronsByName ' + cronsByName);

        return (cronsByName.size() > 0 ? cronsByName[0].Id : null);
    }

    private static ilib_ScheduleAndBatch getInstance(String className)
    {
        Type customType = Type.forName(className);
        ilib_ScheduleAndBatch instance = (ilib_ScheduleAndBatch)customType.newInstance();
        return instance;
    }

    /**
     *  @author   
     *  @description JobDetails class
     **/
    public class JobDetails
    {
        @AuraEnabled public String scheduleName;
        @AuraEnabled public String cronString;
        @AuraEnabled public Boolean productionOnly;
        @AuraEnabled public String scheduleClassName;
        @AuraEnabled public String batchClassName;
        @AuraEnabled public Integer batchSize;
        @AuraEnabled public Boolean currentlyScheduled;
        @AuraEnabled public Boolean selected;
        @AuraEnabled public String friendlyCron;

        /**
         *  @author   
         *  @description parameterized constructor of the class JobDetails
         *  @param Job_Detail__mdt mdtDetails
         *  @return NA
         **/
        public JobDetails(Job_Detail__mdt mdtDetails)
        {
            this.scheduleName = mdtDetails.MasterLabel;
            this.cronString = mdtDetails.Cron_String__c;
            this.productionOnly = mdtDetails.Production_Only__c;
            this.scheduleClassName = mdtDetails.Schedulable_Class_Name__c;
            this.batchClassName = mdtDetails.Batchable_Class_Name__c;
            this.batchSize = Integer.valueOf(mdtDetails.Batch_Size__c);
            this.currentlyScheduled = false;
            this.selected = false;
            this.friendlyCron = getCronDate(this.cronString);
        }

        private String getCronDate(String cr)
        {
            if (String.isBlank(cr)) return '';

            // FORMAT = seconds minutes hours day month
            List<String> cronParts = cr.split(' ');
            Boolean isHourly = ('*' == cronParts.get(2));
            Boolean isDaily = !isHourly;
            Boolean isValid = true;
            Integer hourOfDay = -1;

            if (isDaily)
            {
                try
                {
                    hourOfDay = Integer.valueOf(cronParts.get(2));
                }
                catch (Exception e)
                {
                    isValid = false;
                }
            }

            String friendlyCron = '';

            if (!isValid)
                friendlyCron = '??';
            else
            {
                if (isHourly)
                    friendlyCron = 'Hourly';
                else
                {
                    String friendlyHour = '';
                    if (hourOfDay == 0)
                        friendlyHour = 'midnight';
                    else if (hourOfDay == TWELVE)
                        friendlyHour = 'noon';
                    else
                        friendlyHour = hourOfDay + ':00';

                    friendlyCron = 'Daily at ' + friendlyHour;
                }
            }
            System.debug(friendlyCron);

            return friendlyCron;
        }

    }

}