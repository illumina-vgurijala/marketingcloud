/**
*    @author Rishi Sharma
*    @date   3 June 2021
*    @description  DCP-46376: TAM Deadline Notifications
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*       Developer            Date            Description
*    -----------------------------------------------------------------------------------------------------------------------------------
*       Arif,Dalali           28-Nov-2022             POL-57: Update APJ and EMEA References to AMEA and Europe respectively
*/
@isTest
public with sharing class TestBatchTamDeadlineNotification {

    public static FINAL string AMEA_USD_01 = '01-AMEA-USD'; //POL-57
    public static FINAL string TEST_TXDR = 'Test TXDR';
    public static FINAL string VC0013519_OPA = 'VC0013519-OPA';
    public static FINAL string STRHK01 = 'HK01';
    public static FINAL string STRHK = 'HK';

    /**
     *  @author Saswati Prusty
     *  @description Test Data Setup
     **/
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
        acc1SalesArea.Price_List__c = AMEA_USD_01; //POL-57
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        acc1SalesArea.Price_Group__c = 'TXDR';
        acc1SalesArea.Sales_Organization__c=STRHK01;
        acc1SalesArea.Price_Group_Description__c=TEST_TXDR;
        acc1SalesArea.Distribution_Channel__c='01';

        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea(STRHK01, '02', '179', '00', false);
        acc2SalesArea.Account__c = acc2.Id;
        acc2SalesArea.Price_List_Type__c = '06';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = AMEA_USD_01; //POL-57
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        acc2SalesArea.Price_Group__c = 'TXDR';
        acc2SalesArea.Sales_Organization__c='AU01';
        acc2SalesArea.Price_Group_Description__c=TEST_TXDR;
        acc2SalesArea.Distribution_Channel__c='01';

        Account_Sales_Area__c acc3SalesArea = TestDataAccountSalesArea.getAccountSalesArea(STRHK01, '02', '179', '00', false);
        acc3SalesArea.Account__c = acc2.Id;
        acc3SalesArea.Price_List_Type__c = '06';
        acc3SalesArea.CurrencyIsoCode = 'USD';
        acc3SalesArea.Price_List__c = AMEA_USD_01; //POL-57
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
    static void testBatchTamDeadlineNotifications()
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
        oAgreement.Tenders_Status__c = 'Pending TAM decision';
        oAgreement.TAMs_Deadline_to_Respond__c = system.today()-10;
        oAgreement.RecordTypeId = recTypeTender;
        update oAgreement;

        Test.startTest();
        BatchTamDeadlineNotification tamDeadline = new BatchTamDeadlineNotification();
        Database.executeBatch(tamDeadline);

        String schdule = '0 0 23 * * ?';
        system.schedule('TestSchedule'+system.now(),schdule,tamDeadline);

        Apttus__APTS_Agreement__c objAggUpdated = [SELECT Id,Apttus__Termination_Date__c, TAMs_Deadline_to_Respond__c From Apttus__APTS_Agreement__c WHERE Id =: oAgreement.Id];

        System.assert(true,objAggUpdated.TAMs_Deadline_to_Respond__c<system.today());
        Test.stopTest();
    }

}
