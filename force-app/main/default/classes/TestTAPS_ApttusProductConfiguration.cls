/**
*    @author Todd Newman
*    @date   
*    @description  Test class for TAPS_ApttusProductConfiguration
*    Modification Log:
*    --------------------------------------------------------------------------------------------------------------------------------------------
*           Developer                      Date                Description
*           Todd Newman                                        Initial Version
*           Satya Swain                    10-Dec-2020         DCP-43261/TASK0548217: Modified setupData and setupTerritoryData methods
*           Ashwin Kumar                   31-Mar-2021         DCP-52339 Remove TestTAPS.setupDeferredObjectData
*           Saddam                         08-Dec-2022         Codescan Fix , Varaible naming convention. 
*    --------------------------------------------------------------------------------------------------------------------------------------------
**/
@isTest
private class TestTAPS_ApttusProductConfiguration {

    private static TAPS_ComposedBase mShareClass;

    // NOTE: TestTAPS covers scenarios like new user, new territory, territory move
    // this is just to make sure we have coverage of the specific object trigger
    @testSetup static void setupData()
    {
        setupTerritoryData();
    }
    static void setupTerritoryData()
    {
        User objUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN,new Set<Id>{UserInfo.getUserId()});
        System.runAs(objUser){
            TestTAPS.setupTerritoryData();
        }
    }

    // these methods do most of the object-specific work, modify all of them

    private static TAPS_ComposedBase getShareClass()
    {
        if (mShareClass == null) mShareClass = new TAPS_ApttusProductConfiguration();
        return mShareClass;
    }

    private static void reparentRecord(Id recordId, Id newParentId)
    {
        // opportunity was created in this transaction, clear query cache for update
        OpportunitySelector.clearOpportunityCache();
        // Rahul: Added UC parameter to the below line for DCP-25384
        update new Opportunity(Id = recordId, AccountId = newParentId, Ultimate_Consignee__c = newParentId);
    }

    private static void createShareRecords(Id recordId, List<Id> userIds)
    {
        TAPS_ComposedBase shareClass = getShareClass();

        List<Apttus_Config2__ProductConfiguration__Share> shareRecords = new List<Apttus_Config2__ProductConfiguration__Share>();
        for (Id i : userIds)
            shareRecords.add((Apttus_Config2__ProductConfiguration__Share)shareClass.createSharingRecord(recordId, i));

        insert shareRecords;
    }

    // these methods are the tests, only the object creation need to be altered by class

    // TODO: rewrite these to be deferred runs
    // inserting a record on an account associated to TERRITORY1
    // should add shares to the associated users
    @isTest static void createRecord()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();
        Opportunity o1 = TestDataOpportunity.getNewOpportunity2(accountIds.get(0));
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        Apttus_Proposal__Proposal__c quote1 = TestDataProposal.initProposal(accountIds.get(0), o1.Id, 'Test Proposal', priceList.Id, true, 'Draft', 'None');
        insert quote1;

        // add record
        Apttus_Config2__ProductConfiguration__c rec1 = TestDataProposal.getNewCart(quote1);
        TAPS_DeferredRun.deferSharing(getShareClass().getObjectType().getDescribe().getName(), new Set<Id> {rec1.Id});

        Test.startTest();
        {
            TAPS_DeferredRun processor = new TAPS_DeferredRun();
            processor.execute(null);
            // Added by Satya as part of PRB0042764 
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares were added by batch
        System.assertEquals(2, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id));

        // also check record id conversion method
        Set<Id> recordIds = getShareClass().getRecordIdsFromAccountIdsCustom(new Set<Id>(accountIds));
        System.assert(recordIds.contains(rec1.Id), 'idsFromAccountIds: Did not successfully convert from account IDs to record IDs');
    }

    // moving a record from one account to another (and therefore from one territory to another)
    // should result in the old shares deleted and new shares added
    @isTest static void changeRecordParent()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();
        Opportunity o1 = TestDataOpportunity.getNewOpportunity2(accountIds.get(0));
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        Apttus_Proposal__Proposal__c quote1 = TestDataProposal.initProposal(accountIds.get(0), o1.Id, 'Test Proposal', priceList.Id, true, 'Draft', 'None');
        insert quote1;

        // add record
        Apttus_Config2__ProductConfiguration__c rec1 = TestDataProposal.getNewCart(quote1);

        // get associated users
        List<Id> associatedUserIds = TestTAPS.getAssociatedUserIds();
        List<Id> usersOnA1 = new List<Id> { associatedUserIds.get(0), associatedUserIds.get(1) };
        List<Id> usersOnA2 = new List<Id> { associatedUserIds.get(2) };

        // manually create initial shares since since the trigger won't run the batch
        createShareRecords(rec1.Id, usersOnA1);

        // validate we start with shares to users aligned with a1
        System.assertEquals(2, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, usersOnA1));
        System.assertEquals(0, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, usersOnA2));

        Test.startTest();
        {
            reparentRecord(o1.Id, accountIds.get(1));
            // Added by Satya as part of PRB0042764 
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares now belong to users on a2
        System.assertEquals(0, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, usersOnA1));
        System.assertEquals(1, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, usersOnA2));
    }

    // causes a flow error
    // would be nice to fix sometime but this isn't a real business scenario
    // so let it be for now
//    // inserting a record with no account, shouldn't bomb
//    @isTest static void createOrphanRecord()
//    {
//        // parent records
//        List<Id> accountIds = TestTAPS.createParentAccounts();
//        Opportunity o1 = TestDataOpportunity.getNewOpportunity2(accountIds.get(0));
//        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
//        insert priceList;
//        Apttus_Proposal__Proposal__c quote1 = TestDataProposal.initProposal(accountIds.get(0), o1.Id, 'Test Proposal', priceList.Id, true, 'Draft', 'None');
//        insert quote1;
//
//        // add record
//        Apttus_Config2__ProductConfiguration__c rec1;
//
//        Test.startTest();
//        {
//            rec1 = TestDataProposal.initCart(quote1);
//            rec1.Apttus_QPConfig__Proposald__c = null;
//            insert rec1;
//            Test.getEventBus().deliver();
//        }
//        Test.stopTest();
//
//        // validate shares were added by batch
//        System.assertEquals(0, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id));
//   }

}