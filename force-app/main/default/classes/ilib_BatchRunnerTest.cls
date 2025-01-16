@isTest
private class ilib_BatchRunnerTest {

    private final static String TEST_CLASS = 'ilib_BatchManagerTestBatchable';
    private final static String TEST_INPUT = 'Serializable Input';

    @isTest
    public static void prepareSingleBatchClass()
    {
        ilib_BatchManagerTestBatchable initialBatchClass = new ilib_BatchManagerTestBatchable(TEST_INPUT);

        // prepare deferred record
        Deferred_Batch_Job__c storedBatchDetails = new Deferred_Batch_Job__c(
            Name = TEST_CLASS,
            Serialized_Inputs__c = initialBatchClass.serializeInputs(),
            Batch_Size__c = 200
        );
        insert storedBatchDetails;

        Test.startTest();
        ilib_BatchRunner batchRunner = new ilib_BatchRunner();
        ilib_BatchManagerTestBatchable batchClass = (ilib_BatchManagerTestBatchable)batchRunner.prepareSingleBatchClass(storedBatchDetails);
        Test.stopTest();

        System.assertEquals(TEST_CLASS, batchClass.getName());
        System.assertEquals(TEST_INPUT, batchClass.inputs.val);
    }

    @isTest
    public static void runSingleSpecificBatch()
    {
        // need a product for the batch class to operate on
        Product2 prod = TestDataMaster.getNewProduct('Cookie');

        ilib_BatchManagerTestBatchable initialBatchClass = new ilib_BatchManagerTestBatchable(TEST_INPUT);

        // prepare deferred record
        Deferred_Batch_Job__c storedBatchDetails = new Deferred_Batch_Job__c(
            Name = TEST_CLASS,
            Serialized_Inputs__c = initialBatchClass.serializeInputs(),
            Batch_Size__c = 200
        );
        insert storedBatchDetails;

        Test.startTest();
        ilib_BatchRunner batchRunner = new ilib_BatchRunner(storedBatchDetails.Id);
        batchRunner.execute(null);
        Test.stopTest();

        // assert details row now has processed date populated
        Deferred_Batch_Job__c afterProcessing = [SELECT Id, Processed_Date__c FROM Deferred_Batch_Job__c WHERE Id = :storedBatchDetails.Id];
        System.assert(afterProcessing.Processed_Date__c != null, 'Job was not executed');

        Integer translationsInserted = [SELECT count() FROM Product_Localization__c WHERE Product__c = :prod.Id];
        System.assertEquals(1, translationsInserted);
    }

    @isTest
    public static void runBatchClasses()
    {
        // need a product for the batch class to operate on
        TestDataMaster.getNewProduct('Cookie');

        ilib_BatchManagerTestBatchable initialBatchClass = new ilib_BatchManagerTestBatchable(TEST_INPUT);

        // prepare deferred record
        Deferred_Batch_Job__c storedBatchDetails = new Deferred_Batch_Job__c(
            Name = TEST_CLASS,
            Serialized_Inputs__c = initialBatchClass.serializeInputs(),
            Batch_Size__c = 200
        );
        insert storedBatchDetails;

        Test.startTest();
        ilib_BatchRunner batchRunner = new ilib_BatchRunner();
        batchRunner.execute(null);
        Test.stopTest();

        // assert details row now has processed date populated
        Deferred_Batch_Job__c afterProcessing = [SELECT Id, Processed_Date__c FROM Deferred_Batch_Job__c WHERE Id = :storedBatchDetails.Id];
        System.assert(afterProcessing.Processed_Date__c != null);
    }

}