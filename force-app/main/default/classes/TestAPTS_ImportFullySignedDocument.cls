/**
*    @author Nikil
*    @date   15/03/2020
*    @description    Test Class for APTS_ImportFullySignedDocument class
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------
*      Developer                      Date                Description
*       Nikhil                      15/03/2020            Initial Version
*       Adyasha Satapathy           24-Nov-2022           POL-54: Update region references to AMEA and EUR 
*       Aman Tyagi                  12/12/2022            CodeScan Fixes
*    --------------------------------------------------------------------------------------------------------------------------
**/
@isTest(SeeAllData=false isParallel=false)
public with sharing class TestAPTS_ImportFullySignedDocument {
    public static FINAL String MATERIAL_NUMBER = 'VC0013519-OPA';
	
   @testSetup
    static void setupData(){
        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = '123456';
        acc.Territory_Region__c = 'AMR';    
        Account acc2 = TestDataAccount.initAccount();
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
        product.Material_Number__c = MATERIAL_NUMBER;
        insert product;
        
        CLM_ProfileValidation__c profilevalidation = new CLM_ProfileValidation__c(SetupOwnerId=userinfo.getProfileId(),Channel_Partner_Agreement__c=true,Master_Customer_Agreement__c=true,Master_Service_Agreement__c=true,Negotiated_Terms_and_Conditions__c=true,Standing_Quote__c=true,Tender__c=true);
        insert profilevalidation;
        
        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '01', '178', '00', false);
        acc1SalesArea.Account__c = acc.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = '01-AMEA-USD'; //POL-54
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        acc1SalesArea.Price_Group__c = 'TXDR';
        
        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '02', '179', '00', false);
        acc2SalesArea.Account__c = acc2.Id;
        acc2SalesArea.Price_List_Type__c = '06';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = '01-AMEA-USD'; //POL-54
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        insert new List<Account_Sales_Area__c>{ acc1SalesArea, acc2SalesArea };

        Id recTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Master Customer Agreement').getRecordTypeId();
        Apttus__APTS_Agreement__c oAgreement1 = TestDataAgreement.initAgreements('Test Agreement - Price Group', acc.id);
        //oAgreement1.scount_Level__c = 'Price Group';
        oAgreement1.RecordTypeId = recTypeId;
        oAgreement1.Validation_Status__c = 'Validate';
        oAgreement1.Apttus_Approval__Approval_Status__c = Label.AgreementApprovalStatusApproved;
        oAgreement1.Apttus__Contract_Start_Date__c = Date.Today();
        oAgreement1.Apttus__Contract_End_Date__c = Date.Today()+30;
        oAgreement1.Apttus_Approval__Approval_Status__c = Label.AgreementApprovalStatusNotSubmitted;

        Apttus__APTS_Agreement__c oAgreement2 = TestDataAgreement.initAgreements('Test Agreement - Price Group123', acc.id);
        oAgreement2.RecordTypeId = recTypeId;
        oAgreement2.Validation_Status__c = 'Validate';
        oAgreement2.Apttus_Approval__Approval_Status__c = Label.AgreementApprovalStatusApproved;
        oAgreement2.Apttus__Contract_Start_Date__c = Date.Today();
        oAgreement2.Apttus__Contract_End_Date__c = Date.Today()+30;
        insert new List<Apttus__APTS_Agreement__c>{oAgreement1,oAgreement2};
        
        Apttus__AgreementLineItem__c oAgreementLineItem = TestDataAgreement.initAgreementsLineItem(oAgreement1.id);
        oAgreementLineItem.Material_Number__c = MATERIAL_NUMBER;
        oAgreementLineItem.Line_Type__c = 'Material';
        oAgreementLineItem.Apttus_CMConfig__LineNumber__c = 1;
        oAgreementLineItem.Apttus_CMConfig__ItemSequence__c = 1;
        oAgreementLineItem.Discount_Type__c = '% Discount';
        oAgreementLineItem.Discount__c = 12;
        oAgreementLineItem.CurrencyIsoCode = 'USD';
        oAgreementLineItem.Distribution_Channel__c = '01';
        oAgreementLineItem.Customer_ERP_Number__c = '123456';
        oAgreementLineItem.Sales_Org__c = 'US01';
        oAgreementLineItem.Apttus_CMConfig__StartDate__c = Date.Today() + 5;
        oAgreementLineItem.Apttus_CMConfig__EndDate__c = Date.Today() + 10;
        oAgreementLineItem.Apttus_CMConfig__LineStatus__c = 'New';
        oAgreementLineItem.Discontinued__c = 'No';
        insert oAgreementLineItem;
        Apttus__AgreementLineItem__c oAgreementLineItem1 = TestDataAgreement.initAgreementsLineItem(oAgreement1.id);
        oAgreementLineItem1.Material_Number__c = MATERIAL_NUMBER;
        oAgreementLineItem1.Line_Type__c = 'Material';
        oAgreementLineItem1.Apttus_CMConfig__LineNumber__c = 1;
        oAgreementLineItem1.Apttus_CMConfig__ItemSequence__c = 1;
        oAgreementLineItem1.Discount_Type__c = '% Discount';
        oAgreementLineItem1.Discount__c = 12;
        oAgreementLineItem1.CurrencyIsoCode = 'USD';
        oAgreementLineItem1.Distribution_Channel__c = '01';
        oAgreementLineItem1.Customer_ERP_Number__c = '123456';
        oAgreementLineItem1.Sales_Org__c = 'US01';
        oAgreementLineItem1.Apttus_CMConfig__StartDate__c = Date.Today() - 10;
        oAgreementLineItem1.Apttus_CMConfig__EndDate__c = Date.Today() - 3;
        oAgreementLineItem1.Apttus_CMConfig__LineStatus__c = 'Existing';
        oAgreementLineItem1.Discontinued__c = 'Yes';
        insert oAgreementLineItem1;
            
        
    }
    @isTest
 	static  void testfinalize() {
  
    test.startTest();   
     PageReference pageRef = Page.ImportFullySignedDocument;
	Apttus__APTS_Agreement__c objAgreement = [select id,Apttus__FF_Agreement_Number__c from Apttus__APTS_Agreement__c where Name = 'Test Agreement - Price Group'];  
   Test.setCurrentPage(pageRef);
   pageRef.getParameters().put('id',objAgreement.id);
   ApexPages.StandardController sc = new ApexPages.standardController(objAgreement);
   APTS_ImportFullySignedDocumentController  controller = new APTS_ImportFullySignedDocumentController(sc);
   System.assertNotEquals(null,controller.finalize());
   
   test.stopTest();
}
}