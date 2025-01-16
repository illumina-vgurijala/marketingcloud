/**
* @author Prashanth
* @date 10 Dec 2021
*
* @description DCP-42926 Test class for public with sharing class PartsReversalBeforeUpdate_WDHelper.
*/ 
@isTest(SeeAllData=true)
public class TestPartsReversalBeforeUpdate_WDHelper {
    static final string STRING_CURRENCY = 'USD';
    static final String STRING_NON_TRACKED = 'Non-Tracked';
    static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    static final String STRING_INTEGRATIONSTATUS_SUCCESS = 'Success';
    static final String STRING_ORDER_TYPE_INSTALLATION = 'Installation';
    static User userInstance;
    static  Account objAccountTest1;
    static Contact objContactTest;
    static Product2 nonSerializedProdTest = new Product2();
    static Product2 serializedProdTest = new Product2();
    static SVMXC__Site__c locationTest = new SVMXC__Site__c();
    static SVMXC__Installed_Product__c objInstalledProduct;
    static SVMXC__Product_Stock__c nonserializedProdStockTest= new SVMXC__Product_Stock__c();
    static SVMXC__Product_Stock__c serializedProdStockTest= new SVMXC__Product_Stock__c();
    static SVMXC__Product_Serial__c stockSerial = new SVMXC__Product_Serial__c();
    static Case objCase1;
    static SVMXC__Service_Order__c workOrder1;
    /**
     * Method: initializeTestData
     * Description: Method to load the initinal data.
     */
    public static void initializeTestData() {
        userInstance = [SELECT Id 
                               FROM User 
                               WHERE Profile.Name =: System.Label.Integration_Service_SNAP_Profile AND isActive=true
                               LIMIT 1]; 
        objAccountTest1 = TestDataAccount.initAccount(); //create account
        objAccountTest1.Account_Group__c = 'Distributor';
        insert objAccountTest1;
                       
        objContactTest = TestDataContact.getNewContact(objAccountTest1); //create contact.

        nonSerializedProdTest.Name = 'Test Non-Serialized Product';
        nonSerializedProdTest.IsActive = true;
        nonSerializedProdTest.SVMXC__Tracking__c = STRING_NON_TRACKED;
        nonSerializedProdTest.SVMXC__Stockable__c = true;
        nonSerializedProdTest.SVMXC__Enable_Serialized_Tracking__c = false;
        
        //Create serialized product
        serializedProdTest.Name = 'Test Serialized Product';
        serializedProdTest.IsActive = true;
        serializedProdTest.SVMXC__Tracking__c = 'Serialized';
        serializedProdTest.SVMXC__Stockable__c = true;
        serializedProdTest.SVMXC__Enable_Serialized_Tracking__c = true;
        serializedProdTest.Serial_Number_Profile__c = 'IL01';
        serializedProdTest.FRU_Eligible__c = 'FRU use only';
        serializedProdTest.ProductCode = '2172';

        //Create locationTest1
        locationTest.Name = 'Test Location 1';
        locationTest.SVMXC__Account__c = objAccountTest1.Id;
        locationTest.SVMXC__Stocking_Location__c = true;
        insert locationTest;

        //create Installed Product
        objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP VM', STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Company__c = objAccountTest1.Id;
        objInstalledProduct.SVMXC__Product__c = serializedProdTest.Id;
        insert objInstalledProduct;

        nonserializedProdStocktest.SVMXC__Location__c = locationTest.id;
        nonserializedProdStocktest.SVMXC__Product__c = nonSerializedProdTest.Id;
        nonserializedProdStocktest.SVMXC__Status__c = 'Available';
        nonserializedProdStocktest.SVMXC__Quantity2__c = 2;

        //Create serialized product stock
        serializedProdStockTest.SVMXC__Location__c = locationTest.id;
        serializedProdStockTest.SVMXC__Product__c = serializedProdTest.Id;
        serializedProdStockTest.SVMXC__Status__c = 'Available';
        serializedProdStockTest.SVMXC__Quantity2__c = 2;

        stockSerial.SVMXC__Active__c = true;
        stockSerial.SVMXC__Product__c = serializedProdTest.Id;
        stockSerial.SVMXC__Product_Stock__c = serializedProdStockTest.Id;
        stockSerial.Name = '0987654321';

        objCase1 = TestDataCase.initServiceRequestCase(objContactTest);
        objCase1.SVMXC__Component__c = objInstalledProduct.Id;
        insert objCase1;
        Test.startTest();
        workOrder1 = TestDataFieldService.createworkOrder('Field Service', objCase1.Id, 'Initiated');
        workOrder1.SVMXC__Company__c = objAccountTest1.id;
        workOrder1.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder1.SVMXC__Order_Type__c = STRING_ORDER_TYPE_INSTALLATION;
        workOrder1.Is_Auto_Created__c = true;
        insert workOrder1; 
        Test.stopTest();

    }
    /**
     * Method:testPartsReversalBeforeUpdate
     * Description: Test method to test parts reversal functionality.
     */
    static testmethod void testPartsReversalBeforeUpdate(){
        initializeTestData();
        //Create non serialized product
        List<Product2> productLst = new List<Product2>();
        productLst.add(nonSerializedProdTest);
        productLst.add(serializedProdTest);  
        insert productLst;
        
        //Create non serialized product stock
        List<SVMXC__Product_Stock__c> productStockLst = new List<SVMXC__Product_Stock__c>();
        productStockLst.add(nonSerializedProdStockTest);
        productStockLst.add(serializedProdStockTest);
        insert productStockLst;
    
        //Insert stock serials for serialized product stock
        List<SVMXC__Product_Serial__c> stockedSerialList = new List<SVMXC__Product_Serial__c>();
        stockedSerialList.add(stockSerial);
        insert stockedSerialList;
        
        SVMXC__Service_Order_Line__c objOrderDetail1Test1 = new SVMXC__Service_Order_Line__c();
        objOrderDetail1Test1.SVMXC__Service_Order__c = workOrder1.id;
        objOrderDetail1Test1.SVMXC__Consumed_From_Location__c = locationTest.Id;
        objOrderDetail1Test1.SVMX_PS_VS_Consumed_Product_Stock__c = SerializedProdStockTest.Id;
        objOrderDetail1Test1.SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial.Id;
        objOrderDetail1Test1.SVMXC__Product__c = serializedProdTest.id;
        objOrderDetail1Test1.SVMXC__Line_Type__c = 'Parts';
        objOrderDetail1Test1.SVMXC__Line_Status__c = 'closed';
        objOrderDetail1Test1.SVMX_PS_VS_Consumed_Status__c = '2022-08-09 09:54:48 : Consumption Success : Part Consumption Successful';
        objOrderDetail1Test1.Consumption_Confirmed__c = true;
        objOrderDetail1Test1.SVMXC__Actual_Quantity2__c = 1;
        objOrderDetail1Test1.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        objOrderDetail1Test1.SVMX_PS_VS_Return_Installed_Product__c = objInstalledProduct.Id;
        objOrderDetail1Test1.SVMX_PS_External_ID__c='2323';
        
        insert objOrderDetail1Test1;
        
        System.runAs(userInstance){
        
        objOrderDetail1Test1.SVMXC__Line_Status__c = 'Canceled';
        objOrderDetail1Test1.Integration_Status__c = STRING_INTEGRATIONSTATUS_SUCCESS;        
        try{
                update objOrderDetail1Test1;
            }catch(Exception e){
                System.assert(e.getMessage() != null);
            }
        
        }
        
    }
    /**
     * Method:testPartsReversalBeforeUpdate1
     * Description: Test method to test parts reversal functionality.
     */
    static testmethod void testPartsReversalBeforeUpdate1(){   
        initializeTestData();

        //Create non serialized product
        List<Product2> productLst = new List<Product2>();
        productLst.add(nonSerializedProdTest);
        productLst.add(serializedProdTest);  
        insert productLst;
    
        //Create non serialized product stock
        List<SVMXC__Product_Stock__c> productStockLst = new List<SVMXC__Product_Stock__c>();
        productStockLst.add(nonSerializedProdStockTest);
        productStockLst.add(serializedProdStockTest);
        insert productStockLst;
    
        //Insert stock serials for serialized product stock
        List<SVMXC__Product_Serial__c> stockedSerialList = new List<SVMXC__Product_Serial__c>();
        stockedSerialList.add(stockSerial);
        
        SVMXC__Service_Order_Line__c objOrderDetail1Test2 = new SVMXC__Service_Order_Line__c();
        objOrderDetail1Test2.SVMXC__Service_Order__c = workOrder1.id;
        objOrderDetail1Test2.SVMXC__Consumed_From_Location__c = locationTest.Id;
        objOrderDetail1Test2.SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStockTest.Id;
        //objOrderDetail1Test2.SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial1Test.Id;
        objOrderDetail1Test2.SVMXC__Product__c = serializedProdTest.id;
        objOrderDetail1Test2.SVMXC__Line_Type__c = 'Parts';
        objOrderDetail1Test2.SVMXC__Line_Status__c = 'closed';
        objOrderDetail1Test2.SVMX_PS_VS_Consumed_Status__c = '2022-08-09 09:54:48 : Consumption Success : Part Consumption Successful';
        objOrderDetail1Test2.Consumption_Confirmed__c = true;
        objOrderDetail1Test2.SVMXC__Actual_Quantity2__c = 1;
        objOrderDetail1Test2.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        objOrderDetail1Test2.SVMX_PS_VS_Return_Installed_Product__c = objInstalledProduct.Id;
        objOrderDetail1Test2.SVMX_PS_External_ID__c='2323';
        objOrderDetail1Test2.Batch_Number__c = '89217';
        insert objOrderDetail1Test2;
        
        System.runAs(userInstance){
        
            objOrderDetail1Test2.SVMXC__Line_Status__c = 'Canceled';
            objOrderDetail1Test2.Integration_Status__c = STRING_INTEGRATIONSTATUS_SUCCESS;
                try{
                    update objOrderDetail1Test2;
                }catch(Exception e){
                    System.assert(e.getMessage() != null);
                }
            
        
        }
        
    }
    /**
     * Method:testPartsReversalBeforeUpdate2
     * Description: Test method to test parts reversal functionality.
     */
    static testmethod void testPartsReversalBeforeUpdate2(){   
        initializeTestData();
    
        //Create non serialized product
        List<Product2> productLst = new List<Product2>();
        productLst.add(nonSerializedProdTest);  
        productLst.add(serializedProdTest);  
        insert productLst;
    
        //Create non serialized product stock
        List<SVMXC__Product_Stock__c> productStockLst = new List<SVMXC__Product_Stock__c>();
        productStockLst.add(nonSerializedProdStockTest);
        productStockLst.add(serializedProdStockTest);
        insert productStockLst;
    
        //Insert stock serials for serialized product stock
        List<SVMXC__Product_Serial__c> stockedSerialList = new List<SVMXC__Product_Serial__c>();
        stockedSerialList.add(stockSerial);
        insert stockedSerialList;
        
        SVMXC__Service_Order_Line__c objOrderDetail1Test3 = new SVMXC__Service_Order_Line__c();
        objOrderDetail1Test3.SVMXC__Service_Order__c = workOrder1.id;
        objOrderDetail1Test3.SVMXC__Consumed_From_Location__c = locationTest.Id;
        objOrderDetail1Test3.SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStockTest.Id;
        //objOrderDetail1Test3.SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial1Test.Id;
        objOrderDetail1Test3.SVMXC__Product__c = serializedProdTest.id;
        objOrderDetail1Test3.SVMXC__Line_Type__c = 'Parts';
        objOrderDetail1Test3.SVMXC__Line_Status__c = 'closed';
        objOrderDetail1Test3.SVMX_PS_VS_Consumed_Status__c = '2022-08-09 09:54:48 : Consumption Success : Part Consumption Successful';
        objOrderDetail1Test3.Consumption_Confirmed__c = true;
        objOrderDetail1Test3.SVMXC__Actual_Quantity2__c = 1;
        objOrderDetail1Test3.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        objOrderDetail1Test3.SVMX_PS_VS_Return_Installed_Product__c = objInstalledProduct.Id;
        objOrderDetail1Test3.SVMX_PS_External_ID__c='2323';
        
        insert objOrderDetail1Test3;
        
        System.runAs(userInstance){
            
            objOrderDetail1Test3.SVMXC__Line_Status__c = 'Canceled';
            objOrderDetail1Test3.Integration_Status__c = STRING_INTEGRATIONSTATUS_SUCCESS;
                try{
                    update objOrderDetail1Test3;
                }catch(Exception e){
                    System.assert(e.getMessage() != null);
                }
            
        
        }
        
    }
     /**
     * Method:testPartsReversalBeforeUpdate3
     * Description: Test method to test parts reversal functionality.
     */
	static testmethod void testPartsReversalBeforeUpdate3(){   
        initializeTestData();
        //Create non serialized product
        List<Product2> productLst = new List<Product2>();
        productLst.add(serializedProdTest);  
        insert productLst;

        List<SVMXC__Product_Stock__c> productStockLst = new List<SVMXC__Product_Stock__c>();
        productStockLst.add(serializedProdStockTest);
        insert productStockLst;
    
        //Insert stock serials for serialized product stock
        List<SVMXC__Product_Serial__c> stockedSerialList = new List<SVMXC__Product_Serial__c>();
        stockedSerialList.add(stockSerial);
        insert stockedSerialList;
        System.assert(stockedSerialList.size() > 0);
        
        SVMXC__Service_Order_Line__c objOrderDetail1Test4 = new SVMXC__Service_Order_Line__c();
        objOrderDetail1Test4.SVMXC__Line_Type__c = 'Parts';
        objOrderDetail1Test4.SVMXC__Line_Status__c = 'closed';
        objOrderDetail1Test4.SVMX_PS_VS_Consumed_Status__c = '2022-08-09 09:54:48 : Consumption Success : Part Consumption Successful';
        System.runAs(userInstance){
            PartsReversalBeforeUpdate_WDHelper.validateErrors(objOrderDetail1Test4, objOrderDetail1Test4);
            objOrderDetail1Test4.SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStockTest.Id;
            objOrderDetail1Test4.SVMXC__Product__c = serializedProdTest.id;
            PartsReversalBeforeUpdate_WDHelper.validateErrors(objOrderDetail1Test4, objOrderDetail1Test4);
            objOrderDetail1Test4.SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial.Id;
            PartsReversalBeforeUpdate_WDHelper.validateErrors(objOrderDetail1Test4, objOrderDetail1Test4);
            
        
        }
        
    }
}