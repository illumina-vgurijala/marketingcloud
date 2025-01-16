@isTest
/***************************************************************************************************************************************
* NAME   : TestTAPS_Comments 
*    @author Illumina
*    Modification Log:
*         Developer                      Date                Description
*         Ashwin Kumar                   31-Mar-2021         DCP-52339 Remove TestTAPS.setupDeferredObjectData
* --------------------------------------------------------------------------------------------------------------------------------------
*/
private class TestTAPS_Comments {

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
        if (mshareClass == null) mshareClass = new TAPS_Comments();
        return mshareClass;
    }

    private static void reparentRecord(Id recordId, Id newParentId)
    {
        update new SVMXC__Service_Order__c(Id = recordId, SVMXC__Company__c = newParentId);
    }

    private static void createShareRecords(Id recordId, List<Id> userIds)
    {
        TAPS_ComposedBase shareClass = getShareClass();

        List<Comment__Share> shareRecords = new List<Comment__Share>();
        for (Id i : userIds)
            shareRecords.add((Comment__Share)shareClass.createSharingRecord(recordId, i));

        insert shareRecords;
    }

    @isTest static void objectType()
    {
        System.assertEquals(Comment__c.sObjectType, getShareClass().getObjectType());
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
        Comment__c rec1;

        Test.startTest();
        {
            rec1 = TestDataFieldService.getNewComment(wo.Id);
            // Added by Satya as part of PRB0042764 
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares were added by batch
        System.assertEquals(2, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id));

        // also check record conversion
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

        // add record
        Comment__c rec1 = TestDataFieldService.getNewComment(wo.Id);

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

    // moving a record from one account to another (and therefore from one territory to another)
    // should result in the old shares deleted and new shares added
    @isTest static void changeRecordOwner()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();
        SVMXC__Service_Order__c wo = TestDataFieldService.getNewWorkOrder(accountIds.get(0));
        User otherAdmin = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, new Set<Id> { UserInfo.getUserId() });

        // add record
        Comment__c rec1 = TestDataFieldService.getNewComment(wo.Id);

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
            update new Comment__c(Id = rec1.Id, OwnerId = otherAdmin.Id);
            // Added by Satya as part of PRB0042764 
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // same two shares
        // this is a lame test but I'm not sure how to handle this easily with the test data at hand
        // this gets coverage at least
        System.assertEquals(2, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, usersOnA1));
    }

    // inserting a record with no account
    // should not bomb or create shares
    @isTest static void createOrphanRecord()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();
        SVMXC__Service_Order__c wo = TestDataFieldService.getNewWorkOrder(accountIds.get(0));

        // add orphan record
        Comment__c rec1;
        Test.startTest();
        {
            rec1 = TestDataFieldService.initComment(wo.Id);
            rec1.Work_Order__c = null;
            insert rec1;
            // Added by Satya as part of PRB0042764 
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate nothing bad happens with orphan record
        System.assertEquals(0, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id));
    }

}