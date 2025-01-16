/***************************************************************************************************************************************
* NAME         : TestBatchUpdateWorkOrders
* DESCRIPTION  : Test class for BatchUpdateWorkOrders
*                    
* @AUTHOR      : 
* @DATE        : 23-march-2022  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Prashanth               23-03-2022            Original version
* --------------------------------------------------------------------------------------------------------------------------------------
****************************************************************************************************************************************/
@isTest
public class TestBatchUpdateWorkOrders {
    public static final String STRING_WO_RECORDTYPE_REMOTE_SUPPORT = 'Remote Support';
    public static final String STRING_ACCOUNT = 'Test Acc';
    static testmethod void updateWorkOrdersTest(){
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null);
        //insert case        
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        insert objProduct;
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        objInstalledProduct.Operation_Status__c='Off';
        objInstalledProduct.SVMXC__Product__c = objProduct.Id;
        insert objInstalledProduct;
        
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE_REMOTE_SUPPORT, cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;
        Test.startTest();
        BatchUpdateWorkOrders ba= new BatchUpdateWorkOrders();
        Id jobId = Database.executeBatch(ba);
        ba.processFailureRecords(new Map<Id, String> {workOrder.Id => 'error'},jobId);
        Test.stopTest();
        System.assertEquals(null , [Select Id, Repair_protocols__c from SVMXC__Service_Order__c where Id =: workOrder.Id].Repair_protocols__c, 'Repair Protocol not matched!');
    }
}