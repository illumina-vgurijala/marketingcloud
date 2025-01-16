/**
*    @author Todd Newman
*    @date  17-12-2020   
*    Modification Log:
*    -------------------------------------------------------------------------------------------------------------------------------------
*       Developer           Date            Description
*       Todd Newman        17-12-2020       Created for Running immediate shares as part of DCP-43261/TASK0548217
* -------------------------------------------------------------------------------------------------------------------------------------
**/
public without sharing class PublishExecution implements ITAPS_ExecutionStrategy
{
    List<TAPS_Batch__e> processingRecords = new List<TAPS_Batch__e>();
    /**
    * @author Todd
    * @decription  creates list of processing records   
    **/
    public void processChunk(String objectName, Set<Id> idChunk)
    {
        // TODO: the TAPSBatches API is awkward, could clean it there
        String serializedIds = TAPSBatches.customIdSerialization(idChunk);
        processingRecords.addAll(TAPSBatches.buildEvents(new List<String> {serializedIds}));
    }
    /**
    * @author Todd
    * @decription  inserts TAPS_Batch__e records   
    **/
    public void execute()
    {
        if (processingRecords.isEmpty()) return;

        // TODO: make this an API of TAPSBatches too
        EventBus.publish(processingRecords);
    }
}