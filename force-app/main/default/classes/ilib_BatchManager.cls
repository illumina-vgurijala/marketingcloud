/*
this class is a replacement for calls to Database.executeBatch()
instead clients should call ilib_BatchManager.executeBatch()

if the flex queue is not full, that method will turn around and make the system call
but if the flex queue is full, the details of the execution will be stored and tried again later

An optional parameter - runAsContextUser should be true if it's important who makes the updates in the batch class
deferred batches will generally run as a system administrator
which a) is not the user who triggered the update and b) might be able to bypass validations we don't want to be bypassed

however when runAsContextUser = true and the flex queue is full this class will attempt to schedule a future run
if the system has no room for scheduled jobs, all we can do is throw an error
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Nishan Shetty         13-June-2022              Fixed the bug related to batchSize as part of DCP-50962 user story.
*/

public with sharing class ilib_BatchManager {

    private static final String SCHEDULED_JOB_NAME_PREFIX = 'Delayed Job:';

    /* if unable to defer batch */
    public class DeferralException extends Exception { }

    /* run or defer the batch instance */
    public static Boolean executeBatch(ilib_BatchDeferrable batchClass)
    {
        return executeBatch(batchClass, batchClass.getDefaultBatchSize());
    }

    /* run or defer the batch instance with a given batch size */
    public static Boolean executeBatch(ilib_BatchDeferrable batchClass, Integer batchSize)
    {
        return executeBatch(batchClass,batchSize,false);//DCP-50962
    }

    /* run or defer the batch instance as the current user with a given batch size. Note this could throw an error */
    public static Boolean executeBatch(ilib_BatchDeferrable batchClass, Integer batchSize, Boolean runAsContextUser)
    {
        Boolean useBatchManager = Feature.isOn('ArchitectureBatchManager');
        //CMSI-19: Transaction id 
        batchClass.setTransactionId(ilib_LogEvent.getTransactionId());
        // if runAsContextUser = true use the non-buffered value, otherwise use the buffered value
        Boolean considerBuffer = !runAsContextUser;

        // determine if flex queue is nearing full
        Integer flexQueueAvailableCapacity = ilib_BatchSettings.getFlexQueueCapacity(considerBuffer);

        if (!useBatchManager || flexQueueAvailableCapacity > 0)
        {
            // flex queue has room, execute now
            Database.executeBatch(batchClass, batchSize);
            return true;
        }
        else
        {
            // queue is full, defer execution to later
            return deferExecution(batchClass, batchSize, runAsContextUser);
        }
    }

    private static Boolean deferExecution(ilib_BatchDeferrable batchClass, Integer batchSize, Boolean runAsContextUser)
    {
        Id deferredBatchJobId = persistDeferralInformation(batchClass, batchSize, runAsContextUser);

        if (runAsContextUser)
        {
            // try to schedule
            // gets ID of job if successful
            String response = scheduleJobSafe(new ilib_BatchRunner(deferredBatchJobId));

            if (response instanceOf Id)
            {
                // Success!
                return true;
            } else {
                ApexExceptions.emit('ilib_BatchManager', 'Unable to run batch job as context user.  ' + response,ilib_LogEvent.SALES);
                throw new DeferralException('Unable to run batch job as context user.  ' + response);
            }
        }
        else
        {
            return false;
        }
    }

    private static Id persistDeferralInformation(ilib_BatchDeferrable batchClass, Integer batchSize, Boolean runAsContextUser)
    {
        String serializedInputs = batchClass.serializeInputs();

        // store deferred batch information
        Deferred_Batch_Job__c deferredBatchJob = new Deferred_Batch_Job__c(
            Name = batchClass.getName(),
            Serialized_Inputs__c = serializedInputs,
            Batch_Size__c = batchSize
        );

        // include the running user in the deferral information
        if (runAsContextUser) { deferredBatchJob.Executing_User__c = UserInfo.getUserId(); }

        insert deferredBatchJob;
        return deferredBatchJob.Id;
    }

    private static String scheduleJobSafe(Schedulable job)
    {
        String cron = createCronString();
        String jobName = SCHEDULED_JOB_NAME_PREFIX + UtilsObject.getRandom(10);

        try
        {
            return System.schedule(jobName, cron, job);
        }
        catch (AsyncException e)
        {
            return e.getMessage();
        }
    }

    private static String createCronString()
    {
        Integer minuteDelay = ilib_BatchSettings.getSchedulerDelayInMinutes();
        Datetime scheduleAt = Datetime.now().addMinutes(minuteDelay);

        String year = String.valueOf(scheduleAt.year());
        String month = String.valueOf(scheduleAt.month());
        String day = String.valueOf(scheduleAt.day());
        String hour = String.valueOf(scheduleAt.hour());
        String minute = String.valueOf(scheduleAt.minute());

        String strSchedule = '0 ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
        return strSchedule;
    }

}


/*
DCP-49395

Metadata
Code_Parameter.Batch_Manager_Settings
Feature_Flag.ArchitectureBatchManager
Job_Detail.Batch_Manager_1
Job_Detail.Batch_Manager_2
Job_Detail.Batch_Manager_3

Object
Deferred_Batch_Job__c
plus layout

Classes
ilib_BatchManager (93%)
ilib_BatchRunner (100%)
ilib_BatchSettings (93%)
ilib_BatchDeferrable (100%)
EmailBuilder (100%)

ilib_BatchManagerTestBatchable (100%)
ilib_BatchManagerTest
ilib_BatchRunnerTest
TestEmailBuilder
ilib_ScheduledNotificationsTest
ilib_ScheduledNotificationsTestImpl (100%)

Other Classes
ilib_ScheduledNotifications (87%)
AgreementLineStatusBatchUpdate
BatchUpdateChildRecordsForNewASA
ApttusAgreementLineItemsService
CustomerMasterDataReceiver
BatchPriceRiseNotification
BatchTamDeadlineNotification

In Other Branch
BatchPendingApprovalNotification  DCP-46934


sfdx force:apex:test:run -c --detailedcoverage -r human -d "logs" -w 10 -u devqtly -n "ilib_BatchManagerTest,ilib_BatchRunnerTest"


OLS
Read/Create/Edit for all profiles; Modify All for usual 3
FLS Edit for all profiles for Batch_Size__c, Executing_User__c, Processed_Date__c, Serialized_Inputs__c

Manual
Schedule jobs

*/