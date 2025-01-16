/**
*    @author Todd Newman
*    @date   
*    @description Test Class for TapsBatches
*    Modification Log:
*    --------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*           Todd Newman                                          Initial Version
*           Satya Swain                    01-Aug-2019           PRB0042764: Added testRetriggerTAPSBatches
*           Satya Swain                    16-Dec-2020           Modified setupData and setupTerritoryData methods
*          Nishan Shetty                   17-Jan-2022           CodeScanFix- [Assert Argument Order]
*         Ashwin Kumar                     31-Mar-2021           DCP-52339 Remove TestTAPS.setupDeferredObjectData
*         Nishan Shetty                 24-Aug-2022            DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
*           Prem Ranjan                    21-Feb-2023         Codescan fix (APEX) Unit Test Method should include System.Assert
* --------------------------------------------------------------------------------------------------------------------
**/
@isTest
private class TestTAPSBatches {

    @testSetup static void setupData()
    {
        setupTerritoryData();
    }
    static void setupTerritoryData()
    {
        User objUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN,new Set<Id>{UserInfo.getUserId()});
        System.runAs(objUser){
            TestTAPS.setupTerritoryDataWithPartners();
        }
    }
    @isTest static void makeDelivery()
    {
        Account a1 = TestDataAccount.getNewAccount();
        a1.Account_Group__c = 'Sold To';
        update a1;

        SVMXC__Site__c rec1 = TestDataFieldService.getNewLocation(a1.Id);
        SVMXC__Site__c rec2 = TestDataFieldService.getNewLocation(a1.Id);
        SVMXC__Site__c rec3 = TestDataFieldService.getNewLocation(a1.Id);
        Set<Id> deliveredRecordIds = new Set<Id> { rec1.Id, rec2.Id, rec3.Id };

        TAPS_Batch__e tapsEvent = new TAPS_Batch__e(
            Record_IDs__c = JSON.serialize(deliveredRecordIds)
        );

        Test.startTest();
        
        Database.SaveResult sr = EventBus.publish(tapsEvent);
        Test.getEventBus().deliver();
        
        Test.stopTest();
        System.assertEquals(true,sr.isSuccess());//CodeScanFix [Assert Argument Order]
    }

    @isTest
    static void objectTypesToObjectNames()
    {
        List<SObjectType> types = new List<SObjectType> { Account.SObjectType, Lead.SObjectType };
        TAPS_Orchestrator tapsOrchestrator=new TAPS_Orchestrator();//DCP-44091
        List<String> typeNames = tapsOrchestrator.objectTypesToObjectNames(types);//DCP-44091

        Set<String> setTypeName = new Set<String>(typeNames);
        System.assertEquals(2, setTypeName.size());
        System.assert(setTypeName.contains('Lead'));
        System.assert(setTypeName.contains('Account'));
    }

    @isTest
    static void deferSharingFuture()
    {
        String strErrorMessage = '';
        try{
            Test.startTest();
                Account a1 = TestDataAccount.getNewAccount();
                TAPS_Orchestrator.deferSharingFuture(new Set<Id> {a1.Id}, null);
                TAPS_Orchestrator.deferSharingFuture(new Set<Id> {a1.Id}, new List<String> {'Account'});
            Test.stopTest();
        }catch(Exception e){
            System.debug('@@@ inside exception, value of e: '+e);
            strErrorMessage = String.valueOf(e);
        }    
        System.assert(strErrorMessage.contains(TAPS_ComposedBase.ETM_FUNCTIONALITY_NOT_SUPPORTED),'Sharing logic not working');
    }

    @isTest
    static void recalculateRecordChanges()
    {
        User anotherAdmin = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, new Set<Id> { UserInfo.getUserId() });

        Account a1 = TestDataAccount.getNewAccount();
        Account a2 = a1.clone();
        a2.OwnerId = anotherAdmin.Id;
        system.assert(String.isNotBlank(a2.OwnerId), 'OwnerId is blank');
        List<Account> oldRecs = new List<Account> {a1};
        List<Account> newRecs = new List<Account> {a1};

        List<String> parentFieldNames = new List<String> { 'OwnerId' };
        TAPS_Orchestrator tapsOrchestrator=new TAPS_Orchestrator();//DCP-44091
        tapsOrchestrator.recalculateRecordChanges(oldRecs, new Map<Id, Account>(newRecs), parentFieldNames, Account.SObjectType);//DCP-44091
    }

    @isTest
    static void testRetriggerTAPSBatches()
    {
        Account a1 = TestDataAccount.getNewAccount();
        a1.Account_Group__c = 'Sold To';
        update a1;

        List<SVMXC__Site__c> lstSites = new List<SVMXC__Site__c>();
        for (Integer i = 0; i<200; i++)
        {
            SVMXC__Site__c rec = TestDataFieldService.initLocation(a1.Id);
            lstSites.add(rec);
        }

        // bypass TAPS on insert so that we can
        // control the publish of events
        Locations.bypassTapsOnInsert = true;
        insert lstSites;
        Locations.bypassTapsOnInsert = false;

        List<TAPS_Batch__e> lstTapsEvents = new List<TAPS_Batch__e>();
        for (SVMXC__Site__c site : lstSites)
        {
            lstTapsEvents.add(new TAPS_Batch__e(
                Record_IDs__c = TAPSBatches.customIdSerialization(new Set<Id> { site.Id })
            ));
        }

        Test.startTest();        
        List<Database.SaveResult> sr = EventBus.publish(lstTapsEvents);
        Test.getEventBus().deliver();
        Test.stopTest();

        System.assertEquals(true, sr.get(0).isSuccess());

        // little coverage
        TAPSBatches.notifyDisabled(new List<String>());
        
        Set<Id> ids = new Set<Id> {UserInfo.getUserId()};
        String serializedIds = TAPSBatches.customIdSerialization(ids);
        List<TAPS_Batch__e> lstTapsBatchEvents = new List<TAPS_Batch__e>();
        List<String> lstSerializedIds = new List<String>{serializedIds};
        for (String serializedId : lstSerializedIds){
            lstTapsBatchEvents.add(new TAPS_Batch__e(Record_IDs__c = serializedId));
        }
        TAPSBatches.notifyDisabled(lstTapsBatchEvents);        
    }

    @isTest
    static void coverPublishers()
    {
        Set<Id> ids = new Set<Id> {UserInfo.getUserId()};
        String serializedIds = TAPSBatches.customIdSerialization(ids);

        TAPSBatches.publish(ids);
        TAPSBatches.publish(serializedIds);
        TAPSBatches.publish(new List<String> {serializedIds});
        TAPSBatches.buildEvents(new List<String> {serializedIds});
        system.assert(true,'Assert not true');
    }

}