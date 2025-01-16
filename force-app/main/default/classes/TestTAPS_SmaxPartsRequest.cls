@isTest
/***************************************************************************************************************************************
* NAME   : TestTAPS_SmaxPartsRequest 
*    @author Illumina
*    Modification Log:
*         Developer                      Date                Description
*         Ashwin Kumar                   31-Mar-2021         DCP-52339 Remove TestTAPS.setupDeferredObjectData
* --------------------------------------------------------------------------------------------------------------------------------------
*/
private class TestTAPS_SmaxPartsRequest {

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
        if (mshareClass == null) mshareClass = new TAPS_SmaxPartsRequest();
        return mshareClass;
    }

    private static void reparentRecord(Id recordId, Id newParentId)
    {
        update new SVMXC__Service_Order__c(Id = recordId, SVMXC__Company__c = newParentId);
    }

    private static void createShareRecords(Id recordId, List<Id> userIds)
    {
        TAPS_ComposedBase shareClass = getShareClass();

        List<SVMXC__Parts_Request__Share> shareRecords = new List<SVMXC__Parts_Request__Share>();
        for (Id i : userIds)
            shareRecords.add((SVMXC__Parts_Request__Share)shareClass.createSharingRecord(recordId, i));

        insert shareRecords;
    }

    @isTest static void objectType()
    {
        System.assertEquals(SVMXC__Parts_Request__c.sObjectType, getShareClass().getObjectType());
    }

    // these methods are the tests, only the object creation need to be altered by class

    // inserting a record on an account associated to TERRITORY1
    // should add shares to the associated users
    @isTest static void createRecord()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();
        SVMXC__Service_Order__c wo = TestDataFieldService.getNewWorkOrder(accountIds.get(0));
        SVMXC__Site__c loc1 = TestDataFieldService.getNewLocation(accountIds.get(0));

        // add record
        SVMXC__Parts_Request__c rec1;

        Test.startTest();
        {
            rec1 = TestDataFieldService.getNewPartsRequest(wo.Id, accountIds.get(0), loc1.Id);
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
        SVMXC__Service_Order__c wo = TestDataFieldService.getNewWorkOrder(accountIds.get(0));
        SVMXC__Site__c loc1 = TestDataFieldService.getNewLocation(accountIds.get(0));

        // add record
        SVMXC__Parts_Request__c rec1 = TestDataFieldService.getNewPartsRequest(wo.Id, accountIds.get(0), loc1.Id);

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
            reparentRecord(wo.Id, accountIds.get(1));
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
        SVMXC__Site__c loc1 = TestDataFieldService.getNewLocation(accountIds.get(0));

        // add record
        SVMXC__Parts_Request__c rec1;

        Test.startTest();
        {
            rec1 = TestDataFieldService.initPartsRequest(wo.Id, accountIds.get(0), loc1.Id);
            rec1.SVMX_PS_Work_Order__c = null;
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