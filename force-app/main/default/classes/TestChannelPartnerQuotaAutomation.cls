/*
*    @author Nishan Shetty
*    @date   15 November 2021
*    @description  DCP-50448 Test Class for ChannelPartnerQuotaAutomation.
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*       Developer            Date            Description
*     Nishan Shetty       15-Nov-2021        Initial
*     Adyasha Satapathy   28-Nov-2022        POL-54: Update region references to AMEA and EUR
*    -----------------------------------------------------------------------------------------------------------------------------------
*
*/
@isTest(SeeAllData=false)
public with sharing class TestChannelPartnerQuotaAutomation {

    public static FINAL string ERP_123456 = '123456';
    public static FINAL string AMEA_USD_01 = '01-AMEA-USD'; //POL-54
    public static FINAL string USD = 'USD';
    public static FINAL string TXDR = 'TXDR';
    public static FINAL string TEST_TXDR = 'Test TXDR';
    public static FINAL string HK01 = 'HK01';
    public static FINAL string STANDARD = 'Standard';
    public static FINAL string DISTRIBUTOR='Distributor';
    public static FINAL string AU01 = 'AU01';
    public static FINAL string AMR = 'AMR';
    public static FINAL string APPROVED = 'Approved';
    public static FINAL string VALIDATE = 'Activate Completed';

    /**
     *  @author Nishan Shetty
     *  @description Test Data Setup
     **/
    @testSetup
    static void setupData() {

        //Creating Account
        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = ERP_123456;
        acc.Territory_Region__c = 'AMR';
        acc.Account_Group__c = DISTRIBUTOR;
        acc.Name = 'Distributor Account 1';
        acc.BIllingCountryCode='HK';

        Account acc2 = TestDataAccount.initAccount();
        acc2.ERP_Customer_Id__c = '234567';
        acc2.BIllingCountryCode='HK' ;
        acc2.Account_Group__c = DISTRIBUTOR;
        acc2.Territory_Region__c = 'AMR';
        acc2.Name = 'Distributor Account 2';
        insert new List<Account> { acc, acc2 };

        //Creating Contact
        Contact con = TestDataPerson.initContact(acc.Id);
        Contact con2 = TestDataPerson.initContact(acc2.Id);
        insert new List<Contact> { con, con2 };

        //Customer Master Data
        Customer_Master_Data__c objCMD1 = new Customer_Master_Data__c(Name='CMD1',Country__c='Hong Kong',Country_Code__c='HK'),
        objCMD2 = new Customer_Master_Data__c(Name='CMD2',Country__c='Hong Kong',Country_Code__c='HK');
        objCMD1.ERP_Customer_Id__c = ERP_123456;
        objCMD2.ERP_Customer_Id__c = '234567';
        insert new List<Customer_Master_Data__c> {objCMD1, objCMD2};

        TestDataAgreement.addHierarchyPermission();

        Id recTypeChannelPartner = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Channel Partner Agreement').getRecordTypeId();

        //Creating Account Sales Area
        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea(HK01, '01', '178', '00', false);
        acc1SalesArea.Account__c = acc.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = USD;
        acc1SalesArea.Price_List__c = AMEA_USD_01; //POL-54
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        acc1SalesArea.Price_Group__c = TXDR;
        acc1SalesArea.Sales_Organization__c=HK01;
        acc1SalesArea.Price_Group_Description__c=TEST_TXDR;
        acc1SalesArea.Distribution_Channel__c='01';
        

        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea(AU01, '02', '179', '00', false);
        acc2SalesArea.Account__c = acc2.Id;
        acc2SalesArea.Price_List_Type__c = '06';
        acc2SalesArea.CurrencyIsoCode = USD;
        acc2SalesArea.Price_List__c = AMEA_USD_01; //POL-54
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        acc2SalesArea.Price_Group__c = TXDR;
        acc2SalesArea.Sales_Organization__c=AU01;
        acc2SalesArea.Price_Group_Description__c=TEST_TXDR;
        acc2SalesArea.Distribution_Channel__c='01';

        insert new List<Account_Sales_Area__c>{ acc1SalesArea, acc2SalesArea};

        //Creating Agreement
        Apttus__APTS_Agreement__c oAgreement4 = TestDataAgreement.initAgreements('Test CP Agreement 1', acc.id);
        oAgreement4.Apttus__Contract_End_Date__c = system.today()+30;
        oAgreement4.Sales_Org__c = HK01;//adding reference sales org
        oAgreement4.RecordTypeId = recTypeChannelPartner;
		oAgreement4.Preferred_Language__c = 'English';
        oAgreement4.CurrencyIsoCode=USD;
        oAgreement4.Q1_Quota__c=1;
        oAgreement4.Q2_Quota__c=2;
        oAgreement4.Q3_Quota__c=3;
        oAgreement4.Q4_Quota__c=4;
        oAgreement4.Apttus_Approval__Approval_Status__c=APPROVED;
        oAgreement4.Apttus__Subtype__c=STANDARD;
        oAgreement4.Apttus__Primary_Contact__c=con.Id;
        oAgreement4.Territory__c=AMR;
        oAgreement4.Incoterm__c='CFR: Costs and freight';
        oAgreement4.Discount_Justification__c='Test 1';
        oAgreement4.Channel_Partner_Legal_Name__c='Test CP Agreement 1';

        //Creating Agreement
        Apttus__APTS_Agreement__c oAgreement5 = TestDataAgreement.initAgreements('Test CP Agreement 2', acc2.id);
        oAgreement5.Apttus__Contract_End_Date__c = system.today()+30;
        oAgreement5.Sales_Org__c = AU01;//adding reference sales org
        oAgreement5.RecordTypeId = recTypeChannelPartner;
		oAgreement5.Preferred_Language__c = 'English';
        oAgreement5.CurrencyIsoCode=USD;
        oAgreement5.Q1_Quota__c=10;
        oAgreement5.Q2_Quota__c=20;
        oAgreement5.Q3_Quota__c=30;
        oAgreement5.Q4_Quota__c=40;
        oAgreement5.Territory__c=AMR;
        oAgreement5.Apttus_Approval__Approval_Status__c=APPROVED;
        oAgreement5.Apttus__Subtype__c=STANDARD;
        oAgreement5.Apttus__Primary_Contact__c=con2.Id;
        oAgreement5.Incoterm__c='CFR: Costs and freight';
        oAgreement5.Discount_Justification__c='Test 2';
        oAgreement5.Channel_Partner_Legal_Name__c='Test CP Agreement 2';

        insert new List<Apttus__APTS_Agreement__c> {oAgreement4, oAgreement5};

        //Creating Channel Parter Quota Record
        Channel_Partner_Quota__c objChannelPartnerQuotaRec=new Channel_Partner_Quota__c();
        objChannelPartnerQuotaRec.CurrencyIsoCode=USD;
        objChannelPartnerQuotaRec.Account_Name__c=acc2.Id;
        objChannelPartnerQuotaRec.Name=String.valueOf(System.today().year());
        objChannelPartnerQuotaRec.Year__c=String.valueOf(System.today().year());
        objChannelPartnerQuotaRec.Quarter_1__c=0;
        objChannelPartnerQuotaRec.Quarter_2__c=0;
        objChannelPartnerQuotaRec.Quarter_3__c=0;
        objChannelPartnerQuotaRec.Quarter_4__c=0;
        insert objChannelPartnerQuotaRec;
    }

    @isTest
    static void testChannelPartnerQuotaCreate() {
        Apttus__APTS_Agreement__c oAgreement4=[SELECT Id, Apttus__Status__c,Apttus__Account__c From Apttus__APTS_Agreement__c WHERE Name = 'Test CP Agreement 1' Limit 1];
        test.startTest();
        oAgreement4.Apttus__Status__c='Activated';
        oAgreement4.Validation_Status__c=VALIDATE;
        update oAgreement4;
        test.stopTest();
        List<Channel_Partner_Quota__c> objChannelPartnerQuota=[Select Id,Account_Name__c,FY_Quota__c from Channel_Partner_Quota__c where Account_Name__c=:oAgreement4.Apttus__Account__c Limit 1];
        System.assertEquals(1,objChannelPartnerQuota.size(),'Quota Not Created');
    }


    @isTest
    static void testChannelPartnerQuotaUpdate() {
        Apttus__APTS_Agreement__c oAgreement5=[SELECT Id, Apttus__Status__c,Apttus__Account__c From Apttus__APTS_Agreement__c WHERE Name = 'Test CP Agreement 2' Limit 1];
        test.startTest();
        oAgreement5.Apttus__Status__c='Activated';
        oAgreement5.Validation_Status__c=VALIDATE;
        update oAgreement5;
        test.stopTest();
        Channel_Partner_Quota__c objChannelPartnerQuota=[Select Id,Account_Name__c,FY_Quota__c from Channel_Partner_Quota__c where Account_Name__c=:oAgreement5.Apttus__Account__c Limit 1];
        System.assertEquals(100,objChannelPartnerQuota.FY_Quota__c,'Quota Value Not Set');
    }
}
