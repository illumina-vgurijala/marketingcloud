/**
*    @author Prabhsimran Singh
*    @date   20 August 2020
*    @description    DCP-39587 Test class to cover APttusRelatedAgreements and BatchAgreementLineItemInsertion.
*    Modification Log:
*    ------------------------------------------------------------------------------------
*        Developer                  Date              Description
*        
*    ------------------------------------------------------------------------------------
*      Arif,Dalali           28-Nov-2022             POL-57: Update APJ and EMEA References to AMEA and Europe respectively
*/

@isTest
public with sharing class TestApttusRelatedAgreements {
    
    public static FINAL string VC0013519_OPA = 'VC0013519-OPA';
    public static FINAL string SV_111_3001 = 'SV-111-3001';
    public static FINAL string AMEA_USD = '01-AMEA-USD'; //POL-57
    public static FINAL string PERDISCOUNT = '% Discount';
    
    @testSetup
    static void setupData()
    {
        List<Apttus__APTS_Agreement__c> lstAgreement = new List<Apttus__APTS_Agreement__c>();
        Account acc = TestDataAccount.initAccount();
        acc.Country_Local__c ='Japan';
        acc.ERP_Customer_Id__c = '123456';
        acc.Territory_Region__c = 'AMR';
        acc.Account_Group__c = 'Distributor';
        Account acc2 = TestDataAccount.initAccount();
        acc2.ERP_Customer_Id__c = '234567';
        insert new List<Account> { acc, acc2 };
            Contact con = TestDataPerson.initContact(acc.Id);
        Contact con2 = TestDataPerson.initContact(acc.Id);
        insert new List<Contact> { con, con2 };
            
            
            Customer_Master_Data__c objCMD1 = new Customer_Master_Data__c(Name='CMD1',Country__c='Hong Kong',Country_Code__c='HK'),
            objCMD2 = new Customer_Master_Data__c(Name='CMD2',Country__c='Hong Kong',Country_Code__c='HK');
        objCMD1.ERP_Customer_Id__c = '123456';
        objCMD2.ERP_Customer_Id__c = '234567';
        insert new List<Customer_Master_Data__c> {objCMD1, objCMD2};
            
            Product2 product = TestDataMaster.createProduct(false);
        product.Material_Number__c = VC0013519_OPA ;
        Product2 productTwo = TestDataMaster.createProduct(false);
        productTwo.Material_Number__c = '11234187';
        Product2 productThree = TestDataMaster.createProduct(false);
        productThree.Material_Number__c = 'SV-111-1002';
        Product2 productFour = TestDataMaster.createProduct(false);
        productFour.Old_Material_Number__c = SV_111_3001;
        
        insert new List<Product2> { product, productTwo, productThree, productFour };
            
            CLM_ProfileValidation__c profilevalidation = new CLM_ProfileValidation__c(SetupOwnerId=userinfo.getProfileId(),Channel_Partner_Agreement__c=true,Master_Customer_Agreement__c=true,Master_Service_Agreement__c=true,Negotiated_Terms_and_Conditions__c=true,Standing_Quote__c=true,Tender__c=true);
        insert profilevalidation;
        
        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '01', '178', '00', false);
        acc1SalesArea.Account__c = acc.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = AMEA_USD; //POL-57
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        acc1SalesArea.ERP_Account_Sales_Area_Id__c = '123456_HK010100';
        acc1SalesArea.Price_Group__c = 'TXDR';
        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '02', '179', '00', false);
        acc2SalesArea.Account__c = acc2.Id;
        acc2SalesArea.Price_List_Type__c = '06';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = AMEA_USD; //POL-57
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        insert new List<Account_Sales_Area__c>{ acc1SalesArea, acc2SalesArea };
            
            Id recTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Channel Partner Agreement').getRecordTypeId();
        Apttus__APTS_Agreement__c oAgreement1 = TestDataAgreement.initAgreements('Test Agreement - Customer', acc.id);
        oAgreement1.RecordTypeId = recTypeId;	        
        lstAgreement.add(oAgreement1);
        
        Apttus__APTS_Agreement__c oAgreement2 = TestDataAgreement.initAgreements('Test Agreement - Price Group', acc.id);
        oAgreement2.RecordTypeId = recTypeId;
        oAgreement2.Agreement_Not_Amended__c = false;
        lstAgreement.add(oAgreement2);
        insert lstAgreement;
        
        Apttus__AgreementLineItem__c objAgreementLineItem1 = TestDataAgreement.initAgreementsLineItem(lstAgreement[0].Id);
        objAgreementLineItem1.Line_Type__c = 'Material';
        objAgreementLineItem1.Material_Number__c = VC0013519_OPA;
        objAgreementLineItem1.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem1.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem1.Discount__c = 5;
        objAgreementLineItem1.Discount_Type__c = PERDISCOUNT;
        objAgreementLineItem1.Customer_ERP_Number__c='123456';
        objAgreementLineItem1.Sales_Org__c='AU01';
        objAgreementLineItem1.Distribution_Channel__c='02';
        objAgreementLineItem1.Discount__c = 15;
        objAgreementLineItem1.Apttus_CMConfig__EndDate__c = system.today().addMonths(1);
        objAgreementLineItem1.Discontinued__c = 'No';        
        objAgreementLineItem1.Q1_Quota__c = 10.00;        
        objAgreementLineItem1.Q2_Quota__c = 10.00;        
        objAgreementLineItem1.Q3_Quota__c = 10.00;        
        objAgreementLineItem1.Q4_Quota__c = 10.00;        
        objAgreementLineItem1.Discount_In_Percent__c = 10.00;        
        objAgreementLineItem1.Discount_Amount__c = 10.00;        
        objAgreementLineItem1.Line_Type_1__c = 'Material';        
        objAgreementLineItem1.Partner_Role__c = 'Z5';        
        objAgreementLineItem1.Permitted_Markup_Percentage__c = 10.00;        
        objAgreementLineItem1.Ultimate_Consignee_ERP_Number__c = '123456';
		objAgreementLineItem1.Customer_Price__c = 10.00;       
		objAgreementLineItem1.Material_Group_1_Description__c = 'Test Group Description';
        objAgreementLineItem1.Material_Group_1__c = 'AIM';
        objAgreementLineItem1.Price_Group__c = 'Test';
        insert objAgreementLineItem1;
        
        objAgreementLineItem1.Apttus_CMConfig__LineStatus__c = 'Existing';
        update objAgreementLineItem1;
        
        Apttus__APTS_Related_Agreement__c relAgreement = new Apttus__APTS_Related_Agreement__c();
        relAgreement.Apttus__APTS_Contract_From__c = lstAgreement[0].Id;
        relAgreement.Apttus__APTS_Contract_To__c = lstAgreement[1].Id;
        relAgreement.Apttus__Relationship_From_Type__c = 'Is Amended By';
        insert relAgreement;
        
    }
    
    @isTest
    static void testBatchLineItemsDeletion(){
        List<Apttus__AgreementLineItem__c> lstALIInserted = [SELECT id,Apttus__AgreementId__c from Apttus__AgreementLineItem__c limit 100];
                
        List<Apttus__APTS_Agreement__c> lstAgreement = [SELECT id from Apttus__APTS_Agreement__c limit 100];    
        test.startTest();
        Apttus__APTS_Related_Agreement__c relAgreement = new Apttus__APTS_Related_Agreement__c();
        relAgreement.Apttus__APTS_Contract_From__c = lstAgreement[0].Id;
        relAgreement.Apttus__APTS_Contract_To__c = lstAgreement[1].Id;
        relAgreement.Apttus__Relationship_From_Type__c = 'Is Renewed By';
        insert relAgreement;
        test.stopTest();
        system.assertEquals(2, lstALIInserted.size());
    }
}