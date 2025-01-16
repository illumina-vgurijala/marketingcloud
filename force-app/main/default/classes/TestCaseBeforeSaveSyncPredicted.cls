/**************************************************************************************************************************
* @Author:  Nidhi Hegde
* @Date:    15-Oct-2023
* @Name:    TestCaseBeforeSaveSyncPredicted
* @Description: For Covering Record-Trigger : Case Before Save : Sync Predicted QA Product Family and Predicted QA Sub
 Product Family Flow
* ------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* -------------------------------------------------------------------------------------------------------------------------
* Nidhi Hegde             15-Oct-2023        Initial Version (CMCM-3827)
***************************************************************************************************************************/


@isTest
public class TestCaseBeforeSaveSyncPredicted {
    
    public static final string STRING_EVALUATION_ANSWER_NO = 'No';
    public static final string STRING_EVALUATION_ANSWER_YES = 'YES';
    public static final string STRING_EVALUATION_ANSWER_PENDING='Pending';
    public static final string STRING_CASE_STATUS_CLOSED = 'Closed';
    public static final string STRING_CASE_RECORDTYPENAME = 'Business Issue';
    public static final string STRING_PRODUCT_CODE = 'Test 1234';
    public static final string STRING_CASE_ORIGIN = 'Phone - CS';
    public static final string STRING_PRODUCT_MATERIAL_CLASS = 'Consumable';
    public static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP';
    public static final string STRING_CURRENCY = 'USD';
    public static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    public static final string STRING_CASE_STATUS = 'Initiated';
    
    /**
    *  @author Nidhi
    *  @description - Positive Testing 
    **/
    @isTest
    public static void testCaseBeforeSaveMethod() {
        
        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        objProduct.Source_System__c = 'SAP';
        insert objProduct;
        system.assertNotEquals(null,objProduct.id);
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Product__c = objProduct.Id;
        insert objInstalledProduct;
        system.assertNotEquals(null,objInstalledProduct.id);
        
        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase.SVMXC__Component__c = objInstalledProduct.Id;
        objCase.Date_of_Issue_Awareness__c = Date.Today();
        
        insert objCase;
        Test.startTest();
        objCase.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_NO;
        objCase.Verification_Result__c = 'Test';
        objCase.Record_Updated_from_SFM__c = true;
        objCase.Status = STRING_CASE_STATUS_CLOSED;
        objCase.Record_Updated_from_SFM__c = True;
        objCase.QA_Product_Family__c = 'NIPT';
        objCase.QA_Sub_Product_Family__c = 'NIPT Solution v2';
        update objCase;
        Test.stopTest();
        Case cs = [SELECT Predicted_QA_Product_Family__c FROM Case LIMIT 1];
        Assert.areEqual(cs.Predicted_QA_Product_Family__c , objCase.QA_Product_Family__c);
    }
}