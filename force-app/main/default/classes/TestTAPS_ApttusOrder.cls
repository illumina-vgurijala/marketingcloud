/**
*    @author Illumina
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Ashwin Kumar                   31-Mar-2021         DCP-52339 Remove TestTAPS.setupDeferredObjectData
*         Saddam                         08-Dec-2022         Codescan Fix , Varaible naming convention. 
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@isTest
private class TestTAPS_ApttusOrder {

    private static TAPS_ComposedBase mShareClass;

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

    private static TAPS_ComposedBase getShareClass()
    {
        if (mShareClass == null) mShareClass = new TAPS_ApttusOrder();
        return mShareClass;
    }

    private static void reparentRecord(Id recordId, Id newParentId)
    {
        //Rahul: Added UC parameter to the below line for DCP-25384
        update new Apttus_Config2__Order__c(Id = recordId, Apttus_Config2__SoldToAccountId__c = newParentId,Ultimate_Consignee__c = newParentId);
    }

    private static void createShareRecords(Id recordId, List<Id> userIds)
    {
        TAPS_ComposedBase shareClass = getShareClass();

        List<Apttus_Config2__Order__Share> shareRecords = new List<Apttus_Config2__Order__Share>();
        for (Id i : userIds)
            shareRecords.add((Apttus_Config2__Order__Share)shareClass.createSharingRecord(recordId, i));

        insert shareRecords;
    }

    @isTest static void objectType()
    {
        System.assertEquals(Apttus_Config2__Order__c.sObjectType, getShareClass().getObjectType());
    }

    // these methods are the tests, only the object creation need to be altered by class

    // inserting a record on an account associated to TERRITORY1
    // should add shares to the associated users
    @isTest static void createRecord()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();

        // add record
        Apttus_Config2__Order__c rec1;

        Set<Id> setAccountIds = new Set<Id>();
        for(Id i:accountIds){
            if(i!=null)
                setAccountIds.add(i);
        }

        Test.startTest();
        {
            rec1 = TestDataOrder.getNewOrder(accountIds.get(0));
            // Added by Satya as part of PRB0042764 
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        TAPS_ApttusOrder objTaps = new TAPS_ApttusOrder();
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

        // add record
        Apttus_Config2__Order__c rec1 = TestDataOrder.getNewOrder(accountIds.get(0));

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
            reparentRecord(rec1.Id, accountIds.get(1));
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

        // add record
        Apttus_Config2__Order__c rec1;

        Test.startTest();
        {
            rec1 = TestDataOrder.initOrder(accountIds.get(0));
            rec1.Apttus_Config2__SoldToAccountId__c = null;
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