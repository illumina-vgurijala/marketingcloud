/***************************************************************************************************************************************
 * NAME   : TestUpdateAPwithIPProductSub_CaseHelper
 * DESCRIPTION  : Test Class for UpdateAPwithIPProductSub_CaseHelper (Code Coverage-91%)
 * @AUTHOR : Abhishek Yadav
 * @DATE   : 02-Nov-2024 
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Abhishek Yadav          16-Nov-2023             Initial Version
 ****************************************************************************************************************************************/ 
@isTest
public with sharing class TestUpdateAPwithIPProductSub_CaseHelper { 
    public static final String STRING_WO_RECORDTYPE = 'Field Service';
     public static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP';
     public static final string STRING_CURRENCY = 'USD';
     public static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
     public static final string STRING_CASE_INQ_RECORDTYPE = 'Inquiry';
     public static final string STRING_CASE_SR_RECORDTYPE = 'Service Request';
     public static final string STRING_CASE_BI_RECORDTYPE = 'Business Issue';
     public static final string STRING_CASE_STATUS = 'Initiated';
     public static final string STRING_CASE_ORIGIN = 'Phone - CS';
     public static final string STRING_LOCATION = 'Test Location';
     public static final string STRING_STREET = 'Test Street';
     public static final string STRING_PRODUCT_MATERIAL_CLASS = 'Consumable';
     public static final string STRING_PRODUCT_CODE = 'Test 1234';
     public static final string STRING_EVALUATION_ANSWER_PENDING = 'Pending';
    /**
    *  CMCM-263
    *  @author : Abhishek Yadav
    *  @description - insert Associated Product on Case Creation
    **/
    @isTest
    static void testAPInstallProduct() {

        // Create Account
        Account objAccount = TestDataAccount.getNewAccount();
        // Create Contact
        Contact con = new Contact();
        con.FirstName = 'testfirstname'; 
        con.LastName = 'testlastname'; 
        con.AccountId = objAccount.Id;
        con.Phone = '1234567890';
        con.email = 'abc@test.com.invalid';
        insert con;
        // insert Subscription
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.ERP_Contract_Type__c = 'Software (ZWS)';
        insert objServiceContract;
        // insert Installed Product
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        insert objInstalledProduct;
        // insert Location
        SVMXC__Site__c objLocation = TestDataFieldService.createLocation(STRING_LOCATION,STRING_STREET,'Ireland','123456','USD');
         insert objLocation;
         // insert product 
         Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
         objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
         objProduct.Regulatory_Type__c = 'DX';
         objProduct.Source_System__c = 'SAP';
         insert objProduct;
       // insert Case
       Case objCase = TestDataCase.initNewCase(STRING_CASE_INQ_RECORDTYPE, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
       objCase.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_PENDING; 
       objCase.Date_of_Issue_Awareness__c = Date.Today();      
       insert objCase;
       Test.startTest();
       objCase.SVMXC__Component__c = objInstalledProduct.Id; 
       objCase.SVMXC__Product__c = objProduct.Id; 
       objCase.RecordTypeId = UpdateAPwithIPProductSub_CaseHelper.BUSINESS_ISSUE_CASE_RECORDTYPE;    
       update objCase;
       List<Associated_Product__c> associatedList = [SELECT Id FROM associated_product__c LIMIT 1];
       Assert.isTrue(!associatedList.isEmpty(), 'associatedList should not blank');
       Test.stopTest();
   }
   /*  CMCM-263
   *  @author : Abhishek Yadav
   *  @description - insert Associated Product on Case Creation
   **/
   @isTest
   static void testAPProductNSubscription() {

        // Create Account
        Account objAccount = TestDataAccount.getCustomerAccount();
        insert objAccount;
        // Create Contact
        Contact con = new Contact();
        con.FirstName = 'testfirstname'; 
        con.LastName = 'testlastname'; 
        con.AccountId = objAccount.Id;
        con.Phone = '1234567890';
        con.email = 'abc@test.com.invalid';
        insert con;
        // insert Subscription
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.ERP_Contract_Type__c = 'Software (ZWS)';
        insert objServiceContract;
        // insert Location
        SVMXC__Site__c objLocation = TestDataFieldService.createLocation(STRING_LOCATION,STRING_STREET,'Ireland','123456','USD');
        insert objLocation;
        // insert product 
        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        objProduct.Regulatory_Type__c = 'DX';
        objProduct.Source_System__c = 'SAP';
        insert objProduct;
        // insert Case
        Case objCase = TestDataCase.initNewCase(STRING_CASE_SR_RECORDTYPE, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_PENDING; 
        objCase.Date_of_Issue_Awareness__c = Date.Today();
        objCase.ContactId = con.id;
        insert objCase;
        Test.startTest();
        objCase.SVMXC__Product__c = objProduct.Id;
        objCase.Subscription__c = objServiceContract.id; 
        objCase.RecordTypeId = UpdateAPwithIPProductSub_CaseHelper.BUSINESS_ISSUE_CASE_RECORDTYPE;    
        update objCase;
        List<Associated_Product__c> associatedList = [SELECT Id FROM associated_product__c LIMIT 1];
        Assert.isTrue(!associatedList.isEmpty(), 'associatedList should not blank');
        Test.stopTest();
   }
   /*  CMCM-263
   *  @author : Abhishek Yadav
   *  @description - insert Associated Product on Case Creation
   **/
   @isTest
   static void testAPProduct() {

        // Create Account
        Account objAccount = TestDataAccount.getCustomerAccount();
        insert objAccount;
        // Create Contact
        Contact con = new Contact();
        con.FirstName = 'testfirstname'; 
        con.LastName = 'testlastname'; 
        con.AccountId = objAccount.Id;
        con.Phone = '1234567890';
        con.email = 'abc@test.com.invalid';
        insert con;
        // insert Location
        SVMXC__Site__c objLocation = TestDataFieldService.createLocation(STRING_LOCATION,STRING_STREET,'Ireland','123456','USD');
        insert objLocation;
        // insert product 
        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        objProduct.Regulatory_Type__c = 'DX';
        objProduct.Source_System__c = 'SAP';
        insert objProduct;
    // insert Case
        Case objCase = TestDataCase.initNewCase(STRING_CASE_SR_RECORDTYPE, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_PENDING; 
        objCase.Date_of_Issue_Awareness__c = Date.Today();
        objCase.ContactId = con.id;
        insert objCase;
        Test.startTest();
        objCase.SVMXC__Product__c = objProduct.Id;
        objCase.RecordTypeId = UpdateAPwithIPProductSub_CaseHelper.BUSINESS_ISSUE_CASE_RECORDTYPE;    
        update objCase;
        List<Associated_Product__c> associatedList = [SELECT Id FROM associated_product__c LIMIT 1];
        Assert.isTrue(!associatedList.isEmpty(), 'associatedList should not blank');
        Test.stopTest();
   }
   /*  CMCM-263
   *  @author : Abhishek Yadav
   *  @description - insert Associated Product on Case Creation
   **/
    @isTest
    static void testAPSubscription() {

        // Create Account
        Account objAccount = TestDataAccount.getCustomerAccount();
        insert objAccount;
        // Create Contact
        Contact con = new Contact();
        con.FirstName = 'testfirstname'; 
        con.LastName = 'testlastname'; 
        con.AccountId = objAccount.Id;
        con.Phone = '1234567890';
        con.email = 'abc@test.com.invalid';
        insert con;
        // insert Subscription
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.ERP_Contract_Type__c = 'Software (ZWS)';
        insert objServiceContract;
        // insert Location
        SVMXC__Site__c objLocation = TestDataFieldService.createLocation(STRING_LOCATION,STRING_STREET,'Ireland','123456','USD');
            insert objLocation;
        // insert Case
        Case objCase = TestDataCase.initNewCase(STRING_CASE_SR_RECORDTYPE, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_PENDING; 
        objCase.Date_of_Issue_Awareness__c = Date.Today();
        objCase.ContactId = con.id;
        insert objCase;
        Test.startTest();
        objCase.Subscription__c = objServiceContract.id; 
        objCase.RecordTypeId = UpdateAPwithIPProductSub_CaseHelper.BUSINESS_ISSUE_CASE_RECORDTYPE;    
        update objCase;
        List<Associated_Product__c> associatedList = [SELECT Id FROM associated_product__c LIMIT 1];
        Assert.isTrue(!associatedList.isEmpty(), 'associatedList should not blank');
        Test.stopTest();
   }
}