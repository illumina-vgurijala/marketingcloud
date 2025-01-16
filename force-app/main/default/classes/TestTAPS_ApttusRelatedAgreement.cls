/**
 *    @author Bharath Varma
 *    @date   25-March-2022
 *    @description : TASK0718153 : Test class for TAPS_ApttusRelatedAgreement
 *    Modification Log:
 *    ----------------------------------------------------------------------------------------------- 
 *    Developer                    Date                      Description
 *    Bharath Varma             25-Mar-2022                Initial Version
 *    Ashwin Kumar              31-Mar-2021                DCP-52339 Remove TestTAPS.setupDeferredObjectData
 *    Arif,Dalali               28-Nov-2022                POL-57: Update APJ and EMEA References to AMEA and Europe respectively
 *    Adyasha Satapathy         11-Jan-2023                Codescan Fix for Removing Unused Methods
 *    Sushil Bolwar             2024-June-5                DGP-108
 *   -----------------------------------------------------------------------------------------------        
 */
@isTest
private class TestTAPS_ApttusRelatedAgreement {

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
        if (mshareClass == null) mshareClass = new TAPS_ApttusRelatedAgreement();
        return mshareClass;
    }

    private static List<Apttus__APTS_Agreement__c> getAgreements(Id accountId1)
    {
        Customer_Master_Data__c objCMD1 = TestDataAccount.initCustomerMasterData('123456', 'Hong Kong', 'HK');
        insert new List<Customer_Master_Data__c> { objCMD1 };

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.initAccountSalesArea(accountId1, '123456', 'HK01', '01', '00', '01-AMEA-USD', '06'); //POL-57
        insert new List<Account_Sales_Area__c> { acc1SalesArea };

        // this is needed because the user running the tests might not have permission to insert agreements
        cs_Apex_Settings__c cs = cs_Apex_Settings__c.getInstance(UserInfo.getProfileId());
        cs.Bypass_All_Validations__c = true;
        upsert cs cs_Apex_Settings__c.Id;

        // Inserting two agreements - one parent agreement and one amended agreement
        Apttus__APTS_Agreement__c parentAgreement = TestDataAgreement.initAgreements('Test Agreement - Price Group', accountId1);
        parentAgreement.Sales_Org__c = 'HK01';//adding reference sales org
		parentAgreement.Freight_Charge__c = 'Standard';
        
        Apttus__APTS_Agreement__c amendedAgreement = TestDataAgreement.initAgreements('Test Agreement - Price Group Amended', accountId1);
        amendedAgreement.Sales_Org__c = 'HK01';
		amendedAgreement.Freight_Charge__c = 'Standard';
        
        List<Apttus__APTS_Agreement__c> lstAgreements = new List<Apttus__APTS_Agreement__c> {parentAgreement, amendedAgreement};

        insert lstAgreements;
        return lstAgreements;
    }

    // these methods are the tests, only the object creation need to be altered by class

    // inserting a record on an account associated to TERRITORY1
    // should add shares to the associated users
    @isTest static void createRecord()
    {
        // parent records   
        List<Id> accountIds = TestTAPS.createParentAccounts();
        List<Apttus__APTS_Agreement__c> lstAgreements = getAgreements(accountIds.get(0));
        Apttus__APTS_Agreement__c parentAgreement = lstAgreements.get(0);
        Apttus__APTS_Agreement__c amendedAgreement = lstAgreements.get(1);

        Set<Id> setAccountIds = new Set<Id>();
        for(Id i:accountIds){
            if(i!=null)
                setAccountIds.add(i);
        }

        // add record
        Apttus__APTS_Related_Agreement__c rec1;

        Test.startTest();
        {
            rec1 = new Apttus__APTS_Related_Agreement__c(
                Apttus__APTS_Contract_From__c = parentAgreement.Id,
                Apttus__APTS_Contract_To__c = amendedAgreement.Id,
                Apttus__Relationship_From_Type__c = 'Is Amended By',
                Apttus__Relationship_To_Type__c = 'Is Amendment For'
            );
            insert rec1;
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        TAPS_ApttusRelatedAgreement objTaps = new TAPS_ApttusRelatedAgreement();
        objTaps.getRecordIdsFromAccountIdsCustom(setAccountIds);
        Test.stopTest();

        // validate shares were added by batch
        System.assertEquals(2, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id), 'Shares are not created as expected');
    }

    // inserting a record on an account associated to TERRITORY2
    // should add shares to the associated users
    @isTest static void addToSecondAccount()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();
        List<Apttus__APTS_Agreement__c> lstAgreements = getAgreements(accountIds.get(0));
        Apttus__APTS_Agreement__c parentAgreement = lstAgreements.get(0);
        Apttus__APTS_Agreement__c amendedAgreement = lstAgreements.get(1);

        // add record
        Apttus__APTS_Related_Agreement__c rec1 = new Apttus__APTS_Related_Agreement__c(
            Apttus__APTS_Contract_From__c = parentAgreement.Id,
            Apttus__APTS_Contract_To__c = amendedAgreement.Id,
            Apttus__Relationship_From_Type__c = 'Is Amended By',
            Apttus__Relationship_To_Type__c = 'Is Amendment For'
        );
        insert rec1;

        Test.startTest();
        {
            TestTAPS.objectBeingTested = getShareClass().getObjectType();

            Agreement_Account_Relationship__c rel2 = new Agreement_Account_Relationship__c(
                Agreement__c = amendedAgreement.Id,
                Account__c = accountIds.get(1)
            );
            insert rel2;

            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares were added by batch
        System.assertEquals(3, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id), 'Shares are not created as expected');
    }

   //Test DG fields being copied to child agreement line items
    @isTest static void amendDGfields()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();
        Account acc = [Select Id, Account_Group__c from Account where id =: accountIds.get(0)];
        acc.Account_Group__c ='Distributor';
        update acc;
        List<Apttus__APTS_Agreement__c> lstAgreements = getAgreements(accountIds.get(0));
        Apttus__APTS_Agreement__c parentAgreement = lstAgreements.get(0);       
        Apttus__APTS_Agreement__c amendedAgreement = lstAgreements.get(1);
        
        //Agreement line item for parentAgreement
        Apttus__AgreementLineItem__c oAgreementLI1 = TestDataAgreement.initAgreementsLineItem(parentAgreement.id);
        oAgreementLI1.Material_Group_1__c = 'BGS';
        oAgreementLI1.Line_Type__c = 'Material Group 1';
        oAgreementLI1.Apttus_CMConfig__LineNumber__c = 4;
        oAgreementLI1.Apttus_CMConfig__ItemSequence__c = 4;
        oAgreementLI1.Discount_Type__c = '% Discount';
        oAgreementLI1.Discount__c = 15;
        oAgreementLI1.Customer_ERP_Number__c = '123456';
        oAgreementLI1.Sales_Org__c = 'HK01';
        oAgreementLI1.Distribution_Channel__c = '02';
        oAgreementLI1.CurrencyIsoCode= 'USD';
        oAgreementLI1.Apttus_CMConfig__StartDate__c = system.today()+5;
        oAgreementLI1.Apttus_CMConfig__EndDate__c = system.today()+28;
        oAgreementLI1.Median_Discount_Guidance__c	= 5;
        oAgreementLI1.Max_Discount_Guidance__c = 6;
        oAgreementLI1.Customer_Historical_Discount__c = 7;
        insert oAgreementLI1;
        
        // add record
        Apttus__APTS_Related_Agreement__c rec1 = new Apttus__APTS_Related_Agreement__c(
            Apttus__APTS_Contract_From__c = parentAgreement.Id,
            Apttus__APTS_Contract_To__c = amendedAgreement.Id,
            Apttus__Relationship_From_Type__c = 'Is Amended By',
            Apttus__Relationship_To_Type__c = 'Is Amendment For'
        );       
        
        Test.startTest();
         insert rec1;
        Test.stopTest();
        
        List<Apttus__AgreementLineItem__c> childAliList = new List<Apttus__AgreementLineItem__c>([Select Id, Median_Discount_Guidance__c, Max_Discount_Guidance__c, Customer_Historical_Discount__c from Apttus__AgreementLineItem__c where Apttus__AgreementId__c =: amendedAgreement.Id]);
        System.AssertNotEquals(0, childAliList.size());
        System.assertEquals(5, childAliList[0].Median_Discount_Guidance__c); 
        System.assertEquals(6, childAliList[0].Max_Discount_Guidance__c); 
        System.assertEquals(7, childAliList[0].Customer_Historical_Discount__c); 
       
    }   
}