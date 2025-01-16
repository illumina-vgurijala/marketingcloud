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
private class TestTAPS_Consortium {

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

//    private static TAPS_ComposedBase m_shareClass;
//    private static TAPS_ComposedBase getShareClass()
//    {
//        if (m_shareClass == null) m_shareClass = new TAPS_Consortium();
//        return m_shareClass;
//    }
//
//    private static void reparentRecord(Id recordId, Id newParentId)
//    {
//        update new Consortium_Account__c(Id = recordId, Account__c = newParentId);
//    }
//
//    private static List<Consortium__Share> getShareRecords(Id parentId)
//    {
//        return [SELECT Id
//        FROM Consortium__Share
//        WHERE ParentId = :parentId
//        AND RowCause = :Schema.Consortium__Share.RowCause.Manual];
//    }

    private static List<Consortium__Share> getShareRecords(Id parentId, Set<Id> userIds)
    {
        return [SELECT Id
        FROM Consortium__Share
        WHERE ParentId = :parentId
        AND RowCause = :Schema.Consortium__Share.RowCause.Manual
        AND UserOrGroupId IN :userIds];
    }

//    private static void createShareRecords(Id recordId, Id user1Id)
//    {
//        TAPS_ComposedBase shareClass = getShareClass();
//        insert new List<Consortium__Share> {
//            (Consortium__Share)shareClass.createSharingRecord(recordId, user1Id)
//        };
//    }

    // these methods are the tests, only the object creation need to be altered by class

    // inserting an agreement link to an account associated to TERRITORY1 should add shares to the 2 associated users
    @isTest static void junctionAdd()
    {
        User otherAdmin = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, new Set<Id> { UserInfo.getUserId() });

        Territory2 territory1 = [SELECT Id FROM Territory2 WHERE Name = :TestTAPS.TERRITORY1 LIMIT 1];
        Territory2 territory1cp = [SELECT Id FROM Territory2 WHERE Name = :TestTAPS.TERRITORY1_CP LIMIT 1];
        UserTerritory2Association associatedUser1 = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :territory1.Id];
        UserTerritory2Association associatedUser1cp = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :territory1cp.Id];

        Account a1;
        Consortium__c rec1;
        Consortium_Account__c link1;
        System.runAs(otherAdmin)
        {
            a1 = TestDataAccount.getNewAccount();
            a1.Account_Group__c = 'Sold To';
            update a1;
            rec1 = TestDataConsortium.getNewConsortium();

            TestDataTerritory.getNewAccountTerritoryLink(a1, territory1);
            TestDataTerritory.getNewAccountTerritoryLink(a1, territory1cp);
        }
        Test.startTest();
        {
            link1 = TestDataConsortium.getNewConsortiumAccount(a1.Id, rec1.Id);
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares were added by batch
        List<SObject> shareRecordsAfter = getShareRecords(rec1.Id, new Set<Id> { associatedUser1.Id });
        System.assertEquals(0, shareRecordsAfter.size());

        List<SObject> shareRecordsAfterCp = getShareRecords(rec1.Id, new Set<Id> { associatedUser1cp.UserId });
        System.assertEquals(1, shareRecordsAfterCp.size());
    }

}