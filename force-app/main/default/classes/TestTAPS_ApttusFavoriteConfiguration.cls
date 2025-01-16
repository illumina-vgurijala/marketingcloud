/**
*    @author Illumina
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Ashwin Kumar                   31-Mar-2021         DCP-52339 Remove TestTAPS.setupDeferredObjectData and cover update context
*         Satya Swain                    09 Dec 2022         Added Codescan fix for Variable Naming Convention
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@isTest
private class TestTAPS_ApttusFavoriteConfiguration {

    // NOTE: TestTAPS covers scenarios like new user, new territory, territory move
    // this is just to make sure we have coverage of the specific object trigger

    @testSetup static void setupEtmData()
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

    private static TAPS_ComposedBase mShareClass;
    private static TAPS_ComposedBase getShareClass()
    {
        if (mShareClass == null) mShareClass = new TAPS_ApttusFavoriteConfiguration();
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

        List<Apttus_Config2__FavoriteConfiguration__Share> shareRecords = new List<Apttus_Config2__FavoriteConfiguration__Share>();
        for (Id i : userIds)
            shareRecords.add((Apttus_Config2__FavoriteConfiguration__Share)shareClass.createSharingRecord(recordId, i));

        insert shareRecords;
    }

    @isTest static void objectType()
    {
        System.assertEquals(Apttus_Config2__FavoriteConfiguration__c.sObjectType, getShareClass().getObjectType());
    }

    // these methods are the tests, only the object creation need to be altered by class

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
        Apttus_Config2__ProductConfiguration__c cart1 = TestDataProposal.getNewCart(quote1);

        // add record
        Apttus_Config2__FavoriteConfiguration__c rec1;

        Test.startTest();
        {
            rec1 = TestDataProposal.getNewFavorite(cart1.Id, priceList.Id);
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
        Apttus_Config2__ProductConfiguration__c cart1 = TestDataProposal.getNewCart(quote1);

        // add record
        Apttus_Config2__FavoriteConfiguration__c rec1 = TestDataProposal.getNewFavorite(cart1.Id, priceList.Id);

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

    // inserting a record with no account, shouldn't bomb
    @isTest static void createOrphanRecord()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();
        Opportunity o1 = TestDataOpportunity.getNewOpportunity2(accountIds.get(0));
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        Apttus_Proposal__Proposal__c quote1 = TestDataProposal.initProposal(accountIds.get(0), o1.Id, 'Test Proposal', priceList.Id, true, 'Draft', 'None');
        insert quote1;
        Apttus_Config2__ProductConfiguration__c cart1 = TestDataProposal.getNewCart(quote1);

        // add record
        Apttus_Config2__FavoriteConfiguration__c rec1;
        Test.startTest();
        {
            rec1 = TestDataProposal.initFavorite(cart1.Id, priceList.Id);
            rec1.Apttus_Config2__ConfigurationId__c = null;
            insert rec1;
            // Added by Satya as part of PRB0042764 
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares were added by batch
        System.assertEquals(0, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id));
    }

    //DCP-52339
    @isTest static void updateRecord()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();
        Opportunity o1 = TestDataOpportunity.getNewOpportunity2(accountIds.get(0));
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        Apttus_Proposal__Proposal__c quote1 = TestDataProposal.initProposal(accountIds.get(0), o1.Id, 'Test Proposal', priceList.Id, true, 'Draft', 'None');
        insert quote1;
        Apttus_Config2__ProductConfiguration__c cart1 = TestDataProposal.getNewCart(quote1);

        // add record
        Apttus_Config2__FavoriteConfiguration__c rec1 = TestDataProposal.getNewFavorite(cart1.Id, priceList.Id);
        User objNonAdminUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, new Set<Id>{UserInfo.getUserId()});
        
        Test.startTest();
        //update record
        rec1.OwnerId = objNonAdminUser.Id;
        update rec1;
        Test.stopTest();

        Apttus_Config2__FavoriteConfiguration__c updatedRec = [SELECT Id, OwnerId FROM Apttus_Config2__FavoriteConfiguration__c WHERE Id=:rec1.Id];
        System.assertEquals(objNonAdminUser.Id, updatedRec.OwnerId, 'Owner id not updated as expected');
    }

}