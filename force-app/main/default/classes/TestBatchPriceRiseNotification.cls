/**
*    @author Rishi Sharma
*    @date   1 June 2021
*    @description  DCP-46194: Price Rise Notifications
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*       Developer            Date            Description
*       Adyasha Satapathy    28-Nov-2022     POL-54: Update region references to AMEA and EUR
*    -----------------------------------------------------------------------------------------------------------------------------------
*
*/
@isTest
public with sharing class TestBatchPriceRiseNotification {

    public static FINAL string AMEA_USD_01 = '01-AMEA-USD'; //POL-54
    public static FINAL string TEST_TXDR = 'Test TXDR';
    public static FINAL string VC0013519_OPA = 'VC0013519-OPA';
    public static FINAL string STRHK01 = 'HK01';
    public static FINAL string STRHK = 'HK';

    @testSetup
    static void setupData()
    {
        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = '123456';
        acc.Territory_Region__c = 'AMR';
        acc.Account_Group__c = 'Distributor';
        acc.Name = 'distributor Account';
        acc.BIllingCountryCode = STRHK;
        Account acc2 = TestDataAccount.initAccount();
        acc2.ERP_Customer_Id__c = '234567';
        acc2.BIllingCountryCode = STRHK ;
        insert new List<Account> { acc, acc2 };
        Contact con = TestDataPerson.initContact(acc.Id);
        Contact con2 = TestDataPerson.initContact(acc.Id);
        insert new List<Contact> { con, con2 };

        Customer_Master_Data__c objCMD1 = new Customer_Master_Data__c(Name='CMD1',Country__c='Hong Kong',Country_Code__c=STRHK),
                                objCMD2 = new Customer_Master_Data__c(Name='CMD2',Country__c='Hong Kong',Country_Code__c=STRHK);
        objCMD1.ERP_Customer_Id__c = '123456';
        objCMD2.ERP_Customer_Id__c = '234567';
        insert new List<Customer_Master_Data__c> {objCMD1, objCMD2};

        TestDataAgreement.addHierarchyPermission();

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea(STRHK01, '01', '178', '00', false);
        acc1SalesArea.Account__c = acc.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = AMEA_USD_01; //POL-54
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        acc1SalesArea.Price_Group__c = 'TXDR';
        acc1SalesArea.Sales_Organization__c=STRHK01;
        acc1SalesArea.Price_Group_Description__c=TEST_TXDR;
        acc1SalesArea.Distribution_Channel__c='01';

        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea(STRHK01, '02', '179', '00', false);
        acc2SalesArea.Account__c = acc2.Id;
        acc2SalesArea.Price_List_Type__c = '06';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = AMEA_USD_01; //POL-54
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        acc2SalesArea.Price_Group__c = 'TXDR';
        acc2SalesArea.Sales_Organization__c='AU01';
        acc2SalesArea.Price_Group_Description__c=TEST_TXDR;
        acc2SalesArea.Distribution_Channel__c='01';

        Account_Sales_Area__c acc3SalesArea = TestDataAccountSalesArea.getAccountSalesArea(STRHK01, '02', '179', '00', false);
        acc3SalesArea.Account__c = acc2.Id;
        acc3SalesArea.Price_List_Type__c = '06';
        acc3SalesArea.CurrencyIsoCode = 'USD';
        acc3SalesArea.Price_List__c = AMEA_USD_01;
        acc3SalesArea.Contract_Number__c ='67890_HK010100';
        acc3SalesArea.Price_Group__c = 'TXDR';
        acc3SalesArea.Sales_Organization__c=STRHK01;
        acc3SalesArea.Price_Group_Description__c=TEST_TXDR;
        acc3SalesArea.Distribution_Channel__c='01';
        acc3SalesArea.ERP_Account_Sales_Area_Id__c='67890_HK010100';

        insert new List<Account_Sales_Area__c>{ acc1SalesArea, acc2SalesArea,acc3SalesArea  };

        Product2 product = TestDataMaster.createProduct(false);
        product.Material_Number__c = VC0013519_OPA;
        Product2 productTwo = TestDataMaster.createProduct(false);
        productTwo.Material_Number__c = '11234187';
        Product2 productThree = TestDataMaster.createProduct(false);
        productThree.Material_Number__c = 'SV-111-1002';
        insert new List<Product2> { product, productTwo, productThree };

        Id recTypeChannelPartner = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Channel Partner Agreement').getRecordTypeId();

        Apttus__APTS_Agreement__c oAgreement1 = TestDataAgreement.initAgreements('Test Agreement - Price Group', acc.id);
        oAgreement1.Sales_Org__c =STRHK01;//adding reference sales org
        oAgreement1.RecordTypeId = recTypeChannelPartner;
        oAgreement1.Apttus__Auto_Renewal__c=True;

       insert new List<Apttus__APTS_Agreement__c> {oAgreement1};
    }

    @isTest
    static void testPriceRiseBatch()
    {
        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        Id recTypeTender = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Tender').getRecordTypeId();
        if (setting.Bypass_All_Triggers__c == false || setting.Bypass_All_Validations__c == false)
        {
            setting.Bypass_All_Triggers__c = true;
            setting.Bypass_All_Validations__c = true;
            upsert setting;
        }

        Apttus__APTS_Agreement__c oAgreement = [SELECT Id,Apttus__Status__c,Apttus_Approval__Approval_Status__c,Apttus__Termination_Date__c From Apttus__APTS_Agreement__c WHERE Name = 'Test Agreement - Price Group'];
        oAgreement.Apttus__Status_Category__c = 'In Effect';
        oAgreement.Notification_Period_for_Price_Changes__c = 0;
        oAgreement.Price_Rise_Date__c = system.today();
        oAgreement.RecordTypeId = recTypeTender;
        oAgreement.Freight_Charge__c = 'Standard';
        update oAgreement;

        Test.startTest();
        BatchPriceRiseNotification priceRiseBatch = new BatchPriceRiseNotification();
        Database.executeBatch(priceRiseBatch);

        String schdule = '0 0 23 * * ?';
        system.schedule('TestSchedule'+system.now(),schdule,priceRiseBatch);

        Apttus__APTS_Agreement__c objAggUpdated = [SELECT Id,Apttus__Termination_Date__c, Apttus__Status_Category__c, Price_Rise_Notification_Date__c From Apttus__APTS_Agreement__c WHERE Id =: oAgreement.Id];

        System.assertEquals(system.today(),objAggUpdated.Price_Rise_Notification_Date__c, 'Price Rise Notification Date is not today');
        Test.stopTest();
    }

}