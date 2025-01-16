/***************************************************************************************************************************************
 * NAME   : TestScheduledObjectTruncate
 * DESCRIPTION  : Test Class for ScheduledObjectTruncate and ScheduledObjectTruncateBatch Class.
 *    
 * @AUTHOR : 
 * @DATE   : 
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * Nishan Shetty           17-Mar-22            DCP-52338 Added Coverage Changes.
 * Nishan Shetty           25-May-22            INC0398604 Changes
 * --------------------------------------------------------------------------------------------------------------------------------------
****************************************************************************************************************************************/ 
@isTest
private class TestScheduledObjectTruncate {

    private static Integer maxAge = 90;
    private static String interfaceName = 'Account Outbound';
    

    private static Object_Truncation__mdt testConfig = new Object_Truncation__mdt(
            MasterLabel = 'Interface: Outbound Account',
            DeveloperName = 'Interface_Outbound_Account',
            Object_Name__c = 'Interface_Log__c',
            Max_Record_Age__c = maxAge,
            Batch_Size__c = 200,//INC0398604
            SOQL_Criteria__c = 'Interface_Name__c = \'' + interfaceName + '\'',
            IsActive__c = true);

    

    @isTest private static void queryCoverage() {
        List<Object_Truncation__mdt> lstObjectTruncationMdt = new List<Object_Truncation__mdt>();
        Test.startTest();
            ScheduledObjectTruncate job = new ScheduledObjectTruncate();
            lstObjectTruncationMdt=job.queryMetadata();
        Test.stopTest();
        System.assert(!lstObjectTruncationMdt.isEmpty(),'Object Truncation Metadata Not Found');
    }

    @isTest private static void configToCustomClass() {
        Test.startTest();
        ScheduledObjectTruncate job = new ScheduledObjectTruncate(testConfig);
        List<ScheduledObjectTruncate.TruncationParameters> res = job.getConfiguration(testConfig);
		job.execute(null);
        Test.stopTest();
        System.assertEquals(1, res.size(),'Truncation Parameter List is Incomplete');
        System.assertEquals(testConfig.Object_Name__c, res.get(0).strObjectName,'Truncation Parameter Object Name is Incorrect');
        System.assertEquals(testConfig.Max_Record_Age__c, res.get(0).intMaxRecordAge,'Truncation Parameter Max Age is Incorrect');
        System.assertEquals(testConfig.SOQL_Criteria__c, res.get(0).strSoqlCriteria,'Truncation Parameter SOQL Criteria is Incorrect');
    }

    @isTest private static void oldRecordDeletedBatch() {
        Interface_Log__c log = new Interface_Log__c(Interface_Name__c = interfaceName);
        insert log;
        Test.setCreatedDate(log.Id, DateTime.now() - (maxAge + 10));
        ScheduledObjectTruncateBatch batchJob = new ScheduledObjectTruncateBatch(testConfig.Object_Name__c, Integer.valueOf(testConfig.Max_Record_Age__c), testConfig.SOQL_Criteria__c, Integer.valueOf(testConfig.Batch_Size__c));
        Test.startTest();
          Database.executebatch(batchJob);
        Test.stopTest();
        System.assertEquals(0,[SELECT count() FROM Interface_Log__c LIMIT 10],'Logs Record Not Deleted');
    }

    @isTest private static void newRecordSurvivesBatch() {
        Interface_Log__c log = new Interface_Log__c(Interface_Name__c = interfaceName);
        insert log;
        Test.setCreatedDate(log.Id, DateTime.now() - (maxAge - 10));
        ScheduledObjectTruncateBatch batchJob = new ScheduledObjectTruncateBatch(testConfig.Object_Name__c,Integer.valueOf(testConfig.Max_Record_Age__c),testConfig.SOQL_Criteria__c, Integer.valueOf(testConfig.Batch_Size__c));
        Test.startTest();
            Database.executebatch(batchJob);
        Test.stopTest();
        System.assertEquals(1,[SELECT count() FROM Interface_Log__c LIMIT 10],'Logs Record Incorrect');
    }

    @isTest private static void testDefferableImpl() {
        ScheduledObjectTruncateBatch batchJob = new ScheduledObjectTruncateBatch(testConfig.Object_Name__c,Integer.valueOf(testConfig.Max_Record_Age__c),testConfig.SOQL_Criteria__c, Integer.valueOf(testConfig.Batch_Size__c));
        Integer intDefaultBatchSize;
        Test.startTest();
            String strSerializedInputs= batchJob.serializeInputs();
            batchJob.restoreInputs(strSerializedInputs);
            intDefaultBatchSize=batchJob.getDefaultBatchSize();
        Test.stopTest();
        System.assertEquals(200,intDefaultBatchSize,'Default Batch Size Not Set');
    }

}