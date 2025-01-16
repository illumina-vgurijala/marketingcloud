/***************************************************************************************************************************************
* NAME   : TestCodeTitleChangeFlow
* DESCRIPTION  : For Covering the "AssociatedCodes : Record-Trigger : Before Save : updateCheckCertainEditsOnCodeTitleChangeCheck" Flow
*    
* @AUTHOR : Nidhi
* @DATE   : 13-Oct-2023  
*
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Nidhi               13-Oct-2023              Initial Version (CMCM-3827)
****************************************************************************************************************************************/
@isTest
public class TestCodeTitleChangeFlow {
    private static final string STRING_PRODUCT_MATERIAL_CLASS = 'Consumable';
    private static final string STRING_PRODUCT_CODE = 'Test 1234';
    private static final string STRING_EVALUATION_ANSWER_PENDING='Pending';
    private static final string STRING_CASE_SUB_TYPE = 'Complaint';
    private static final string STRING_CASE_RECORDTYPENAME = 'Business Issue';
    private static final string STRING_CASE_STATUS = 'Initiated';
    private static final string STRING_CASE_ORIGIN = 'Phone - CS';
    
    /**
*  @author Nidhi
*  @description - Match Found Desion Test
**/
    @isTest
    public static void testMatchFound() {
        Account objAccount = TestDataAccount.getNewAccount();
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname',AccountID = objAccount.Id,Email='test@gmail.com.invalid' , Phone = '1234567890');
        insert con;
        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        objProduct.Regulatory_Type__c = 'DX';
        insert objProduct;
        
        cs_Apex_Settings__c csapex = new cs_Apex_Settings__c();
        csapex.Bypass_All_Validations__c = true;
        csapex.SetupOwnerId = UserInfo.getUserId();
        insert csapex;
        
        SVMXC__Installed_Product__c ip = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
        ip.SVMXC__Product__c = objProduct.id;
        ip.SVMXC__Company__c = objAccount.Id;
        insert ip;
        
        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME,STRING_CASE_STATUS,STRING_CASE_ORIGIN);
        objCase.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get(STRING_CASE_RECORDTYPENAME).getRecordTypeId();
        objCase.Date_of_Issue_Awareness__c =  Date.today().addDays(-3);
        objCase.SVMXC__Product__c = objProduct.Id;
        objCase.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_PENDING;
        objCase.Description = 'testDescription';
        objCase.Sub_Type__c = STRING_CASE_SUB_TYPE;    
        objCase.Category__c = 'LIMS';
        objCase.Product_Utilization_Mode__c = 'IUO';
        insert objCase;
        Test.startTest();
        Code_Library__c code = new Code_Library__c();
        code.Name = 'INQ General Process Inquiry';
        code.Code_type__c = 'Analysis';
        code.Case_Sub_Type__c = 'Complaint';
        code.Case_Type__c = STRING_CASE_RECORDTYPENAME;
        insert code;
        Associated_Codes__c ac = new Associated_Codes__c();
        ac.Code_Title__c = code.Id;
        ac.Case__c = objCase.Id;
        insert ac;
        Test.stopTest();
        Associated_Codes__c assocCode = [SELECT Id, CheckCertainEditsOnCodeTitleChange_Check__c FROM Associated_Codes__c WHERE Id =:ac.Id];
        Assert.areEqual('CodeTitleChange',assocCode.CheckCertainEditsOnCodeTitleChange_Check__c);
    }
    /**
*  @author Nidhi
*  @description - Default outcome Test 
**/
    @isTest
    public static void testDefaultOutcome() {
        Account objAccount = TestDataAccount.getNewAccount();
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname',AccountID = objAccount.Id,Email='test@gmail.com.invalid' , Phone = '1234567890');
        insert con;
        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        objProduct.Regulatory_Type__c = 'DX';
        insert objProduct;
        
        cs_Apex_Settings__c csapex = new cs_Apex_Settings__c();
        csapex.Bypass_All_Validations__c = true;
        csapex.SetupOwnerId = UserInfo.getUserId();
        insert csapex;
        
        SVMXC__Installed_Product__c ip = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
        ip.SVMXC__Product__c = objProduct.id;
        ip.SVMXC__Company__c = objAccount.Id;
        insert ip;
        
        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME,STRING_CASE_STATUS,STRING_CASE_ORIGIN);
        objCase.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get(STRING_CASE_RECORDTYPENAME).getRecordTypeId();
        objCase.Date_of_Issue_Awareness__c =  Date.today().addDays(-3);
        objCase.SVMXC__Product__c = objProduct.Id;
        objCase.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_PENDING;
        objCase.Description = 'testDescription';
        objCase.Sub_Type__c = STRING_CASE_SUB_TYPE;    
        objCase.Category__c = 'LIMS';
        objCase.Product_Utilization_Mode__c = 'IUO';
        insert objCase;
        Test.startTest();
        Code_Library__c code = new Code_Library__c();
        code.Name = 'INQ General Process Inquiry';
        code.Code_type__c = 'Analysis';
        code.Case_Type__c = STRING_CASE_RECORDTYPENAME;
        insert code;
        Associated_Codes__c ac = new Associated_Codes__c();
        ac.Code_Title__c = code.Id;
        ac.Case__c = objCase.Id;
        insert ac;
        Test.stopTest();
        Associated_Codes__c assocCode = [SELECT Id, CheckCertainEditsOnCodeTitleChange_Check__c FROM Associated_Codes__c WHERE Id =:ac.Id];
        Assert.areEqual('FALSE',assocCode.CheckCertainEditsOnCodeTitleChange_Check__c);
    }
}