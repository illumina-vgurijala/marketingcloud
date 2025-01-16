/**
*    @author Todd Newman
*    @date  17-12-2020   
*    Modification Log:
*    -------------------------------------------------------------------------------------------------------------------------------------
*       Developer           Date            Description
*       Todd Newman      17-12-2020         Created for Deferring Execution as part of DCP-43261/TASK0548217
*       Ashwin Kumar     11-Mar-2022        DCP-52339: Insert deferred records by using TAPS_DeferredRun.insertDeferredRecs()
* -------------------------------------------------------------------------------------------------------------------------------------
**/
public without sharing class DeferExecution implements ITAPS_ExecutionStrategy
{
    List<TAPS_Deferred_Record__c> processingRecords = new List<TAPS_Deferred_Record__c>();
    /**
    * @author Todd
    * @decription  creates list of processing records   
    **/
    public void processChunk(String objectName, Set<Id> idChunk)
    {
        processingRecords.addAll(TAPS_DeferredRun.getDeferredList(objectName, idChunk));
    }
    /**
    * @author Todd
    * @decription  inserts TAPS_Deferred_Record__c records   
    **/
    public void execute()
    {
        if (processingRecords.isEmpty()) { return; }

        TAPS_DeferredRun.insertDeferredRecs(processingRecords);         //DCP-52339
    }
}