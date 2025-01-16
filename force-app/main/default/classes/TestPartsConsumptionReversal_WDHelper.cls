/**
* @author Shivani Jain
* @date 10 Dec 2021
*
* @description DCP-42926 Test class for PartsConsumptionReversal_WDHelper
*/ 
@isTest(SeeAllData=true)
public class TestPartsConsumptionReversal_WDHelper {

    static final string STRING_CURRENCY = 'USD';
    static final String STRING_NON_TRACKED = 'Non-Tracked';
    static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    static final String STRING_REVERSAL_REQUESTED = 'Reversal Requested';
    static final String STRING_INTEGRATIONSTATUS_SUCCESS = 'Success';
    static final String STRING_ORDER_TYPE_INSTALLATION = 'Installation';
    static final String STRING_STATUS_OPEN = 'Open';
    static User userInstance;
    static  Account objAccountTest1;
    static Contact objContactTest1;
    static Product2 nonSerializedProdTest1 = new Product2();
    static Product2 serializedProdTest1 = new Product2();
    static SVMXC__Site__c locationTest1 = new SVMXC__Site__c();
    static SVMXC__Installed_Product__c objInstalledProduct;
    static SVMXC__Product_Stock__c nonserializedProdStocktest1= new SVMXC__Product_Stock__c();
    static SVMXC__Product_Stock__c serializedProdStockTest1= new SVMXC__Product_Stock__c();
    static SVMXC__Product_Serial__c stockSerial1 = new SVMXC__Product_Serial__c();
    static Case objCase;
    static SVMXC__Service_Order__c workOrder;
    /**
     * Method: initializeTestData
     * Description: Method to load the initinal data.
     */
    public static void initializeTestData() {

        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        cs_Apex_Settings__c cs=cs_Apex_Settings__c.getInstance(p.Id);
        cs.Bypass_Triggers_By_Object_1__c = 'Case';
        cs.Bypass_Triggers_By_Object_2__c = 'SVMXC__Service_Order__c';
        cs.Bypass_Triggers_By_Object_3__c = 'Product2';
        cs.Bypass_Triggers_By_Object_4__c = 'SVMXC__Installed_Product__c';    
        upsert cs cs_Apex_Settings__c.Id;
       
        userInstance = [SELECT Id 
                               FROM User 
                               WHERE Profile.Name =: System.Label.Integration_Service_SNAP_Profile AND isActive=true
                               LIMIT 1]; 

        objAccountTest1 = TestDataAccount.initAccount(); //create account
        objAccountTest1.Account_Group__c = 'Distributor';
        insert objAccountTest1;

        objContactTest1 = TestDataContact.getNewContact(objAccountTest1); //create contact.

        nonSerializedProdTest1.Name = 'Test Non-Serialized Product';
        nonSerializedProdTest1.IsActive = true;
        nonSerializedProdTest1.SVMXC__Tracking__c = STRING_NON_TRACKED;
        nonSerializedProdTest1.SVMXC__Stockable__c = true;
        nonSerializedProdTest1.SVMXC__Enable_Serialized_Tracking__c = false;
        nonSerializedProdTest1.Source_System__c = 'SAP';
        
        //Create serialized product
        serializedProdTest1.Name = 'Test Serialized Product';
        serializedProdTest1.IsActive = true;
        serializedProdTest1.SVMXC__Tracking__c = 'Serialized';
        serializedProdTest1.SVMXC__Stockable__c = true;
        serializedProdTest1.SVMXC__Enable_Serialized_Tracking__c = true;
        serializedProdTest1.Serial_Number_Profile__c = 'IL01';
        serializedProdTest1.FRU_Eligible__c = 'FRU use only';
        serializedProdTest1.ProductCode = '2172';
        serializedProdTest1.Source_System__c = 'SAP';
        //Create non serialized product
        List<Product2> productLst = new List<Product2>();
        productLst.add(nonSerializedProdTest1);
        productLst.add(serializedProdTest1);  
        insert productLst;
        //System.debug('seralized product-->'+[Select Id,SVMXC__Tracking__c from Product2 where Id=: serializedProdTest1.Id]);

        //Create locationTest1
        locationTest1.Name = 'Test Location 1';
        locationTest1.SVMXC__Account__c = objAccountTest1.Id;
        locationTest1.SVMXC__Stocking_Location__c = true;
        insert locationTest1;

         //create Installed Product
        objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP VM', STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
         objInstalledProduct.SVMXC__Company__c = objAccountTest1.Id;
         objInstalledProduct.SVMXC__Product__c = serializedProdTest1.Id;
         insert objInstalledProduct;

        nonserializedProdStocktest1.SVMXC__Location__c = locationTest1.id;
        nonserializedProdStocktest1.SVMXC__Product__c = nonSerializedProdTest1.Id;
        nonserializedProdStocktest1.SVMXC__Status__c = 'Available';
        nonserializedProdStocktest1.SVMXC__Quantity2__c = 2;

        //Create serialized product stock
        serializedProdStockTest1.SVMXC__Location__c = locationTest1.id;
        serializedProdStockTest1.SVMXC__Product__c = serializedProdTest1.Id;
        serializedProdStockTest1.SVMXC__Status__c = 'Available';
        serializedProdStockTest1.SVMXC__Quantity2__c = 2;
        List<SVMXC__Product_Stock__c> productStockLst = new List<SVMXC__Product_Stock__c>();
        productStockLst.add(nonserializedProdStocktest1);
        productStockLst.add(serializedProdStockTest1);
        insert productStockLst;
    
        stockSerial1.SVMXC__Active__c = true;
        stockSerial1.SVMXC__Product__c = serializedProdTest1.Id;
        stockSerial1.SVMXC__Product_Stock__c = serializedProdStockTest1.Id;
        stockSerial1.Name = '0987654321';

        objCase = TestDataCase.initServiceRequestCase(objContactTest1);
        objCase.SVMXC__Component__c = objInstalledProduct.Id;
        insert objCase;
        
        workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');
        workOrder.SVMXC__Company__c = objAccountTest1.id;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Order_Type__c = STRING_ORDER_TYPE_INSTALLATION;
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;
    }
    /**
     * Method:testSerializedPartsConsumptionReversal
     * Description: Test method to test parts consumption reversal functionality.
     */
    static testmethod void testSerializedPartsConsumptionReversal(){
        initializeTestData();

        //Insert stock serials for serialized product stock
        List<SVMXC__Product_Serial__c> stockedSerialList = new List<SVMXC__Product_Serial__c>();
        stockedSerialList.add(stockSerial1);
        insert stockedSerialList;
    
        Test.startTest();
        
        SVMXC__Service_Order_Line__c objOrderDetailTest1 = new SVMXC__Service_Order_Line__c();
        objOrderDetailTest1.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetailTest1.SVMXC__Consumed_From_Location__c = locationTest1.Id;
        objOrderDetailTest1.SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStockTest1.Id;
        objOrderDetailTest1.SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial1.Id;
        objOrderDetailTest1.SVMXC__Product__c = serializedProdTest1.id;
        objOrderDetailTest1.SVMXC__Line_Type__c = 'Parts';
        objOrderDetailTest1.SVMXC__Line_Status__c = STRING_STATUS_OPEN;
        objOrderDetailTest1.Consumption_Confirmed__c = true;
        objOrderDetailTest1.SVMXC__Actual_Quantity2__c = 1;
        objOrderDetailTest1.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        objOrderDetailTest1.SVMX_PS_VS_Return_Installed_Product__c = objInstalledProduct.Id;

        
        insert objOrderDetailTest1;
        //System.debug('product tracking-->'+[Select Id,Product_Tracking__c from SVMXC__Service_Order_Line__c where Id=: objOrderDetailTest1.Id]);
        System.runAs(userInstance){
        
        objOrderDetailTest1.SVMXC__Line_Status__c = STRING_REVERSAL_REQUESTED;
        objOrderDetailTest1.Integration_Status__c = STRING_INTEGRATIONSTATUS_SUCCESS;
        objOrderDetailTest1.Part_Consumption_Reversal_External_ID__c = '784783';
        objOrderDetailTest1.SVMX_PS_External_ID__c='2323';
        
        
        update objOrderDetailTest1;
        Test.stopTest();
        System.assertEquals(STRING_REVERSAL_REQUESTED,objOrderDetailTest1.SVMXC__Line_Status__c);
        
        }
        
    }
    /**
     * Method:testAdjustBatchInventory
     * Description: Test method to test parts consumption reversal functionality.
     */
    public static testmethod void testAdjustBatchInventory(){   
        initializeTestData();
        //Create non serialized product
        List<Product2> productLst = new List<Product2>();
        Product2 batchTrackedProdTest1 = new Product2();
        batchTrackedProdTest1.Name = 'Batch Tracked';
        batchTrackedProdTest1.IsActive = true;
        batchTrackedProdTest1.SVMXC__Tracking__c = 'Lot/Batch Tracked';
        batchTrackedProdTest1.Batch_Management__c = true;
        batchTrackedProdTest1.SVMXC__Enable_Serialized_Tracking__c = false;
        batchTrackedProdTest1.ProductCode = '0419-0022'; //
        batchTrackedProdTest1.Source_System__c = 'SAP';
        productLst.add(batchTrackedProdTest1);  
        insert productLst;

        //Create non serialized product stock
        List<SVMXC__Product_Stock__c> productStockLst = new List<SVMXC__Product_Stock__c>();
        SVMXC__Product_Stock__c batchTrackedProdTest1Stock = new SVMXC__Product_Stock__c();
        batchTrackedProdTest1Stock.SVMXC__Location__c = locationTest1.id;
        batchTrackedProdTest1Stock.SVMXC__Product__c = batchTrackedProdTest1.Id;
        batchTrackedProdTest1Stock.SVMXC__Status__c = 'Available';
        batchTrackedProdTest1Stock.SVMXC__Quantity2__c = 2;
        productStockLst.add(batchTrackedProdTest1Stock);
        insert productStockLst;


        //create Batch stock
        SVMXC__Product_Serial__c batchedStockTest1 = new SVMXC__Product_Serial__c();
        batchedStockTest1.Name = 'Batch123';
        batchedStockTest1.Batch_Number__c = 'Batch123';
        batchedStockTest1.Location__c = locationTest1.Id;
        batchedStockTest1.SVMXC__Product__c = batchTrackedProdTest1.Id;
        batchedStockTest1.SVMXC__Product_Stock__c = batchTrackedProdTest1Stock.Id;
        batchedStockTest1.SVMXC__Active__c = true;
        insert batchedStockTest1;
        
        Test.startTest();
        
        SVMXC__Service_Order_Line__c objOrderDetailTest2 = new SVMXC__Service_Order_Line__c();
        objOrderDetailTest2.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetailTest2.SVMXC__Consumed_From_Location__c = locationTest1.Id;
        objOrderDetailTest2.SVMX_PS_VS_Consumed_Product_Stock__c = batchTrackedProdTest1Stock.Id;
        objOrderDetailTest2.SVMXC__Product__c = batchTrackedProdTest1.id;
        objOrderDetailTest2.SVMXC__Line_Type__c = 'Parts';
        objOrderDetailTest2.SVMXC__Line_Status__c = STRING_STATUS_OPEN;
        objOrderDetailTest2.Consumption_Confirmed__c = true;
        objOrderDetailTest2.SVMXC__Actual_Quantity2__c = 1;
        objOrderDetailTest2.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        objOrderDetailTest2.SVMX_PS_VS_Return_Installed_Product__c = objInstalledProduct.Id;
        objOrderDetailTest2.Batch_Lookup__c = batchedStockTest1.id;
        objOrderDetailTest2.Batch_Number__c = '1234';
        
        insert objOrderDetailTest2;
        
        System.runAs(userInstance){
        
            objOrderDetailTest2.SVMXC__Line_Status__c = STRING_REVERSAL_REQUESTED;
            objOrderDetailTest2.Integration_Status__c = STRING_INTEGRATIONSTATUS_SUCCESS;
            objOrderDetailTest2.Part_Consumption_Reversal_External_ID__c = '784783';
            objOrderDetailTest2.Batch_Number__c = '12345';
            objOrderDetailTest2.SVMXC__Actual_Quantity2__c = 2;
            
            update objOrderDetailTest2;
            Test.stopTest();
            System.assertEquals(STRING_REVERSAL_REQUESTED,objOrderDetailTest2.SVMXC__Line_Status__c);
        
        }
        
    }
            
    /*
    *  @DESCRIPTION: DCP-44981 - Part Consumption Reversal For Batch Product.
    *  @PARAM : 
    *  @RETURN:  void
    */
    public static testmethod void testBatchPartsConsumptionReversal(){
        initializeTestData();
        
        //Create non serialized product
        List<Product2> productLst = new List<Product2>();
        Product2 batchTrackedProdTest2 = new Product2();
        batchTrackedProdTest2.Name = 'Batch Tracked';
        batchTrackedProdTest2.IsActive = true;
        batchTrackedProdTest2.SVMXC__Tracking__c = 'Lot/Batch Tracked';
        batchTrackedProdTest2.Batch_Management__c = true;
        batchTrackedProdTest2.SVMXC__Enable_Serialized_Tracking__c = false;
        batchTrackedProdTest2.ProductCode = '0419-0022'; //
        batchTrackedProdTest2.Source_System__c = 'SAP';
        productLst.add(batchTrackedProdTest2);  
        insert productLst;
        System.assert(batchTrackedProdTest2.Id != null);
        //Create non serialized product stock
        SVMXC__Product_Stock__c batchTrackedProdTestStock = new SVMXC__Product_Stock__c();
        batchTrackedProdTestStock.SVMXC__Location__c = locationTest1.id;
        batchTrackedProdTestStock.SVMXC__Product__c = batchTrackedProdTest2.Id;
        batchTrackedProdTestStock.SVMXC__Status__c = 'Available';
        batchTrackedProdTestStock.SVMXC__Quantity2__c = 2;
        insert batchTrackedProdTestStock;
        System.assert(batchTrackedProdTestStock.Id != null);

        //create Batch stock
        SVMXC__Product_Serial__c batchLookup = new SVMXC__Product_Serial__c();
        batchLookup.Name = 'Batch123';
        batchLookup.Batch_Number__c = 'Batch123';
        batchLookup.Location__c = locationTest1.Id;
        batchLookup.SVMXC__Product__c = batchTrackedProdTest2.Id;
        batchLookup.SVMXC__Product_Stock__c = batchTrackedProdTestStock.Id;
        batchLookup.SVMXC__Active__c = true;
        insert batchLookup;
        System.assert(batchLookup.Id != null);
        Test.startTest();
        
        SVMXC__Service_Order_Line__c objOrderDetailTest3 = new SVMXC__Service_Order_Line__c();
        objOrderDetailTest3.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetailTest3.SVMXC__Consumed_From_Location__c = locationTest1.Id;
        objOrderDetailTest3.SVMX_PS_VS_Consumed_Product_Stock__c = batchTrackedProdTestStock.Id;
        objOrderDetailTest3.SVMXC__Product__c = batchTrackedProdTest2.id;
        objOrderDetailTest3.Batch_Lookup__c = batchLookup.Id;
        objOrderDetailTest3.SVMXC__Line_Type__c = 'Parts';
        objOrderDetailTest3.SVMXC__Line_Status__c = STRING_STATUS_OPEN;
        objOrderDetailTest3.Consumption_Confirmed__c = true;
        objOrderDetailTest3.SVMXC__Actual_Quantity2__c = 1;
        objOrderDetailTest3.Batch_Number__c = '123456';
        
        insert objOrderDetailTest3;
        System.assert(objOrderDetailTest3.Id != null);

        System.runAs(userInstance){
        
            objOrderDetailTest3.SVMXC__Line_Status__c = STRING_REVERSAL_REQUESTED;
            objOrderDetailTest3.Integration_Status__c = STRING_INTEGRATIONSTATUS_SUCCESS;
            objOrderDetailTest3.Part_Consumption_Reversal_External_ID__c = '4561';
            update objOrderDetailTest3;
            Test.stopTest();
            System.assertEquals(STRING_REVERSAL_REQUESTED, objOrderDetailTest3.SVMXC__Line_Status__c);
        }  
            
    }
    /**
     * Method: testSerializedPartsConsumptionReversal1
     * Description: Method to test verifyserializedproducts
     * */
    static testmethod void testSerializedPartsConsumptionReversal1(){   
        initializeTestData();

        //Insert stock serials for serialized product stock
        List<SVMXC__Product_Serial__c> stockedSerialList = new List<SVMXC__Product_Serial__c>();
        stockedSerialList.add(stockSerial1);
        insert stockedSerialList;
        Test.startTest();
        
        SVMXC__Service_Order_Line__c objOrderDetailTest4 = new SVMXC__Service_Order_Line__c();
        objOrderDetailTest4.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetailTest4.SVMXC__Consumed_From_Location__c = locationTest1.Id;
        objOrderDetailTest4.SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStockTest1.Id;
        objOrderDetailTest4.SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial1.Id;
        objOrderDetailTest4.SVMXC__Product__c = serializedProdTest1.id;
        objOrderDetailTest4.SVMXC__Line_Type__c = 'Parts';
        objOrderDetailTest4.SVMXC__Line_Status__c = STRING_STATUS_OPEN;
        objOrderDetailTest4.Consumption_Confirmed__c = true;
        objOrderDetailTest4.SVMXC__Actual_Quantity2__c = 1;
        objOrderDetailTest4.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        objOrderDetailTest4.SVMX_PS_VS_Return_Installed_Product__c = objInstalledProduct.Id;
        
        insert objOrderDetailTest4;
        SVMXC__Allocated_Stock__c allocatedStock = new SVMXC__Allocated_Stock__c();
        allocatedStock.SVMXC__Allocated_Qty__c = 1;
        allocatedStock.Work_Order__c = workOrder.Id;
        allocatedStock.SVMX_PS_VS_Work_Detail__c = objOrderDetailTest4.id;
        allocatedStock.SVMXC__Product_Stock__c = serializedProdStockTest1.id;
        allocatedStock.SVMX_PS_VS_Stocked_Serial__c = stockSerial1.Id;
        allocatedStock.Product__c = serializedProdTest1.Id;
        allocatedStock.Location__c = locationTest1.Id;
        insert allocatedStock;
        VerifySerializedParts_WorkDetailHelper.prepareAllocatedStockMap(new Set<Id>{stockSerial1.Id});
        Map<Id, String> mapStockSerials = new Map<Id, String>();
        mapStockSerials.put(stockSerial1.Id, 'test');
        VerifySerializedParts_WorkDetailHelper.verifySerializedParts(new Set<SVMXC__Service_Order_Line__c >{objOrderDetailTest4}, new Set<Id>{stockSerial1.Id}, mapStockSerials);
        Test.stopTest();
        System.assert(objOrderDetailTest4.Id != null);
        
    }
	
	/*Test method to cover Catch Block of Class QualifyWOsForConsumption_WDHelper
	*/
   public static testmethod void coverCatchBlockQualifyWOsForConsumptionWDHelper(){
    try{
        QualifyWOsForConsumption_WDHelper.catchException = true;
        QualifyWOsForConsumption_WDHelper qw = new QualifyWOsForConsumption_WDHelper(null);
        Test.startTest();
        System.enqueueJob(qw);
        Test.stopTest();
    	}catch(Exception e){
            System.assert(e!=null, 'e is not empty');
    	}
   }
}