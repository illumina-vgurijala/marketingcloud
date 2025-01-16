/**
*    @author Illumina
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Ashwin Kumar                   31-Mar-2021         DCP-52339 Remove TestTAPS.setupDeferredObjectData
*    ---------------------------------------------------------------------------------------------------------------------------
**/	
@isTest
private class TestTAPS_ApttusTempObject {

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

    private static TAPS_ComposedBase mshareClass;
    private static TAPS_ComposedBase getShareClass()
    {
        if (mshareClass == null) mshareClass = new TAPS_ApttusTempObject();
        return mshareClass;
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

        List<Apttus_Config2__TempObject__Share> shareRecords = new List<Apttus_Config2__TempObject__Share>();
        for (Id i : userIds)
            shareRecords.add((Apttus_Config2__TempObject__Share)shareClass.createSharingRecord(recordId, i));

        insert shareRecords;
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
        Apttus_Config2__TempObject__c rec1 = TestDataProposal.getNewTemp(cart1.Id);
        TAPS_DeferredRun.deferSharing(getShareClass().getObjectType().getDescribe().getName(), new Set<Id> {rec1.Id});
        
        Set<Id> setAccountIds = new Set<Id>();
        for(Id i:accountIds){
            if(i!=null)
                setAccountIds.add(i);
        }

        Test.startTest();
        {
            TAPS_DeferredRun processor = new TAPS_DeferredRun();
            processor.execute(null);
            // Added by Satya as part of PRB0042764 
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        TAPS_ApttusTempObject objTaps = new TAPS_ApttusTempObject();
        objTaps.getRecordIdsFromAccountIdsCustom(setAccountIds);
        Test.stopTest();

        // validate shares were added by batch
        System.assertEquals(2, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id));
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
        Apttus_Config2__TempObject__c rec1 = TestDataProposal.getNewTemp(cart1.Id);

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
    @isTest static void orphanRecord()
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
        Apttus_Config2__TempObject__c rec1;

        Test.startTest();
        {
            rec1 = TestDataProposal.initTemp(cart1.Id);
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

}