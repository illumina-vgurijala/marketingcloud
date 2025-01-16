@isTest
private class ilib_BatchManagerTest {

    private final static String TEST_INPUT = 'Serializable Input';

    @isTest
    public static void baseClassCoverage()
    {
        ilib_BatchDeferrable batchClass = new ilib_BatchDeferrable();

        // default batch size is correct
        System.assertEquals(ilib_BatchDeferrable.DEFAULT_BATCH_SIZE, batchClass.getDefaultBatchSize());

        // get name works properly
        System.assertEquals('ilib_BatchDeferrable', batchClass.getName());

        // everything in this class throws an exception because it should be overridden by a descendent

        try {
            batchClass.start(null);
            System.assert(false, 'start method should require override');
        } catch (Exception e) { System.assert(true); }

        try {
            batchClass.execute(null, null);
            System.assert(false, 'execute method should require override');
        } catch (Exception e) { System.assert(true); }

        try {
            batchClass.finish(null);
            System.assert(false, 'finish method should require override');
        } catch (Exception e) { System.assert(true); }

        try {
            batchClass.serializeInputs();
            System.assert(false, 'serializeInputs method should require override');
        } catch (Exception e) { System.assert(true); }

        try {
            batchClass.restoreInputs(null);
            System.assert(false, 'restoreInputs method should require override');
        } catch (Exception e) { System.assert(true); }
    }

    @isTest
    public static void serializations()
    {
        ilib_BatchManagerTestBatchable batchClass = new ilib_BatchManagerTestBatchable(TEST_INPUT);

        String serializedInputs = batchClass.serializeInputs();
        System.assert(serializedInputs.contains(TEST_INPUT));

        ilib_BatchManagerTestBatchable restoredBatchClass = (ilib_BatchManagerTestBatchable)(Type.forName('ilib_BatchManagerTestBatchable').newInstance());
        restoredBatchClass.restoreInputs(serializedInputs);
        System.assertEquals(TEST_INPUT, restoredBatchClass.inputs.val);
    }

    @isTest
    public static void executesNow()
    {
        Test.startTest();
        ilib_BatchManagerTestBatchable batchClass = new ilib_BatchManagerTestBatchable(TEST_INPUT);
        ilib_BatchManager.executeBatch(batchClass);
        Test.stopTest();

        Integer deferredJobCount = [SELECT count() FROM Deferred_Batch_Job__c WHERE Processed_Date__c = null];

        // the flex queue will have been empty so the batch class would have run right away
        System.assertEquals(0, deferredJobCount);
    }

    @isTest
    public static void executionDeferred()
    {
        // set the flex queue buffer so that it's always "full"
        flexQueueHoldingMax = 0;
        configureSettingsForTestRun();

        Integer batchSize = 2;
        ilib_BatchManagerTestBatchable batchClass = new ilib_BatchManagerTestBatchable(TEST_INPUT);
        ilib_BatchManager.executeBatch(batchClass, batchSize);

        Integer deferredJobCount = [SELECT count() FROM Deferred_Batch_Job__c WHERE Processed_Date__c = null];

        // the flex queue was "full" so the batch class was deferred
        System.assertEquals(1, deferredJobCount);
    }

    @isTest
    public static void executionDeferredAsUser()
    {
        // set the flex queue buffer so that it's always "full"
        flexQueueHoldingMax = 0;
        configureSettingsForTestRun();

        Integer batchSize = 2;
        ilib_BatchManagerTestBatchable batchClass = new ilib_BatchManagerTestBatchable(TEST_INPUT);
        ilib_BatchManager.executeBatch(batchClass, batchSize, true);

        Integer deferredJobCount = [SELECT count() FROM Deferred_Batch_Job__c WHERE Processed_Date__c = null];

        // the flex queue was "full" so the batch class was deferred
        System.assertEquals(1, deferredJobCount);
    }

    // default values
    private static Integer flexQueueHoldingMax = 100;
    private static Integer flexQueueHoldingBuffer = 10;

    // before calling this, set some of the static variables above
    // note that the settings class will correct out of bounds values on the maximum side
    // i.e. max % threshold of 90 will be enforced no matter what is set here
    // 0 is allowed as a minimum for unit testing
    private static void configureSettingsForTestRun()
    {
        Map<String, String> settings = new Map<String, String>
        {
            'flexQueueMax' => String.valueOf(flexQueueHoldingMax),
            'flexQueueBuffer' => String.valueOf(flexQueueHoldingBuffer)
        };

        ilib_BatchSettings.unitTestSettingsRecord = settings;
    }

}