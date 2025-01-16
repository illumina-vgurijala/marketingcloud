/**
 * @actor illumina
 * @description
 */
@isTest
private class TestTAPS_ScheduleSharingCalc {

   /* @isTest static void splitIdsToBatches() 
    {
        Integer twoBatches = TAPS_ScheduleSharingCalc.ID_BATCH_SIZE + 1;
        List<ApexClass> someRecords = [SELECT Id FROM ApexClass LIMIT :twoBatches];
        Set<Id> someIds = UtilsCollection.getSetOfIds(someRecords, 'Id');

        TAPS_ScheduleSharingCalc c = new TAPS_ScheduleSharingCalc();
        List<Set<Id>> batchedIds = c.splitIdsToBatches(someIds);

        System.assertEquals(2, batchedIds.size());
        System.assertEquals(1, batchedIds.get(1).size());
    }

    @isTest static void idTooNew()
    {
        Account a = TestDataAccount.getNewAmrAccount();
        Opportunity o1 = TestDataOpportunity.getNewOpportunity2(a.Id);
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        Apttus_Proposal__Proposal__c quote1 = TestDataProposal.initProposal(a.Id, o1.Id, 'Test Proposal', priceList.Id, true, 'Draft', 'None');
        insert quote1;
        TestDataProposal.getNewCart(quote1);

        Test.startTest();
        {
            TAPS_ScheduleSharingCalc calc = new TAPS_ScheduleSharingCalc();
            calc.execute(null);
        }
        Test.stopTest();

        // assert nothing was created
        List<TAPS_Deferred_Run__c> deferredRuns = [SELECT Id, Object_Type__c, Record_IDs__c FROM TAPS_Deferred_Run__c];
        System.assertEquals(0, deferredRuns.size());

        List<TAPS_IDs_Already_Deferred__c> alreadyDeferredIds = [SELECT Id, Object_Type__c, Record_IDs__c FROM TAPS_IDs_Already_Deferred__c];
        System.assertEquals(0, alreadyDeferredIds.size());
    }

    @isTest static void idMovesToDeferredTable()
    {
        Account a = TestDataAccount.getNewAmrAccount();
        Opportunity o1 = TestDataOpportunity.getNewOpportunity2(a.Id);
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        Apttus_Proposal__Proposal__c quote1 = TestDataProposal.initProposal(a.Id, o1.Id, 'Test Proposal', priceList.Id, true, 'Draft', 'None');
        insert quote1;
        Apttus_Config2__ProductConfiguration__c config = TestDataProposal.getNewCart(quote1);
        Datetime recCreatedDate = Datetime.now().addMinutes(-1 * (TAPS_ScheduleSharingCalc.MIN_RECORD_AGE_MINUTES + 2));
        Test.setCreatedDate(config.Id, recCreatedDate);

        Test.startTest();
        {
            TAPS_ScheduleSharingCalc calc = new TAPS_ScheduleSharingCalc();
            calc.execute(null);
        }
        Test.stopTest();

        TAPS_Deferred_Run__c deferredRun = [SELECT Id, Object_Type__c, Record_IDs__c FROM TAPS_Deferred_Run__c];
        System.assertEquals('Apttus_Config2__ProductConfiguration__c', deferredRun.Object_Type__c);
        System.assert(deferredRun.Record_IDs__c.contains(config.Id));

        TAPS_IDs_Already_Deferred__c alreadyDeferredIds = [SELECT Id, Object_Type__c, Record_IDs__c FROM TAPS_IDs_Already_Deferred__c];
        System.assertEquals('Apttus_Config2__ProductConfiguration__c', alreadyDeferredIds.Object_Type__c);
        System.assert(alreadyDeferredIds.Record_IDs__c.contains(config.Id));
    }

    @isTest static void idAlreadyInDeferredTable()
    {
        Account a = TestDataAccount.getNewAmrAccount();
        Opportunity o1 = TestDataOpportunity.getNewOpportunity2(a.Id);
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        Apttus_Proposal__Proposal__c quote1 = TestDataProposal.initProposal(a.Id, o1.Id, 'Test Proposal', priceList.Id, true, 'Draft', 'None');
        insert quote1;
        Apttus_Config2__ProductConfiguration__c config = TestDataProposal.getNewCart(quote1);
        Datetime recCreatedDate = Datetime.now().addMinutes(-1 * (TAPS_ScheduleSharingCalc.MIN_RECORD_AGE_MINUTES + 2));
        Test.setCreatedDate(config.Id, recCreatedDate);

        insert new TAPS_IDs_Already_Deferred__c(
            Object_Type__c = 'Apttus_Config2__ProductConfiguration__c',
            Record_IDs__c = JSON.serialize(new Set<Id> {config.Id})
        );

        Test.startTest();
        {
            TAPS_ScheduleSharingCalc calc = new TAPS_ScheduleSharingCalc();
            calc.execute(null);
        }
        Test.stopTest();

        // assert no deferred runs created
        List<TAPS_Deferred_Run__c> deferredRuns = [SELECT Id, Object_Type__c, Record_IDs__c FROM TAPS_Deferred_Run__c];
        System.assertEquals(0, deferredRuns.size());

        // assert no new rows
        List<TAPS_IDs_Already_Deferred__c> alreadyDeferredIds = [SELECT Id, Object_Type__c, Record_IDs__c FROM TAPS_IDs_Already_Deferred__c];
        System.assertEquals(1, alreadyDeferredIds.size());
    }
*/
}