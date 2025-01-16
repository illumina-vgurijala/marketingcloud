/**
     * @author : Illumina
     * @description - Test Class for ilib_LogEvent 
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Rishi Sharma                  16-Jan-2023          Codescan Fix for Removing Unused Methods
*         Gerardo Garcia                05-Jun-2024          CMCM-5579: fixes uat tests.
*    ---------------------------------------------------------------------------------------------------------------------------
     */
    @isTest
    private with sharing class ilib_LogEventTest {
        // default values
        private static Boolean diableAllLogs = false;
        private static Boolean diablePersistSlowQueries = false;
        private static Boolean diablePersistSlowTransactions = false;
        private static Decimal slowQueryThreshold = 3.0;
        private static Decimal slowTransactionThreshold = 8.0;
        private static Decimal percentPublishThreshold = 75;
        // private static Datetime pausePublishUntil = null;
        private static Integer lineCountCap = 1000;
        private static Integer lineLengthCap = 1000;
        private static Decimal heapSizeThreshold = 70.00;
        private static Decimal cpuTimeThreshold = 70.00;
        private static String limitsCheckInterval = '500';
        private static String interfaceClass = 'ilib_LogEvent_PlatformEventEmit';
         private static String interfaceClassPop = 'ilib_LogEvent_PlatformEventPop';																		   
        private static String logLevel = 'Fine';
        private static Boolean apex = true;
        private static Boolean restInterface = true;
        private static Boolean batchable = true;
        private static Boolean queueable = true;
        private static String title = 'LogUnitTest';
        private static String method1 = 'MyClass.methodA';
        private static String method2 = 'MyClass.methodB';
        private static String message1 = 'Doing something';
        private static String message2 = 'Doing something more';
        private static String fine = 'Fine Log Level';
        private static String info = 'Info Log Level';
        private static String error = 'Error Log Level';
        private static String workstream = 'Sales';
        //Cmsi-2 Added variables minsFromNow, topOfmins, dtTime, topOfHour, valueMap for methods corresponding to testing CMSI-2 changes
        private static DateTime minsFromNow;
        private static Datetime topOfmins;
        private static  Map<String, String> valueMap = new Map<String, String>{
        'DefChkInt'=>'500','defPSSetng'=>'PS_Log_Settings','cpuTh'=>'70','heapTh'=>'70',
        'SlwQryTh'=>'2.00','SlwTranxTh'=>'8.00','PubPerTh'=>'75','LneCntCap'=>'1000',
        'LneLngthCap'=>'1000','IntrfcCls'=>'ilib_LogEvent_PlatformEventEmit','SwtchOffLogngUntl'=>'2022-04-18 09:22:56'};
    
         /**
         * @author : Illumina
         * @description - method to test basic debugging functionality of framework
         */
        @isTest public static void basicDebugging()
        {
            insert new cs_Apex_Settings__c(SetupOwnerId = UserInfo.getUserId(), Persist_All_ILMN_Logs__c = true);
            configureSettingsForTestRun();
            ilib_LogEvent.rootTitle = title;
    
            // simulate entering methodA 
            ilib_LogEvent.push(method1);
    
            // simulate entering methodB
            ilib_LogEvent.push(method2);
            ilib_LogEvent.message(message1);
            ilib_LogEvent.pop();
    
            // back to methodA
            ilib_LogEvent.message(message2);
            ilib_LogEvent.pop();
            
    
            Test.startTest();
            String s = ilib_LogEvent_PlatformEventEmit.getRootTitle();
            ilib_LogEvent_PlatformEventEmit.logInternalWarning(s);
            ilib_LogEvent.emit();
            Test.getEventBus().deliver();
            Test.stopTest();
            ILMN_Debug_Log__c persistedLog = [SELECT data__c, User__c FROM ILMN_Debug_Log__c WHERE Title__c = :title][0];
            String generatedLog = persistedLog.data__c;
            message1 = 'DEBUG : '+message1;
            message2 = 'DEBUG : '+message2;
            System.assert(generatedLog.contains(title), 'Generated Title is not same');
            System.assert(generatedLog.contains('1:' + method1), 'Generated Message is not same');
            System.assert(generatedLog.contains('  2:' + method2), 'Generated Message is not same');
            System.assert(generatedLog.contains('    3:' +message1), 'Generated Message is not same');
            System.assert(generatedLog.contains('  2:' +message2), 'Generated Message is not same');   
            
        }
    
        /**
         * @author : Illumina
         * @description nothing to assert, ensuring if user calls message() then emit() utility does not error
         */
        @isTest public static void messageOnly()
        {
            ilib_LogEvent.message(message1);
    
            Test.startTest();
            ilib_LogEvent.emit();
            Test.stopTest();
            Integer persistedLogCount = [SELECT count() FROM ILMN_Debug_Log__c LIMIT 10];
            System.assertEquals(0, persistedLogCount, 'Logs persisted');
    
            }
    
        /**
         * @author : Illumina
         * @description method to check if logs get printed without title
         */
        @isTest public static void noTitle()
        {
            // configure user to persist always
            insert new cs_Apex_Settings__c(SetupOwnerId = UserInfo.getUserId(), Persist_All_ILMN_Logs__c = true);
    
            ilib_LogEvent.push(method1);
            ilib_LogEvent.message(message1);
            ilib_LogEvent.pop();
            ilib_LogEvent.pop();
    
            Test.startTest();
            ilib_LogEvent.emit();
            Test.stopTest();
            // confirm persistence
            Integer persistedLogCount = [SELECT count() FROM ILMN_Debug_Log__c LIMIT 10];
            Assert.isTrue(persistedLogCount > 0, 'No Logs found');
    
         
        }
    
        /**
         * @author : Illumina
         * @description method to persist log as another user
         */
        @isTest public static void asAnotherUser()
        {
            ilib_LogEvent.rootTitle = title;
            ilib_LogEvent.push(method1);
            ilib_LogEvent.message(message1);
            ilib_LogEvent.pop();
    
            // configure to log as the other user and force persist
            User anotherAdmin = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, new Set<Id> { UserInfo.getUserId() });
            ilib_LogEvent.setLoggingUserId(anotherAdmin.Id);
            ilib_LogEvent.forcePersistLogs();
    
            Test.startTest();
            ilib_LogEvent.emit();
            Test.getEventBus().deliver();
            Test.stopTest();
    
            // check the other user was attached to the persisted log
            ILMN_Debug_Log__c persistedLog = [SELECT User__c FROM ILMN_Debug_Log__c WHERE Title__c = :title LIMIT 1];
            System.assertEquals(anotherAdmin.Id, persistedLog.User__c, 'User Id is not same');
        }
    
        /**
         * @author : Illumina
         * @description method for extra coverage
         */
        @isTest public static void extraCoverage()
        {
            ilib_LogEvent.pop(); // pop without a push
            ilib_LogEvent.logInternalWarning('test');
    
    
            try
            {
                Integer x = 5 / 0;
                System.debug(x);
            }
            catch (Exception e)
            {
                // lgo error sugar method
                ilib_LogEvent.logError(e);
                System.assertEquals('System.MathException', e.getTypeName(), 'Exception Type is not System.MathException');
            }
    
            // nothing to assert, just covering
        }
    
        /**
         * @author : Illumina
         * @description method to check log persistence functionality
         */
        @isTest public static void persistAllLogs()
        {
            // configure user to persist always
            insert new cs_Apex_Settings__c(SetupOwnerId = UserInfo.getUserId(), Persist_All_ILMN_Logs__c = true);
    
            ilib_LogEvent.rootTitle = title;
            ilib_LogEvent.push(method1);
            ilib_LogEvent.message(message1);
            ilib_LogEvent.pop();
    
            Test.startTest();
            ilib_LogEvent.emit();
            Test.getEventBus().deliver();
            Test.stopTest();
    
            // confirm persistence
            Integer persistedLogCount = [SELECT count() FROM ILMN_Debug_Log__c WHERE Title__c = :title];
            Assert.isTrue(persistedLogCount > 0, 'No Logs found');
        }
    
        /**
         * @author : Illumina
         * @description method to check persistence by title functionality
         */
        @isTest public static void persistLogsByTitle()
        {
            // configure user to persist by a specific title
            insert new cs_Apex_Settings__c(SetupOwnerId = UserInfo.getUserId(), ILMN_Logs_to_Persist__c = title);
    
            ilib_LogEvent.rootTitle = title;
            ilib_LogEvent.push(method1);
            ilib_LogEvent.message(message1);
            ilib_LogEvent.pop();
    
            Test.startTest();
            ilib_LogEvent.emit();
            Test.getEventBus().deliver();
            Test.stopTest();
    
            // confirm persistence
            Integer persistedLogCount = [SELECT count() FROM ILMN_Debug_Log__c WHERE Title__c = :title];
            Assert.isTrue(persistedLogCount > 0, 'No Logs found');
        }
    
        /**
         * @author : Illumina
         * @description method to check force persisting of logs functionality
         */
        @isTest public static void forcePersistLogs()
        {
            ilib_LogEvent.rootTitle = title;
            ilib_LogEvent.push(method1);
            ilib_LogEvent.message(message1);
            ilib_LogEvent.pop();
    
            // force persist (this method is only used by ApexExceptions)
            ilib_LogEvent.forcePersistLogsAndLinkToError();
    
            Test.startTest();
            ilib_LogEvent.emit();
            Test.getEventBus().deliver();
            Test.stopTest();
    
            Integer persistedLogCount = [SELECT count() FROM ILMN_Debug_Log__c WHERE Title__c = :title];
            Assert.isTrue(persistedLogCount > 0, 'No Logs found');
            System.assertNotEquals(null, ilib_LogEvent.getTransactionId());
            System.assertNotEquals(null, ilib_LogEvent.getFlowExceptionLogVariables());
        }
    
        /**
         * @author : Illumina
         * @description method to check slow query persistence functionality
         */
        @isTest public static void slowQueryPersisted()
        {
            // if long query threshold is 0, all query logs will be persisted
            slowQueryThreshold = 0.0;
            configureSettingsForTestRun();
    
    
            Test.startTest();
            ilib_LogEvent.setTitle('UnitTest');
            executeInstrumentedQuery();
            ilib_LogEvent.emit();
            Test.getEventBus().deliver();
            Test.stopTest();
    
            List<ILMN_Debug_Log__c> savedLogs = [SELECT Id, Title__c, Data__c, Data_Length__c, User__c FROM ILMN_Debug_Log__c LIMIT 10];
    
            ILMN_Debug_Log__c savedLog = savedLogs.get(0);
            System.assertEquals(UserInfo.getUserId(), savedLog.User__c, 'User Id is different');
            System.assert(savedLog.Title__c.contains(ilib_LogEvent.SLOW_QUERY_LOG_TITLE_PREFIX), 'Missing from title: ' + ilib_LogEvent.SLOW_QUERY_LOG_TITLE_PREFIX);
            System.assertEquals(savedLog.Data_Length__c, savedLog.Data__c.length(), 'Data length not saved properly');
        }
    
        /**
         * @author : Illumina
         * @description method to check slow query persistence disabled functionality
         */
        @isTest public static void slowQueryPersistenceDisabled()
        {
            // all query logs persistence disabled despite threshold at 0
            diablePersistSlowQueries = true;
            slowQueryThreshold = 0.0;
            configureSettingsForTestRun();
    
            Test.startTest();
            ilib_LogEvent.setTitle('UnitTest');
            executeInstrumentedQuery();
            ilib_LogEvent.emit();
            Test.getEventBus().deliver();
            Test.stopTest();
    
            Integer persistedLogCount = [SELECT count() FROM ILMN_Debug_Log__c LIMIT 10];
            Assert.isTrue(persistedLogCount > 0, 'logs persisted');
        }
    
        /**
         * @author : Illumina
         * @description method to check slow transaction persistence functionality
         */
        @isTest public static void slowTransactionPersisted()
        {
            // if long transaction threshold is 0, logs will be persisted
            slowTransactionThreshold = 0.0;
            configureSettingsForTestRun();
    
            ilib_LogEvent.rootTitle = title;
            ilib_LogEvent.push(method1);
            ilib_LogEvent.message(message1);
            ilib_LogEvent.pop();
    
            Test.startTest();
            ilib_LogEvent.emit();
            Test.getEventBus().deliver();
            Test.stopTest();
    
            // confirm persistence
            String likeValue = '%' + title + '%';
            Integer persistedLogCount = [SELECT count() FROM ILMN_Debug_Log__c WHERE Title__c LIKE :likeValue];
            Assert.isTrue(persistedLogCount > 0, 'No Logs found');
        }
    
        /**
         * @author : Illumina
         * @description method to check slow transaction persistence disabled functionality
         */
        @isTest public static void slowTransactionPersistenceDisabled()
        {
            // all slow transaction persistence disabled despite threshold at 0
            diablePersistSlowTransactions = true;
            slowTransactionThreshold = 0.0;
            configureSettingsForTestRun();
    
            ilib_LogEvent.rootTitle = title;
            ilib_LogEvent.push(method1);
            ilib_LogEvent.message(message1);
            ilib_LogEvent.pop();
    
            Test.startTest();
            ilib_LogEvent.emit();
            Test.getEventBus().deliver();
            Test.stopTest();
    
            // confirm persistence
            String likeValue = title + '%';
            Integer persistedLogCount = [SELECT count() FROM ILMN_Debug_Log__c WHERE Title__c LIKE :likeValue];
            System.assertEquals(0, persistedLogCount, 'log persisted');
        }
    
        /**
         * @author : Illumina
         * @description method to check persistence disabled functionality
         */
        @isTest public static void allPersistenceDisabled()
        {
            // configure user to persist always
            insert new cs_Apex_Settings__c(SetupOwnerId = UserInfo.getUserId(), Persist_All_ILMN_Logs__c = true);
    
            // all log persistence disabled
            // despite this user set to persist all
            diableAllLogs = true;
            configureSettingsForTestRun();
    
            ilib_LogEvent.rootTitle = title;
            ilib_LogEvent.push(method1);
            ilib_LogEvent.message(message1);
            ilib_LogEvent.pop();
    
            Test.startTest();
            ilib_LogEvent.emit();
            Test.getEventBus().deliver();
            Test.stopTest();
    
            // confirm no persistence
            Integer persistedLogCount = [SELECT count() FROM ILMN_Debug_Log__c WHERE Title__c = :title];
            System.assertEquals(0, persistedLogCount, 'Log persisted');
        }
    
        /**
         * @author : Illumina
         * @description method to check persistence pause functionality
         * @modification- CMSI-2 Added minsFromNow, topOfmins and valueMap variable corresponding to Metadata values 
         */
        @isTest public static void allPersistencePaused()
        {
            // configure user to persist always
            insert new cs_Apex_Settings__c(SetupOwnerId = UserInfo.getUserId(), Persist_All_ILMN_Logs__c = true);
            // all log persistence paused
            // despite this user set to persist all
            //CMSI-2 added new parameters corresponding to meta data
            minsFromNow = Datetime.now().addMinutes(10);
            topOfmins = Datetime.newInstance(minsFromNow.year(), minsFromNow.month(), minsFromNow.day(), minsFromNow.hour(), minsFromNow.minute(), minsFromNow.second());
            valueMap.put('SwtchOffLogngUntl',string.valueOf(topOfmins));
            configureSettingsForPausePublish();
    
            ilib_LogEvent.rootTitle = title;
            ilib_LogEvent.push(method1);
            ilib_LogEvent.message(message1);
            ilib_LogEvent.pop();
    
            Test.startTest();
            ilib_LogEvent.emit();
            Test.getEventBus().deliver();
            Test.stopTest();
    
            // confirm no persistence
            Integer persistedLogCount = [SELECT count() FROM ILMN_Debug_Log__c WHERE Title__c = :title];
            System.assertEquals(0, persistedLogCount, 'Logs persisted');
        }
        /**
         * @author : Illumina
         * @description CMSI-2 Method to persist logs when no default metadata name provided in code params
         */
         @isTest public static void allPersistencePausedNoDefaultMetadata()
        {
            // configure user to persist always
            insert new cs_Apex_Settings__c(SetupOwnerId = UserInfo.getUserId(), Persist_All_ILMN_Logs__c = true);
            // all log persistence paused
            // despite this user set to persist all
            valueMap.put('defPSSetng','');
            configureSettingsForPausePublish();
            
            ilib_LogEvent.rootTitle = title;
            ilib_LogEvent.push(method1);
            ilib_LogEvent.message(message1);
            ilib_LogEvent.pop();
    
            Test.startTest();
            ilib_LogEvent.emit();
            Test.getEventBus().deliver();
            Test.stopTest();
    
            // confirm no persistence
            Integer persistedLogCount = [SELECT count() FROM ILMN_Debug_Log__c WHERE Title__c = :title];
            Assert.isTrue(persistedLogCount > 0, 'No Logs found');
        }
        /**
         * @author : Illumina
         * @description Method to test message length cap
         * @modification- CMSI-2 Added message in system.assert to fix codescan error
         */
        @isTest public static void messageLengthCapped()
        {
            // configure user to persist always
            insert new cs_Apex_Settings__c(SetupOwnerId = UserInfo.getUserId(), Persist_All_ILMN_Logs__c = true);
    
            // cap message length to 5 characters
            lineLengthCap = 5;
            configureSettingsForTestRun();
    
            ilib_LogEvent.rootTitle = title;
            ilib_LogEvent.push(method1);
            ilib_LogEvent.message(message1);
            ilib_LogEvent.pop();
    
            Test.startTest();
            ilib_LogEvent.emit();
            Test.getEventBus().deliver();
            Test.stopTest();
    
            // confirm persistence message length capped
            List<ILMN_Debug_Log__c> savedLogs = [SELECT Id, Data__c FROM ILMN_Debug_Log__c LIMIT 10];
            ILMN_Debug_Log__c savedLog = savedLogs.get(0);
            message1 = 'DEBUG : '+message1;
            //CMSI-2 Added message in system.assert to fix codescan error
            System.assert(savedLog.Data__c.contains(message1.abbreviate(5)),'Message is more than 5 characters');
        }
    
        /**
         * @author : Illumina
         * @description Method to test line count cap
         */
        @isTest public static void messageCountCapped()
        {
            // configure user to persist always
            insert new cs_Apex_Settings__c(SetupOwnerId = UserInfo.getUserId(), Persist_All_ILMN_Logs__c = true);
    
            // cap message count to 4 lines (1 for push and 3 messages)
            lineCountCap = 4;
            configureSettingsForTestRun();
    
            ilib_LogEvent.rootTitle = title;
            ilib_LogEvent.push(method1);
            ilib_LogEvent.message(message1 + ' line 1');
            ilib_LogEvent.message(message1 + ' line 2');
            ilib_LogEvent.message(message1 + ' line 3');
            ilib_LogEvent.message(message1 + ' line 4');
            ilib_LogEvent.message(message1 + ' line 5');
            ilib_LogEvent.pop();
    
            Test.startTest();
            ilib_LogEvent.emit();
            Test.getEventBus().deliver();
            Test.stopTest();
    
            // confirm persistence line count capped
            List<ILMN_Debug_Log__c> savedLogs = [SELECT Id, Data__c FROM ILMN_Debug_Log__c LIMIT 10];
            ILMN_Debug_Log__c savedLog = savedLogs.get(0);
            System.debug('TTN ' + savedLog);
            System.assert(savedLog.Data__c.contains(message1 + ' line 1'), 'Line 1 not present');
            System.assert(savedLog.Data__c.contains(message1 + ' line 2'), 'Line 2 not present');
            System.assert(savedLog.Data__c.contains(message1 + ' line 3'), 'Line 3 not present');
            System.assert(!savedLog.Data__c.contains(message1 + ' line 4'), 'Line 4 present but should not be');
            System.assert(!savedLog.Data__c.contains(message1 + ' line 5'), 'Line 5 present but should not be');
        }
    
        private static final String QUERY_TITLE = 'UnitTestQuery';
        private static final String QUERY_PARMS = 'limit 10';
        private static void executeInstrumentedQuery()
        {
            ilib_LogQuery logger = new ilib_LogQuery(
                QUERY_TITLE,
                QUERY_PARMS
            );
    
            List<User> res = [SELECT Id FROM User LIMIT 10];
    
            logger.stop(res.size());
        }
    
    
        // before calling this, set some of the static variables above
        // note that the settings class will correct out of bounds values on the maximum side
        // i.e. max % threshold of 90 will be enforced no matter what is set here
        // 0 is allowed as a minimum for unit testing
        private static void configureSettingsForTestRun()
        {
            PS_Log_Setting__mdt settings = new PS_Log_Setting__mdt(
                MasterLabel = ilib_LogSettings.CONFIG_RECORD_LABEL,
                DeveloperName = ilib_LogSettings.CONFIG_RECORD_NAME,
                Disable_All_Log_Persistence__c = diableAllLogs,
                Disable_Slow_Query_Publish__c = diablePersistSlowQueries,
                Disable_Slow_Transaction_Publish__c = diablePersistSlowTransactions,
                Slow_Query_Threshold__c = slowQueryThreshold,
                Slow_Transaction_Threshold__c = slowTransactionThreshold,
                Publish_Percent_Threshold__c = percentPublishThreshold,
                // Pause_Publishes_Until__c = pausePublishUntil, //CMSI-2 Pause_Publishes_Until__c moved to code params metadata
                Line_Count_Cap__c = lineCountCap,
                Line_Length_Cap__c = lineLengthCap,
                //CMSI-2 Added below variable assignment as a part of CMSI-2 development
                Log_Level__c = 'Fine',
                Apex__c = apex,
                Interface__c = restInterface,
                Queueable__c = queueable,
                Batchable__c = batchable,
                Limits_Check_Interval__c = limitsCheckInterval,
                Heap_Size_Threshold__c = heapSizeThreshold,
                Cpu_Time_Threshold__c = cpuTimeThreshold,
                Interface_Class__c = interfaceClass
                
            );
    
            ilib_LogSettings.unitTestSettingsRecord = settings;
        }
        /**
         * @author : Anshaj
         * @description CMSI-2 Method create default meta data record for test usage
         */
        private static void configureSettingsForPausePublish(){
            String updatedTextValue = '';
            for(String key: valueMap.keySet()){
            updatedTextValue += key + ':' + valueMap.get(key)+';';
            }
            updatedTextValue = updatedTextValue.removeEnd(';');
            
            Code_Parameter__mdt codeParam = new Code_Parameter__mdt(
                MasterLabel = ilib_LogSettings.METADATA_CONFIG_RECORD_LABEL,
                DeveloperName = ilib_LogSettings.METADATA_CONFIG_RECORD_NAME,
                Values_Text__c = updatedTextValue
            );
            ilib_LogSettings.unitTestRecordCodeParam = codeParam;
        }
         /**
         * @author : Illumina
         * @description CMSI-2 Method to persist and test all log level messages
         */
        @isTest public static void persistLogsAllLogLevel()
        {
            // configure user to persist always
            insert new cs_Apex_Settings__c(SetupOwnerId = UserInfo.getUserId(), Persist_All_ILMN_Logs__c = true);
            configureSettingsForTestRun();
            ilib_LogEvent.setTitle(title, workstream);
            ilib_LogEvent.push(method1);
            ilib_LogEvent.message(message1);
            ilib_LogEvent.fine(fine);
            ilib_LogEvent.info(info);
            ilib_LogEvent.error(error);
            ilib_LogEvent.pop();
    
            Test.startTest();
            ilib_LogEvent.emit();
            Test.getEventBus().deliver();
            Test.stopTest();
    
            // confirm persistence
            List<ILMN_Debug_Log__c> debugLogs = [SELECT Id,Data__c, Log_Categorization__c FROM ILMN_Debug_Log__c WHERE Title__c = :title];
            ILMN_Debug_Log__c debugLog=debugLogs.get(0);
            error = 'ERROR : '+error;
            fine = 'FINE : '+fine;
            info = 'INFO : '+info;
            message1 = 'DEBUG : '+message1;
            Assert.isTrue(debugLogs.size() > 0 ,'No Log Found');
            Assert.areEqual('Apex', debugLog.Log_Categorization__c, 'Log Category is not Apex');
            Assert.isTrue(debugLog.Data__c.contains('1:' + method1), 'Does not contains specified message');
            Assert.isTrue(debugLog.Data__c.contains('  2:' + message1),'Does not contains specified message');
            Assert.isTrue(debugLog.Data__c.contains('  2:' + fine),'Does not contains specified message');
            Assert.isTrue(debugLog.Data__c.contains('  2:' + info),'Does not contains specified message');
            Assert.isTrue(debugLog.Data__c.contains('  2:' + error),'Does not contains specified message');
            
        }
        /**
         * @author : Nitin
         * @description CMSI-5 Method to persist Batch Logs
         */
        @isTest private static void persistBatchLogs(){
            insert new cs_Apex_Settings__c(SetupOwnerId = UserInfo.getUserId(), Persist_All_ILMN_Logs__c = true);
            configureSettingsForTestRun();
    
            ilib_LogEvent.setTitle(title, workstream);
                ilib_LogEvent.setLogCategory(ilib_LogEvent.Category.Batchable);
                ilib_LogEvent.push(method1);
                ilib_LogEvent.message(message1);
                ilib_LogEvent.pop();
                Test.startTest();
                ilib_LogEvent.emit();
                Test.getEventBus().deliver();
                Test.stopTest();
                List<ILMN_Debug_Log__c> debugLogs = [SELECT Id, Log_Categorization__c FROM ILMN_Debug_Log__c LIMIT 1];
                ILMN_Debug_Log__c debugLog=debugLogs.get(0);
                system.assertEquals('Batchable', debugLog.Log_Categorization__c, 'Log Category is not Batchable');
        
        }
        /**
         * @author : Nitin
         * @description CMSI-5 Method to persist Interface Logs
         */
        @isTest private static void persistInterfaceLogs(){
            insert new cs_Apex_Settings__c(SetupOwnerId = UserInfo.getUserId(), Persist_All_ILMN_Logs__c = true);
            configureSettingsForTestRun();
            ilib_LogEvent.setTitle(title, workstream);
            ilib_LogEvent.setLogCategory(ilib_LogEvent.Category.restInterface);
            ilib_LogEvent.push(method1);
            ilib_LogEvent.message(message1);
            ilib_LogEvent.pop();
            Test.startTest();
            ilib_LogEvent.emit();
            Test.getEventBus().deliver();
            Test.stopTest();
            List<ILMN_Debug_Log__c> debugLogs = [SELECT Id, Log_Categorization__c FROM ILMN_Debug_Log__c LIMIT 1];
            ILMN_Debug_Log__c debugLog=debugLogs.get(0);
            system.assertEquals('Interface', debugLog.Log_Categorization__c, 'Log Category is not Interface');
        }
        /**
         * @author : Nitin
         * @description CMSI-5 Method to persist Queueable Logs
         */
        @isTest private static void persistQueueableLogs(){
            insert new cs_Apex_Settings__c(SetupOwnerId = UserInfo.getUserId(), Persist_All_ILMN_Logs__c = true);
            configureSettingsForTestRun();
            ilib_LogEvent.setTitle(title, workstream);
                ilib_LogEvent.setLogCategory(ilib_LogEvent.Category.Queueable);
                ilib_LogEvent.push(method1);
                ilib_LogEvent.message(message1);
                ilib_LogEvent.pop();
                Test.startTest();
                ilib_LogEvent.emit();
                Test.getEventBus().deliver();
                Test.stopTest();
                List<ILMN_Debug_Log__c> debugLogs = [SELECT Id, Log_Categorization__c FROM ILMN_Debug_Log__c  LIMIT 1];
                ILMN_Debug_Log__c debugLog=debugLogs.get(0);
                system.assertEquals('Queueable', debugLog.Log_Categorization__c, 'Log Category is not Queueable');
        }
        /**
         * @author : Anshaj
         * @description CMSI-2 Method to check isOn functionality
         */
        @isTest private static void isOnCheck(){
            insert new cs_Apex_Settings__c(SetupOwnerId = UserInfo.getUserId(), Persist_All_ILMN_Logs__c = true);
            Apex = false;
            configureSettingsForTestRun();
            ilib_LogEvent.setTitle(title, workstream);
            ilib_LogEvent.push(method1);
            ilib_LogEvent.message(message1);
            ilib_LogEvent.pop();
            Test.startTest();
            ilib_LogEvent.emit();
            Test.getEventBus().deliver();
            Test.stopTest();
            Integer persistedLogCount = [SELECT count() FROM ILMN_Debug_Log__c WHERE Title__c = :title];
            System.assertEquals(0, persistedLogCount, 'Expected no. of logs should be 0 but it is not');
        }
        /**
         * @author : Anshaj
         * @description CMSI-2 Method to check limit usage check functionality
         */
        @isTest private static void limitsCheck(){
            insert new cs_Apex_Settings__c(SetupOwnerId = UserInfo.getUserId(), Persist_All_ILMN_Logs__c = true); 
            limitsCheckInterval = '1';
            heapSizeThreshold = 5;
            cpuTimeThreshold = 2; 
            configureSettingsForTestRun();
            ilib_LogEvent.setTitle(title);
            Long startTime = DateTime.now().getTime();
	    Long finishTime = DateTime.now().getTime();
		while ((finishTime - startTime) < 3000) 
            {
    		//sleep for 3 second to hit CPU % limit
    		finishTime = DateTime.now().getTime();
	    }
            ilib_LogEvent.setWorkstream('Sales');
            ilib_LogEvent.push(method1);
            ilib_LogEvent.message(message1);
            ilib_LogEvent.pop();            
            
            Test.startTest();
            ilib_LogEvent.emit();
            Test.stopTest();

            List<ILMN_Debug_Log__c> debugLogs = [SELECT Id,Data__c FROM ILMN_Debug_Log__c WHERE Title__c = :title];
            ILMN_Debug_Log__c debugLog = debugLogs.get(0);
            Assert.isTrue(debugLogs.size() > 0 ,'No Log Found');
            Assert.isTrue(!debugLog.Data__c.contains('1:' + method1), 'Data did not get trimmed');
        }
              /**
         * @author : Illumina
         * @description Method to test line count cap
         */
        @isTest public static void persistInfoLogs()
        {
            // configure user to persist always
            insert new cs_Apex_Settings__c(SetupOwnerId = UserInfo.getUserId(), Persist_All_ILMN_Logs__c = true);
            logLevel = 'Info';
            configureSettingsForTestRun();
            ilib_LogEvent.setTitle(title, workstream);
            ilib_LogEvent.push(method1);
            ilib_LogEvent.info(info);
            ilib_LogEvent.pop();
    
            Test.startTest();
            ilib_LogEvent.emit();
            Test.getEventBus().deliver();
            Test.stopTest();
    
            // confirm persistence
            List<ILMN_Debug_Log__c> debugLogs = [SELECT Id,Data__c, Log_Categorization__c FROM ILMN_Debug_Log__c WHERE Title__c = :title];
            ILMN_Debug_Log__c debugLog=debugLogs.get(0);
            INFO = 'INFO : '+info;
            Assert.isTrue(debugLogs.size() > 0 ,'No Log Found');
            Assert.isTrue(debugLog.Data__c.contains('1:' + method1), 'Does not contains specified message');
            Assert.isTrue(debugLog.Data__c.contains('  2:' + info),'Does not contains specified message');
            
        }
          /**
         * @author : Illumina
         * @description Method to test line count cap
         */
        @isTest public static void persistErrorLogs()
        {
            // configure user to persist always
            insert new cs_Apex_Settings__c(SetupOwnerId = UserInfo.getUserId(), Persist_All_ILMN_Logs__c = true);
            logLevel = 'Error';
            configureSettingsForTestRun();
            ilib_LogEvent.setTitle(title, workstream);
            ilib_LogEvent.push(method1);
            ilib_LogEvent.error(error);
            ilib_LogEvent.pop();
    
            Test.startTest();
            ilib_LogEvent.emit();
            Test.getEventBus().deliver();
            Test.stopTest();
    
            // confirm persistence
            List<ILMN_Debug_Log__c> debugLogs = [SELECT Id,Data__c, Log_Categorization__c FROM ILMN_Debug_Log__c WHERE Title__c = :title];
            ILMN_Debug_Log__c debugLog = debugLogs.get(0);
            ERROR = 'ERROR : '+error;
            Assert.isTrue(debugLogs.size() > 0 ,'No Log Found');
            Assert.isTrue(debugLog.Data__c.contains('1:' + method1), 'Does not contains specified message');
            Assert.isTrue(debugLog.Data__c.contains('  2:' + error),'Does not contains specified message');
            
        }
        
        
             /**
         * @author : Illumina
         * @description Method to test line count cap
         */
        @isTest public static void persistErrorLogsPop()
        {
            // configure user to persist always
            insert new cs_Apex_Settings__c(SetupOwnerId = UserInfo.getUserId(), Persist_All_ILMN_Logs__c = true);
            logLevel = 'Error';
            configureSettingsForTestRunPop();
            ilib_LogEvent.setTitle(title, workstream);
            ilib_LogEvent.push(method1);
            ilib_LogEvent.error(error);
            
    
            Test.startTest();
            ilib_LogEvent.pop();
            Test.getEventBus().deliver();
            Test.stopTest();
    
            // confirm persistence
            List<ILMN_Debug_Log__c> debugLogs = [SELECT Id,Data__c, Log_Categorization__c FROM ILMN_Debug_Log__c WHERE title__c =: method1];
            ILMN_Debug_Log__c debugLog=debugLogs.get(0);
            ERROR = 'ERROR : '+error;
            Assert.isTrue(debugLogs.size() > 0 ,'No Log Found');
            Assert.isTrue(debugLog.Data__c.contains(method1), 'Does not contains specified message');
            Assert.isTrue(debugLog.Data__c.contains('1:' + error),'Does not contains specified message');
            
        }
        
        
         /**
         * @author : Illumina
         * @description Method to test line count cap
         */
        @isTest public static void persistInfoLogsPop()
        {
            // configure user to persist always
            insert new cs_Apex_Settings__c(SetupOwnerId = UserInfo.getUserId(), Persist_All_ILMN_Logs__c = true);
            logLevel = 'Info';
            configureSettingsForTestRunPop();
            ilib_LogEvent.setTitle(title, workstream);
            ilib_LogEvent.push(method1);
            ilib_LogEvent.info(info);
            
    
            Test.startTest();
            ilib_LogEvent.pop();
            Test.getEventBus().deliver();
            Test.stopTest();
    
            // confirm persistence
            List<ILMN_Debug_Log__c> debugLogs = [SELECT Id,Data__c, Log_Categorization__c FROM ILMN_Debug_Log__c WHERE title__c =: method1];
            ILMN_Debug_Log__c debugLog=debugLogs.get(0);
            INFO = 'INFO : '+info;
            Assert.isTrue(debugLogs.size() > 0 ,'No Log Found');
            Assert.isTrue(debugLog.Data__c.contains(method1), 'Does not contains specified message');
            Assert.isTrue(debugLog.Data__c.contains('1:' + info),'Does not contains specified message');
            
        }
        
        
        @isTest private static void isOnCheckPop(){
            insert new cs_Apex_Settings__c(SetupOwnerId = UserInfo.getUserId(), Persist_All_ILMN_Logs__c = true);
            Apex = false;
            configureSettingsForTestRunPop();
            ilib_LogEvent.setTitle(title, workstream);
            ilib_LogEvent.push(method1);
            ilib_LogEvent.message(message1);
            
            Test.startTest();
            ilib_LogEvent.pop();
            Test.getEventBus().deliver();
            Test.stopTest();
            Integer persistedLogCount = [SELECT count() FROM ILMN_Debug_Log__c WHERE Title__c = :title];
            System.assertEquals(0, persistedLogCount, 'Expected no. of logs should be 0 but it is not');
        }
    
    
        
        
        
        @isTest private static void persistInterfaceLogsPop(){
            insert new cs_Apex_Settings__c(SetupOwnerId = UserInfo.getUserId(), Persist_All_ILMN_Logs__c = true);
            configureSettingsForTestRunPop();
            ilib_LogEvent.setTitle(title, workstream);
            ilib_LogEvent.setLogCategory(ilib_LogEvent.Category.restInterface);
            ilib_LogEvent.push(method1);
            ilib_LogEvent.message(message1);
            
            Test.startTest();
            ilib_LogEvent.pop();
            Test.getEventBus().deliver();
            Test.stopTest();
            List<ILMN_Debug_Log__c> debugLogs = [SELECT Id, Log_Categorization__c FROM ILMN_Debug_Log__c WHERE Log_Categorization__c='Interface' LIMIT 1];
            ILMN_Debug_Log__c debugLog=debugLogs.get(0);
            system.assertEquals('Interface', debugLog.Log_Categorization__c, 'Log Category is not Interface');
        }
        
        @isTest private static void persistBatchLogsPop(){
                insert new cs_Apex_Settings__c(SetupOwnerId = UserInfo.getUserId(), Persist_All_ILMN_Logs__c = true);
                configureSettingsForTestRunPop();
                ilib_LogEvent.setTitle(title, workstream);
                ilib_LogEvent.setLogCategory(ilib_LogEvent.Category.Batchable);
                
                ilib_LogEvent.push(method1);
                ilib_LogEvent.message(message1);
                
                Test.startTest();
                ilib_LogEvent.pop();
                Test.getEventBus().deliver();
                Test.stopTest();
                List<ILMN_Debug_Log__c> debugLogs = [SELECT Id, Log_Categorization__c FROM ILMN_Debug_Log__c WHERE Log_Categorization__c='Batchable' LIMIT 1];
                ILMN_Debug_Log__c debugLog=debugLogs.get(0);
                system.assertEquals('Batchable', debugLog.Log_Categorization__c, 'Log Category is not Batchable');
        }
    
         /**
         * @author : Illumina
         * @description method to check slow query persistence functionality
         */
        @isTest public static void slowQueryPersistedPop()
        {
            // if long query threshold is 0, all query logs will be persisted
            slowQueryThreshold = 0.0;
            configureSettingsForTestRunPop();
    
    
            Test.startTest();
            ilib_LogEvent.setTitle('UnitTest');
            executeInstrumentedQuery();
            ilib_LogEvent.emit();
            Test.getEventBus().deliver();
            Test.stopTest();
    
            List<ILMN_Debug_Log__c> savedLogs = [SELECT Id, Title__c, Data__c, Data_Length__c, User__c FROM ILMN_Debug_Log__c WHERE title__c = 'Slow Query: UnitTestQuery'];
    
           ILMN_Debug_Log__c savedLog = savedLogs.get(0);
            System.assertEquals(UserInfo.getUserId(), savedLog.User__c, 'User Id is different');
            System.assert(savedLog.Title__c.contains(ilib_LogEvent.SLOW_QUERY_LOG_TITLE_PREFIX), 'Missing from title: ' + ilib_LogEvent.SLOW_QUERY_LOG_TITLE_PREFIX);
            System.assertEquals(savedLog.Data_Length__c, savedLog.Data__c.length(), 'Data length not saved properly');
        }
    
    
         /**
         * @author : Illumina
         * @description method to check log levels for pop mechanism
         */
        @isTest public static void persistLogsAllLogLevelPop()
        {
            // configure user to persist always
            insert new cs_Apex_Settings__c(SetupOwnerId = UserInfo.getUserId(), Persist_All_ILMN_Logs__c = true);
            configureSettingsForTestRunPop();
            ilib_LogEvent.setTitle(title, workstream);
            ilib_LogEvent.push(method1);
            ilib_LogEvent.message(message1);
            ilib_LogEvent.fine(fine);
            ilib_LogEvent.info(info);
            ilib_LogEvent.error(error);
            //ilib_LogEvent.pop();
    
            Test.startTest();
            ilib_LogEvent.Pop();
            Test.getEventBus().deliver();
            Test.stopTest();
    
            // confirm persistence
            List<ILMN_Debug_Log__c> debugLogs = [SELECT Id,Data__c, Log_Categorization__c FROM ILMN_Debug_Log__c WHERE Title__c =: method1];
            ILMN_Debug_Log__c debugLog=debugLogs.get(0);
            ERROR = 'ERROR : '+error;
            fine = 'FINE : '+fine;
            INFO = 'INFO : '+info;
            message1 = 'DEBUG : '+message1;
            Assert.isTrue(debugLogs.size() > 0 ,'No Log Found');
            Assert.areEqual('Apex', debugLog.Log_Categorization__c, 'Log Category is not Apex');
            Assert.isTrue(debugLog.Data__c.contains(method1), 'Does not contains specified message');
            Assert.isTrue(debugLog.Data__c.contains('1:' + message1),'Does not contains specified message');
            Assert.isTrue(debugLog.Data__c.contains('1:' + fine),'Does not contains specified message');
            Assert.isTrue(debugLog.Data__c.contains('1:' + info),'Does not contains specified message');
            Assert.isTrue(debugLog.Data__c.contains('1:' + error),'Does not contains specified message');
            
        }
    
        // before calling this, set some of the static variables above
        // note that the settings class will correct out of bounds values on the maximum side
        // i.e. max % threshold of 90 will be enforced no matter what is set here
        // 0 is allowed as a minimum for unit testing
        private static void configureSettingsForTestRunPop()
        {
            PS_Log_Setting__mdt settings = new PS_Log_Setting__mdt(
                MasterLabel = ilib_LogSettings.CONFIG_RECORD_LABEL,
                DeveloperName = ilib_LogSettings.CONFIG_RECORD_NAME,
                Disable_All_Log_Persistence__c = diableAllLogs,
                Disable_Slow_Query_Publish__c = diablePersistSlowQueries,
                Disable_Slow_Transaction_Publish__c = diablePersistSlowTransactions,
                Slow_Query_Threshold__c = slowQueryThreshold,
                Slow_Transaction_Threshold__c = slowTransactionThreshold,
                Publish_Percent_Threshold__c = percentPublishThreshold,
                // Pause_Publishes_Until__c = pausePublishUntil, //CMSI-2 Pause_Publishes_Until__c moved to code params metadata
                Line_Count_Cap__c = lineCountCap,
                Line_Length_Cap__c = lineLengthCap,
                Log_Level__c = logLevel,
                Apex__c = apex,
                Interface__c = restInterface,
                Queueable__c = queueable,
                Batchable__c = batchable,
                Limits_Check_Interval__c = limitsCheckInterval,
                Heap_Size_Threshold__c = heapSizeThreshold,
                Cpu_Time_Threshold__c = cpuTimeThreshold,
                Interface_Class__c = interfaceClassPop
                
            );
    
            ilib_LogSettings.unitTestSettingsRecord = settings;
            
        }
    
    
         /**
         * @author : Illumina
         * @description method to check slow transaction persistence functionality
         */
        @isTest public static void slowTransactionPersistedPop()
        {
            // if long transaction threshold is 0, logs will be persisted
            slowTransactionThreshold = 0.0;
            configureSettingsForTestRunPop();
    
            ilib_LogEvent.rootTitle = title;
            ilib_LogEvent.push(method1);
            ilib_LogEvent.message(message1);
            
    
            Test.startTest();
            ilib_LogEvent.pop();
            Test.getEventBus().deliver();
            Test.stopTest();
    
            // confirm persistence
            String likeValue = '%' + method1 + '%';
            Integer persistedLogCount = [SELECT count() FROM ILMN_Debug_Log__c WHERE Title__c LIKE :likeValue];
            Assert.isTrue(persistedLogCount > 0, 'No Logs found');
        }
    
        /**
         * @author : Illumina
         * @description method to check slow query persistence disabled functionality
         */
        @isTest public static void slowQueryPersistenceDisabledPop()
        {
            // all query logs persistence disabled despite threshold at 0
            diablePersistSlowQueries = true;
            slowQueryThreshold = 0.0;
            configureSettingsForTestRunPop();
    
            Test.startTest();
            ilib_LogEvent.setTitle('UnitTest');
            executeInstrumentedQuery();
            ilib_LogEvent.emit();
            Test.getEventBus().deliver();
            Test.stopTest();
    
            Integer persistedLogCount = [SELECT count() FROM ILMN_Debug_Log__c LIMIT 10];
            Assert.isTrue(persistedLogCount > 0, 'logs persisted');
        }
    
         /**
         * @author : Illumina
         * @description method to check persistence disabled functionality
         */
        @isTest public static void allPersistenceDisabledPop()
        {
            // configure user to persist always
            insert new cs_Apex_Settings__c(SetupOwnerId = UserInfo.getUserId(), Persist_All_ILMN_Logs__c = true);
    
            // all log persistence disabled
            // despite this user set to persist all
            diableAllLogs = true;
            configureSettingsForTestRunPop();
    
            ilib_LogEvent.rootTitle = title;
            ilib_LogEvent.push(method1);
            ilib_LogEvent.message(message1);
            
    
            Test.startTest();
            ilib_LogEvent.pop();
            Test.getEventBus().deliver();
            Test.stopTest();
    
            // confirm no persistence
            Integer persistedLogCount = [SELECT count() FROM ILMN_Debug_Log__c WHERE Title__c = : method1];
            System.assertEquals(0, persistedLogCount, 'Log persisted');
        }
    
    
         /**
         * @author : Illumina
         * @description method to check slow transaction persistence disabled functionality
         */
        @isTest public static void slowTransactionPersistenceDisabledPop()
        {
            // all slow transaction persistence disabled despite threshold at 0
            diablePersistSlowTransactions = true;
            slowTransactionThreshold = 0.0;
            configureSettingsForTestRunPop();
    
            ilib_LogEvent.rootTitle = title;
            ilib_LogEvent.push(method1);
            ilib_LogEvent.message(message1);
            
    
            Test.startTest();
            ilib_LogEvent.pop();
            Test.getEventBus().deliver();
            Test.stopTest();
    
            // confirm persistence
            String likeValue = method1 + '%';
            Integer persistedLogCount = [SELECT count() FROM ILMN_Debug_Log__c WHERE Title__c LIKE :likeValue];
            System.assertEquals(0, persistedLogCount, 'log persisted');
        }
    
        
        @isTest private static void persistQueueableLogsPop(){
            insert new cs_Apex_Settings__c(SetupOwnerId = UserInfo.getUserId(), Persist_All_ILMN_Logs__c = true);
            configureSettingsForTestRunPop();
            ilib_LogEvent.setTitle(title, workstream);
            ilib_LogEvent.setLogCategory(ilib_LogEvent.Category.Queueable);
            ilib_LogEvent.push(method1);
            ilib_LogEvent.message(message1);
            
            Test.startTest();
            ilib_LogEvent.pop();
            Test.getEventBus().deliver();
            Test.stopTest();
            List<ILMN_Debug_Log__c> debugLogs = [SELECT Id, Log_Categorization__c FROM ILMN_Debug_Log__c WHERE Log_Categorization__c='Queueable' LIMIT 1];
            ILMN_Debug_Log__c debugLog=debugLogs.get(0);
            system.assertEquals(1, debugLogs.size() , 'Logs are not generated');
            system.assertEquals('Queueable', debugLog.Log_Categorization__c, 'Log Category is not Queueable');
        }
        
        
        /**
         * @author : Illumina
         * @description Method to test line count cap
         */
        @isTest public static void messageCountCappedPop()
        {
            // configure user to persist always
            insert new cs_Apex_Settings__c(SetupOwnerId = UserInfo.getUserId(), Persist_All_ILMN_Logs__c = true);
    
            // cap message count to 4 lines (1 for push and 3 messages)
            lineCountCap = 4;
            configureSettingsForTestRunPop();
    
            ilib_LogEvent.rootTitle = title;
            ilib_LogEvent.push(method1);
            ilib_LogEvent.message(message1 + ' line 1');
            ilib_LogEvent.message(message1 + ' line 2');
            ilib_LogEvent.message(message1 + ' line 3');
            ilib_LogEvent.message(message1 + ' line 4');
            ilib_LogEvent.message(message1 + ' line 5');
            
    
            Test.startTest();
            ilib_LogEvent.pop();
            Test.getEventBus().deliver();
            Test.stopTest();
    
            // confirm persistence line count capped
            List<ILMN_Debug_Log__c> savedLogs = [SELECT Id, Data__c FROM ILMN_Debug_Log__c where title__c =: method1 ];
            ILMN_Debug_Log__c savedLog = savedLogs.get(0);
            System.debug('TTN ' + savedLog);
            System.assert(savedLog.Data__c.contains(message1 + ' line 1'), 'Line 1 not present');
            System.assert(savedLog.Data__c.contains(message1 + ' line 2'), 'Line 2 not present');
            System.assert(savedLog.Data__c.contains(message1 + ' line 3'), 'Line 3 not present');
            System.assert(!savedLog.Data__c.contains(message1 + ' line 4'), 'Line 4 present but should not be');
            System.assert(!savedLog.Data__c.contains(message1 + ' line 5'), 'Line 5 present but should not be');
        }
        
              /**
         * @author : Illumina
         * @description Method to test message length cap
         */
        @isTest public static void messageLengthCappedPop()
        {
            // configure user to persist always
            insert new cs_Apex_Settings__c(SetupOwnerId = UserInfo.getUserId(), Persist_All_ILMN_Logs__c = true);
    
            // cap message length to 5 characters
            lineLengthCap = 5;
            configureSettingsForTestRunPop();
    
            ilib_LogEvent.rootTitle = title;
            ilib_LogEvent.push(method1);
            ilib_LogEvent.message(message1);
            
    
            Test.startTest();
            ilib_LogEvent.pop();
            Test.getEventBus().deliver();
            Test.stopTest();
    
            // confirm persistence message length capped
            List<ILMN_Debug_Log__c> savedLogs = [SELECT Id, Data__c FROM ILMN_Debug_Log__c where title__c =: method1];
            ILMN_Debug_Log__c savedLog = savedLogs.get(0);
            message1 = 'DEBUG : '+message1;
            System.assert(savedLog.Data__c.contains(message1.abbreviate(5)), 'Message is more than 5 characters');
        }
    
        /**
         * @author : Illumina
         * @description 
         */
        @isTest public static void asAnotherUserPop()
        {
            
            configureSettingsForTestRunPop();
            ilib_LogEvent.rootTitle = title;
            ilib_LogEvent.push(method1);
            ilib_LogEvent.message(message1);
            
    
            // configure to log as the other user and force persist
            User anotherAdmin = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, new Set<Id> { UserInfo.getUserId() });
            ilib_LogEvent.setLoggingUserId(anotherAdmin.Id);
            ilib_LogEvent.forcePersistLogs();
    
            Test.startTest();
            ilib_LogEvent.pop();
            Test.getEventBus().deliver();
            Test.stopTest();
    
            // check the other user was attached to the persisted log
            ILMN_Debug_Log__c persistedLog = [SELECT User__c FROM ILMN_Debug_Log__c WHERE Title__c = :method1 LIMIT 1];
            Assert.areEqual(anotherAdmin.Id, persistedLog.User__c, 'User Id is not same');
        }
        /**
         * @author : Illumina
         * @description 
         */
        @isTest public static void persistAllLogsPop()
        {
            // configure user to persist always
            insert new cs_Apex_Settings__c(SetupOwnerId = UserInfo.getUserId(), Persist_All_ILMN_Logs__c = true);
            configureSettingsForTestRunPop();
    
            ilib_LogEvent.rootTitle = title;
            ilib_LogEvent.push(method1);
            ilib_LogEvent.message(message1);
           
    
            Test.startTest();
            ilib_LogEvent.pop();
            Test.getEventBus().deliver();
            Test.stopTest();
    
            // confirm persistence
            Integer persistedLogCount = [SELECT count() FROM ILMN_Debug_Log__c WHERE Title__c = :method1];
            Assert.isTrue(persistedLogCount > 0, 'No Logs found');
    
            ilib_LogEvent_PlatformEventPop.logInternalWarning('LogError');
            ilib_LogEvent.getImplementationClass().getRootTitle();
        }
    
    
         /**
         * @author : Illumina
         * @description method to check force persisting of logs functionality
         */
        @isTest public static void forcePersistLogsPop()
        {    configureSettingsForTestRunPop();
            ilib_LogEvent.rootTitle = title;
            ilib_LogEvent.push(method1);
            ilib_LogEvent.message(message1);
            ilib_LogEvent.pop();
    
            // force persist (this method is only used by ApexExceptions)
            ilib_LogEvent.forcePersistLogsAndLinkToError();
    
            Test.startTest();
            ilib_LogEvent.emit();
            Test.getEventBus().deliver();
            Test.stopTest();
    
            Integer persistedLogCount = [SELECT count() FROM ILMN_Debug_Log__c WHERE Title__c = :title];
            Assert.isTrue(persistedLogCount > 0, 'No Logs found');
            
        }
    
        
        /**
         * @author : Illumina
         * @description method for extra coverage
         */
        @isTest public static void extraCoveragePop()
        {    configureSettingsForTestRunPop();
            ilib_LogEvent.pop(); // pop without a push
            ilib_LogEvent.logInternalWarning('test');
    
    
            try
            {
                Integer x = 5 / 0;
                System.debug(x);
            }
            catch (Exception e)
            {
                // lgo error sugar method
                ilib_LogEvent.logError(e);
                System.assertEquals('System.MathException', e.getTypeName(), 'Exception Type is not System.MathException');
            }
    
            // nothing to assert, just covering
        }
    
         /**
         * @author : Illumina
         * @description method to check persistence by title functionality
         */
        @isTest public static void persistLogsByTitlePop()
        {
            // configure user to persist by a specific title
            insert new cs_Apex_Settings__c(SetupOwnerId = UserInfo.getUserId(), ILMN_Logs_to_Persist__c = title);
            configureSettingsForTestRunPop();
    
            ilib_LogEvent.rootTitle = title;
            ilib_LogEvent.push(method1);
            ilib_LogEvent.message(message1);
            ilib_LogEvent.pop();
    
            Test.startTest();
            ilib_LogEvent.emit();
            Test.getEventBus().deliver();
            Test.stopTest();
    
            // confirm persistence
            Integer persistedLogCount = [SELECT count() FROM ILMN_Debug_Log__c WHERE Title__c = :title];
            Assert.isTrue(persistedLogCount > 0, 'No Logs found');
        }
        
    }