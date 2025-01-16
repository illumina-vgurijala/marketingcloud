/**
*    @author Todd Newman
*    Created Date 2018-12-11
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Ashwin Kumar                   31-Mar-2021         DCP-52339 Remove TestTAPS.setupDeferredObjectData
*    ---------------------------------------------------------------------------------------------------------------------------
**/	

@isTest
private class TestTAPS_Locations {

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
            TestTAPS.setupTerritoryDataWithPartners();
        }
    }

    // these methods do most of the object-specific work, modify all of them

    private static TAPS_ComposedBase mshareClass;
    private static TAPS_ComposedBase getShareClass()
    {
        if (mshareClass == null) mshareClass = new TAPS_Locations();
        return mshareClass;
    }

    private static void reparentRecord(Id recordId, Id newParentId)
    {
        update new SVMXC__Site__c(Id = recordId, SVMXC__Account__c = newParentId);
    }

    private static List<SVMXC__Site__Share> getShareRecords(Id parentId)
    {
        return [SELECT Id
        FROM SVMXC__Site__Share
        WHERE ParentId = :parentId
        AND RowCause = :Schema.SVMXC__Site__Share.RowCause.Manual];
    }

    private static List<SVMXC__Site__Share> getShareRecords(Id parentId, Set<Id> userIds)
    {
        return [SELECT Id
        FROM SVMXC__Site__Share
        WHERE ParentId = :parentId
        AND RowCause = :Schema.SVMXC__Site__Share.RowCause.Manual
        AND UserOrGroupId IN :userIds];
    }

    private static void createShareRecords(Id recordId, Id userId)
    {
        TAPS_ComposedBase shareClass = getShareClass();
        insert (SVMXC__Site__Share)shareClass.createSharingRecord(recordId, userId);
    }

    // these methods are the tests, only the object creation need to be altered by class

    // inserting a record to an account associated to TERRITORY1 should add shares to the 2 associated users
    @isTest static void customAdd()
    {
        User otherAdmin = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, new Set<Id> { UserInfo.getUserId() });

        Territory2 territory1 = [SELECT Id FROM Territory2 WHERE Name = :TestTAPS.TERRITORY1 LIMIT 1];
        Territory2 territory1cp = [SELECT Id FROM Territory2 WHERE Name = :TestTAPS.TERRITORY1_CP LIMIT 1];
        UserTerritory2Association associatedUser1 = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :territory1.Id];
        UserTerritory2Association associatedUser1cp = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :territory1cp.Id];

        Account a1;
        SVMXC__Site__c rec1;
        System.runAs(otherAdmin)
        {
            a1 = TestDataAccount.getNewAccount();
            a1.Account_Group__c = 'Sold To';
            update a1;

            TestDataTerritory.getNewAccountTerritoryLink(a1, territory1);
            TestDataTerritory.getNewAccountTerritoryLink(a1, territory1cp);
        }

        Test.startTest();
        {
            rec1 = TestDataFieldService.getNewLocation(a1.Id);
            // Added by Satya as part of PRB0042764 
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares were added by batch
        List<SObject> shareRecordsAfter = getShareRecords(rec1.Id, new Set<Id> { associatedUser1.Id });
        System.assertEquals(0, shareRecordsAfter.size());

        List<SObject> shareRecordsAfterCp = getShareRecords(rec1.Id, new Set<Id> { associatedUser1cp.UserId });
        System.assertEquals(1, shareRecordsAfterCp.size());
    }

    // inserting a record to an account associated to TERRITORY1 should add shares to the 2 associated users
    @isTest static void customAddWithoutAccount()
    {
        User otherAdmin = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, new Set<Id> { UserInfo.getUserId() });

        Territory2 territory1 = [SELECT Id FROM Territory2 WHERE Name = :TestTAPS.TERRITORY1 LIMIT 1];
        Territory2 territory1cp = [SELECT Id FROM Territory2 WHERE Name = :TestTAPS.TERRITORY1_CP LIMIT 1];
        UserTerritory2Association associatedUser1 = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :territory1.Id];
        UserTerritory2Association associatedUser1cp = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :territory1cp.Id];

        Account a1;
        SVMXC__Site__c rec1;
        System.runAs(otherAdmin)
        {
            a1 = TestDataAccount.getNewAccount();
            a1.Account_Group__c = 'Sold To';
            update a1;

            TestDataTerritory.getNewAccountTerritoryLink(a1, territory1);
            TestDataTerritory.getNewAccountTerritoryLink(a1, territory1cp);
        }

        Test.startTest();
        {
            rec1 = TestDataFieldService.initLocation(a1.Id);
            rec1.SVMXC__Account__c = null;
            rec1.Type__c = 'Partner Stock';
            insert rec1;

            Product2 prod = TestDataMaster.getNewProduct('Test Product','Instrument');
            SVMXC__Installed_Product__c ipRec = TestDataFieldService.createInstalledProduct(prod.Id);
            ipRec.SVMXC__Company__c = a1.Id;
            ipRec.SVMXC__Site__c = rec1.Id;
            insert ipRec; 

            // Added by Satya as part of PRB0042764 
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares were added by batch
        List<SObject> shareRecordsAfter = getShareRecords(rec1.Id, new Set<Id> { associatedUser1.Id });
        System.assertEquals(0, shareRecordsAfter.size());

        List<SObject> shareRecordsAfterCp = getShareRecords(rec1.Id, new Set<Id> { associatedUser1cp.UserId });
        System.assertEquals(1, shareRecordsAfterCp.size());
    }
    
    // move a record from one account to another (and therefore from one territory to another)
    // the old shares should go away and new shares created
    @isTest static void customReparent()
    {
        User otherAdmin = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, new Set<Id> { UserInfo.getUserId() });

        Territory2 territory1 = [SELECT Id FROM Territory2 WHERE Name = :TestTAPS.TERRITORY1 LIMIT 1];
        Territory2 territory2 = [SELECT Id FROM Territory2 WHERE Name = :TestTAPS.TERRITORY2 LIMIT 1];
        Territory2 territory1cp = [SELECT Id FROM Territory2 WHERE Name = :TestTAPS.TERRITORY1_CP LIMIT 1];
        Territory2 territory2cp = [SELECT Id FROM Territory2 WHERE Name = :TestTAPS.TERRITORY2_CP LIMIT 1];
        UserTerritory2Association associatedUser1 = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :territory1.Id];
        //UserTerritory2Association associatedUser2 = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :territory2.Id];
        UserTerritory2Association associatedUser1cp = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :territory1cp.Id];
        UserTerritory2Association associatedUser2cp = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :territory2cp.Id];

        Account a1;
        Account a2;
        SVMXC__Site__c rec1;
        System.runAs(otherAdmin)
        {
            a1 = TestDataAccount.initAccount();
            a1.Account_Group__c = 'Sold To';
            a2 = TestDataAccount.initAccount();
            a2.Account_Group__c = 'Sold To';
            insert new List<Account> { a1, a2 };

            rec1 = TestDataFieldService.getNewLocation(a1.Id);

            TestDataTerritory.getNewAccountTerritoryLink(a1, territory1);
            TestDataTerritory.getNewAccountTerritoryLink(a1, territory1cp);
            TestDataTerritory.getNewAccountTerritoryLink(a2, territory2);
            TestDataTerritory.getNewAccountTerritoryLink(a2, territory2cp);
        }

        // manually create initial shares since since the trigger won't run the batch
        createShareRecords(rec1.Id, associatedUser1cp.UserId);

        // validate we start with shares on channel users for a1
        List<SObject> shareRecordsBefore1 = getShareRecords(rec1.Id, new Set<Id> { associatedUser1cp.UserId });
        System.assertEquals(1, shareRecordsBefore1.size());
        List<SObject> shareRecordsBefore2 = getShareRecords(rec1.Id, new Set<Id> { associatedUser2cp.UserId, associatedUser1.UserId });
        System.assertEquals(0, shareRecordsBefore2.size());

        Test.startTest();
        {
            reparentRecord(rec1.Id, a2.Id);
            // Added by Satya as part of PRB0042764 
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares now belong to channel users on a2
        List<SObject> shareRecordsAfter1 = getShareRecords(rec1.Id, new Set<Id> { associatedUser1cp.UserId });
        System.assertEquals(0, shareRecordsAfter1.size());
        List<SObject> shareRecordsAfter2 = getShareRecords(rec1.Id, new Set<Id> { associatedUser2cp.UserId });
        System.assertEquals(1, shareRecordsAfter2.size());
    }

    // inserting a record with no account, shouldn't bomb
    @isTest static void orphanRecord()
    {
        User otherAdmin = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, new Set<Id> { UserInfo.getUserId() });

        Territory2 territory1 = [SELECT Id FROM Territory2 WHERE Name = :TestTAPS.TERRITORY1_CP LIMIT 1];

        Account a1;
        SVMXC__Site__c rec1;
        System.runAs(otherAdmin)
        {
            a1 = TestDataAccount.getNewAccount();
            a1.Account_Group__c = 'Sold To';
            update a1;

            TestDataTerritory.getNewAccountTerritoryLink(a1, territory1);
        }

        Test.startTest();
        {
            rec1 = TestDataFieldService.initLocation(a1.Id);
            rec1.SVMXC__Account__c = null;
            insert rec1;
            // Added by Satya as part of PRB0042764 
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate nothing bad happens with orphan record
        List<SObject> shareRecordsAfter = getShareRecords(rec1.Id);
        System.assertEquals(0, shareRecordsAfter.size());
    }

}