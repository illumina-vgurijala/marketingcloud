/***************************************************************************************************************************************
 * NAME   : TestAutoCompleteController
 * DESCRIPTION  : TestClass for AutoCompleteController Class
 * @AUTHOR : Vaibhav
 * @DATE   : 15-May-2019  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
  ****************************************************************************************************************************************/ 
@isTest
public with sharing class TestAutoCompleteController {

    public static final boolean BOOLEAN_CONSUMABLES_INCLUDED = false;
    public static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP';
    public static final string STRING_CURRENCY = 'USD';
    public static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    public static final string STRING_CASE_RECORDTYPENAME = 'Business Issue';
    public static final string STRING_CASE_STATUS = 'Initiated';
    public static final string STRING_CASE_ORIGIN = 'Phone - CS';

    @TestSetup
    static void testData() {

        Account objAccount = TestDataAccount.getNewAccount();

        Test.startTest();
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        insert objServiceContract;
        SVMXC__Service_Contract__c insertedServiceContract = [Select Consumables_Included__c from SVMXC__Service_Contract__c where Id =: objServiceContract.Id];
        System.assertEquals(insertedServiceContract.Consumables_Included__c, BOOLEAN_CONSUMABLES_INCLUDED);

        SVMXC__Site__c objLocation = TestDataFieldService.createLocation('Test Location', 'Test Street', 'Ireland', '123456', 'USD');
        insert objLocation;

        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        insert objInstalledProduct;
        SVMXC__Installed_Product__c insertedInstalledProduct = [Select SVMXC__Status__c from SVMXC__Installed_Product__c where Id =: objInstalledProduct.Id];
        System.assertEquals(insertedInstalledProduct.SVMXC__Status__c, STRING_INSTALLED_PRODUCT_STATUS);

        SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(objInstalledProduct.Id);
        objCoveredProduct.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert objCoveredProduct;
        SVMXC__Service_Contract_Products__c insertedCoveredProduct = [Select SVMXC__Installed_Product__c from SVMXC__Service_Contract_Products__c where SVMXC__Installed_Product__c =: objInstalledProduct.Id];
        System.assertEquals(insertedCoveredProduct.SVMXC__Installed_Product__c, objInstalledProduct.Id);

        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase.SVMXC__Component__c = objInstalledProduct.Id;
        objCase.SVMXC__Site__c = objLocation.Id;
        objCase.Date_of_Issue_Awareness__c = Date.Today();
        insert objCase;
        Case insertedCase = [Select SVMXC__Component__c from Case where Id =: objCase.Id];
        System.assertEquals(InsertedCase.SVMXC__Component__c, objInstalledProduct.Id);

        Applied_Contract__c objEntitlement = new Applied_Contract__c();
        objEntitlement.CurrencyIsoCode = 'USD';
        objEntitlement.Case_Number__c = objCase.id;
        insert objEntitlement;
        List<Applied_Contract__c> insertedEntitlement = [Select Case_Number__c from Applied_Contract__c where Case_Number__c =: objCase.Id];
        System.assertEquals(insertedEntitlement[0].Case_Number__c, objCase.Id);

        Test.stopTest();
    }

    @isTest
    static void testGetRecords() {
        //query the inserted case.
        Case caseRec = [Select Id, CaseNumber from Case Limit 1];
        //search the inserted case using automComplete component.
        List < SObject > cases = AutoCompleteController.getRecords(caseRec.CaseNumber, 'Case', 'Id', 'CaseNumber', null, 10);
        System.assertEquals(1, cases.size());
    }
}