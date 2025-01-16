/**
 *   @author: Rajbabu Boopalan
*    @date:   11-Mar-2024
*    @description: Test class class for Ilib_LogEvent_PlatformEventEmitQueueable
*    @Test Class: TestLogEvent_PlatformEventEmitQueueable
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*        Developer           Date                Description
*        Rajbabu Boopalan    11-Mar-2024         CMCM-5579: Initial build
*        Gerardo Garcia      05-June-2024        CMCM-5579: fixes uat tests.
*    --------------------------------------------------------------------------------------------------
 */
@isTest
private class TestLogEvent_PlatformEventEmitQueueable {
    // default values
    private static final Boolean DISABLE_ALL_LOGS = false;
    private static final Boolean DISABLE_PERSISTS_LOW_QUERIES = false;
    private static final Boolean DISABLE_PERSIST_SLOW_TRANSACTIONS = false;
    private static final Decimal SLOW_QUERY_THRESHOLD = 3.0;
    private static final Decimal SLOW_TRANSACTION_THRESHOLD = 8.0;
    private static final Decimal PERCENT_PUBLISH_THRESHOLD = 75;
    private static final Integer LINE_COUNT_CAP = 1000;
    private static final Integer LINE_LENGTH_CAP = 1000;
    private static final Decimal HEAP_SIZE_THRESHOLD = 70.00;
    private static final Decimal CPU_TIME_THRESHOLD = 70.00;
    private static final String LIMITS_CHECK_INTERVAL = '500';
    private static final String INTERFACE_CLASS = 'Ilib_LogEvent_PlatformEventEmitQueueable';
    private static final Boolean APEX_FLAG = true;
    private static final Boolean REST_INTERFACE = true;
    private static final Boolean BATCHABLE = true;
    private static final Boolean QUEUEABLE = true;
    private static final String TITLE = 'title';


    @TestSetup
    static void makeData(){
        insert new cs_Apex_Settings__c(SetupOwnerId = UserInfo.getUserId(), Persist_All_ILMN_Logs__c = true);

        configureSettingsForTestRun();
    }

    /**
      * @author: Rajbabu Boopalan
      * @date: 11-Mar-2024
      * @description: Test method for queueable
      * @param: NA
      * @return: NA
      */
      @isTest
    static void testPlatformEventEmitQueueable() {

        ilib_LogEvent.publishParameter currPublishParameter = generateParam(TITLE);

        List<ilib_LogEvent.publishParameter> lstPublishParameters = new List<ilib_LogEvent.publishParameter>();
        lstPublishParameters.add(currPublishParameter);

        Test.startTest();
        Ilib_LogEvent_PlatformEventEmitQueueable queueable = new Ilib_LogEvent_PlatformEventEmitQueueable(lstPublishParameters);
        System.enqueueJob(queueable);
        Test.stopTest();

        ILMN_Debug_Log__c generatedLog = [SELECT data__c, User__c, Title__c FROM ILMN_Debug_Log__c WHERE Title__c =: TITLE LIMIT 1];
        Assert.areEqual(TITLE, generatedLog.Title__c, 'Generated Title is not same');
    }

    @IsTest
    private static void testLimitRowEntriesPublish(){
        List<ilib_LogEvent.publishParameter> lstPublishParameters = new List<ilib_LogEvent.publishParameter>();

        Integer numParamLogs = 200;

        for(Integer i = 0; i < numParamLogs; i++) {
            ilib_LogEvent.publishParameter currPublishParameter = generateParam(TITLE + '_' + i);
            lstPublishParameters.add(currPublishParameter);
        }
        System.debug('size:' + lstPublishParameters.size());
        System.debug('Limits.getLimitDMLRows():' + Limits.getLimitDMLRows());
        Test.startTest();
        IlmnLogs.publishList(lstPublishParameters);
        Test.getEventBus().deliver();
        Test.stopTest();

        System.debug('Limits.getDMLRows():' + Limits.getDMLRows());

        String evalLike = '%' + TITLE + '%';
        Integer numLogs = [SELECT COUNT() FROM ILMN_Debug_Log__c WHERE Title__c LIKE :evalLike];
        System.debug('Number of Results:' + numLogs);
        Assert.isTrue(numLogs > 0, 'It should generate logs without issue');
    }

    /**
     * Test for avoiding Too many Publish Immediate DML: 151
     */
    @IsTest
    private static void tooManyPublishDML() {
        Integer numberOfLogs = 151;

        Test.startTest();
        for(Integer i = 0; i < numberOfLogs; i++) { 
            ilib_LogEvent.setTitle(TITLE + '_' + i);
            ilib_LogEvent.info('testMessage_' + i);
            ilib_LogEvent.emit();
        }
        Test.getEventBus().deliver();
        Test.stopTest();

        String evalLike = '%' + TITLE + '%';
        Integer res = [SELECT COUNT() FROM ILMN_Debug_Log__c WHERE Title__c LIKE :evalLike];
        System.debug('Number of Results:' + res);
        Assert.isTrue(res > 0, 'It should generate logs without issue');
    }

    // before calling this, set some of the static variables above
    // note that the settings class will correct out of bounds values on the maximum side
    // i.e. max % threshold of 90 will be enforced no matter what is set here
    // 0 is allowed as a minimum for unit testing
    private static void configureSettingsForTestRun() {
        PS_Log_Setting__mdt settings = new PS_Log_Setting__mdt(
            MasterLabel = ilib_LogSettings.CONFIG_RECORD_LABEL,
            DeveloperName = ilib_LogSettings.CONFIG_RECORD_NAME,
            Disable_All_Log_Persistence__c = DISABLE_ALL_LOGS,
            Disable_Slow_Query_Publish__c = DISABLE_PERSISTS_LOW_QUERIES,
            Disable_Slow_Transaction_Publish__c = DISABLE_PERSIST_SLOW_TRANSACTIONS,
            Slow_Query_Threshold__c = SLOW_QUERY_THRESHOLD,
            Slow_Transaction_Threshold__c = SLOW_TRANSACTION_THRESHOLD,
            Publish_Percent_Threshold__c = PERCENT_PUBLISH_THRESHOLD,
            Line_Count_Cap__c = LINE_COUNT_CAP,
            Line_Length_Cap__c = LINE_LENGTH_CAP,
            Log_Level__c = 'Fine',
            Apex__c = APEX_FLAG,
            Interface__c = REST_INTERFACE,
            Queueable__c = QUEUEABLE,
            Batchable__c = BATCHABLE,
            Limits_Check_Interval__c = LIMITS_CHECK_INTERVAL,
            Heap_Size_Threshold__c = HEAP_SIZE_THRESHOLD,
            Cpu_Time_Threshold__c = CPU_TIME_THRESHOLD,
            Interface_Class__c = INTERFACE_CLASS
        );

        ilib_LogSettings.unitTestSettingsRecord = settings;
    }

    private static ilib_LogEvent.publishParameter generateParam(String title) {
        ilib_LogEvent.publishParameter currPublishParameter = new ilib_LogEvent.publishParameter( title,
            'logData1',
            UserInfo.getUserId(), 
            500, 
            'serializedLimitz1',
            'tid1', 
            ilib_LogEvent.SALES,
            ilib_LogEvent.Category.Queueable,
            'Emit', 
            'linkKey1');

        return currPublishParameter;
    }
}