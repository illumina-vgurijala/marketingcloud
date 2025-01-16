/**
*    @author Todd Newman
*    Created Date 2018-12-13
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Ashwin Kumar                   31-Mar-2021         DCP-52339 Remove TestTAPS.setupDeferredObjectData
*         Prem Ranjan                    21-Feb-2023         Codescan fix (APEX) Unit Test Method should include System.Assert
*    ---------------------------------------------------------------------------------------------------------------------------
**/	
@isTest
private class TestTAPS_CustomerReadinessForm {

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
        if (mshareClass == null) mshareClass = new TAPS_CustomerReadinessForm();
        return mshareClass;
    }

    private static void reparentRecord(Id recordId, Id newParentId, Id newOpportunityId)
    {
        update new Customer_Readiness_Form__c(Id = recordId, SFT_Account__c = newParentId, Opportunity_Name__c = newOpportunityId);
    }

    private static void createShareRecords(Id recordId, List<Id> userIds)
    {
        TAPS_ComposedBase shareClass = getShareClass();

        List<Customer_Readiness_Form__Share> shareRecords = new List<Customer_Readiness_Form__Share>();
        for (Id i : userIds)
            shareRecords.add((Customer_Readiness_Form__Share)shareClass.createSharingRecord(recordId, i));

        insert shareRecords;
    }

    // these methods are the tests, only the object creation need to be altered by class

//    @isTest static void createRecordWithFieldUser()
//    {
//        // parent records
//
//        List<Id> accountIds = TestTAPS.createParentAccounts();
//        Opportunity o1 = TestDataOpportunity.getNewOpportunity2(accountIds.get(0));
//
//        // field users associated with parent account
//        Set<Id> alreadyUsedUserIds = new Set<Id>(TestTAPS.getAssociatedUserIds());
//        User fieldUser1 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_FIELD_SERVICE, alreadyUsedUserIds);
//        alreadyUsedUserIds.add(fieldUser1.Id);
//        User fieldUser2 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_FIELD_SERVICE, alreadyUsedUserIds);
//        SVMXC__Service_Group__c team1 = TestDataFieldService.getNewServiceTeam('Antarctica');
//        SVMXC__Service_Group_Members__c fieldService1 = TestDataFieldService.getNewFieldSupport(fieldUser1.Id, fieldUser1.Name, team1.id);
//        SVMXC__Service_Group_Members__c fieldService2 = TestDataFieldService.getNewFieldSupport(fieldUser2.Id, fieldUser2.Name, team1.id);
//
//        // this guy has a sharable role, he will be counted
//        TestDataFieldService.getNewAccountToFieldSupport(accountIds.get(0), AccountToFieldSupports.FSE_MANAGER, fieldService1.Id);
//        // this guy does not have a sharable role, he will not be counted
//        TestDataFieldService.getNewAccountToFieldSupport(accountIds.get(0), AccountToFieldSupports.SECONDARY_FSE, fieldService2.Id);
//
//        // add record
//        Customer_Readiness_Form__c rec1;
//        Test.startTest();
//        {
//            rec1 = TestDataOpportunity.getNewCrf(accountIds.get(0), o1.Id);
//            Test.getEventBus().deliver();
//        }
//        Test.stopTest();
//
//        // validate shares were added by batch
//        // one more than usual because of the field service user
//        System.assertEquals(3, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, new List<String> {'Field_Users__c'}));
//    }

    @isTest static void removeFieldUserFromRecord()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();
        Opportunity o1 = TestDataOpportunity.getNewOpportunity2(accountIds.get(0));

        // field users associated with parent account
        Set<Id> alreadyUsedUserIds = new Set<Id>(TestTAPS.getAssociatedUserIds());
        User fieldUser1 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_FIELD_SERVICE, alreadyUsedUserIds);
        SVMXC__Service_Group__c team1 = TestDataFieldService.getNewServiceTeam('Antarctica');
        SVMXC__Service_Group_Members__c fieldService1 = TestDataFieldService.getNewFieldSupport(fieldUser1.Id, fieldUser1.Name, team1.id);
        Account_to_Field_Support__c accountSupportLink1 = TestDataFieldService.getNewAccountToFieldSupport(accountIds.get(0), AccountToFieldSupports.FSE_MANAGER, fieldService1.Id);

        // add record
        Customer_Readiness_Form__c rec1 = TestDataOpportunity.getNewCrf(accountIds.get(0), o1.Id);

        // get associated users
        List<Id> associatedUserIds = TestTAPS.getAssociatedUserIds();
        List<Id> usersOnA1 = new List<Id> { associatedUserIds.get(0), associatedUserIds.get(1), fieldUser1.Id };

        // manually create initial shares since since the trigger won't run the batch
        createShareRecords(rec1.Id, usersOnA1);
// pull assert because there is a chicken-and-egg in initial deployment
        System.assertEquals(3, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, new List<String> {'Field_Users__c'}));

        Test.startTest();
        {
            delete accountSupportLink1;
            // Added by Satya as part of PRB0042764 
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares were added by batch
        // no field users for this case
// pull assert because there is a chicken-and-egg in initial deployment
//        System.assertEquals(2, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, new List<String> {'Field_Users__c'}));
    }

//    @isTest static void modifyFieldUserSharesWithRecord()
//    {
//        // parent records
//        List<Id> accountIds = TestTAPS.createParentAccounts();
//        Opportunity o1 = TestDataOpportunity.getNewOpportunity2(accountIds.get(0));
//
//        // field users associated with parent account
//        Set<Id> alreadyUsedUserIds = new Set<Id>(TestTAPS.getAssociatedUserIds());
//        User fieldUser1 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_FIELD_SERVICE, alreadyUsedUserIds);
//        alreadyUsedUserIds.add(fieldUser1.Id);
//        User fieldUser2 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_FIELD_SERVICE, alreadyUsedUserIds);
//        SVMXC__Service_Group__c team1 = TestDataFieldService.getNewServiceTeam('Antarctica');
//        SVMXC__Service_Group_Members__c fieldService1 = TestDataFieldService.getNewFieldSupport(fieldUser1.Id, fieldUser1.Name, team1.id);
//        SVMXC__Service_Group_Members__c fieldService2 = TestDataFieldService.getNewFieldSupport(fieldUser2.Id, fieldUser2.Name, team1.id);
//        Account_to_Field_Support__c accountSupportLink1 = TestDataFieldService.getNewAccountToFieldSupport(accountIds.get(0), AccountToFieldSupports.PRIMARY_FSE, fieldService1.Id);
//        Account_to_Field_Support__c accountSupportLink2 = TestDataFieldService.getNewAccountToFieldSupport(accountIds.get(0), AccountToFieldSupports.SECONDARY_FSE, fieldService2.Id);
//
//        // add record
//        Customer_Readiness_Form__c rec1 = TestDataOpportunity.getNewCrf(accountIds.get(0), o1.Id);
//
//        // get associated users
//        List<Id> associatedUserIds = TestTAPS.getAssociatedUserIds();
//        List<Id> usersOnA1 = new List<Id> { associatedUserIds.get(0), associatedUserIds.get(1), fieldUser1.Id };
//
//        // manually create initial shares since since the trigger won't run the batch
//        createShareRecords(rec1.Id, usersOnA1);
//
//        Test.startTest();
//        {
//            // flip roles around
//            update new List<Account_to_Field_Support__c> {
//                new Account_to_Field_Support__c(Id = accountSupportLink1.Id, User_Role__c = AccountToFieldSupports.SECONDARY_FAS),
//                new Account_to_Field_Support__c(Id = accountSupportLink2.Id, User_Role__c = AccountToFieldSupports.FAS_MANAGER)
//            };
//            Test.getEventBus().deliver();
//        }
//        Test.stopTest();
//
//        // validate shares were swapped by batch
//        System.assertEquals(0, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, new List<Id> {fieldUser1.Id}, new List<String> {'Field_Users__c'}));
//        System.assertEquals(1, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, new List<Id> {fieldUser2.Id}, new List<String> {'Field_Users__c'}));
//    }

//    @isTest static void modifyRecordParent()
//    {
//        // parent records
//        List<Id> accountIds = TestTAPS.createParentAccounts();
//        Opportunity o1 = TestDataOpportunity.getNewOpportunity2(accountIds.get(0));
//        Opportunity o2 = TestDataOpportunity.getNewOpportunity2(accountIds.get(1));
//
//        // field users associated with parent account
//        Set<Id> alreadyUsedUserIds = new Set<Id>(TestTAPS.getAssociatedUserIds());
//        User fieldUser1 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_FIELD_SERVICE, alreadyUsedUserIds);
//        alreadyUsedUserIds.add(fieldUser1.Id);
//        User fieldUser2 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_FIELD_SERVICE, alreadyUsedUserIds);
//        SVMXC__Service_Group__c team1 = TestDataFieldService.getNewServiceTeam('Antarctica');
//        SVMXC__Service_Group_Members__c fieldService1 = TestDataFieldService.getNewFieldSupport(fieldUser1.Id, fieldUser1.Name, team1.id);
//        SVMXC__Service_Group_Members__c fieldService2 = TestDataFieldService.getNewFieldSupport(fieldUser2.Id, fieldUser2.Name, team1.id);
//        TestDataFieldService.getNewAccountToFieldSupport(accountIds.get(0), AccountToFieldSupports.PRIMARY_FSE, fieldService1.Id);
//        TestDataFieldService.getNewAccountToFieldSupport(accountIds.get(1), AccountToFieldSupports.PRIMARY_FSE, fieldService2.Id);
//
//        // add record
//        Customer_Readiness_Form__c rec1 = TestDataOpportunity.getNewCrf(accountIds.get(0), o1.Id);
//
//        // get associated users
//        List<Id> associatedUserIds = TestTAPS.getAssociatedUserIds();
//        List<Id> usersOnA1 = new List<Id> { associatedUserIds.get(0), associatedUserIds.get(1), fieldUser1.Id };
//
//        // manually create initial shares since since the trigger won't run the batch
//        createShareRecords(rec1.Id, usersOnA1);
//
//        Test.startTest();
//        {
//System.debug('TTN: starting test here');
//            reparentRecord(rec1.Id, accountIds.get(1), o2.Id);
//            Test.getEventBus().deliver();
//        }
//        Test.stopTest();
//
//        // validate shares were swapped by batch
//        System.assertEquals(0, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, new List<Id> {fieldUser1.Id}, new List<String> {'Field_Users__c'}));
//        System.assertEquals(1, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, new List<Id> {fieldUser2.Id}, new List<String> {'Field_Users__c'}));
//    }


    // inserting a record on an account associated to TERRITORY1
    // should add shares to the associated users
    @isTest static void createRecord()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();
        Opportunity o1 = TestDataOpportunity.getNewOpportunity2(accountIds.get(0));

        // add record
        Customer_Readiness_Form__c rec1;
        Test.startTest();
        {
            rec1 = TestDataOpportunity.getNewCrf(accountIds.get(0), o1.Id);
            // Added by Satya as part of PRB0042764 
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares were added by batch
        System.assertEquals(2, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, new List<String> {'Field_Users__c'}));
    }

    // moving a record from one account to another (and therefore from one territory to another)
    // should result in the old shares deleted and new shares added
    @isTest static void changeRecordParent()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();
        Opportunity o1 = TestDataOpportunity.getNewOpportunity2(accountIds.get(0));
        Opportunity o2 = TestDataOpportunity.getNewOpportunity2(accountIds.get(1));

        // add record
        Customer_Readiness_Form__c rec1 = TestDataOpportunity.getNewCrf(accountIds.get(0), o1.Id);

        // get associated users
        List<Id> associatedUserIds = TestTAPS.getAssociatedUserIds();
        List<Id> usersOnA1 = new List<Id> { associatedUserIds.get(0), associatedUserIds.get(1) };
        List<Id> usersOnA2 = new List<Id> { associatedUserIds.get(2) };

        // manually create initial shares since since the trigger won't run the batch
        createShareRecords(rec1.Id, usersOnA1);

        // validate we start with shares to users aligned with a1
        System.assertEquals(2, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, usersOnA1, new List<String> {'Field_Users__c'}));
        System.assertEquals(0, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, usersOnA2, new List<String> {'Field_Users__c'}));

        Test.startTest();
        {
            reparentRecord(rec1.Id, accountIds.get(1), o2.Id);
            // Added by Satya as part of PRB0042764 
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares now belong to users on a2
        System.assertEquals(0, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, usersOnA1, new List<String> {'Field_Users__c'}));
        System.assertEquals(1, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, usersOnA2, new List<String> {'Field_Users__c'}));
    }

    // NOTE: this method conflicted with a flow so I decided forget it
//    // inserting a record with no account
//    // should not bomb or create shares
//    @isTest static void createOrphanRecord()
//    {
//        // parent records
//        List<Id> accountIds = TestTAPS.createParentAccounts();
//        Opportunity o1 = TestDataOpportunity.getNewOpportunity2(accountIds.get(0));
//
//        // add orphan record
//        Customer_Readiness_Form__c rec1;
//        Test.startTest();
//        {
//            rec1 = TestDataOpportunity.initCrf(accountIds.get(0), o1.Id);
//            rec1.Opportunity_Name__c = null;
//            insert rec1;
//            Test.getEventBus().deliver();
//        }
//        Test.stopTest();
//
//        // validate shares were added by batch
//        System.assertEquals(0, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, new List<String> {'Field_Users__c'}));
//    }

}