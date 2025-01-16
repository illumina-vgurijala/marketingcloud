@isTest
/***************************************************************************************************************************************
* NAME   : TestTAPS_InstalledProducts 
*    @author Illumina
*    Modification Log:
*         Developer                      Date                Description
*         Ashwin Kumar                   31-Mar-2021         DCP-52339 Remove TestTAPS.setupDeferredObjectData
* --------------------------------------------------------------------------------------------------------------------------------------
*/
private class TestTAPS_InstalledProducts {

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
        if (mshareClass == null) mshareClass = new TAPS_InstalledProducts();
        return mshareClass;
    }

    private static void reparentRecord(Id recordId, Id newParentId)
    {
        update new SVMXC__Installed_Product__c(Id = recordId, SVMXC__Company__c = newParentId);
    }

    private static void createShareRecords(Id recordId, List<Id> userIds)
    {
        TAPS_ComposedBase shareClass = getShareClass();

        List<SVMXC__Installed_Product__Share> shareRecords = new List<SVMXC__Installed_Product__Share>();
        for (Id i : userIds)
            shareRecords.add((SVMXC__Installed_Product__Share)shareClass.createSharingRecord(recordId, i));

        insert shareRecords;
    }

    // these methods are the tests, only the object creation need to be altered by class

    // inserting a record on an account associated to TERRITORY1
    // should add shares to the associated users
    @isTest static void createRecord()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();
        SVMXC__Service_Order__c wo = TestDataFieldService.getNewWorkOrder(accountIds.get(0));

        // add record
        SVMXC__Installed_Product__c rec1;

        Test.startTest();
        {
            rec1 = TestDataInstalledProduct.getNewInstalledProduct(accountIds.get(0));
            // Added by Satya as part of PRB0042764 
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
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
        SVMXC__Service_Order__c wo = TestDataFieldService.getNewWorkOrder(accountIds.get(0));

        // add record
        SVMXC__Installed_Product__c rec1 = TestDataInstalledProduct.getNewInstalledProduct(accountIds.get(0));

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
            InstalledProducts.hasRunTaps = false;
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
        SVMXC__Service_Order__c wo = TestDataFieldService.getNewWorkOrder(accountIds.get(0));

        // add record
        SVMXC__Installed_Product__c rec1;

        Test.startTest();
        {
            rec1 = TestDataInstalledProduct.getNewInstalledProduct(null);
            // Added by Satya as part of PRB0042764 
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares were added by batch
        System.assertEquals(0, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id));
    }

}