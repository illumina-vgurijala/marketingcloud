/**
*    @author Illumina
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Ashwin Kumar                   31-Mar-2021         DCP-52339 Remove TestTAPS.setupDeferredObjectData
*         Arif,Dalali                    28-Nov-2022         POL-57: Update APJ and EMEA References to AMEA and Europe respectively
*         Adyasha Satapathy              11-Jan-2023         Codescan Fix for Removing Unused Methods
*         Satya Swain                    09 Dec 2022         Added Codescan fix for Variable Naming Convention
*    ----------------------------------------------------------------------------------------------------------------------------
***/
@isTest
private class TestTAPS_ApttusDocumentVersion {

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
        if (mShareClass == null) mShareClass = new TAPS_ApttusDocumentVersion();
        return mShareClass;
    }

    private static Apttus__APTS_Agreement__c getAgreement(Id accountId1, Boolean isIlluminaRecordType)
    {
        Customer_Master_Data__c objCMD1 = TestDataAccount.initCustomerMasterData('123456', 'Hong Kong', 'HK');
        insert new List<Customer_Master_Data__c> { objCMD1 };

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.initAccountSalesArea(accountId1, '123456', 'HK01', '01', '00', '01-AMEA-USD', '06'); //POL-57
        insert new List<Account_Sales_Area__c> { acc1SalesArea };

        // this is needed because the user running the tests might not have permission to insert agreements
        cs_Apex_Settings__c cs = cs_Apex_Settings__c.getInstance(UserInfo.getProfileId());
        cs.Bypass_All_Validations__c = true;
        upsert cs cs_Apex_Settings__c.Id;

        Apttus__APTS_Agreement__c agreement = TestDataAgreement.initAgreements('Test Agreement - Price Group', accountId1);
        agreement.Sales_Org__c = 'HK01';//adding reference sales org
        if (isIlluminaRecordType) {
            agreement.RecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Illumina Lab Services').getRecordTypeId();
        }
        insert agreement;
        return agreement;
    }

    // these methods are the tests, only the object creation need to be altered by class

    // inserting a record on an account associated to TERRITORY1
    // should add shares to the associated users
    @isTest static void createRecord()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();
        Apttus__APTS_Agreement__c agreement = getAgreement(accountIds.get(0), false);

        // add record
        Apttus__DocumentVersion__c rec1;

        Test.startTest();
        {
            rec1 = new Apttus__DocumentVersion__c(
                Apttus__AgreementId__c = agreement.Id,
                Apttus__LatestVersion__c = 'hi',
                Apttus__Title__c = 'hi'
            );
            insert rec1;
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares were added by batch
        Assert.areEqual(2, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id), '2 Apttus__DocumentVersion__Share should be generated');
    }

    @isTest static void createRecordWithIlluminaRecordType()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();
        Apttus__APTS_Agreement__c agreement = getAgreement(accountIds.get(0), true);

        // add record
        Apttus__DocumentVersion__c rec1;

        Test.startTest();
        {
            rec1 = new Apttus__DocumentVersion__c(
                Apttus__AgreementId__c = agreement.Id,
                Apttus__LatestVersion__c = 'hi',
                Apttus__Title__c = 'hi',
                Agreement_Record_Type__c = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Illumina Lab Services').getRecordTypeId()
            );
            insert rec1;
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares were added by batch
        Assert.areEqual(0, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id), 'No sharing entries(Apttus__DocumentVersion__Share) should be generated');
    }

    // inserting a record on an account associated to TERRITORY2
    // should add shares to the associated users
    @isTest static void addToSecondAccount()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();
        Apttus__APTS_Agreement__c agreement = getAgreement(accountIds.get(0), false);

        // add record
        Apttus__DocumentVersion__c rec1 = new Apttus__DocumentVersion__c(
            Apttus__AgreementId__c = agreement.Id,
            Apttus__LatestVersion__c = 'hi',
            Apttus__Title__c = 'hi'
        );
        insert rec1;

        Test.startTest();
        {
            TestTAPS.objectBeingTested = getShareClass().getObjectType();

            Agreement_Account_Relationship__c rel2 = new Agreement_Account_Relationship__c(
                Agreement__c = agreement.Id,
                Account__c = accountIds.get(1)
            );
            insert rel2;

            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares were added by batch
        Assert.areEqual(3, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id), '3 Apttus__DocumentVersion__Share should be generated');
    }

}