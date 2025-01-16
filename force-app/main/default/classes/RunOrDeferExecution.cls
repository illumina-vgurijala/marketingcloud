/**
*    @author Todd Newman
*    @date  17-12-2020   
*    Modification Log:
*    -------------------------------------------------------------------------------------------------------------------------------------
*       Developer           Date            Description
*       Todd Newman        17-12-2020       Created for Run/Defer batches as part of DCP-43261/TASK0548217
*       Ashwin Kumar       11-Mar-2022      DCP-52339: Insert deferred records by using TAPS_DeferredRun.insertDeferredRecs()
* -------------------------------------------------------------------------------------------------------------------------------------
**/
public without sharing class RunOrDeferExecution implements ITAPS_ExecutionStrategy
{
    List<TAPS_Deferred_Record__c> deferredProcessingRecords = new List<TAPS_Deferred_Record__c>();
    /**
    * @author Todd
    * @decription  creates list of processing records   
    **/
    public void processChunk(String objectName, Set<Id> idChunk)
    {
        // kicks off a batch job if there is space in the flex queue
        // adds to deferredProcessingRecords if the queue is full
        TAPSBatches.runOrDeferBatch(idChunk, deferredProcessingRecords);
    }
    /**
    * @author Todd
    * @decription  inserts TAPS_Deferred_Record__c records   
    **/
    public void execute()
    {
        // batches are executed, if any records needed to be deferred, insert those jobs now
        if (deferredProcessingRecords.isEmpty()) { return; }

        TAPS_DeferredRun.insertDeferredRecs(deferredProcessingRecords);         //DCP-52339
    }
}