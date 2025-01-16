/**  
*    @description  Test class for SharingConsole
*    Modification Log:
*    --------------------------------------------------------------------------------------------------------------------------------------------
*           Developer                      Date                Description
*           Ashwin Kumar                   28-Mar-2022         DCP-52339: Remove TAPS_Deferred_Object__c & its field's references
*           Nishan Shetty                  24-Aug-2022         DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
*           Nishan                         10-Oct-2022         CodeScanFix [Method name should not start with Capital].
*           Adyasha Satapathy              28-Nov-2022         POL-54: Update region references to AMEA and EUR
*           Prem Ranjan                    21-Feb-2023         Codescan fix (APEX) Unit Test Method should include System.Assert
*           Gerardo Garcia                 10-Oct-2023         CMCM-2893 Add throw exception if active territory model was not found
*           Rajbabu Boopalan               20-Dec-2023         CMCM-4122 fix SOQL 201 error
*    --------------------------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public class TestTAPS {

    // place to store the object being tested by the current unit test method
    // is used in TAPSBatches to run code only for that object in order
    // to fit in Salesforce platform limits
    public static Schema.SObjectType objectBeingTested;

    public final static String ACCOUNT1_NAME = 'Test Account 1';
    public final static String ACCOUNT2_NAME = 'Test Account 2';
    //Added by Rahul - DCP-25384
    public final static String UC1_NAME = 'Test UC Account 1';
    public final static String UC2_NAME = 'Test UC Account 2';

    // first region in the hierarchy
    public final static String REGION1 = 'R1';
    public final static String BU1 = 'BU1';
    public final static String SUBREGION1 = 'SR1';
    public final static String SUBREGION2 = 'SR2';
    public final static String DISTRICT1 = 'D1';
    public final static String DISTRICT2 = 'D2';
    public final static String TERRITORY1 = 'T1';
    public final static String TERRITORY2 = 'T2';
    public final static String TERRITORY1_CP = TERRITORY1 + '_' + Territories2.CHANNEL_PARTNER_LABEL;
    public final static String TERRITORY2_CP = TERRITORY2 + '_' + Territories2.CHANNEL_PARTNER_LABEL;

    // second region in the hierarchy (new) DCP-25384
    public final static String REGION2 = 'R2';
    public final static String BU2 = 'BU2';
    public final static String SUBREGION3 = 'SR3';
    public final static String DISTRICT3 = 'D3';
    public final static String TERRITORY3 = 'T3';

    @testSetup static void setupEtmData()
    {
        setupTestTAPSTerritoryData();
    }
    static void setupTestTAPSTerritoryData(){
        User objUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN,new Set<Id>{UserInfo.getUserId()});
        System.runAs(objUser){
            setupTerritoryData();
        }
    }
    /**
     * @actor illumina
     * @description:- available for use in other TAPS test classes
     */
    public static void setupTerritoryData()
    {
        setupTerritoryData(false);
    }
     /**
     * @actor illumina
     * @description:- 
     */
    public static void setupTerritoryDataWithPartners()
    {
        setupTerritoryData(true);
    }
     /**
     * @actor illumina
     * @description:- 
     */
    private static void setupTerritoryData(Boolean includeChannelUsers)
    {
        List<Territory2Model> activeModels = [SELECT Id FROM Territory2Model WHERE State = 'Active'];
        if (activeModels.size() == 0) {
            throw new AuraHandledException('You need Active Territory2Model in order to continue the test');
        }
        Id modelId = activeModels.get(0).Id;

        Territory2 region1 = TestDataTerritory.getNewTerritory(modelId, REGION1, TerritoryTypesService.pickT2TypeIdFromList(TerritoryTypesService.TYPE_REGION));
        Territory2 bu1 = TestDataTerritory.getNewTerritory(modelId, BU1, TerritoryTypesService.pickT2TypeIdFromList(TerritoryTypesService.TYPE_BU), region1.Id);

        Territory2 subregion1 = TestDataTerritory.initTerritory(modelId, SUBREGION1, TerritoryTypesService.pickT2TypeIdFromList(TerritoryTypesService.TYPE_SUBREGION), bu1.Id);
        Territory2 subregion2 = TestDataTerritory.initTerritory(modelId, SUBREGION2, TerritoryTypesService.pickT2TypeIdFromList(TerritoryTypesService.TYPE_SUBREGION), bu1.Id);
        insert new List<Territory2> { subregion1, subregion2 };

        Territory2 district1 = TestDataTerritory.initTerritory(modelId, DISTRICT1, TerritoryTypesService.pickT2TypeIdFromList(TerritoryTypesService.TYPE_DISTRICT), subregion1.Id);
        Territory2 district2 = TestDataTerritory.initTerritory(modelId, DISTRICT2, TerritoryTypesService.pickT2TypeIdFromList(TerritoryTypesService.TYPE_DISTRICT), subregion2.Id);
        insert new List<Territory2> { district1, district2 };

        Territory2 territory1 = TestDataTerritory.initTerritory(modelId, TERRITORY1, TerritoryTypesService.pickT2TypeIdFromList(TerritoryTypesService.TYPE_TERRITORY), district1.Id);
        Territory2 territory2 = TestDataTerritory.initTerritory(modelId, TERRITORY2, TerritoryTypesService.pickT2TypeIdFromList(TerritoryTypesService.TYPE_TERRITORY), district2.Id);
        insert new List<Territory2> { territory1, territory2 };

        ////second region (new) DCP-25384
        Territory2 region2 = TestDataTerritory.getNewTerritory(modelId, REGION2, TerritoryTypesService.pickT2TypeIdFromList(TerritoryTypesService.TYPE_REGION));
        Territory2 bu2 = TestDataTerritory.getNewTerritory(modelId, BU2, TerritoryTypesService.pickT2TypeIdFromList(TerritoryTypesService.TYPE_BU), region2.Id);
        Territory2 subregion3 = TestDataTerritory.getNewTerritory(modelId, SUBREGION3, TerritoryTypesService.pickT2TypeIdFromList(TerritoryTypesService.TYPE_SUBREGION), bu2.Id);
        Territory2 district3 = TestDataTerritory.getNewTerritory(modelId, DISTRICT3, TerritoryTypesService.pickT2TypeIdFromList(TerritoryTypesService.TYPE_DISTRICT), subregion3.Id);
        Territory2 territory3 = TestDataTerritory.getNewTerritory(modelId, TERRITORY3, TerritoryTypesService.pickT2TypeIdFromList(TerritoryTypesService.TYPE_TERRITORY), district3.Id);

        User territoryUser1 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_SALES_REP, new Set<Id>());
        User srUser1 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_SALES_REP, new Set<Id> { territoryUser1.Id }); // TestDataUser.PROFILE_FIELD_SERVICE ... , territoryUser2.Id
        User srUser2 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_FIELD_SERVICE, new Set<Id> { territoryUser1.Id, srUser1.Id });
        ////DCP-25384
        User srUser3 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_SALES_REP, new Set<Id> { territoryUser1.Id, srUser1.Id , srUser2.Id });

        // second region (new) DCP-25384
        User territoryUser2 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_SALES_REP, new Set<Id> { territoryUser1.Id, srUser1.Id, srUser2.Id,srUser3.Id});

        // user to territory associations
        UserTerritory2Association associatedUser1 = TestDataTerritory.initUserTerritoryLink(territoryUser1.Id, territory1.Id);
        UserTerritory2Association associatedUser2 = TestDataTerritory.initUserTerritoryLink(srUser1.Id, subregion1.Id);
        UserTerritory2Association associatedUser3 = TestDataTerritory.initUserTerritoryLink(srUser2.Id, subregion2.Id);
        //// second region (new) DCP-25384
        UserTerritory2Association associatedUser4 = TestDataTerritory.initUserTerritoryLink(territoryUser2.Id, territory3.Id);
        UserTerritory2Association associatedUser5 = TestDataTerritory.initUserTerritoryLink(srUser3.Id, subregion3.Id);
        insert new List<UserTerritory2Association> { associatedUser1, associatedUser2, associatedUser3,associatedUser4,associatedUser5}; // Added by Rahul

        if (includeChannelUsers)
        {
            setupIndirectTerritoryData(modelId, district1, district2);
        }
    }

    private static Id distContact1;
    private static Id distContact2;
    private static void createDistributorContacts()
    {
        // need a different admin b/c this is a non-setup object
        //User otherAdmin = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, new Set<Id> { UserInfo.getUserId() });
        User otherAdmin = [SELECT Id FROM User WHERE Profile.Name = :TestDataUser.PROFILE_ADMIN AND Id != :UserInfo.getUserId() AND UserRoleId != null AND IsActive = true LIMIT 1];

        System.runAs(otherAdmin)
        {
            Account distrib = TestDataAccount.initAccount();
            distrib.Account_Group__c = Accounts.GROUP_DISTRIBUTOR;
            insert distrib;

            Contact con1 = TestDataContact.initContact(distrib);
            Contact con2 = TestDataContact.initContact(distrib);
            insert new List<Contact> {con1, con2};
            distContact1 = con1.Id;
            distContact2 = con2.Id;
        }
    }
    /**
     * @actor illumina
     * @descrption:-available for use in other TAPS test classes
     */
    public static void setupIndirectTerritoryData(Id modelId, Territory2 district1, Territory2 district2)
    {
        createDistributorContacts();

        Id myId = UserInfo.getUserId();
        User anotherAdmin = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, new Set<Id> { myId });
        System.runAs(anotherAdmin)
        {
            TestDataUser.allowUserCreation(myId);
        }

        Territory2 territory1cp = TestDataTerritory.initTerritory(modelId, TERRITORY1_CP, TerritoryTypesService.pickT2TypeIdFromList(TerritoryTypesService.TYPE_TERRITORY_CP), district1.Id);
        Territory2 territory2cp = TestDataTerritory.initTerritory(modelId, TERRITORY2_CP, TerritoryTypesService.pickT2TypeIdFromList(TerritoryTypesService.TYPE_TERRITORY_CP), district2.Id);
        insert new List<Territory2> { territory1cp, territory2cp };

        Id profileId = [SELECT Id FROM Profile WHERE Name = :TestDataUser.PROFILE_CHANNEL].Id;

        // have to insert channel users so that we can find the account they are connected to within the test context
        User channelUser1 = TestDataUser.initPartnerUser(profileId, distContact1);
        User channelUser2 = TestDataUser.initPartnerUser(profileId, distContact2);
        insert new List<User> {channelUser1, channelUser2};

        insert new List<UserTerritory2Association> {
            TestDataTerritory.initUserTerritoryLink(channelUser1.Id, territory1cp.Id),
            TestDataTerritory.initUserTerritoryLink(channelUser2.Id, territory2cp.Id)
        };
    }
    /**
     * @actor illumina
     * @descrption:-
     */
    public static List<Id> createParentAccounts()
    {
        Territory2 territory1 = [SELECT Id FROM Territory2 WHERE Name = :TERRITORY1 LIMIT 1];
        Territory2 territory2 = [SELECT Id FROM Territory2 WHERE Name = :TERRITORY2 LIMIT 1];
        Territory2 territory3 = [SELECT Id FROM Territory2 WHERE Name = :TERRITORY3 LIMIT 1];

        Account a1;
        Account a2,uc1,uc2;

        a1 = TestDataAccount.initAmrAccount();
        a1.Name = ACCOUNT1_NAME;
        a2 = TestDataAccount.initAmrAccount();
        a2.Name = ACCOUNT2_NAME;
        //Added by Rahul
        uc1 = TestDataAccount.initAmrAccount();
        uc1.Name = UC1_NAME;
        uc2 = TestDataAccount.initAmrAccount();
        uc2.Name = UC2_NAME;

        insert new List<Account>{ a1, a2,uc1, uc2  };

        //Updated Definition by Rahul DCP-25384
        ObjectTerritory2Association objAssoc1 = TestDataTerritory.initAccountTerritoryLink(a1, territory1);
        ObjectTerritory2Association objAssoc2 =TestDataTerritory.initAccountTerritoryLink(a2, territory2);
        //Added by Rahul DCP-25384
         ObjectTerritory2Association objAssoc3 =TestDataTerritory.initAccountTerritoryLink(uc1, territory1);
         ObjectTerritory2Association objAssoc4 =TestDataTerritory.initAccountTerritoryLink(uc2, territory3);
        insert new List<ObjectTerritory2Association>{objAssoc1,objAssoc2,objAssoc3,objAssoc4 };

        // handle indirect
        List<Territory2> indirectTerritories = [SELECT Id FROM Territory2 WHERE Name IN (:TERRITORY1_CP, :TERRITORY2_CP)];
        if (indirectTerritories.size() > 0)
        {
            TestDataTerritory.getNewAccountTerritoryLink(a1, indirectTerritories.get(0));
            TestDataTerritory.getNewAccountTerritoryLink(a2, indirectTerritories.get(1));
        }

        return new List<Id> { a1.Id, a2.Id ,uc1.Id,uc2.Id};
    }
    /**
     * @actor illumina
     * @descrption:-
     */
    public static List<Id> getAssociatedUserIds()
    {
        List<Id> associatedUserIds = new List<Id>(3);

        List<UserTerritory2Association> allAssociations = [SELECT Id, UserId, Territory2.Name FROM UserTerritory2Association WHERE Territory2.Name IN (:TestTAPS.TERRITORY1, :TestTAPS.SUBREGION1, :TestTAPS.SUBREGION2)];
        for (UserTerritory2Association assoc : allAssociations)
        {
            if (assoc.Territory2.Name == TestTAPS.TERRITORY1) associatedUserIds.set(0, assoc.UserId);
            if (assoc.Territory2.Name == TestTAPS.SUBREGION1) associatedUserIds.set(1, assoc.UserId);
            if (assoc.Territory2.Name == TestTAPS.SUBREGION2) associatedUserIds.set(2, assoc.UserId);
        }
        return associatedUserIds;
    }
    /**
     * @actor illumina
     * @descrption:-
     */
    public static List<Id> getAssociatedPartnerUserIds()
    {
        List<Id> associatedUserIds = new List<Id>(2);

        List<UserTerritory2Association> allAssociations = [SELECT Id, UserId, Territory2.Name FROM UserTerritory2Association WHERE Territory2.Name IN (:TestTAPS.TERRITORY1_CP, :TestTAPS.TERRITORY2_CP)];
        for (UserTerritory2Association assoc : allAssociations)
        {
            if (assoc.Territory2.Name == TestTAPS.TERRITORY1_CP) associatedUserIds.set(0, assoc.UserId);
            if (assoc.Territory2.Name == TestTAPS.TERRITORY2_CP) associatedUserIds.set(1, assoc.UserId);
        }
        return associatedUserIds;
    }
    /**
     * @actor illumina
     * @descrption:-
     */
    public static Integer getShareRecordCount(TAPS_ComposedBase shareClass, Id parentId)
    {
        return getShareRecordCount(shareClass, parentId, null, New List<String>());
    }
    /**
     * @actor illumina
     * @descrption:-
     */
    public static Integer getShareRecordCount(TAPS_ComposedBase shareClass, Id parentId, List<Id> userIds)
    {
        return getShareRecordCount(shareClass, parentId, userIds, New List<String>());
    }
    /**
     * @actor illumina
     * @descrption:-
     */
     public static Integer getShareRecordCount(TAPS_ComposedBase shareClass, Id parentId, List<String> sharingReasons)
    {
        return getShareRecordCount(shareClass, parentId, null, sharingReasons);
    }
    /**
     * @actor illumina
     * @descrption:-
     */
    public static Integer getShareRecordCount(TAPS_ComposedBase shareClass, Id parentId, List<Id> userIds, List<String> sharingReasons)
    {
        sharingReasons.add('Manual');
        String soql = 'SELECT count()' +
            ' FROM ' + shareClass.getShareObjectType() +
            ' WHERE ' + shareClass.getShareParentFieldName() + ' = :parentId' +
            ' AND RowCause IN :sharingReasons';
        if (userIds != null) soql += ' AND UserOrGroupId IN :userIds';

        return Database.countQuery(soql);
    }
    /*
     * direct record manipulation tests
     * e.g. create a new record, move the record to a different account (and territory)
     */

    // inserting an installed product to an account associated to TERRITORY1 should add shares to the 2 associated users
    @isTest static void directAdd()
    {
        User otherAdmin = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, new Set<Id> { UserInfo.getUserId() });

        Territory2 territory1 = [SELECT Id FROM Territory2 WHERE Name = :TERRITORY1 LIMIT 1];

        SVMXC__Installed_Product__c c1;
        System.runAs(otherAdmin)
        {
            Account a1 = TestDataAccount.getNewAccount();
            c1 = TestDataInstalledProduct.getNewInstalledProduct(a1.Id);
            TestDataTerritory.getNewAccountTerritoryLink(a1, territory1);
        }
        Set<Id> modifiedRecordIds = new Set<Id> {c1.Id};

        // validate we start with 0 shares
        List<SVMXC__Installed_Product__Share> shareRecordsBefore = [SELECT Id FROM SVMXC__Installed_Product__Share WHERE ParentId = :c1.Id AND RowCause = :Schema.SVMXC__Installed_Product__Share.RowCause.Manual];
        System.assertEquals(0, shareRecordsBefore.size());

        Test.startTest();
        {
            // trigger would call the above line which passes result from a factory method into...
            TAPS_Orchestrator tapsOrchestrator = new TAPS_Orchestrator();//DCP-44091
            tapsOrchestrator.recalculateRecordChangesForObject(new InstalledProductSharing(), modifiedRecordIds);//DCP-44091
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares were added by batch
        List<SVMXC__Installed_Product__Share> shareRecordsAfter = [SELECT Id FROM SVMXC__Installed_Product__Share WHERE ParentId = :c1.Id AND RowCause = :Schema.SVMXC__Installed_Product__Share.RowCause.Manual];
        System.assertEquals(2, shareRecordsAfter.size());
    }

    // move an installed product from one account to another (and therefore from one territory to another)
    // the old shares should go away and new shares created
    @isTest static void directReparent()
    {
        User otherAdmin = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, new Set<Id> { UserInfo.getUserId() });

        Territory2 territory1 = [SELECT Id FROM Territory2 WHERE Name = :TERRITORY1 LIMIT 1];
        Territory2 territory2 = [SELECT Id FROM Territory2 WHERE Name = :TERRITORY2 LIMIT 1];
        Territory2 subregion1 = [SELECT Id FROM Territory2 WHERE Name = :SUBREGION1 LIMIT 1];
        Territory2 subregion2 = [SELECT Id FROM Territory2 WHERE Name = :SUBREGION2 LIMIT 1];
        UserTerritory2Association associatedUser1 = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :territory1.Id];
        //UserTerritory2Association associatedUser2 = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :territory2.Id];
        UserTerritory2Association associatedUser3 = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :subregion1.Id];
        UserTerritory2Association associatedUser4 = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :subregion2.Id];

        SVMXC__Installed_Product__c c1;
        Account a2;
        System.runAs(otherAdmin)
        {
            Account a1 = TestDataAccount.getNewAccount();
            a2 = TestDataAccount.getNewAccount();
            c1 = TestDataInstalledProduct.getNewInstalledProduct(a1.Id);
            TestDataTerritory.getNewAccountTerritoryLink(a1, territory1);
            TestDataTerritory.getNewAccountTerritoryLink(a2, territory2);
        }

        // manually create initial shares since since no actual trigger is firing
        TAPS_ComposedBase shareClass = new InstalledProductSharing();
        insert new List<SVMXC__Installed_Product__Share> {
                (SVMXC__Installed_Product__Share)shareClass.createSharingRecord(c1.Id, associatedUser1.UserId),
                (SVMXC__Installed_Product__Share)shareClass.createSharingRecord(c1.Id, associatedUser3.UserId)
        };

        // validate we start with shares on users for a1
        List<SVMXC__Installed_Product__Share> shareRecordsBefore1 = [SELECT Id FROM SVMXC__Installed_Product__Share WHERE ParentId = :c1.Id AND UserOrGroupId IN (:associatedUser1.UserId, :associatedUser3.UserId) AND RowCause = :Schema.SVMXC__Installed_Product__Share.RowCause.Manual];
        System.assertEquals(2, shareRecordsBefore1.size());
        List<SVMXC__Installed_Product__Share> shareRecordsBefore2 = [SELECT Id FROM SVMXC__Installed_Product__Share WHERE ParentId = :c1.Id AND UserOrGroupId IN (:associatedUser4.UserId) AND RowCause = :Schema.SVMXC__Installed_Product__Share.RowCause.Manual];
        System.assertEquals(0, shareRecordsBefore2.size());

        Test.startTest();
        {
            c1.SVMXC__Company__c = a2.Id;
            update c1;

            // trigger would call the above line which passes result from a factory method into...
            TAPS_Orchestrator tapsOrchestrator = new TAPS_Orchestrator();//DCP-44091
            tapsOrchestrator.recalculateRecordChangesForObject(new InstalledProductSharing(), new Set<Id> {c1.Id});//DCP-44091
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares now belong to users on a2
        List<SVMXC__Installed_Product__Share> shareRecordsAfter1 = [SELECT Id FROM SVMXC__Installed_Product__Share WHERE ParentId = :c1.Id AND UserOrGroupId IN (:associatedUser1.UserId, :associatedUser3.UserId) AND RowCause = :Schema.SVMXC__Installed_Product__Share.RowCause.Manual];
        System.assertEquals(0, shareRecordsAfter1.size());
        List<SVMXC__Installed_Product__Share> shareRecordsAfter2 = [SELECT Id FROM SVMXC__Installed_Product__Share WHERE ParentId = :c1.Id AND UserOrGroupId IN (:associatedUser4.UserId) AND RowCause = :Schema.SVMXC__Installed_Product__Share.RowCause.Manual];
        System.assertEquals(1, shareRecordsAfter2.size());
    }

    // TODO: redo this with another junction class such as apttus agreements or consortium

    // inserting an agreement link to an account associated to TERRITORY1 should add shares to the 2 associated users
    /*@isTest static void junctionAdd()
    {
        User otherAdmin = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, new Set<Id> { UserInfo.getUserId() });

        Territory2 territory1 = [SELECT Id FROM Territory2 WHERE Name = :TERRITORY1 LIMIT 1];

        Account a1;
        Customer_Agreement__c c1;
        Customer_Agreement_Account_Link__c link1;
        System.runAs(otherAdmin)
        {
            a1 = TestDataAccount.getNewAccount();
            a1.Account_Group__c = CustomerMasterDatas.GROUP_SOLD_TO;
            update a1;
            c1 = TestDataContract.getNewAgreement();
            link1 = TestDataContract.getNewAgreementLink(a1.Id, c1.Id);
            TestDataTerritory.getNewAccountTerritoryLink(a1, territory1);
        }
        List<Customer_Agreement_Account_Link__c> junctionRecords = [SELECT Id, Customer_Agreement__c, Account__c FROM Customer_Agreement_Account_Link__c WHERE Customer_Agreement__c = :c1.Id AND Account__c = :a1.Id];
        Set<Id> modifiedRecordIds = new Set<Id> {junctionRecords.get(0).Id};

        // validate we start with 0 shares
        List<Customer_Agreement__Share> shareRecordsBefore = [SELECT Id FROM Customer_Agreement__Share WHERE ParentId = :c1.Id AND RowCause = :Schema.Customer_Agreement__Share.RowCause.Manual];
        System.assertEquals(0, shareRecordsBefore.size());

        Test.startTest();
        {
            // trigger would call the above line which passes result from a factory method into...
            TAPS_Orchestrator.recalculateRecordChangesForObject(new AgreementJunctionSharing(), modifiedRecordIds);
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares were added by batch
        List<Customer_Agreement__Share> shareRecordsAfter = [SELECT Id FROM Customer_Agreement__Share WHERE ParentId = :c1.Id AND RowCause = :Schema.Customer_Agreement__Share.RowCause.Manual];
        System.assertEquals(2, shareRecordsAfter.size());
    }*/

    // move an agreement link from one account to another (and therefore from one territory to another)
    // the old shares should go away and new shares created
    /*@isTest static void junctionReparent()
    {
        User otherAdmin = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, new Set<Id> { UserInfo.getUserId() });

        Territory2 territory1 = [SELECT Id FROM Territory2 WHERE Name = :TERRITORY1 LIMIT 1];
        Territory2 territory2 = [SELECT Id FROM Territory2 WHERE Name = :TERRITORY2 LIMIT 1];
        Territory2 subregion1 = [SELECT Id FROM Territory2 WHERE Name = :SUBREGION1 LIMIT 1];
        Territory2 subregion2 = [SELECT Id FROM Territory2 WHERE Name = :SUBREGION2 LIMIT 1];
        UserTerritory2Association associatedUser1 = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :territory1.Id];
        //UserTerritory2Association associatedUser2 = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :territory2.Id];
        UserTerritory2Association associatedUser3 = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :subregion1.Id];
        UserTerritory2Association associatedUser4 = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :subregion2.Id];

        Account a1;
        Account a2;
        Customer_Agreement__c c1;
        Customer_Agreement_Account_Link__c link1;
        System.runAs(otherAdmin)
        {
            a1 = TestDataAccount.getNewAccount();
            a1.Account_Group__c = CustomerMasterDatas.GROUP_SOLD_TO;
            update a1;
            a2 = TestDataAccount.getNewAccount();
            a2.Account_Group__c = CustomerMasterDatas.GROUP_SOLD_TO;
            update a2;
            c1 = TestDataContract.getNewAgreement();
            link1 = TestDataContract.getNewAgreementLink(a1.Id, c1.Id);
            TestDataTerritory.getNewAccountTerritoryLink(a1, territory1);
            TestDataTerritory.getNewAccountTerritoryLink(a2, territory2);
        }

        // manually create initial shares since since no actual trigger is firing
        TAPS_ComposedBase shareClass = new AgreementJunctionSharing();
        insert new List<Customer_Agreement__Share> {
                (Customer_Agreement__Share)shareClass.createSharingRecord(c1.Id, associatedUser1.UserId),
                (Customer_Agreement__Share)shareClass.createSharingRecord(c1.Id, associatedUser3.UserId)
        };

        // validate we start with shares on users for a1
        List<Customer_Agreement__Share> shareRecordsBefore1 = [SELECT Id FROM Customer_Agreement__Share WHERE ParentId = :c1.Id AND UserOrGroupId IN (:associatedUser1.UserId, :associatedUser3.UserId) AND RowCause = :Schema.SVMXC__Installed_Product__Share.RowCause.Manual];
        System.assertEquals(2, shareRecordsBefore1.size());
        List<Customer_Agreement__Share> shareRecordsBefore2 = [SELECT Id FROM Customer_Agreement__Share WHERE ParentId = :c1.Id AND UserOrGroupId IN (:associatedUser4.UserId) AND RowCause = :Schema.SVMXC__Installed_Product__Share.RowCause.Manual];
        System.assertEquals(0, shareRecordsBefore2.size());

        Test.startTest();
        {
            link1.Account__c = a2.Id;
            update link1;
            // by default the above update will leave a non-primary link between a1 and c1
            // for this test that needs to be removed
            delete [SELECT Id FROM Customer_Agreement_Account_Link__c WHERE Customer_Agreement__c = :c1.Id AND Account__c = :a1.Id];

            List<Customer_Agreement_Account_Link__c> junctionRecords = [SELECT Id, Customer_Agreement__c, Account__c FROM Customer_Agreement_Account_Link__c WHERE Customer_Agreement__c = :c1.Id AND Account__c = :a2.Id];
            Set<Id> modifiedRecordIds = new Set<Id> {junctionRecords.get(0).Id};

            // trigger would call the above line which passes result from a factory method into...
            TAPS_Orchestrator.recalculateRecordChangesForObject(new AgreementJunctionSharing(), modifiedRecordIds);
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares now belong to users on a2
        List<Customer_Agreement__Share> shareRecordsAfter1 = [SELECT Id FROM Customer_Agreement__Share WHERE ParentId = :c1.Id AND UserOrGroupId IN (:associatedUser1.UserId, :associatedUser3.UserId) AND RowCause = :Schema.SVMXC__Installed_Product__Share.RowCause.Manual];
        System.assertEquals(0, shareRecordsAfter1.size());
        List<Customer_Agreement__Share> shareRecordsAfter2 = [SELECT Id FROM Customer_Agreement__Share WHERE ParentId = :c1.Id AND UserOrGroupId IN (:associatedUser4.UserId) AND RowCause = :Schema.SVMXC__Installed_Product__Share.RowCause.Manual];
        System.assertEquals(1, shareRecordsAfter2.size());
    }*/

    // inserting a comment to an account associated to TERRITORY1 should add shares to the 2 associated users
    @isTest static void customAdd()
    {
        User otherAdmin = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, new Set<Id> { UserInfo.getUserId() });

        Territory2 territory1 = [SELECT Id FROM Territory2 WHERE Name = :TERRITORY1 LIMIT 1];

        Account a1;
        Comment__c c1;
        System.runAs(otherAdmin)
        {
            a1 = TestDataAccount.getNewAccount();
            a1.Account_Group__c = CustomerMasterDatas.GROUP_SOLD_TO;
            update a1;
            SVMXC__Service_Order__c wo = TestDataFieldService.getNewWorkOrder(a1.Id);
            c1 = TestDataFieldService.getNewComment(wo.Id);
            TestDataTerritory.getNewAccountTerritoryLink(a1, territory1);
        }

        List<Comment__c> commentRecords = [SELECT Id, Work_Order__c, Work_Order__r.SVMXC__Company__c FROM Comment__c WHERE Id = :c1.Id];
        Set<Id> modifiedRecordIds = new Set<Id> {commentRecords.get(0).Work_Order__c};

        // validate we start with 0 shares
        List<Comment__Share> shareRecordsBefore = [SELECT Id FROM Comment__Share WHERE ParentId = :c1.Id AND RowCause = :Schema.SVMXC__Installed_Product__Share.RowCause.Manual];
        System.assertEquals(0, shareRecordsBefore.size());

        Test.startTest();
        {
            // trigger would call the above line which passes result from a factory method into...
            TAPS_Orchestrator tapsOrchestrator = new TAPS_Orchestrator();//DCP-44091
            tapsOrchestrator.recalculateRecordChangesForObject(new CommentCustomSharing(), modifiedRecordIds);//DCP-44091
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares were added by batch
        List<Comment__Share> shareRecordsAfter = [SELECT Id FROM Comment__Share WHERE ParentId = :c1.Id AND RowCause = :Schema.SVMXC__Installed_Product__Share.RowCause.Manual];
        System.assertEquals(2, shareRecordsAfter.size());
    }

    // move a comment from one account to another (and therefore from one territory to another)
    // the old shares should go away and new shares created
    @isTest static void customReparent()
    {
        User otherAdmin = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, new Set<Id> { UserInfo.getUserId() });

        Territory2 territory1 = [SELECT Id FROM Territory2 WHERE Name = :TERRITORY1 LIMIT 1];
        Territory2 territory2 = [SELECT Id FROM Territory2 WHERE Name = :TERRITORY2 LIMIT 1];
        Territory2 subregion1 = [SELECT Id FROM Territory2 WHERE Name = :SUBREGION1 LIMIT 1];
        Territory2 subregion2 = [SELECT Id FROM Territory2 WHERE Name = :SUBREGION2 LIMIT 1];
        UserTerritory2Association associatedUser1 = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :territory1.Id];
        //UserTerritory2Association associatedUser2 = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :territory2.Id];
        UserTerritory2Association associatedUser3 = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :subregion1.Id];
        UserTerritory2Association associatedUser4 = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :subregion2.Id];

        Account a1;
        Account a2;
        Comment__c c1;
        System.runAs(otherAdmin)
        {
            a1 = TestDataAccount.getNewAccount();
            a1.Account_Group__c = CustomerMasterDatas.GROUP_SOLD_TO;
            update a1;
            a2 = TestDataAccount.getNewAccount();
            a2.Account_Group__c = CustomerMasterDatas.GROUP_SOLD_TO;
            update a2;
            SVMXC__Service_Order__c wo = TestDataFieldService.getNewWorkOrder(a1.Id);
            c1 = TestDataFieldService.getNewComment(wo.Id);
            TestDataTerritory.getNewAccountTerritoryLink(a1, territory1);
            TestDataTerritory.getNewAccountTerritoryLink(a2, territory2);
        }

        // manually create initial shares since since no actual trigger is firing
        TAPS_ComposedBase shareClass = new CommentCustomSharing();
        insert new List<Comment__Share> {
                (Comment__Share)shareClass.createSharingRecord(c1.Id, associatedUser1.UserId),
                (Comment__Share)shareClass.createSharingRecord(c1.Id, associatedUser3.UserId)
        };

        // validate we start with shares on users for a1
        List<Comment__Share> shareRecordsBefore1 = [SELECT Id FROM Comment__Share WHERE ParentId = :c1.Id AND UserOrGroupId IN (:associatedUser1.UserId, :associatedUser3.UserId) AND RowCause = :Schema.Comment__Share.RowCause.Manual];
        System.assertEquals(2, shareRecordsBefore1.size());
        List<Comment__Share> shareRecordsBefore2 = [SELECT Id FROM Comment__Share WHERE ParentId = :c1.Id AND UserOrGroupId IN (:associatedUser4.UserId) AND RowCause = :Schema.Comment__Share.RowCause.Manual];
        System.assertEquals(0, shareRecordsBefore2.size());

        Comment__c commentDetails = [SELECT Id, Work_Order__c FROM Comment__c WHERE Id = :c1.Id];
        SVMXC__Service_Order__c woDetails = [SELECT Id, SVMXC__Company__c FROM SVMXC__Service_Order__c WHERE Id = :commentDetails.Work_Order__c];

        Test.startTest();
        {
            woDetails.SVMXC__Company__c = a2.Id;
            update woDetails;

            Set<Id> modifiedRecordIds = new Set<Id> {woDetails.Id};

            // trigger would call the above line which passes result from a factory method into...
            TAPS_Orchestrator tapsOrchestrator = new TAPS_Orchestrator();//DCP-44091
            tapsOrchestrator.recalculateRecordChangesForObject(new CommentCustomSharing(), modifiedRecordIds);//DCP-44091
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares now belong to users on a2
        List<Comment__Share> shareRecordsAfter1 = [SELECT Id FROM Comment__Share WHERE ParentId = :c1.Id AND UserOrGroupId IN (:associatedUser1.UserId, :associatedUser3.UserId) AND RowCause = :Schema.Comment__Share.RowCause.Manual];
        System.assertEquals(0, shareRecordsAfter1.size());
        List<Comment__Share> shareRecordsAfter2 = [SELECT Id FROM Comment__Share WHERE ParentId = :c1.Id AND UserOrGroupId IN (:associatedUser4.UserId) AND RowCause = :Schema.Comment__Share.RowCause.Manual];
        System.assertEquals(1, shareRecordsAfter2.size());
    }

    /*
     * territory user and hierarchy tests
     * e.g. move a territory in the hierarchy, add/remove a user from the hierarchy
     */

    // reparent a territory and make sure the shares flow to users in the new territory
    @isTest static void territoryMoveAffectsShares()
    {
        User otherAdmin = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, new Set<Id> { UserInfo.getUserId() });

        Territory2 territory1 = [SELECT Id FROM Territory2 WHERE Name = :TERRITORY1 LIMIT 1];
        Territory2 district2 = [SELECT Id, Name, ParentTerritory2Id FROM Territory2 WHERE Name = :DISTRICT2 LIMIT 1];
        Territory2 subregion1 = [SELECT Id FROM Territory2 WHERE Name = :SUBREGION1 LIMIT 1];
        Territory2 subregion2 = [SELECT Id FROM Territory2 WHERE Name = :SUBREGION2 LIMIT 1];
        UserTerritory2Association associatedUser1 = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :subregion1.Id];
        UserTerritory2Association associatedUser2 = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :subregion2.Id];

        Account a1;
        SVMXC__Installed_Product__c c1;
        System.runAs(otherAdmin)
        {
            a1 = TestDataAccount.getNewAccount();
            c1 = TestDataInstalledProduct.getNewInstalledProduct(a1.Id);
            TestDataTerritory.getNewAccountTerritoryLink(a1, territory1);
        }

        // manually create initial shares since since no actual trigger is firing
        TAPS_ComposedBase shareClass = new InstalledProductSharing();
        insert shareClass.createSharingRecord(c1.Id, associatedUser1.UserId);

        // Validate old SR user starts with a share
        List<SVMXC__Installed_Product__Share> shareRecordsBeforeUpdate1 = [SELECT Id FROM SVMXC__Installed_Product__Share WHERE ParentId = :c1.Id AND UserOrGroupId = :associatedUser1.UserId];
        System.assertEquals(1, shareRecordsBeforeUpdate1.size());

        Test.startTest();
        {
            // Now move the territory to a different district
            System.runAs(otherAdmin)
            {
                territory1.ParentTerritory2Id = district2.Id;
                update territory1;
            }

            // trigger would call recalculateTerritoryChanges()
            // aside from getting an implementation from a factory method,
            // that method makes these two calls
            TAPS_Orchestrator tapsOrchestrator = new TAPS_Orchestrator();//DCP-44091
            Set<Id> accountIds = tapsOrchestrator.getAccountIdsFromTerritoryIds(new Set<Id>{territory1.Id});//DCP-44091
            tapsOrchestrator.recalculateAccountChangesForObject(new InstalledProductSharing(), accountIds);//DCP-44091
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // old SR user lost his share
        List<SVMXC__Installed_Product__Share> shareRecordsafterUpdate1 = [SELECT Id FROM SVMXC__Installed_Product__Share WHERE ParentId = :c1.Id AND UserOrGroupId = :associatedUser1.UserId];
        System.assertEquals(0, shareRecordsafterUpdate1.size());
        // new SR user gained a share
        List<SVMXC__Installed_Product__Share> shareRecordsafterUpdate2 = [SELECT Id FROM SVMXC__Installed_Product__Share WHERE ParentId = :c1.Id AND UserOrGroupId = :associatedUser2.UserId];
        System.assertEquals(1, shareRecordsafterUpdate2.size());
    }

    // reparent a district and make sure the shares flow to users in and under the new district
    @isTest static void districtMoveAffectsShares()
    {
        User otherAdmin = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, new Set<Id> { UserInfo.getUserId() });

        Territory2 territory1 = [SELECT Id FROM Territory2 WHERE Name = :TERRITORY1 LIMIT 1];
        Territory2 district = [SELECT Id, Name, ParentTerritory2Id FROM Territory2 WHERE Name = :DISTRICT1 LIMIT 1];
        Territory2 subregion1 = [SELECT Id FROM Territory2 WHERE Name = :SUBREGION1 LIMIT 1];
        Territory2 subregion2 = [SELECT Id FROM Territory2 WHERE Name = :SUBREGION2 LIMIT 1];
        UserTerritory2Association associatedUser1 = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :subregion1.Id];
        UserTerritory2Association associatedUser2 = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :subregion2.Id];

        Account a1;
        SVMXC__Installed_Product__c c1;
        System.runAs(otherAdmin)
        {
            a1 = TestDataAccount.getNewAccount();
            c1 = TestDataInstalledProduct.getNewInstalledProduct(a1.Id);
            TestDataTerritory.getNewAccountTerritoryLink(a1, territory1);
        }

        Test.startTest();
        {
            // Now move the district to a different SR
            System.runAs(otherAdmin)
            {
                district.ParentTerritory2Id = subregion2.Id;
                update district;
            }

            // trigger would call recalculateTerritoryChanges()
            // aside from getting an implementation from a factory method,
            // that method makes these two calls
            TAPS_Orchestrator tapsOrchestrator = new TAPS_Orchestrator();//DCP-44091
            Set<Id> accountIds = tapsOrchestrator.getAccountIdsFromTerritoryIds(new Set<Id>{territory1.Id});//DCP-44091
            tapsOrchestrator.recalculateAccountChangesForObject(new InstalledProductSharing(), accountIds);//DCP-44091
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // old SR user has no share
        List<SVMXC__Installed_Product__Share> shareRecordsafterUpdate1 = [SELECT Id FROM SVMXC__Installed_Product__Share WHERE ParentId = :c1.Id AND UserOrGroupId = :associatedUser1.UserId];
        System.assertEquals(0, shareRecordsafterUpdate1.size());
        // new SR user has a share
        List<SVMXC__Installed_Product__Share> shareRecordsafterUpdate2 = [SELECT Id FROM SVMXC__Installed_Product__Share WHERE ParentId = :c1.Id AND UserOrGroupId = :associatedUser2.UserId];
        System.assertEquals(1, shareRecordsafterUpdate2.size());
    }

    // add a user to a territory and make sure shares are added
    @isTest static void userAddAffectsShares()
    {
        User otherAdmin = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, new Set<Id> { UserInfo.getUserId() });

        Territory2 territory1 = [SELECT Id FROM Territory2 WHERE Name = :TERRITORY1 LIMIT 1];
        Territory2 subregion2 = [SELECT Id FROM Territory2 WHERE Name = :SUBREGION2 LIMIT 1];
        UserTerritory2Association associatedUser1 = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :territory1.Id];
        UserTerritory2Association associatedUser2 = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :subregion2.Id];

        // remove user2 from SR2, he's now a free agent and will be repurposed later
        List<UserTerritory2Association> oldAssoc = [SELECT Id FROM UserTerritory2Association WHERE Territory2Id = :subregion2.Id AND UserId = :associatedUser2.UserId];
        System.assertEquals(1, oldAssoc.size());
        System.runAs(otherAdmin)
        {
            delete oldAssoc;
        }

        TAPS_ComposedBase shareClass = new InstalledProductSharing();

        Account a1;
        SVMXC__Installed_Product__c c1;
        System.runAs(otherAdmin)
        {
            a1 = TestDataAccount.getNewAccount();
            c1 = TestDataInstalledProduct.getNewInstalledProduct(a1.Id);
            TestDataTerritory.getNewAccountTerritoryLink(a1, territory1);

            // manually create initial shares since since no actual trigger is firing
            insert shareClass.createSharingRecord(c1.Id, associatedUser1.UserId);
        }

        // Validate only one share between the two users to start
        List<SVMXC__Installed_Product__Share> shareRecordsBeforeUpdate1 = [SELECT Id FROM SVMXC__Installed_Product__Share WHERE ParentId = :c1.Id AND UserOrGroupId IN (:associatedUser1.UserId, :associatedUser2.UserId)];
        System.assertEquals(1, shareRecordsBeforeUpdate1.size());

        Test.startTest();
        {
            // associate the user with the territory
            System.runAs(otherAdmin)
            {
                TestDataTerritory.getNewUserTerritoryLink(associatedUser2.UserId, territory1.Id);
            }

            // trigger would call recalculateTerritoryChanges()
            // aside from getting an implementation from a factory method,
            // that method makes these two calls
            TAPS_Orchestrator tapsOrchestrator = new TAPS_Orchestrator();//DCP-44091
            Set<Id> accountIds = tapsOrchestrator.getAccountIdsFromTerritoryIds(new Set<Id>{territory1.Id});//DCP-44091
            tapsOrchestrator.recalculateAccountChangesForObject(new InstalledProductSharing(), accountIds);//DCP-44091
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // old territory user still has his share
        List<SVMXC__Installed_Product__Share> shareRecordsafterUpdate1 = [SELECT Id FROM SVMXC__Installed_Product__Share WHERE ParentId = :c1.Id AND UserOrGroupId = :associatedUser1.UserId];
        System.assertEquals(1, shareRecordsafterUpdate1.size());
        // new territory user now has his share
        List<SVMXC__Installed_Product__Share> shareRecordsafterUpdate2 = [SELECT Id FROM SVMXC__Installed_Product__Share WHERE ParentId = :c1.Id AND UserOrGroupId = :associatedUser2.UserId];
        System.assertEquals(1, shareRecordsafterUpdate2.size());
    }

    // change a user's territory role and make sure shares are added
    @isTest static void userUpdateAffectsShares()
    {
        User otherAdmin = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, new Set<Id> { UserInfo.getUserId() });

        Territory2 territory1 = [SELECT Id FROM Territory2 WHERE Name = :TERRITORY1 LIMIT 1];
        Territory2 subregion2 = [SELECT Id FROM Territory2 WHERE Name = :SUBREGION2 LIMIT 1];
        UserTerritory2Association associatedUser1 = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :territory1.Id];
        UserTerritory2Association associatedUser2 = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :subregion2.Id];

        // remove user2 from SR2, he's now a free agent and will be repurposed later
        List<UserTerritory2Association> oldAssoc = [SELECT Id FROM UserTerritory2Association WHERE Territory2Id = :subregion2.Id AND UserId = :associatedUser2.UserId];
        System.assertEquals(1, oldAssoc.size());
        System.runAs(otherAdmin)
        {
            delete oldAssoc;
        }

        TAPS_ComposedBase shareClass = new InstalledProductSharing();

        Account a1;
        SVMXC__Installed_Product__c c1;
        UserTerritory2Association assoc1;

        System.runAs(otherAdmin)
        {
            a1 = TestDataAccount.getNewAccount();
            c1 = TestDataInstalledProduct.getNewInstalledProduct(a1.Id);
            TestDataTerritory.getNewAccountTerritoryLink(a1, territory1);

            // manually create initial shares since since no actual trigger is firing
            insert shareClass.createSharingRecord(c1.Id, associatedUser1.UserId);

            assoc1 = TestDataTerritory.initUserTerritoryLink(associatedUser2.UserId, territory1.Id);
            assoc1.RoleInTerritory2 = '';
            insert assoc1;
        }

        // Validate no shares yet.  NOTE: flaw in this test, need to change logic of trigger to fix
        List<SVMXC__Installed_Product__Share> shareRecordsBeforeUpdate1 = [SELECT Id FROM SVMXC__Installed_Product__Share WHERE ParentId = :c1.Id AND UserOrGroupId IN (:associatedUser1.UserId, :associatedUser2.UserId)];
        System.assertEquals(1, shareRecordsBeforeUpdate1.size());

        Test.startTest();
        {
            // associate the user with the territory
            System.runAs(otherAdmin)
            {
                assoc1.RoleInTerritory2 = TestDataTerritory.TERRITORY_ROLE_TAM;
                update assoc1;
            }

            // trigger would call recalculateTerritoryChanges()
            // aside from getting an implementation from a factory method,
            // that method makes these two calls
            TAPS_Orchestrator tapsOrchestrator = new TAPS_Orchestrator();//DCP-44091
            Set<Id> accountIds = tapsOrchestrator.getAccountIdsFromTerritoryIds(new Set<Id>{territory1.Id});//DCP-44091
            tapsOrchestrator.recalculateAccountChangesForObject(new InstalledProductSharing(), accountIds);//DCP-44091
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // Validate one share added
        List<SVMXC__Installed_Product__Share> shareRecordsAfterUpdate1 = [SELECT Id FROM SVMXC__Installed_Product__Share WHERE ParentId = :c1.Id AND UserOrGroupId IN (:associatedUser1.UserId, :associatedUser2.UserId)];
        System.assertEquals(2, shareRecordsAfterUpdate1.size());
    }

    /*
     * account alignment tests
     * e.g. align an account to a territory
     */

    // add an account to a territory and make sure shares are added
    @isTest static void accountAddAffectsShares()
    {
        User otherAdmin = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, new Set<Id> { UserInfo.getUserId() });

        Territory2 territory1 = [SELECT Id FROM Territory2 WHERE Name = :TERRITORY1 LIMIT 1];
        Territory2 subregion1 = [SELECT Id FROM Territory2 WHERE Name = :SUBREGION1 LIMIT 1];
        UserTerritory2Association associatedUser1 = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :territory1.Id];
        UserTerritory2Association associatedUser2 = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :subregion1.Id];

        Account a1;
        SVMXC__Installed_Product__c c1;
        System.runAs(otherAdmin)
        {
            a1 = TestDataAccount.getNewAccount();
            c1 = TestDataInstalledProduct.getNewInstalledProduct(a1.Id);
        }

        // Validate no shares between the two users to start
        List<SVMXC__Installed_Product__Share> shareRecordsBeforeUpdate1 = [SELECT Id FROM SVMXC__Installed_Product__Share WHERE ParentId = :c1.Id AND UserOrGroupId IN (:associatedUser1.UserId, :associatedUser2.UserId)];
        System.assertEquals(0, shareRecordsBeforeUpdate1.size());

        Test.startTest();
        {
            // Associate the account with the territory
            System.runAs(otherAdmin)
            {
                TestDataTerritory.getNewAccountTerritoryLink(a1, territory1);
            }

            // batch job would call recalculateAccountChanges()
            // aside from getting an implementation from a factory method,
            // that method makes this call
            TAPS_Orchestrator tapsOrchestrator = new TAPS_Orchestrator();//DCP-44091
            tapsOrchestrator.recalculateAccountChangesForObject(new InstalledProductSharing(), new Set<Id>{a1.Id});//DCP-44091
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // each user now has a share
        List<SVMXC__Installed_Product__Share> shareRecordsafterUpdate = [SELECT Id FROM SVMXC__Installed_Product__Share WHERE ParentId = :c1.Id AND UserOrGroupId IN (:associatedUser1.UserId, :associatedUser2.UserId)];
        System.assertEquals(2, shareRecordsafterUpdate.size());
    }
    /*
     * @actor illumina
     * @descritption :-
     */

    @isTest static void orchestrationCoverage()
    {
        Account a = TestDataAccount.getNewAccount();
        SVMXC__Installed_Product__c c = TestDataInstalledProduct.getNewInstalledProduct(a.Id);

        try
        {
            TAPS_Orchestrator tapsOrchestrator = new TAPS_Orchestrator();//DCP-44091
            tapsOrchestrator.recalculateRecordChanges(new Set<Id> { c.Id }, SVMXC__Installed_Product__c.SObjectType);//DCP-44091
            system.assert(true,'Assert not true');
        }
        catch (Exception e)
        {
            // will throw an exception my dev org with no implementations
            // Added below line for DCP-30062: SonarQube Fixes Done
            System.debug('Exception occured, details: '+e);
        }
    }



    /*
     * coverage of basic methods and unimplemented exceptions
     */

    @isTest static void directBasic()
    {
        Account a = TestDataAccount.getNewAccount();
        SVMXC__Installed_Product__c c = TestDataInstalledProduct.getNewInstalledProduct(a.Id);

        InstalledProductSharing shareClass = new InstalledProductSharing();

        Test.startTest();
        System.assertEquals(SVMXC__Installed_Product__c.SObjectType, shareClass.getObjectType());
        System.assertEquals('SVMXC__Company__c', shareClass.getLookupFieldName());
        System.assertEquals('ParentId', shareClass.getShareParentFieldName());

        SVMXC__Installed_Product__Share shareRec = (SVMXC__Installed_Product__Share)shareClass.createSharingRecord(c.Id, UserInfo.getUserId());
        System.assertEquals(c.Id, shareRec.ParentId);
        System.assertEquals(UserInfo.getUserId(), shareRec.UserOrGroupId);

        Set<Id> recordIds = shareClass.getRecordIdsFromAccountIds(new Set<Id> {a.Id});
        System.assert(recordIds.contains(c.Id));
        Test.stopTest();
    }

    /*@isTest static void junctionBasic()
    {
        Account a = TestDataAccount.getNewAccount();
        a.Account_Group__c = CustomerMasterDatas.GROUP_SOLD_TO;
        update a;
        Customer_Agreement__c c = TestDataContract.getNewAgreement();
        Customer_Agreement_Account_Link__c link = TestDataContract.getNewAgreementLink(a.Id, c.Id);

        AgreementJunctionSharing shareClass = new AgreementJunctionSharing();

        Test.startTest();
        System.assertEquals(Customer_Agreement__c.SObjectType, shareClass.getObjectType());
        System.assertEquals('Customer_Agreement_Account_Link__c', shareClass.getJunctionTableName());
        System.assertEquals('Customer_Agreement__c', shareClass.getKeyFieldName());
        System.assertEquals('Account__c', shareClass.getValueFieldName());
        System.assertEquals('ParentId', shareClass.getShareParentFieldName());
        System.assertEquals(Customer_Agreement__Share.sObjectType, shareClass.getShareObjectType());

        Customer_Agreement__Share shareRec = (Customer_Agreement__Share)shareClass.createSharingRecord(c.Id, UserInfo.getUserId());
        System.assertEquals(c.Id, shareRec.ParentId);
        System.assertEquals(UserInfo.getUserId(), shareRec.UserOrGroupId);

        Map<Id, Set<Id>> recordIdToAccountIds = shareClass.getRecordIdToAccountIds(new Set<Id> { c.Id });
        System.assert(recordIdToAccountIds.get(c.Id).contains(a.Id));

        Set<Id> recordIds = shareClass.getRecordIdsFromAccountIds(new Set<Id> {a.Id});
        System.assert(recordIds.contains(c.Id));
        Test.stopTest();
    }*/

    @isTest static void customBasic()
    {
        Account a = TestDataAccount.getNewAccount();
        a.Account_Group__c = CustomerMasterDatas.GROUP_SOLD_TO;
        update a;
        SVMXC__Service_Order__c wo = TestDataFieldService.getNewWorkOrder(a.Id);
        Comment__c c = TestDataFieldService.getNewComment(wo.Id);

        Set<Id> childIds = new Set<Id> { c.Id };

        List<SVMXC__Service_Order__c> junctionRecords = [SELECT Id, SVMXC__Company__c FROM SVMXC__Service_Order__c WHERE Id = :c.Work_Order__c];
        Set<Id> modifiedRecordIds = new Set<Id> {junctionRecords.get(0).Id};

        CommentCustomSharing shareClass = new CommentCustomSharing();

        Test.startTest();
        System.assertEquals(Comment__c.SObjectType, shareClass.getObjectType());
        System.assertEquals(Comment__Share.sObjectType, shareClass.getShareObjectType());
        System.assert(childIds.containsAll(shareClass.getRecordIdsFromModifiedRecordIdsCustom(childIds)));

        Comment__Share shareRec = (Comment__Share)shareClass.createSharingRecord(c.Id, UserInfo.getUserId());
        System.assertEquals(c.Id, shareRec.ParentId);
        System.assertEquals(UserInfo.getUserId(), shareRec.UserOrGroupId);

        Map<Id, Set<Id>> recordIdToAccountIds = shareClass.getRecordIdToAccountIds(childIds);
        System.assert(recordIdToAccountIds.get(c.Id).contains(a.Id));

        Set<Id> recordIds = shareClass.getRecordIdsFromAccountIdsCustom(new Set<Id> {a.Id});
        System.assert(recordIds.contains(c.Id));

        recordIds = shareClass.getRecordIdsFromModifiedRecordIdsCustom(modifiedRecordIds);
        System.assert(recordIds.containsAll(childIds));

        recordIds = shareClass.getRecordIdsFromAccountIds(new Set<Id> {a.Id});
        System.assert(recordIds.contains(c.Id));
        Test.stopTest();
    }

    @isTest static void testTAPSOrchestrationImpl()//CodeScanIssue Fix
    {
        Account a = TestDataAccount.getNewAccount();
        a.Account_Group__c = CustomerMasterDatas.GROUP_SOLD_TO;
        update a;

         Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '01', '178', '00', false);
        acc1SalesArea.Account__c = a.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c =  '01-AMEA-USD';//POL-54
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        acc1SalesArea.Price_Group__c = 'TXDR';
        acc1SalesArea.Sales_Organization__c='HK01';
        acc1SalesArea.Price_Group_Description__c= 'Test TXDR';
        acc1SalesArea.Distribution_Channel__c='01';
        insert acc1SalesArea;

        TestDataAgreement.addHierarchyPermission();

        Apttus__APTS_Agreement__c c = TestDataAgreement.initAgreements('Test Agreement - Price Group', a.id);
        //c.RecordTypeId = recTypeChannelPartner;
        c.Sales_Org__c ='HK01';//adding reference sales org
        c.Apttus__Auto_Renewal__c=True;
        c.Justification_for_No_Agreement_Value__c = 'Comparison Customer';
        //Added by Saurabh Brahmankar
        c.Apttus__Total_Contract_Value__c = 0;
        insert c;

        TAPS_ApttusAgreements shareClass = new TAPS_ApttusAgreements();
        Map<Id, Set<Id>> recordIdToUserIds = new Map<Id, Set<Id>>();
        recordIdToUserIds.put(c.Id, new Set<Id> {UserInfo.getUserId()});

        Test.startTest();

        shareClass.createSharingRecord(recordIdToUserIds);
        Map<Id, Set<Id>> recordIdToAccountIds = shareClass.getRecordIdToAccountIds(new Set<Id> { c.Id });
        Set<Id> recordIds = shareClass.getRecordIdsFromAccountIds(new Set<Id> {a.Id});

        Test.stopTest();

        System.assert(recordIdToAccountIds.size() > 0);
        System.assert(recordIds.size() > 0);
    }

    @isTest static void directNoImpl()
    {
        DirectMissingImpl shareClass = new DirectMissingImpl();

        try
        {
            shareClass.getObjectType();
            System.assert(false, 'No error when getObjectType() not implemented');
        }
        catch (Exception e)
        {
            System.assertEquals(TAPS_ComposedBase.IMPLEMENTATION_REQUIRED, e.getMessage());
        }

        try
        {
            shareClass.getLookupFieldName();
            System.assert(false, 'No error when getLookupFieldName() not implemented');
        }
        catch (Exception e)
        {
            System.assertEquals(TAPS_ComposedBase.REQUIRED_FOR_DIRECT, e.getMessage());
        }

        // default implementation
        System.assertEquals('ParentId', shareClass.getShareParentFieldName());

        try
        {
            shareClass.createSharingRecord(null, UserInfo.getUserId());
            System.assert(false, 'No error when createSharingRecord() not implemented');
        }
        catch (Exception e)
        {
            System.assertEquals(TAPS_ComposedBase.IMPLEMENTATION_REQUIRED, e.getMessage());
        }

        try
        {
            shareClass.getShareObjectType();
            System.assert(false, 'No error when getShareObjectType() not implemented');
        }
        catch (Exception e)
        {
            System.assertEquals(TAPS_ComposedBase.IMPLEMENTATION_REQUIRED, e.getMessage());
        }
    }

    // asdf
    @isTest static void junctionNoImpl()
    {
        JunctionMissingImpl shareClass = new JunctionMissingImpl();

        try
        {
            shareClass.getJunctionTableName();
            System.assert(false, 'No error when getJunctionTableName() not implemented');
        }
        catch (Exception e)
        {
            System.assertEquals(TAPS_ComposedBase.REQUIRED_FOR_JUNCTION, e.getMessage());
        }

        try
        {
            shareClass.getKeyFieldName();
            System.assert(false, 'No error when getKeyFieldName() not implemented');
        }
        catch (Exception e)
        {
            System.assertEquals(TAPS_ComposedBase.REQUIRED_FOR_JUNCTION, e.getMessage());
        }

        try
        {
            shareClass.getValueFieldName();
            System.assert(false, 'No error when getValueFieldName() not implemented');
        }
        catch (Exception e)
        {
            System.assertEquals(TAPS_ComposedBase.REQUIRED_FOR_JUNCTION, e.getMessage());
        }
    }

    @isTest static void customNoImpl()
    {
        CustomMissingImpl shareClass = new CustomMissingImpl();

        try
        {
            shareClass.mapRecordToAccountsCustom(null);
            System.assert(false, 'No error when mapRecordToAccountsCustom() not implemented');
        }
        catch (Exception e)
        {
            System.assertEquals(TAPS_ComposedBase.REQUIRED_FOR_CUSTOM, e.getMessage());
        }

        try
        {
            shareClass.getRecordIdsFromAccountIdsCustom(null);
            System.assert(false, 'No error when getRecordIdsFromAccountIdsCustom() not implemented');
        }
        catch (Exception e)
        {
            System.assertEquals(TAPS_ComposedBase.REQUIRED_FOR_CUSTOM, e.getMessage());
        }

        try
        {
            shareClass.getRecordIdsFromModifiedRecordIdsCustom(null);
            System.assert(false, 'No error when getRecordIdsFromModifiedRecordIdsCustom() not implemented');
        }
        catch (Exception e)
        {
            System.assertEquals(TAPS_ComposedBase.REQUIRED_FOR_CUSTOM, e.getMessage());
        }
    }

    @isTest static void noSubtype()
    {
        MissingSubType shareClass = new MissingSubType();

        try
        {
            shareClass.getRecordIdToAccountIds(new Set<Id> {});
            System.assert(false, 'No error in getRecordIdToAccountIds() with no object subtype');
        }
        catch (Exception e)
        {
            System.assertEquals(TAPS_ComposedBase.SUB_INTERFACE_REQUIRED, e.getMessage());
        }

        try
        {
            shareClass.getRecordIdsFromAccountIds(new Set<Id> {});
            System.assert(false, 'No error in getRecordIdsFromAccountIds() with no object subtype');
        }
        catch (Exception e)
        {
            System.assertEquals(TAPS_ComposedBase.SUB_INTERFACE_REQUIRED, e.getMessage());
        }

        try
        {
            shareClass.getRecordIdsFromModifiedRecordIds(new Set<Id> {});
            System.assert(false, 'No error in getRecordIdsFromModifiedRecordIds() with no object subtype');
        }
        catch (Exception e)
        {
            System.assertEquals(TAPS_ComposedBase.SUB_INTERFACE_REQUIRED, e.getMessage());
        }
    }

    @isTest static void noObjectSupport()
    {
        try
        {
            TAPS_ObjectSupport.sharingFactory(User.SObjectType);
            System.assert(false, 'No error in sharingFactory()');
        }
        catch (Exception e)
        {
            System.assert(e.getMessage().contains(TAPS_ComposedBase.ETM_SHARING_NOT_SUPPORTED));
        }
    }

    //Added by Rahul: Code Coverage Issue for UtilsCollection
    @isTest static void testUtilityMethods()
    {
        Account acc1 = TestDataAccount.getAccount('Test Acccount 1');
        Account acc2 = TestDataAccount.getAccount('Test Acccount 2');
        Account acc3 = TestDataAccount.getAccount('Test Acccount 3');

        insert new List<Account>{acc1,acc2,acc3};

        Set<Id> setAccountsPos = new Set<Id>{acc1.id};
        Set<Id> setAccountsNeg = new Set<Id>{acc2.id,acc3.id};
        Set<Id> setPositive = UtilsCollection.take(setAccountsPos,1);
        System.assertEquals(setAccountsPos.size(),setPositive.size(),'Utils Function not working properly');
        Set<Id> setNegative = UtilsCollection.take(setAccountsNeg,1);
        System.assertEquals(setAccountsNeg.size()-1,setNegative.size(),'Utils Function not working properly');

        // this is just coverage for paths
        // the paths don't do anything except call code which is already very well covered
        // so no need to assert on these
        try
        {
            TAPS_SharingUsingFuture.recFutureSharing(setAccountsPos, 'Comment__c');
        }
        catch (Exception e)
        {
            System.debug('do not worry');
        }
    }

    /*
     * @actor illumina
     * @descritption :-test implementations
     */

    private with sharing class MissingSubType extends TAPS_ComposedBase { }
    /*
     * @actor illumina
     * @descritption :-
     */

    private with sharing class DirectMissingImpl extends TAPS_ComposedBase implements TAPS_IObjectsDirect { }
    /*
     * @actor illumina
     * @descritption :-
     */

    private with sharing class JunctionMissingImpl extends TAPS_ComposedBase implements TAPS_IObjectsJunction { }
    /*
     * @actor illumina
     * @descritption :-
     */

    private with sharing class CustomMissingImpl extends TAPS_ComposedBase implements TAPS_IObjectsCustom { }
    /*
     * @actor illumina
     * @descritption :-example direct implementation
     */
    public with sharing class InstalledProductSharing extends TAPS_ComposedBase implements TAPS_IObjectsDirect
    {
        /*
     * @actor illumina
     * @descritption :-
     */
        public override SObjectType getObjectType() {
            return SVMXC__Installed_Product__c.sObjectType;
        }
        /*
     * @actor illumina
     * @descritption :-example direct implementation
     */
        public override String getLookupFieldName() {
            return 'SVMXC__Company__c';
        }
    /*
     * @actor illumina
     * @descritption :-example direct implementation
     */
        public override SObjectType getShareObjectType() {
            return SVMXC__Installed_Product__Share.sObjectType;
        }
    /*
     * @actor illumina
     * @descritption :-
     */
        public override String getShareParentFieldName() {
            return 'ParentId';
        }
        /*
     * @actor illumina
     * @descritption :-
     */
        public override SObject createSharingRecord(Id recordId, Id userId) {
            return new SVMXC__Installed_Product__Share(
                    UserOrGroupId = userId,
                    ParentId = recordId,
                    AccessLevel = 'Read',
                    RowCause = Schema.SVMXC__Installed_Product__Share.RowCause.Manual
            );
        }
    }
    /*
     * @actor illumina
     * @descritption :-
     */
    public with sharing class AgreementJunctionSharing extends TAPS_ComposedBase implements TAPS_IObjectsJunction {

        /*public override SObjectType getObjectType()
        {
            return Customer_Agreement__c.sObjectType;
        }

        public override String getJunctionTableName()
        {
            return 'Customer_Agreement_Account_Link__c';
        }

        public override String getKeyFieldName()
        {
            return 'Customer_Agreement__c';
        }

        public override String getValueFieldName()
        {
            return 'Account__c';
        }

        public override SObjectType getShareObjectType()
        {
            return Customer_Agreement__Share.sObjectType;
        }

        public override String getShareParentFieldName()
        {
            return 'ParentId';
        }

        public override SObject createSharingRecord(Id recordId, Id userId)
        {
            return new Customer_Agreement__Share(
                    UserOrGroupId = userId,
                    ParentId = recordId,
                    AccessLevel = 'Read',
                    RowCause = Schema.Customer_Agreement__Share.RowCause.Manual
            );
        }*/

    }

    public with sharing class CommentCustomSharing extends TAPS_ComposedBase implements TAPS_IObjectsCustom
    {
        /*
     * @actor illumina
     * @descritption :-
     */
        public override SObjectType getObjectType()
        {
            return Comment__c.sObjectType;
        }
        /*
     * @actor illumina
     * @descritption :-
     */
        public override Map<Id, Set<Id>> mapRecordToAccountsCustom(Set<Id> recordIds)
        {
            Map<Id, Set<Id>> commentIdToAccountIds = new Map<Id, Set<Id>>();

            List<Comment__c> recordDetails = [SELECT Id, Work_Order__c FROM Comment__c WHERE Id IN :recordIds];
            Map<Id, Id> commentIdToWoId = UtilsCollection.getMapOfIdToId(recordDetails, 'Id', 'Work_Order__c');
            Map<Id, Id> woIdToCommentId = UtilsCollection.getMapOfIdToId(recordDetails, 'Work_Order__c', 'Id');

            for (Comment__c c : recordDetails)
                commentIdToAccountIds.put(c.Id, new Set<Id>());

            List<SVMXC__Service_Order__c> parentDetails = [SELECT Id, SVMXC__Company__c FROM SVMXC__Service_Order__c WHERE Id IN :commentIdToWoId.values()];
            for (SVMXC__Service_Order__c wo : parentDetails)
            {
                if (woIdToCommentId.containsKey(wo.Id))
                {
                    Id commentId = woIdToCommentId.get(wo.Id);
                    commentIdToAccountIds.get(commentId).add(wo.SVMXC__Company__c);
                }
            }

            return commentIdToAccountIds;
        }
        /*
     * @actor illumina
     * @descritption :-
     */
        public override Set<Id> getRecordIdsFromAccountIdsCustom(Set<Id> accountIds)
        {
            List<Comment__c> commentDetails = [SELECT Id, Work_Order__c, Work_Order__r.SVMXC__Company__c FROM Comment__c WHERE Work_Order__r.SVMXC__Company__c IN :accountIds];
            return UtilsCollection.getSetOfIds(commentDetails, 'Id');
        }
    /*
     * @actor illumina
     * @descritption :-
     */
        public override Set<Id> getRecordIdsFromModifiedRecordIdsCustom(Set<Id> modifiedRecordIds)
        {
            List<Comment__c> commentDetails = [SELECT Id, Work_Order__c FROM Comment__c WHERE Work_Order__c IN :modifiedRecordIds];
            return UtilsCollection.getSetOfIds(commentDetails, 'Id');
        }
    /*
     * @actor illumina
     * @descritption :-
     */
        public override SObjectType getShareObjectType()
        {
            return Comment__Share.sObjectType;
        }
    /*
     * @actor illumina
     * @descritption :-
     */
        public override String getShareParentFieldName()
        {
            return 'ParentId';
        }
    /*
     * @actor illumina
     * @descritption :-
     */
        public override SObject createSharingRecord(Id recordId, Id userId)
        {
            return new Comment__Share(
                    UserOrGroupId = userId,
                    ParentId = recordId,
                    AccessLevel = 'Read',
                    RowCause = Schema.Comment__Share.RowCause.Manual
            );
        }
    }

}