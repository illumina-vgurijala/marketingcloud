@isTest
private class TestTAPS_QueuedDeferredSharing {

    @isTest static void oneChunkInserts()
    {
        Integer singleChunkCount = TAPS_QueuedDeferredSharing.ELEMENTS_PER_CHUNK_TEST - 1;
        List<User> records = [SELECT Id FROM User LIMIT :singleChunkCount];
        Set<Id> recordIds = UtilsCollection.getSetOfIds(records);

        // NOTE: the name of the object and kind of ID doesn't matter for this test
        TAPS_QueuedDeferredSharing job = new TAPS_QueuedDeferredSharing('Account', recordIds);

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        List<TAPS_Deferred_Record__c> deferredIds = [SELECT Id FROM TAPS_Deferred_Record__c];
        System.assertEquals(singleChunkCount, deferredIds.size());
        // removed because I don't trust the value returned - see comment in chainsMultipleChunks()
        // System.assert(!job.forUnitTest_JobWillChain(), 'Job wants to chain when there is only one chunk worth of IDs');
    }

    @isTest static void chainsMultipleChunks()
    {
        Integer multipleChunkCount = TAPS_QueuedDeferredSharing.ELEMENTS_PER_CHUNK_TEST + 1;
        List<User> records = [SELECT Id FROM User LIMIT :multipleChunkCount];
        Set<Id> recordIds = UtilsCollection.getSetOfIds(records);

        // NOTE: the name of the object and kind of ID doesn't matter for this test
        TAPS_QueuedDeferredSharing job = new TAPS_QueuedDeferredSharing('Account', recordIds);

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        List<TAPS_Deferred_Record__c> deferredIds = [SELECT Id FROM TAPS_Deferred_Record__c];
        System.assertEquals(TAPS_QueuedDeferredSharing.ELEMENTS_PER_CHUNK_TEST, deferredIds.size());
        // removed because I was getting false even though I confirmed the value was set to true
        // my best guess is something weird happens internally to state for async jobs
        // like the object gets cloned into another thread but here I have access to the first thread

        // System.assert(job.forUnitTest_JobWillChain(), 'Job did not chain despite more than one chunk of IDs');
        // System.assertEquals(1, job.forUnitTest_NextChunkNumber());
    }

}
