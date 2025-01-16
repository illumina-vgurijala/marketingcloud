/***************************************************************************************************************************************
 * NAME   : TestFANRecordListController
 * DESCRIPTION  : TestClass for FANRecordListController
 *         
 *    
 * @AUTHOR : Digvijay
 * @DATE   : 23-02-2021 
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Digvijay            23-02-2021           Initial Version
 * Priya Mukherjee	   07-11-2021			CMCM-1021
  ****************************************************************************************************************************************/ 
  @isTest(SeeAllData = false) 
public class TestFANRecordListController {

    public static final string STRING_PRODUCT_MATERIAL_CLASS = 'Consumable';
    public static final string STRING_PRODUCT_CODE = 'Test 1234';
    public static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP';
    public static final string STRING_CURRENCY = 'USD';
    public static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    public static final string STRING_CASE_RECORDTYPENAME = 'Business Issue';
    public static final string STRING_CASE_STATUS = 'Initiated';
    public static final string STRING_CASE_ORIGIN = 'Phone - CS';
    public static final string STRING_FAN_STATUS_LOCKED = 'Locked Assessment';//CMCM-1021
    public static final string STRING_FAN_STATUS = 'Assessment';//CMCM-1021

    static Case cs;
    static Field_Action_Notification__c fan;
    static Field_Action_Notification__c fan2;//CMCM-1021

/* testSetup method */
    @testSetup
    public static void initializeTestData() {
        // To create a FAN record of record type "Notification"
        FAN =TestDataFieldService.createFAN('Notification');
        FAN.Status__c = STRING_FAN_STATUS_LOCKED; //CMCM-1021
        insert FAN;

        FAN2=TestDataFieldService.createFAN('Notification');//CMCM-1021
        FAN2.Status__c = STRING_FAN_STATUS;
        insert FAN2;
    }

/* test method */
    public static testMethod void newFieldActionItem(){
        initializeTestData();

        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        objProduct.ProductCode='TestProduct0006';
        objProduct.Source_System__c='SAP';
        insert objProduct;

        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Product__c=objProduct.Id;
        insert objInstalledProduct;

        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase.SVMXC__Component__c = objInstalledProduct.Id; 
        objCase.Product_Serial_Number__c='Test11';
        objCase.SVMXC__Product__c = objProduct.Id;
        insert objCase;
        //CMCM-1021 start
        Case objCase2 = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase2.SVMXC__Component__c = objInstalledProduct.Id; 
        objCase2.Product_Serial_Number__c='Test123';
        objCase2.SVMXC__Product__c = objProduct.Id;
        insert objCase2; //CMCM-1021 end
            
        List<Impacted_Products_Serials_Lots__c> lstimpprod=new List<Impacted_Products_Serials_Lots__c>();
        lstimpprod.add(new Impacted_Products_Serials_Lots__c(Field_Action_Notification__c=FAN.Id,Serial_Number__c='Test11'));
        lstimpprod.add(new Impacted_Products_Serials_Lots__c(Field_Action_Notification__c=FAN.Id,Lot_Number__c='Test12'));
        lstimpprod.add(new Impacted_Products_Serials_Lots__c(Field_Action_Notification__c=FAN.Id,Product__c=objProduct.Id));
        insert lstimpprod;
        //CMCM-1021 start
        List<Impacted_Products_Serials_Lots__c> lstimpprod2 =new List<Impacted_Products_Serials_Lots__c>();
        lstimpprod2.add(new Impacted_Products_Serials_Lots__c(Field_Action_Notification__c=FAN2.Id,Serial_Number__c='Test111'));
        lstimpprod2.add(new Impacted_Products_Serials_Lots__c(Field_Action_Notification__c=FAN2.Id,Lot_Number__c='Test123'));
        lstimpprod2.add(new Impacted_Products_Serials_Lots__c(Field_Action_Notification__c=FAN2.Id,Product__c=objProduct.Id));
        insert lstimpprod2;
        //CMCM-1021 end
        try{
        Test.StartTest();            
            List<FANRecordListController.DataWrapper> lstdatawrapper=FANRecordListController.getwrapperList(objCase.Id);
            system.assertNotEquals(null,lstdatawrapper);
            //CMCM-1021 start
            for (FANRecordListController.DataWrapper wrapper : lstdatawrapper) {
            System.assertNotEquals(STRING_FAN_STATUS_LOCKED, wrapper.statusFan, 'Locked statuses should not be present in the result.');
        }

            List<FANRecordListController.DataWrapper> lstdatawrapper2 =FANRecordListController.getwrapperList(objCase2.Id);
            system.assertNotEquals(null,lstdatawrapper2);
            for (FANRecordListController.DataWrapper wrapper : lstdatawrapper2) {
            System.assertEquals(STRING_FAN_STATUS, wrapper.statusFan, 'Locked statuses should not be present in the result.');
            //CMCM-1021 end
        }
        Test.StopTest();
        }
    	catch(Exception e){}
       }
}