/**
*    @author Illumina
*    @date   2018
*    @description    Test Class for ApexExceptions
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                     Date                   Description
*         Ashwin                        2022-01-17             TASK0699567: Added sourceAndExceptionAndMultipleIds method
*         Ashwin Kumar                  29-Mar-2022            DCP-52339: cover ApexExceptions.emitSpecificExceptions()
*         Ashwin Kumar                  14-July-2022           INC0407615: cover ApexExceptions.emitSpecificExceptions() for upsert
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@isTest
private class TestApexExceptions {

    private static final String ERROR_SOURCE = 'Unit Test';
    
	
    @isTest static void sourceAndException() 
    {
        try
        {
            Integer i = 1 / 0;
        }
        catch (Exception e)
        {
            Test.startTest();
            ApexExceptions.emit(ERROR_SOURCE, e);
            ApexExceptions.emit(ERROR_SOURCE, e, 'Sales');
            Test.getEventBus().deliver();
            Test.stopTest();
        }

        List<Exception_Log__c> persistedExceptions = [SELECT Id, Source__c, Type__c FROM Exception_Log__c LIMIT 100];
        System.assertEquals(2, persistedExceptions.size(), 'Exception Logs not created as expected');
        System.assertEquals(ERROR_SOURCE, persistedExceptions.get(0).Source__c, 'Error source not matching with exception log as expected');
        System.assertEquals('System.MathException', persistedExceptions.get(0).Type__c, 'Exception type not matching with exception log as expected');
    }

    @isTest static void sourceAndExceptionAndRelatedLog()
    {
        try
        {
            Integer i = 1 / 0;
        }
        catch (Exception e)
        {
            Test.startTest();
            // NOTE: related log is not yet used so just pass null to get coverage for now
            Id relatedRecID = UserInfo.getUserId();
            ApexExceptions.emit(ERROR_SOURCE, e, relatedRecID);
            ApexExceptions.emit(ERROR_SOURCE, e, relatedRecID, 'Sales');
            Test.getEventBus().deliver();
            Test.stopTest();
        }

        List<Exception_Log__c> persistedExceptions = [SELECT Id, Source__c, Type__c FROM Exception_Log__c LIMIT 100];
        System.assert(!persistedExceptions.isEmpty() , 'Exception Logs not created as expected');
        //System.assertEquals(ERROR_SOURCE, persistedExceptions.get(0).Source__c, 'Error source not matching with exception log as expected');
        //System.assertEquals('System.MathException', persistedExceptions.get(0).Type__c, 'Exception type not matching with exception log as expected');
    }

    //TASK0699567
    @isTest static void sourceAndExceptionAndMultipleIds()
    {
        List<Account> lstAccounts = new List<Account>();
        String strAccIds = '';
        for(Integer i=0; i<20; i++) {
            lstAccounts.add(TestDataAccount.getAccount('Test Acc '+i)); 
        }
        insert lstAccounts;
        for(Account acc : lstAccounts) { 
            strAccIds += acc.Id + ';';
        }
        try
        {
            Integer i = 1 / 0;
        }
        catch (Exception e)
        {
            Test.startTest();
            ApexExceptions.emit(e, ERROR_SOURCE, strAccIds);
            ApexExceptions.emit(e, ERROR_SOURCE, strAccIds, 'Sales');
            Test.getEventBus().deliver();
            Test.stopTest();
        }

        List<Exception_Log__c> persistedExceptions = [SELECT Id, Source__c, Type__c, Related_Record__c FROM Exception_Log__c LIMIT 100];
        System.assertEquals(2, persistedExceptions.size(), 'Exception Logs not created as expected');
        System.assertEquals(ERROR_SOURCE, persistedExceptions.get(0).Source__c, 'Error source not matching with exception log as expected');
        System.assertEquals('System.MathException', persistedExceptions.get(0).Type__c, 'Exception type not matching with exception log as expected');
        System.debug(persistedExceptions.get(0).Related_Record__c.length());
        System.assert(persistedExceptions.get(0).Related_Record__c.length() <= 255, 'Related record length not less than or equal to 255 as expected');
    }

    @isTest static void sourceAndMessage()
    {
        Test.startTest();
        //ApexExceptions.emit(ERROR_SOURCE, 'Test Error Message');
        ApexExceptions.emit(ERROR_SOURCE, 'Test Error Message', 'Sales');
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Exception_Log__c> persistedExceptions = [SELECT Id, Source__c, Message__c FROM Exception_Log__c LIMIT 100];
        System.assertEquals(1, persistedExceptions.size(), 'Exception Logs not created as expected');
        System.assertEquals(ERROR_SOURCE, persistedExceptions.get(0).Source__c, 'Error source not matching with exception log as expected');
        System.assertEquals('Test Error Message', persistedExceptions.get(0).Message__c, 'Message matching with exception log as expected');
    }

    @isTest static void saveErrorEmitter()
    {
        List<Lead> l = new List<Lead> {
            new Lead(), // missing last name
            TestDataPerson.initLead()
        };

        Test.startTest();
        List<Database.SaveResult> res = Database.insert(l, false);
        ApexExceptions.emitSaveErrors(res, ERROR_SOURCE);
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Exception_Log__c> persistedExceptions = [SELECT Id, Source__c FROM Exception_Log__c LIMIT 100];
        // can be more than one error if a system and custom validation hit
        System.assert(!persistedExceptions.isEmpty(), 'Exception Logs not created as expected');
        System.assertEquals(ERROR_SOURCE, persistedExceptions.get(0).Source__c, 'Error source not matching with exception log as expected');
    }

    @isTest static void upsertErrorEmitter()
    {
        List<Lead> l = new List<Lead> {
            TestDataPerson.initLead(),
            TestDataPerson.initLead()
        };
        insert l;

        Test.startTest();
        {
            // this will cause an error
            l.get(0).LastName = '';
            List<Database.UpsertResult> res = Database.upsert(l, false);

            ApexExceptions.emitUpsertErrors(res, ERROR_SOURCE);
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        List<Exception_Log__c> persistedExceptions = [SELECT Id, Source__c FROM Exception_Log__c LIMIT 100];
        // can be more than one error if a system and custom validation hit
        System.assert(!persistedExceptions.isEmpty(), 'Exception Logs not created as expected');
        System.assertEquals(ERROR_SOURCE, persistedExceptions.get(0).Source__c, 'Error source not matching with exception log as expected');
    }

    
    //DCP-52339
    @isTest static void testEmitSpecificExceptions() {
        Account acct = TestDataAccount.getAccount('Test Account'); 
        insert acct;
        List<TAPS_Deferred_Record__c> lstDeferredRecords = new List<TAPS_Deferred_Record__c>();

        Test.startTest();
        lstDeferredRecords.addAll(TAPS_DeferredRun.getDeferredList('Account', new Set<Id>{acct.Id}));
        lstDeferredRecords.addAll(TAPS_DeferredRun.getDeferredList('Account', new Set<Id>{acct.Id}));   //Trying to create duplicate deferred record
        
        List<Database.SaveResult> insertResults = Database.insert(lstDeferredRecords, false);
        ApexExceptions.emitSpecificExceptions(
            insertResults, ERROR_SOURCE, lstDeferredRecords, new Set<String> {'duplicate value found:'}, 'Record_ID__c'
        );
        Test.getEventBus().deliver();
        Test.stopTest();
        
        List<Exception_Log__c> persistedExceptions = [SELECT Id, Source__c, Related_Record__c, Message__c FROM Exception_Log__c LIMIT 100];
        System.assertEquals(0, persistedExceptions.size(), 'exception is not skipped as expected when duplicates are inserted');
    }

    //DCP-52339
    @isTest static void testEmitSpecificExceptionsForDelete() {
        List<Account> lstAccounts = new List<Account>{TestDataAccount.getAccount('Test Account')};
        insert lstAccounts;

        Test.startTest();
        delete lstAccounts;
        List<Database.DeleteResult> deleteResults = Database.delete(lstAccounts, false);
        ApexExceptions.emitSpecificExceptions(
            deleteResults, ERROR_SOURCE, lstAccounts, new Set<String> {'entity is deleted'}, 'Id'
        );
        Test.stopTest();
        
        // get logs and skip from async operations e.g. Accounts After Insert BatchDMLService.updateAsyncRecords
        List<Exception_Log__c> persistedExceptions = [SELECT Id, Source__c, Related_Record__c, Message__c FROM Exception_Log__c WHERE Source__c NOT IN ('BatchDMLOperation') LIMIT 100];
        System.debug(JSON.serializePretty(persistedExceptions));
        System.assertEquals(0, persistedExceptions.size(), 'known exception is not skipped as expected when list of records is deleted twice');
    }

    @isTest static void deleteErrorEmitter()
    {
    List<Lead> l = new List<Lead> {
        TestDataPerson.getNewLead()
    };
    
    Test.startTest();
    List<Database.DeleteResult> res = Database.delete(l, false);    
    List<Database.DeleteResult> result = Database.delete(l, false);   
    Database.DeleteResult r= result[0];   
    ApexExceptions.emitDeleteErrors(result, ERROR_SOURCE);
    Test.getEventBus().deliver();
    Test.stopTest();
    system.assertEquals(false,r.isSuccess(),'Excepted value is false but actual value is true');
    

    List<Exception_Log__c> persistedExceptions = [SELECT Id, Source__c FROM Exception_Log__c LIMIT 100];
    //can be more than one error if a system and custom validation hit
    System.assert(!persistedExceptions.isEmpty(),'The size of persistedExceptions is zero because there are no Exception_Log__c records');
    System.assertEquals(ERROR_SOURCE, persistedExceptions.get(0).Source__c,'excepted value is '+ERROR_SOURCE+' actual value is'+persistedExceptions.get(0).Source__c);
    }
    //INC0407615
    @isTest static void testEmitSpecificExceptionsForUpsert() {
        Account acct = TestDataAccount.getAccount('Test Account'); 
        insert acct;
        List<TAPS_Deferred_Record__c> lstDeferredRecords = new List<TAPS_Deferred_Record__c>();
        List<TAPS_Deferred_Record__c> lstDeferredRecordsToUpsert = new List<TAPS_Deferred_Record__c>();

        Test.startTest();
        lstDeferredRecords.addAll(TAPS_DeferredRun.getDeferredList('Account', new Set<Id>{acct.Id}));
        insert lstDeferredRecords;

        lstDeferredRecordsToUpsert.addAll(TAPS_DeferredRun.getDeferredList('Account', new Set<Id>{acct.Id}));   //Trying to upsert duplicate deferred record
        
        Schema.SObjectField externalField = TAPS_Deferred_Record__c.Fields.Record_ID__c;
        List<Database.UpsertResult> upsertResults = Database.upsert(lstDeferredRecordsToUpsert, externalField, false);
        ApexExceptions.emitSpecificExceptions(
            upsertResults, ERROR_SOURCE, lstDeferredRecordsToUpsert, new Set<String> {'duplicate value found:'}, 'Record_ID__c'
        );
        Test.getEventBus().deliver();
        Test.stopTest();
        
        List<Exception_Log__c> persistedExceptions = [SELECT Id, Source__c, Related_Record__c, Message__c FROM Exception_Log__c LIMIT 100];
        System.assertEquals(0, persistedExceptions.size(), 'exception is not skipped as expected when duplicates are upserted');
    }
}