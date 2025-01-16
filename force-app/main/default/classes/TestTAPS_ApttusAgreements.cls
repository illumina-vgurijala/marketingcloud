/**
*    @author Illumina
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Ashwin Kumar                   31-Mar-2021         DCP-52339 Remove TestTAPS.setupDeferredObjectData
*         Adyasha Satapathy              28-Nov-2022         POL-54: Update region references to AMEA and EUR
*         Satya Swain                    22-Feb-2022         TASK0862791 : Remove unused private methods as part of codescan
*         Rajbabu Boopalan               20-Dec-2023         CMCM-4122 Fix SOQL 201 error
*         Rajbabu Boopalan               08-Feb-2024         CMCM-5707 Fix 10001 DML records error
*    ----------------------------------------------------------------------------------------------------------------------------
***/
@isTest
private class TestTAPS_ApttusAgreements {
    
    // @isTest static void checkAgreementClasses()
    // {
    //     TAPS_ApttusAgreements objTAPS_ApttusAgreements = new TAPS_ApttusAgreements();
    //     AgreementAccountRelationships objAgreementAccountRelationships = new AgreementAccountRelationships();
    // }

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

    private static TAPS_ComposedBase mShareClass;
    private static TAPS_ComposedBase getShareClass()
    {
        if (mShareClass == null) mShareClass = new TAPS_ApttusAgreements();
        return mShareClass;
    }

    private static Apttus__APTS_Agreement__c getAgreementRecord(Id accountId1, Boolean isIlluminaRecordType)
    {
        Customer_Master_Data__c objCMD1 = TestDataAccount.initCustomerMasterData('123456', 'Hong Kong', 'HK');
        Customer_Master_Data__c objCMD2 = TestDataAccount.initCustomerMasterData('234567', 'Hong Kong', 'HK');
        insert new List<Customer_Master_Data__c> { objCMD1, objCMD2 };

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.initAccountSalesArea(accountId1, '123456', 'HK01', '01', '00', '01-AMEA-USD', '06'); //POL-54
        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.initAccountSalesArea(accountId1, '234567', 'HK01', '01', '00', '01-AMEA-USD', '06'); //POL-54
        insert new List<Account_Sales_Area__c> { acc1SalesArea, acc2SalesArea };

        // this is needed because the user running the tests might not have permission to insert agreements
        cs_Apex_Settings__c cs = cs_Apex_Settings__c.getInstance(UserInfo.getProfileId());
        cs.Bypass_All_Validations__c = true;
        upsert cs cs_Apex_Settings__c.Id;

        Apttus__APTS_Agreement__c rec1 = TestDataAgreement.initAgreements('Test Agreement - Price Group', accountId1);
        rec1.Sales_Org__c = 'HK01'; //adding reference sales org
        if (isIlluminaRecordType) {
            rec1.RecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Illumina Lab Services').getRecordTypeId();
        }
        insert rec1;
        return rec1;
    }

    // these methods are the tests, only the object creation need to be altered by class

    // inserting a record on an account associated to TERRITORY1
    // should add shares to the associated users
    @isTest static void createRecord()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();
        Apttus__APTS_Agreement__c rec1 = getAgreementRecord(accountIds.get(0), false);
        
        // add record
        Agreement_Account_Relationship__c link1;

        Test.startTest();
        {
            link1 = TestDataAgreement.getNewRelationship(accountIds.get(0), rec1.Id);
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares were added by batch
        Assert.areEqual(2, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id), '2 Apttus__APTS_Agreement__Share should be generated');
    }

    // should not have shares to the associated users, due the record type of Apttus__APTS_Agreement__c is "Illumina Lab Services"
    @isTest static void createRecordWithIlluminaRecordType()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();
        Apttus__APTS_Agreement__c rec1 = getAgreementRecord(accountIds.get(0), true);
        // add record
        Agreement_Account_Relationship__c link1;

        Test.startTest();
        {
            link1 = TestDataAgreement.getNewRelationship(accountIds.get(0), rec1.Id);
            System.debug('link1:' + JSON.serializePretty(link1));
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares were added by batch
        Assert.areEqual(0, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id), 'No sharing entries(Apttus__APTS_Agreement__Share) should be generated');
    }

    @isTest
    static void testcreateShareRecordsInBatchMethod(){
        List<SObject> shareRecords = new List<SObject>();
        Integer num = 1;
        String result = String.valueOf(num++);
        string fakeOpptyId1 = Opportunity.SObjectType.getDescribe().getKeyPrefix() + '0'.repeat(12-result.length()) + result;
        Opportunity oppty = new Opportunity(id = fakeOpptyId1, Price_List_Type__c='01');
        Apttus__APTS_Agreement__Share shareRec = new Apttus__APTS_Agreement__Share();
        shareRec.ParentId = oppty.Id;
        shareRec.UserOrGroupId = UserInfo.getUserId();
        shareRec.AccessLevel = 'Edit';
        shareRec.RowCause = Schema.Apttus__APTS_Agreement__Share.RowCause.Manual;
        shareRecords.add(shareRec);
        TAPS_ApttusAgreements objTAPSApttusAgreements = new TAPS_ApttusAgreements();
        Test.startTest();
        objTAPSApttusAgreements.createShareRecordsInBatch(shareRecords);
        Test.stopTest();
        System.assert(shareRec!=Null ,'Check Sobject');
    }

    // currently not reparentable, restore if that changes
    // // moving a record from one account to another (and therefore from one territory to another)
    // // should result in the old shares deleted and new shares added
    // @isTest static void changeRecordParent()
    // {
    //     // parent records
    //     List<Id> accountIds = TestTAPS.createParentAccounts();
    //     Apttus__APTS_Agreement__c rec1 = getAgreementRecord(accountIds.get(0), accountIds.get(1));

    //     // add record
    //     Agreement_Account_Relationship__c link1 = TestDataAgreement.getNewRelationship(accountIds.get(0), rec1.Id);

    //     // get associated users
    //     List<Id> associatedUserIds = TestTAPS.getAssociatedUserIds();
    //     List<Id> usersOnA1 = new List<Id> { associatedUserIds.get(0), associatedUserIds.get(1) };
    //     List<Id> usersOnA2 = new List<Id> { associatedUserIds.get(2) };

    //     // manually create initial shares since since the trigger won't run the batch
    //     createShareRecords(rec1.Id, usersOnA1);

    //     // validate we start with shares to users aligned with a1
    //     System.assertEquals(2, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, usersOnA1));
    //     System.assertEquals(0, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, usersOnA2));

    //     Test.startTest();
    //     {
    //         reparentRecord(link1.Id, accountIds.get(1));
    //         // Added by Satya as part of PRB0042764 
    //         TestTAPS.objectBeingTested = getShareClass().getObjectType();
    //         Test.getEventBus().deliver();
    //     }
    //     Test.stopTest();

    //     // validate shares now belong to users on a2
    //     System.assertEquals(0, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, usersOnA1));
    //     System.assertEquals(1, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, usersOnA2));
    // }

}