/**
*    @author Illumina
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Ashwin Kumar                   31-Mar-2021         DCP-52339 Remove TestTAPS.setupDeferredObjectData
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@isTest
private class TestTAPS_ApttusAssetLine {

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
        if (mshareClass == null) mshareClass = new TAPS_ApttusAssetLine();
        return mshareClass;
    }

    private static void reparentRecord(Id recordId, Id newParentId)
    {
        //Rahul: Added UC parameter to the below line for DCP-25384

        update new Apttus_Config2__AssetLineItem__c(Id = recordId, Apttus_Config2__AccountId__c = newParentId,Ultimate_Consignee__c = newParentId);
    }

    private static void createShareRecords(Id recordId, List<Id> userIds)
    {
        TAPS_ComposedBase shareClass = getShareClass();

        List<Apttus_Config2__AssetLineItem__Share> shareRecords = new List<Apttus_Config2__AssetLineItem__Share>();
        for (Id i : userIds)
            shareRecords.add((Apttus_Config2__AssetLineItem__Share)shareClass.createSharingRecord(recordId, i));

        insert shareRecords;
    }

    @isTest static void objectType()
    {
        System.assertEquals(Apttus_Config2__AssetLineItem__c.sObjectType, getShareClass().getObjectType());
    }

    // these methods are the tests, only the object creation need to be altered by class

    // inserting a record on an account associated to TERRITORY1
    // should add shares to the associated users
    @isTest static void createRecord()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();
        Product2 p1 = TestDataMaster.createProduct(true);

        Set<Id> setAccountIds = new Set<Id>();
        for(Id i:accountIds){
            if(i!=null)
                setAccountIds.add(i);
        }

        // add record
        Apttus_Config2__AssetLineItem__c rec1;

        Test.startTest();
        {
            rec1 = TestDataProposal.getNewAssetLineItem(accountIds.get(0), p1.Id);
            // Added by Satya as part of PRB0042764 
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        TAPS_ApttusAssetLine objTaps = new TAPS_ApttusAssetLine();
        objTaps.getRecordIdsFromAccountIdsCustom(setAccountIds);
        objTaps.getRecordIdsFromModifiedRecordIdsCustom(setAccountIds);
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
        Product2 p1 = TestDataMaster.createProduct(true);

        // add record
        Apttus_Config2__AssetLineItem__c rec1 = TestDataProposal.getNewAssetLineItem(accountIds.get(0), p1.Id);

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
            System.debug('Asset hasRunTaps'+ApttusAssetLineItems.hasRunTaps);
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

}