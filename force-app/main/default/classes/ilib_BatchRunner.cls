/*
// This class runs in two situations
// (1) It will be scheduled to run every X minutes.  On each run it will run some deferred batch jobs if there is room in the flex queue
//     The no-argument constructor starts this process
//
// (2) ilib_BatchManager will schedule a single execute to run a specific batch as a specific user
//     While running in context as that specific user, ilib_BatchManager will schedule this class a few minutes in the future
//     The constructor with a single ID starts this process
*/
/*
* Test class for 90% coverage: ilib_BatchRunnerTest
* Test class for 75% coverage: ilib_BatchRunnerTest 
*	------------------------------------------------------------------------------------
*	Modification Log:
*	------------------------------------------------------------------------------------
*			Developer					Date				Description	
*           Todd Newman		                                Initial Version
*           Atit Kar                    2022-09-13          INC0419648 - added try catch block to catch the exception
*	------------------------------------------------------------------------------------
*/
global without sharing class ilib_BatchRunner extends ilib_ScheduleAndBatch {

    @TestVisible
    private Id specificBatchId = null;
    public static final String LOG_TITLE = 'ilib_BatchRunner';

    /* constructor to run as many deferred batches as possible */
    global ilib_BatchRunner() { }

    /* constructor to run a specific deferred batch */
    global ilib_BatchRunner(Id specificBatchId)
    {
        this.specificBatchId = specificBatchId;
    }

    /* run deferred batches */
    global override void execute(SchedulableContext sc)
    {
        ilib_LogEvent.setTitle(LOG_TITLE);
        ilib_LogEvent.push('execute');

        if (specificBatchId != null)
        {
            runSingleSpecificBatch();
        }
        else
        {
            runBatchClasses();
        }

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    private void runSingleSpecificBatch()
    {
        Integer flexQueueCapacity = ilib_BatchSettings.getFlexQueueCapacity(true);
        ilib_LogEvent.message('Flex Queue Capacity = ' + flexQueueCapacity);
        if (flexQueueCapacity == 0) return;

        // query for batch details using specificBatchId
        Deferred_Batch_Job__c storedBatchDetails = [
            SELECT Id, Name, Batch_Size__c, Executing_User__c, Serialized_Inputs__c, Processed_Date__c
            FROM Deferred_Batch_Job__c
            WHERE Id = :specificBatchId
        ];

        // prepare the batch class
        // INC0419648 - added try catch block to catch the exception
        try {
            ilib_BatchDeferrable batchClass = prepareSingleBatchClass(storedBatchDetails);

            // the flex queue might still be full so run the batch class using the manager
            Boolean isBatchExecutedNow = ilib_BatchManager.executeBatch(batchClass, Integer.valueOf(storedBatchDetails.Batch_Size__c), true);
    
            if (isBatchExecutedNow)
            {
                storedBatchDetails.Processed_Date__c = Date.today();
                update storedBatchDetails;
            }
        } catch(Exception e){
            ApexExceptions.emit(LOG_TITLE+ ' - '+storedBatchDetails.Name, e);
        }
    }

    private void runBatchClasses()
    {
        // figure out how many batches can be run
        // Flex Queue Capacity - Jobs holding in queue - buffer
        Integer flexQueueAvailableCapacity = ilib_BatchSettings.getFlexQueueCapacity(true);
        ilib_LogEvent.message('Flex Queue Capacity = ' + flexQueueAvailableCapacity);
        if (flexQueueAvailableCapacity == 0) return;

        // query rows from deferred batch table
        List<Deferred_Batch_Job__c> lstStoredBatchDetails = [
            SELECT Id, Name, Batch_Size__c, Executing_User__c, Serialized_Inputs__c, Processed_Date__c
            FROM Deferred_Batch_Job__c
            WHERE Processed_Date__c = null
            AND Executing_User__c = null
            ORDER BY CreatedDate ASC
            LIMIT :flexQueueAvailableCapacity];

        for (Deferred_Batch_Job__c storedBatchDetails : lstStoredBatchDetails)
        {
            // INC0419648 - added try catch block to catch the exception
            try {
                ilib_BatchDeferrable batchClass = prepareSingleBatchClass(storedBatchDetails);
                Database.executeBatch(batchClass, Integer.valueOf(storedBatchDetails.Batch_Size__c));
                storedBatchDetails.Processed_Date__c = Date.today();
            } catch(Exception e){
                ApexExceptions.emit(LOG_TITLE+ ' - '+storedBatchDetails.Name, e);
            }
        }
        update lstStoredBatchDetails;
    }

    @TestVisible
    private ilib_BatchDeferrable prepareSingleBatchClass(Deferred_Batch_Job__c storedBatchDetails)
    {
        // instantiate class
        String className = storedBatchDetails.Name;
        ilib_LogEvent.message('Will execute class ' + className);
        ilib_BatchDeferrable batchClass = (ilib_BatchDeferrable)(Type.forName(className).newInstance());

        // restore its state
        ilib_LogEvent.message('...with state ' + storedBatchDetails.Serialized_Inputs__c);
        batchClass.restoreInputs(storedBatchDetails.Serialized_Inputs__c);

        return batchClass;
    }

}