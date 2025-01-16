/***************************************************************************************************************************************
* NAME         : TestProactiveRunDetails
* DESCRIPTION  : Test class for ProactiveRunDetails Trigger
*                    
* @AUTHOR      : Raviteja Vakkalagadda
* @DATE        : 16-11-2021  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/

@isTest public class TestProactiveRunDetails {
    static Case cs;
    public static final String STRING_ACCOUNT = 'Test Acc';
    public static final String STRING_WO_RECORDTYPE = 'Field Service';
    public static final String STRING_WO_ORDER_TYPE = 'Service Activities';
    
/***************************************************************************************
* Author: Raviteja
* Description: Initial Test data setup of Account,contact,Product,IP,Case and Work Order
* Params :None
*****************************************************************************************/
    
    @testSetup 
    public static void initializeTestData() {
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c = 'Distributor';
        insert acc;
        
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null);
        
        //Product Record to reference in IP
        Product2 objProduct = TestDataFieldService.createProduct('TestProduct', 'Instrument');
        objProduct.Product_Category__c = 'MiSeq';
        objProduct.ProductCode = 'TestProduct';
        insert objProduct;
        
        //Installed Product
        SVMXC__Installed_Product__c objInstalledProduct=TestDataFieldService.createInstalledProduct('TestIP', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        objInstalledProduct.Operation_Status__c = 'Off';
        objInstalledProduct.SVMXC__Product__c = objProduct.Id;
        objInstalledProduct.SVMXC__Serial_Lot_Number__c = 'FS10001248';
        INSERT objInstalledProduct;
        
        cs = TestDataCase.initServiceRequestCase(con);
        cs.SVMXC__Component__c = objInstalledProduct.Id;
        insert cs;
        
        //Field Service Type of WO
        SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        wo.Evaluation__c = 'Test';
        wo.SVMXC__Work_Performed__c = 'Test';
        wo.Verification_Result__c = 'Test'; 
        insert wo;
        System.assert(wo.Id != null);
        wo.SVMXC__Order_Status__c = 'Completed';
        wo.No_Calibrated_Tools_Used__c = true;
        wo.Is_Service_Report_Generated__c = true;
        wo.PO_Number__c = '12';
        wo.No_Calibrated_Tools_Used__c = true;
        Test.startTest();
        update wo;
        Test.stopTest();
        
        //Proactive Run Detail Record
        Proactive_Run_Detail__c prRec = new Proactive_Run_Detail__c();
        prRec.Work_Order__c = wo.Id;
        prRec.Case__c = cs.Id;
        prRec.Notes__c = 'TestNotes';
        prRec.Run_Status__c = 'complt';
        Insert prRec;
        
        //Proactive Run Detail Record
        Proactive_Run_Detail__c proRec = new Proactive_Run_Detail__c();
        proRec.Work_Order__c = wo.Id;
        proRec.Case__c = cs.Id;
        proRec.Notes__c = 'Test Notes';
        proRec.Run_Status__c = 'Completed';
        Insert proRec;
        // Create and Insert Associated_Product__c record
        Associated_Product__c assocProduct = new Associated_Product__c();
        assocProduct.Case__c = cs.Id; 
        assocProduct.Installed_Product__c = objInstalledProduct.id;
        assocProduct.Proactive_Run_Detail__c = proRec.id;
        assocProduct.Account__c = acc.Id;
        insert assocProduct;
    }
    
/***************************************************************************************
* Author: Raviteja
* Description: Test Method to cover the MiniSeq product category run metrics 'save' funtionality
* Params :None
*****************************************************************************************/
    
    static testMethod void testNotesUpdate() {
        Proactive_Run_Detail__c prdRec = [SELECT Id,Notes__c from Proactive_Run_Detail__c WHERE Run_Status__c = 'complt' limit 1];
        SVMXC__Service_Order__c workOrdRec = [SELECT Id,SVMXC__Order_Status__c from SVMXC__Service_Order__c limit 1];
        system.assertEquals('TestNotes', prdRec.Notes__c, 'Notes value on Proactive Run Detail not updated');
        system.debug('workOrdRec Status***'+workOrdRec.SVMXC__Order_Status__c);
        Test.startTest();
        try { 
            prdRec.Notes__c = 'TestNotesUpdate';
            update prdRec;
           } catch(Exception e) {
               system.debug(e);
           }
           Test.stopTest();
        
    }
    
/***************************************************************************************
* Author: Raviteja
* Description: Test Method to cover the Proactive Run Detail Delete 
* Params :None
* DCP-51097
*****************************************************************************************/
    
    static testMethod void testProactiveRunDetailDelete() {
        Test.startTest();
        Proactive_Run_Detail__c prdRec = [SELECT Id,Notes__c from Proactive_Run_Detail__c WHERE Run_Status__c = 'complt' limit 1];
        system.assertNotEquals(null,prdRec,'Proactive Record is Not Fetched');
        DELETE prdRec;  
        Test.stopTest();
    }
/***************************************************************************************
* Author: Abhishek
* Description: Test Method to cover the Proactive Run Detail Delete 
* Params :None
* CMCM-303
*****************************************************************************************/
    static testMethod void testProactiveRunDetailAssociatedRecordDelete() {
        Test.startTest();
        Feature.setMockFeatureFlag('ServiceAssociatedProducts', true);
        Proactive_Run_Detail__c prdRec = [SELECT Id,Notes__c from Proactive_Run_Detail__c WHERE Run_Status__c = 'Completed' limit 1];
        system.assertNotEquals(null,prdRec,'Proactive Record Fetched');    
        DELETE prdRec;
        List<Associated_product__c> acList = [SELECT Name FROM Associated_product__c WHERE Proactive_Run_Detail__c = :prdRec.Id LIMIT 1];
        Assert.isTrue(acList.isEmpty());
        Test.stopTest();
    }
}