/***************************************************************************************************************************************
 * NAME   : TestCaseLines
 * DESCRIPTION  : TestClass for CaseLines
 * @AUTHOR : Shashank Singhal
 * @DATE   : 30-Aug-2018  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Shashank             30-Aug-2018            Initial Vesrion
 * Preetha              6-Apr-2022             Added testCheckShowOnCase,checkShowOnCase1 to test checkShowOnCase
 *****************************************************************************************************************************************/ 
@isTest(seeAllData = false)
private class TestCaseLines {
    //QACM-18 starts
    public static final string STRING_PRODUCT_CODE = 'Test 1234';
    public static final string STRING_PRODUCT_MATERIAL_CLASS = 'Consumable';
    public static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP';
    public static final string STRING_CURRENCY = 'USD';
    public static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    public static final string STRING_CASE_RECORDTYPENAME = 'Business Issue';
    public static final string STRING_CASE_STATUS = 'Initiated';
    public static final string STRING_CASE_ORIGIN = 'Phone - CS';
    //QACM-18 Ends



    static testMethod void checkShowOnCase(){
    SVMX_PS_VS_Part_Consumption_Settings__c consumptionSetting= new  SVMX_PS_VS_Part_Consumption_Settings__c(Name = 'Use Allocated Qty',
                                                                                                                SVMX_PS_VS_Field_Type__c ='Boolean');
                                                                                                                
       insert consumptionSetting;
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
        Case cs = TestDataCase.initServiceRequestCase(con);

        insert cs;
        SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        wo.SVMXC__Order_Type__c='Relocation';
        wo.Record_Created_from_SFM__c=true;
        insert wo;
        Product2 objProd = new Product2(Name = 'testProd', Regulatory_Type__c = 'DX', Source_System__c='SAP');
        insert objProd;
        Product2 objProd1 = new Product2(Name = 'testProd', Regulatory_Type__c = 'test', Source_System__c='SAP');
        insert objProd1;
        SVMXC__Installed_Product__c ip = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
        ip.SVMXC__Product__c = objProd.id;
        insert ip;
	
        SVMXC__Installed_Product__c ip1 = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
        ip1.SVMXC__Product__c = objProd1.id;
        insert ip1;
        
        SVMXC__Case_Line__c cl = new SVMXC__Case_Line__c();
        cl.SVMXC__Installed_Product__c = ip.Id;
        cl.Show_On_Case__c = true;
        cl.SVMXC__Case__c = cs.Id;
        cl.Product_Lot_Number__c = '1000';
        insert cl;
        cl.SVMXC__Installed_Product__c = ip1.Id;
        cl.IsExpired__c = true;
        cl.Instrument_Mode__c = 'RUO';
        cl.Product_Lot_Number__c = '1001';
        Test.startTest();
        update cl;
        cl.Show_On_Case__c = false;
        update cl;
        cl.Show_On_Case__c = true;
        update cl;
        Test.stopTest();
        Case cs1 = [Select Id, AP_Installed_Product__c from Case where Id = :cs.Id limit 1];
        //system.assertEquals(ip1.Id, cs1.AP_Installed_Product__c);
        
    }
    /*******************************************************************************************************
    * author - Preetha[QACM-18]
    * @description test method to check Show On Case for Additionl products
    * 
    */
    static testMethod void testcheckShowOnCase(){
        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        objProduct.Source_System__c='SAP';
        insert objProduct;

        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Product__c=objProduct.Id;
        insert objInstalledProduct;

        Case objCase1 = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase1.SVMXC__Component__c = objInstalledProduct.Id; 
        ObjCase1.Sub_Type__c = 'Complaint';
        objCase1.Date_of_Issue_Awareness__c = Date.Today();
        insert objCase1;
        test.startTest();
        SVMXC__Case_Line__c cl = New SVMXC__Case_Line__c();
        cl.SVMXC__Case__c = objCase1.id;
        cl.SVMXC__Product__c = objProduct.id;
        insert cl;
        test.stopTest();
        SVMXC__Case_Line__c insertedCL=[Select id,Show_On_Case__c from SVMXC__Case_Line__c where id=:cl.id];
        //System.assert(insertedCL.Show_On_Case__c==true, 'Show on case is not set to True');     
    }
    /*******************************************************************************************************
    * author - Preetha[QACM-18]
    * @description test method check Show On Case for Additionl products negative senario
    * 
    */
    static testMethod void testcheckShowOnCase1(){
        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        objProduct.Source_System__c='SAP';
        insert objProduct;

        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Product__c=objProduct.Id;
        insert objInstalledProduct;

        Case objCase1 = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase1.SVMXC__Component__c = objInstalledProduct.Id; 
        ObjCase1.Sub_Type__c = 'Complaint';
        objCase1.Date_of_Issue_Awareness__c = Date.Today();
        insert objCase1;
       
        SVMXC__Case_Line__c cl = New SVMXC__Case_Line__c();
        cl.SVMXC__Case__c = objCase1.id;
        cl.SVMXC__Product__c = objProduct.id;
        cl.Show_On_Case__c = true;
        insert cl;
        test.startTest();
        SVMXC__Case_Line__c cl1= New SVMXC__Case_Line__c();
        cl1.SVMXC__Case__c = objCase1.id;
        cl1.SVMXC__Product__c = objProduct.id;
        insert cl1;
        test.stopTest();
        SVMXC__Case_Line__c insertedCL=[Select id,Show_On_Case__c from SVMXC__Case_Line__c where id=:cl1.id];
        //System.assert(insertedCL.Show_On_Case__c==false, 'Show on case is not set to true');     
    }
    /*******************************************************************************************************
    * author - Preetha[QACM-18]
    * @description test method checkShowOnCase Exception in the catch block
    * 
    */
    @isTest
    static void testcheckShowOnCaseException() {
        Test.startTest();
        try {
            CaseLines.checkShowOnCase(null);
        } catch (Exception e) {
            System.assertEquals('Script-thrown exception',e.getMessage(),'Unhandled Error');
        }
        Test.stopTest();
    }
   
}