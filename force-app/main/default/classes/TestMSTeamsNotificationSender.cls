/*************************************************************************************
*   @Author:Nitin Sood
*   @Description:Test class for MSTeamsNotificationSender
*/
@isTest(SeeAllData = false)  
public with sharing class TestMSTeamsNotificationSender {

    public static final string STRING_PRODUCT_CODE = 'Test 1234';
    public static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP';
     public static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    public static final string STRING_CURRENCY = 'USD';
    public static final string STRING_CASE_RECORDTYPENAME = 'Business Issue';
    public static final string STRING_CASE_STATUS = 'Initiated';
    public static final string STRING_CASE_ORIGIN = 'Phone - CS';
    public static final string STRING_EVALUATION_ANSWER_PENDING='Pending';  
    public static final string STRING_PRODUCT_MATERIAL_CLASS = 'Consumable';
    
    static testmethod void testMethod1(){
        
        Account objAccount = TestDataAccount.getNewAccount();
        system.assertNotEquals(null,objAccount.id);

        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        objProduct.Regulatory_Type__c = 'DX';
        objProduct.Source_System__c = 'SAP';
        insert objProduct;
        system.assertNotEquals(null,objProduct.id);
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Product__c=objProduct.Id;
        insert objInstalledProduct;
        system.assertNotEquals(null,objInstalledProduct.id);
        
        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase.SVMXC__Component__c = objInstalledProduct.Id; 
        objCase.SVMXC__Product__c = objProduct.Id;
        objCase.PAE_PFA_Evaluation_Required__c =STRING_EVALUATION_ANSWER_PENDING;
        //objCase.Answer_1__c = STRING_EVALUATION_ANSWER_NO;
        //objCase.pAE_pFA_Awareness_Date__c = Date.Today() -3;   
        objCase.Date_of_Issue_Awareness__c = Date.Today();      
        insert objCase; 


        Map<Id, String> mapRecIdToErrors = new Map<Id, String>();
        String errorMsg = 'Error 1';
        mapRecIdToErrors.put(objCase.id,errorMsg);
        List<String> lstCaseNumber = new List<String>();
        lstCaseNumber.add('12345');
        MSTeamsNotificationSender.sendTeamsNotificationForCase('xyz@gmail.com' ,'test','test', lstCaseNumber);
        MSTeamsNotificationSender.getTableEmailBodyAndSendNotification(mapRecIdToErrors, 'BatchAttemptAutoCloseCase', null);        
    }

}