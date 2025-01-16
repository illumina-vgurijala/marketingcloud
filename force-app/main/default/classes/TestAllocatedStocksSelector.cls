//TestAllocatedStocksSelector 
/*
* @ author       : Romi
* @ date         : 30-Aug-2021
* @ Description  : Test class for AllocatedStocksSelector class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                              Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Romi                  30-Aug-2021                        Initial version
*/
@isTest
public class TestAllocatedStocksSelector {
    /**
     * @author: Romi
     * @decription: test method for selectAllocatedStockWithWd.
     */
    public testMethod static void selectAllocatedStockWithWdTest(){
        
        //insert Account
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;
        System.assert(acc.Id != null);
        
        //insert Contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null);
        
        //insert Case
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.Status = 'Initiated';
        insert cs;
        System.assert(cs.Id != null);
        
        //insert Work Order
        SVMXC__Service_Order__c workOrder2= TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder2.SVMXC__Company__c=acc.id;
        workOrder2.Is_Auto_Created__c = true;
        insert workOrder2;
        
        //insert Work Detail
        SVMXC__Service_Order_Line__c objWorkDetail = new SVMXC__Service_Order_Line__c();
        objWorkDetail.SVMXC__Service_Order__c = workOrder2.Id;
        insert objWorkDetail;
        
        Set<Id> setWD = new Set<Id>();
        setWD.add(objWorkDetail.Id);
        
        //insert Product
        Product2 objProduct = TestDataMaster.initProduct('1241527');
        objProduct.Service_Product_Type__c = 'Core';
        insert objProduct;
        
        //insert Product stock
        SVMXC__Product_Stock__c objProductStock = new SVMXC__Product_Stock__c();
        objProductStock.SVMXC__Product__c = objProduct.Id;
        insert objProductStock;
        
        Set<Id> setProductStock = new Set<Id>();
        setProductStock.add(objProductStock.Id);
        
        //insert Stocked Serial/Batch Detail
        SVMXC__Product_Serial__c objStockedSerial = new SVMXC__Product_Serial__c();
        objStockedSerial.SVMXC__Product__c = objProduct.Id;
        objStockedSerial.SVMXC__Product_Stock__c = objProductStock.Id;
        insert objStockedSerial;
        
        Set<Id> setSerialBatch = new Set<Id>();
        setSerialBatch.add(objStockedSerial.Id);

        //insert Location
        SVMXC__Site__c loc = TestDataFieldService.createLocation('ServiceLoc1', 'Stringing street New York', 'USA', '43527', 'USD');
        insert loc;
        
        Set<Id> setLocation = new Set<Id>();
        setLocation.add(loc.Id);
        
        SVMXC__Allocated_Stock__c objAllStock = new SVMXC__Allocated_Stock__c();
        objAllStock.SVMX_PS_VS_Work_Detail__c = objWorkDetail.Id;
        objAllStock.SVMXC__Allocated_Qty__c = 3;
        objAllStock.SVMXC__Product_Stock__c = objProductStock.Id;
        objAllStock.SVMX_PS_VS_Stocked_Serial__c = objStockedSerial.Id;
        objAllStock.Product__c = objProduct.Id;
        objAllStock.Location__c = loc.Id;
        objAllStock.Batch_Number__c = '3';
        objAllStock.Work_Order__c = workOrder2.Id;
        
        Set<String> str= new Set<String>();
        str.add('test');
        
        Test.startTest();
        AllocatedStocksSelector selector = new AllocatedStocksSelector();
        selector.selectAllocatedStockWithWd(setWD);
        selector.selectAllocatedStocksByBatchAndLocation(setLocation,str);
        selector.selectAllocatedStocksByStockSerialIds(setSerialBatch);
        selector.selectAllocatedStocksByProductStockIds(setProductStock);
        List<SVMXC__Allocated_Stock__c> lstAllStock = new AllocatedStocksSelector().selectAllocatedStockWithWd(setWD);
        system.assertNotEquals(null, lstAllStock.size());
        Test.stopTest();
        
    }
    
}