trigger TAPSBatchTrigger on TAPS_Batch__e (after insert) {

    ilib_SObjectDomain.triggerHandler(TAPSBatches.class);

}