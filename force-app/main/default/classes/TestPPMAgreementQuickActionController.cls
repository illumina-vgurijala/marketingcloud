/**
*    @author Prem Ranjan
*    @date   16 Aug 2021
*    @description    Test Class for PPMAgreementQuickActionController
*    Modification Log:
*   ------------------------------------------------------------------------------------------------
*    Developer                      Date                		Description
*    Prem Ranjan                    16 Aug 2021               Initial Version
*    Pravallika, Gundreddy          28-nov-2022               POL-57: Update APJ and EMEA References to AMEA and Europe respectively
*    -----------------------------------------------------------------------------------------------
*/

@isTest(SeeAllData=false)
public with sharing class TestPPMAgreementQuickActionController {
    public static FINAL string HK01 = 'HK01';
    public static FINAL string ERP_123456 = '123456';
    public static FINAL string ERP_123455 = '123455';
    public static FINAL string TXDR = 'TXDR';
    public static FINAL string TEST_TXDR = 'Test TXDR';
    public static FINAL string AMEA_USD_01 = '01-AMEA-USD'; //POL-57
    public static FINAL string USD = 'USD';
    public static final String MATERIALNUMBER = 'VC0013519-OPA';
    
    @testSetup
    static void setupData()
    {
       
        CLM_ProfileValidation__c profilevalidation = new CLM_ProfileValidation__c(SetupOwnerId=userinfo.getProfileId(),Channel_Partner_Agreement__c=true,Master_Customer_Agreement__c=true,Master_Service_Agreement__c=true,Negotiated_Terms_and_Conditions__c=true,Standing_Quote__c=true,Tender__c=true);
        insert profilevalidation;
        
        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = ERP_123456;
        acc.Territory_Region__c = 'AMR';
        acc.Account_Group__c = 'Sold To';
        acc.Name = 'distributor Account';
        acc.BIllingCountryCode='HK';
        
        Account acc1 = TestDataAccount.initAccount();
        acc1.ERP_Customer_Id__c = ERP_123455;
        acc1.Territory_Region__c = 'China';
        acc1.Account_Group__c = 'Distributor';
        acc1.Name = 'distributor Account';
        acc1.BIllingCountryCode='HK';
        insert new List<Account> { acc, acc1 };
            
        Id recStandinQuote = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standing Quote').getRecordTypeId();
        Id recTypeTender = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Tender').getRecordTypeId();
        
        Contact con = TestDataPerson.initContact(acc.Id);
        Contact con2 = TestDataPerson.initContact(acc1.Id);
        insert new List<Contact> { con, con2 };
            
        Customer_Master_Data__c objCMD1 = new Customer_Master_Data__c(Name='CMD1',Country__c='Hong Kong',Country_Code__c='HK'),
                                objCMD2 = new Customer_Master_Data__c(Name='CMD2',Country__c='Hong Kong',Country_Code__c='HK');
        objCMD1.ERP_Customer_Id__c = ERP_123456;
        objCMD2.ERP_Customer_Id__c = ERP_123455;
        insert new List<Customer_Master_Data__c> {objCMD1, objCMD2};
        Product2 product = TestDataMaster.createProduct(false);
        product.Material_Number__c = MATERIALNUMBER;
        insert product;
        
        Account_Sales_Area__c accSalesArea = TestDataAccountSalesArea.getAccountSalesArea(HK01, '02', '179', '00', false);
        accSalesArea.Account__c = acc.Id;
        accSalesArea.Price_List_Type__c = '06';
        accSalesArea.CurrencyIsoCode = USD;
        accSalesArea.Price_List__c = AMEA_USD_01; //POL-57
        accSalesArea.Contract_Number__c = '123456_HK010100';
        accSalesArea.Price_Group__c = TXDR;
        accSalesArea.Sales_Organization__c=HK01;
        accSalesArea.Price_Group_Description__c=TEST_TXDR;
        accSalesArea.Distribution_Channel__c='01';
        Account_Sales_Area__c accSalesArea1 = TestDataAccountSalesArea.getAccountSalesArea('TW01', '01', '178', '00', false);
        accSalesArea1.Account__c = acc1.Id;
        accSalesArea1.Price_List_Type__c = '06';
        accSalesArea1.CurrencyIsoCode = USD;
        accSalesArea1.Price_List__c = 'TWD_USD_01';
        accSalesArea1.Contract_Number__c = '123456_HK010101';
        accSalesArea1.Price_Group__c = TXDR;
        accSalesArea1.Sales_Organization__c='TW01';
        accSalesArea1.Price_Group_Description__c=TEST_TXDR;
        accSalesArea1.Distribution_Channel__c='01';
        insert new List<Account_Sales_Area__c>{ accSalesArea, accSalesArea1  };
            
        Apttus__APTS_Agreement__c agreement1 = TestDataAgreement.initAgreements('Test Agreement 1', acc1.id);
        agreement1.Sales_Org__c ='TW01';//adding reference sales org
        agreement1.RecordTypeId = recTypeTender;
        agreement1.Apttus__Subtype__c = 'Indirect';
        agreement1.One_Time_Agreement_Products__c = 'test';
        agreement1.Ultimate_Consignee__c = acc1.id;
        
        Apttus__APTS_Agreement__c agreement2 = TestDataAgreement.initAgreements('Test Agreement -  No Sales Org', acc.id);
        agreement2.RecordTypeId = recStandinQuote;
        agreement2.Justification_for_No_Agreement_Value__c = 'Comparison Customer';
        agreement2.Apttus__Contract_Start_Date__c = system.today();
        agreement2.Apttus__Contract_End_Date__c = system.today() + 750;
        agreement2.Sales_Org__c = HK01; 

                insert new List<Apttus__APTS_Agreement__c> {agreement1, agreement2 };
        
    }
    @isTest
    static void testPPM()
    {    
        Test.starttest();
        List<Apttus__APTS_Agreement__c> lstAgreement = [Select Id, Name, Apttus_Approval__Approval_Status__c, Approval_Category__c, Apttus__Status_Category__c,
                                                        Apttus__Status__c, Post_Pricing_Message__c 
                                                        From  Apttus__APTS_Agreement__c  LIMIT 2];
        
        lstAgreement[0].Post_Pricing_Message__c = 'Test PPM Message for Tender';
        lstAgreement[1].Post_Pricing_Message__c = 'Test PPM Message for SQ';

            Update lstAgreement;
        PPMAgreementQuickActionController.getAgreementRecord(lstAgreement[0].Id);
        PPMAgreementQuickActionController.getAgreementRecord(lstAgreement[1].Id);
        PPMAgreementQuickActionController.saveRecord(lstAgreement[0].Id,'premTestingtestPPM1');
        PPMAgreementQuickActionController.saveRecord(lstAgreement[1].Id,'premTestingtestPPM2');

        PPMAgreementQuickActionController.saveRecord(lstAgreement[0].Id,'premTestingtestPPM1assert');
        PPMAgreementQuickActionController.saveRecord(lstAgreement[1].Id,'premTestingtestPPM2');
         System.assertequals('Test PPM Message for SQ',lstAgreement[1].Post_Pricing_Message__c);

        PPMAgreementQuickActionController.isTest = true;
        try {
            PPMAgreementQuickActionController.saveRecord(lstAgreement[0].Id,'premTestingtestPPM1Exception');
        } catch (AuraHandledException e) {
            System.debug(e.getMessage());
            System.debug(e.getTypeName());
        }
        Test.stoptest();
    }
}