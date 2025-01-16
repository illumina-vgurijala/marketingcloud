/***************************************************************************************************************************************
 * NAME   : TestInventoryDataReceiver
 * DESCRIPTION  : TestClass for InventoryDataReceiver class.
                  Annotated with SeeAllData=true due to dependency on ServiceMax managed trigger
                    
 * @AUTHOR : Vaibhav
 * @DATE   : 22-May-2018  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Vaibhav             22-May-2018            Initial Version
* KD                    25-June-2021           DCP-46257 : Refactored code to include incremental sync
* Vineeta Verma         9-Jan-2025             PRB0047876: To add logic for Serialized+Batched Products
  ****************************************************************************************************************************************/
@IsTest(SeeAllData = true)
public class TestInventoryDataReceiver {
     
	public static final String STRING_BATCH_NUMBER_B1 = 'B-1';
    public static final String STRING_BATCH_NUMBER_B2 = 'B-2';
    private static final String STRING_CONTACT_FIRSTNAME = 'testfirstname';
    private static final String STRING_CONTACT_LASTNAME = 'testlastname';
    private static final String STRING_SOURCE_LOCATION = 'source location' ;
    private static final String STRING_PRODUCT_CODE = '43535';
    private static final String STRING_CURRENCY_CODE = 'USD' ;

    static InventoryDataReceiverWrapper.Location getInventoryJson(String indicator, String location, String product, String quantity, String status) {

        /****** POPULATE THE WRAPPER WITH DATA **************/

        //create stocked serial for product stock JSON.
        InventoryDataReceiverWrapper.StockedSerial stockedSerialRecords = new InventoryDataReceiverWrapper.StockedSerial();
        stockedSerialRecords.Name = '71781';
        stockedSerialRecords.Equipment_Id = '71781';

        //create stocked batch for product stock JSON.[DCp-31054]
        InventoryDataReceiverWrapper.StockedBatch stockedBatchRecords = new InventoryDataReceiverWrapper.StockedBatch();
        stockedBatchRecords.Batch_Number = STRING_BATCH_NUMBER_B1;
        stockedBatchRecords.Quantity = 16;

        //create product stock for Location JSON.
        InventoryDataReceiverWrapper.ProductStock productStockRecords = new InventoryDataReceiverWrapper.ProductStock();
        productStockRecords.SVMXC_Quantity2 = quantity;
        productStockRecords.SVMXC_Status = status;
        productStockRecords.SVMXC_Product = product;
        productStockRecords.StockedSerial.add(stockedSerialRecords);
        productStockRecords.StockedBatch.add(stockedBatchRecords);

        //create header for Location JSON.
        InventoryDataReceiverWrapper.Location locationRecords = new InventoryDataReceiverWrapper.Location();
        locationRecords.Action = indicator;
        locationRecords.Location = location;
        locationRecords.ProductStock.add(productStockRecords);


        //return the wrapper object.
        return locationRecords;
    }

    static testMethod void testInventoryInsertHTTPPost() {
    
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Integration SAP Service'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', FirstName='SNAP Service', LastName='Integration', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
         UserName=uniqueUserName);
        
        System.runAs(u) {
        //holds the wrapper records in list.
        List < InventoryDataReceiverWrapper.Location > lstInventoryRecords = new List < InventoryDataReceiverWrapper.Location > ();

        //get the wrapper object.
        //Passing new unique numbers will insert the data.
        InventoryDataReceiverWrapper.Location inventoryRecords = getInventoryJson('Upsert', '3231', '8182', '99', 'Available');

        //pass it over to a list.  
        lstInventoryRecords.add(inventoryRecords);

        //convert the apex list into a Json structure.
        String inventoryJSON = JSON.serialize(lstInventoryRecords);

        Test.startTest();

        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/InventorySyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(inventoryJSON);
        RestContext.request = req;
        RestContext.response = res;
        InventoryDataReceiver.upsertIncomingValues();

        Test.stopTest();

        //make sure the status is success.
        System.assertequals(200, res.statuscode);
        
        }

    }

    static testMethod void testInventoryUpdateHTTPPost() {
    
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Integration SAP Service'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', FirstName='SNAP Service', LastName='Integration', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
         UserName=uniqueUserName);

        Contact con = new Contact(FirstName = STRING_CONTACT_FIRSTNAME, LastName = STRING_CONTACT_LASTNAME);

        Case objCase = TestDataCase.initServiceRequestCase(con);
        insert objCase;

        //Create Source Location
        SVMXC__Site__c sourceLocation = new SVMXC__Site__c();
        sourceLocation.Name = STRING_SOURCE_LOCATION;
        //sourceLocation.SVMXC__Account__c = testAccount.Id;
        sourceLocation.SVMXC__Stocking_Location__c = true;
        sourceLocation.SVMX_PS_External_ID__c = '1234';
        insert sourceLocation;

        SVMXC__RMA_Shipment_Order__c partOrder = TestDataFieldService.createPartOrder('RMA', objCase.Id, 'Open');
        partOrder.SVMXC__Order_Type__c = 'Return';
        partOrder.Contact_Name__c = 'Test Contact';
        partOrder.Contact_Phone__c = '+100021';
        partOrder.Shipping_Location__c = sourceLocation.Id;
        insert partOrder;

        Product2 serializedProd = new Product2();
        serializedProd.Name = 'Test Serialized Product';
        serializedProd.IsActive = true;
        serializedProd.ProductCode = '0101';
        insert serializedProd;

        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(partOrder.Id);
        objPartsOrderLine.Requested_Delivery_Date__c = date.today();
        objPartsOrderLine.SVMXC__Line_Status__c = 'Open';
        objPartsOrderLine.Batch_Number__c = STRING_BATCH_NUMBER_B1;
        objPartsOrderLine.To_Location__c = sourceLocation.Id;
        objPartsOrderLine.SVMXC__Product__c = serializedProd.Id;
        objPartsOrderLine.SVMXC__Actual_Quantity2__c = 10;
        objPartsOrderLine.Consumed_QTY__c = 1;
        insert objPartsOrderLine;

        objPartsOrderLine.SVMXC__Line_Status__c = 'Shipped';

        update objPartsOrderLine;
        
        System.runAs(u) {
        //holds the wrapper records in list.
        List < InventoryDataReceiverWrapper.Location > lstInventoryRecords = new List < InventoryDataReceiverWrapper.Location > ();

        //get the wrapper object.
        //Passing new unique numbers will insert the data.
        InventoryDataReceiverWrapper.Location inventoryRecords = getInventoryJson('Override', '1234', '0101', '10', 'Available');

        //pass it over to a list.  
        lstInventoryRecords.add(inventoryRecords);

        //convert the apex list into a Json structure.
        String inventoryJSON = JSON.serialize(lstInventoryRecords);

        Test.startTest();

        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/InventorySyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(inventoryJSON);
        RestContext.request = req;
        RestContext.response = res;
        InventoryDataReceiver.upsertIncomingValues();

        Test.stopTest();

        //make sure the status is success.
        System.assertequals(200, res.statuscode);
        
        }

    }


    static testMethod void testInventoryAdjustment() {
    
         String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Integration SAP Service'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', FirstName='SNAP Service', LastName='Integration', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
         UserName=uniqueUserName);

        Contact con = new Contact(FirstName = STRING_CONTACT_FIRSTNAME, LastName = STRING_CONTACT_LASTNAME);

        Case objCase = TestDataCase.initServiceRequestCase(con);
        insert objCase;

        //Create Source Location
        SVMXC__Site__c sourceLocation = new SVMXC__Site__c();
        sourceLocation.Name = STRING_SOURCE_LOCATION;
        //sourceLocation.SVMXC__Account__c = testAccount.Id;
        sourceLocation.SVMXC__Stocking_Location__c = true;
        sourceLocation.SVMX_PS_External_ID__c = '1234';
        insert sourceLocation;

        SVMXC__RMA_Shipment_Order__c partOrder = TestDataFieldService.createPartOrder('RMA', objCase.Id, 'Open');
        partOrder.SVMXC__Order_Type__c = 'Return';
        partOrder.Contact_Name__c = 'Test Contact';
        partOrder.Contact_Phone__c = '+100021';
        partOrder.Shipping_Location__c = sourceLocation.Id;
        insert partOrder;

        Product2 serializedProd = new Product2();
        serializedProd.Name = 'Test Serialized Product';
        serializedProd.IsActive = true;
        serializedProd.ProductCode = '0101';
        insert serializedProd;

        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(partOrder.Id);
        objPartsOrderLine.Requested_Delivery_Date__c = date.today();
        objPartsOrderLine.SVMXC__Line_Status__c = 'Open';
        objPartsOrderLine.Batch_Number__c = STRING_BATCH_NUMBER_B1;
        objPartsOrderLine.To_Location__c = sourceLocation.Id;
        objPartsOrderLine.SVMXC__Product__c = serializedProd.Id;
        objPartsOrderLine.SVMXC__Actual_Quantity2__c = 32;
        objPartsOrderLine.Consumed_QTY__c = 1;
        insert objPartsOrderLine;

        objPartsOrderLine.SVMXC__Line_Status__c = 'Shipped';

        update objPartsOrderLine;
        
        System.runAs(u) {
        //holds the wrapper records in list.
        List < InventoryDataReceiverWrapper.Location > lstInventoryRecords = new List < InventoryDataReceiverWrapper.Location > ();

        //get the wrapper object.
        //Passing new unique numbers will insert the data.
        InventoryDataReceiverWrapper.Location inventoryRecords = getInventoryJson('Override', '1234', '0101', '10', 'Available');

        //pass it over to a list.  
        lstInventoryRecords.add(inventoryRecords);

        //convert the apex list into a Json structure.
        String inventoryJSON = JSON.serialize(lstInventoryRecords);

        Test.startTest();

        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/InventorySyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(inventoryJSON);
        RestContext.request = req;
        RestContext.response = res;
        InventoryDataReceiver.upsertIncomingValues();

        Test.stopTest();
        
        //make sure the status is success.
        System.assertequals(200, res.statuscode);
        }

    }


    static testMethod void negativeTest() {
        Test.startTest();

        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/InventorySyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = null;
        RestContext.request = req;
        RestContext.response = res;
        InventoryDataReceiver.upsertIncomingValues();

        Test.stopTest();
        System.assertequals(412, res.statuscode);
    }
    
    
    static testMethod void testProcessStockAndStockSerials() {
    
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Integration SAP Service'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', FirstName='SNAP Service', LastName='Integration', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
            UserName=uniqueUserName);

        Contact con = new Contact(FirstName = STRING_CONTACT_FIRSTNAME, LastName = STRING_CONTACT_LASTNAME);

        Case objCase = TestDataCase.initServiceRequestCase(con);
        insert objCase;
        
        List<Product2> lstProduct = new List<Product2>();

        Product2 prod = new Product2(Name='TestProd',
                                        //Auto_Create_Install_Work_Order__c=true,
                                        Auto_Create_Installation_Workflow__c = 'Auto Create Install Work Order and Service Request Case',
                                        Service_Product_Type__c='Instrument',
                                        Regulatory_Type__c='DX',
                                        IsActive=true,
                                        ProductCode=STRING_PRODUCT_CODE,
                                        Material_Number__c = '1111',
                                        Service_Level__c = 'GOLD'
                                    );    
        lstProduct.add(prod);

        Product2 prod2 = new Product2(Name='TestProd2',
        Service_Product_Type__c='Instrument',
        Regulatory_Type__c='DX',
        IsActive=true,
        ProductCode='0101',
        Material_Number__c = '1122',
        Service_Level__c = 'GOLD',
        Material_Group__c  = '41',
        Batch_Management__c = true,
        SVMXC__Enable_Serialized_Tracking__c = false
        );  
        lstProduct.add(prod2);
        
        Product2 prod3 = new Product2(Name='TestProd3',
        Service_Product_Type__c='Instrument',
        Regulatory_Type__c='DX',
        IsActive=true,
        ProductCode='20201',
        Material_Number__c = '20201',
        Service_Level__c = 'GOLD',
        Material_Group__c  = '20201',
        Batch_Management__c = true,
        SVMXC__Enable_Serialized_Tracking__c = true,
        SVMXC__Tracking__c = 'Serialized'
        );  
        lstProduct.add(prod3);

        insert lstProduct;

        //Create Source Location
        SVMXC__Site__c sourceLocation = new SVMXC__Site__c();
        sourceLocation.Name = STRING_SOURCE_LOCATION;
        sourceLocation.SVMXC__Stocking_Location__c = true;
        sourceLocation.SVMX_PS_External_ID__c = '1234';
        insert sourceLocation;
        
        List<SVMXC__Product_Stock__c> lstProductStock = new List<SVMXC__Product_Stock__c>();
        //Create Product Stock
        SVMXC__Product_Stock__c productStock = new SVMXC__Product_Stock__c(
        CurrencyIsoCode = STRING_CURRENCY_CODE,
        SVMXC__IsPartnerRecord__c = false,
        SVMXC__Location__c = sourceLocation.Id,   
        SVMXC__Product__c = prod.Id,
        SVMXC__Quantity2__c = 1.0,                                                                          
        SVMXC__Status__c = 'Available',
        SVMX_PS_External_ID__c = '123443535');
        lstProductStock.add(productStock);
        
        SVMXC__Product_Stock__c productStock1 = new SVMXC__Product_Stock__c(
        CurrencyIsoCode = STRING_CURRENCY_CODE,
        SVMXC__IsPartnerRecord__c = false,
        SVMXC__Location__c = sourceLocation.Id,   
        SVMXC__Product__c = prod2.Id,
        SVMXC__Quantity2__c = 2.0,                                                                          
        SVMXC__Status__c = 'Available',
        SVMX_PS_External_ID__c = '12340101');
        lstProductStock.add(productStock1);
        
        SVMXC__Product_Stock__c productStock2 = new SVMXC__Product_Stock__c(
        CurrencyIsoCode = STRING_CURRENCY_CODE,
        SVMXC__IsPartnerRecord__c = false,
        SVMXC__Location__c = sourceLocation.Id,   
        SVMXC__Product__c = prod2.Id,
        SVMXC__Quantity2__c = 10.0,                                                                          
        SVMXC__Status__c = 'Consumed');
        lstProductStock.add(productStock2);
        
        SVMXC__Product_Stock__c productStock3 = new SVMXC__Product_Stock__c(
        CurrencyIsoCode = STRING_CURRENCY_CODE,
        SVMXC__IsPartnerRecord__c = false,
        SVMXC__Location__c = sourceLocation.Id,   
        SVMXC__Product__c = prod3.Id,
        SVMXC__Quantity2__c = 1.0,                                                                          
        SVMXC__Status__c = 'Available',
        SVMX_PS_External_ID__c = '123420201');
        lstProductStock.add(productStock3);
        
        insert lstProductStock;

        List<SVMXC__Product_Serial__c> lstStockSerial = new List<SVMXC__Product_Serial__c>();
        //Create Stocked Serial
        SVMXC__Product_Serial__c objStockedSerial = new SVMXC__Product_Serial__c();
        objStockedSerial.Name='S-1';
        objStockedSerial.SVMXC__Product__c = prod.Id;
        objStockedSerial.SVMXC__Product_Stock__c = productStock.Id;
        objStockedSerial.SVMX_PS_External_ID__c = '1234' +objStockedSerial.Name;
        lstStockSerial.add(objStockedSerial);
        
        SVMXC__Product_Serial__c objStockedSerial1 = new SVMXC__Product_Serial__c();
        objStockedSerial1.SVMXC__Product__c = prod2.Id;
        objStockedSerial1.SVMXC__Product_Stock__c = productStock1.Id;
        objStockedSerial1.Batch_Number__c = STRING_BATCH_NUMBER_B2;
        objStockedSerial1.Quantity__c = 2;
        objStockedSerial1.SVMX_PS_External_ID__c = '1234' + '0101' + STRING_BATCH_NUMBER_B2;
        lstStockSerial.add(objStockedSerial1);

        SVMXC__Product_Serial__c objStockedSerial2 = new SVMXC__Product_Serial__c();
        objStockedSerial2.SVMXC__Product__c = prod2.Id;
        objStockedSerial2.SVMXC__Product_Stock__c = productStock2.Id;
        objStockedSerial2.Batch_Number__c = STRING_BATCH_NUMBER_B2;
        objStockedSerial2.Quantity__c = 10;
        objStockedSerial2.SVMX_PS_External_ID__c = '1234' + '0101' + STRING_BATCH_NUMBER_B2 + 'Consumed';
        lstStockSerial.add(objStockedSerial2);
        
        SVMXC__Product_Serial__c objStockedSerial3 = new SVMXC__Product_Serial__c();
        objStockedSerial3.Name='S-3';
        objStockedSerial3.SVMXC__Product__c = prod3.Id;
        objStockedSerial3.SVMXC__Product_Stock__c = productStock3.Id;
        objStockedSerial3.SVMX_PS_External_ID__c = '1234' +objStockedSerial3.Name;
        objStockedSerial3.Batch_Number__c = '202001';
        lstStockSerial.add(objStockedSerial3);
        
        insert lstStockSerial;
                
            System.runAs(u) {
        //holds the wrapper records in list.
        List < InventoryDataReceiverWrapper.Location > lstInventoryRecords = new List < InventoryDataReceiverWrapper.Location > ();

        //create header for Location JSON.
        InventoryDataReceiverWrapper.Location locationRecords = new InventoryDataReceiverWrapper.Location();
        locationRecords.Location = '1234';
        InventoryDataReceiverWrapper.ProductStock serialProductStockRecords = getProductStockJsonForSerialAndBatch('1234', STRING_PRODUCT_CODE,'0', 'Available');
        InventoryDataReceiverWrapper.ProductStock batchProductStockRecords = getProductStockJsonForSerialAndBatch('1234', '0101', '1', 'Available');
        InventoryDataReceiverWrapper.ProductStock serialBatchedProductStockRecords1 = getProductStockJsonForSerialAndBatch('1234', '20201','0', 'Available');
        
        serialProductStockRecords.StockedSerial.add(getSerialJson('71818'));
        batchProductStockRecords.StockedBatch.add(getBatchJson(STRING_BATCH_NUMBER_B1,1));
        batchProductStockRecords.StockedBatch.add(getBatchJson(STRING_BATCH_NUMBER_B2,1));
        
        locationRecords.ProductStock.add(serialProductStockRecords);
        locationRecords.ProductStock.add(batchProductStockRecords);
		locationRecords.ProductStock.add(serialBatchedProductStockRecords1);
        system.debug('## : locationRecords : ' + locationRecords);
        //pass it over to a list.  
        lstInventoryRecords.add(locationRecords);

        //convert the apex list into a Json structure.
        String inventoryJSON = JSON.serialize(lstInventoryRecords);

        Test.startTest();

        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/InventorySyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(inventoryJSON);
        RestContext.request = req;
        RestContext.response = res;
        InventoryDataReceiver.upsertIncomingValues();

        Test.stopTest();
        System.debug('res.statuscode--'+res.statuscode);
        //make sure the status is success.
        System.assertequals(200, res.statuscode);
        }
        
    
    }


    static InventoryDataReceiverWrapper.ProductStock getProductStockJsonForSerialAndBatch(String location, String product, String quantity, String status) {

        InventoryDataReceiverWrapper.ProductStock productStockRecords = new InventoryDataReceiverWrapper.ProductStock();
        productStockRecords.SVMXC_Quantity2 = quantity;
        productStockRecords.SVMXC_Status = status;
        productStockRecords.SVMXC_Product = product;
        //return the wrapper object.
        return productStockRecords;
    }

    static InventoryDataReceiverWrapper.StockedSerial getSerialJson(String serialNumber) {
        //create stocked serial for product stock JSON.
        InventoryDataReceiverWrapper.StockedSerial stockedSerialRecords = new InventoryDataReceiverWrapper.StockedSerial();
        stockedSerialRecords.Name = serialNumber;
        stockedSerialRecords.Equipment_Id = serialNumber;
        return stockedSerialRecords;
    }
   
    static InventoryDataReceiverWrapper.StockedBatch getBatchJson(String batchNumber, Decimal quantity) {
        //create stocked batch for product stock JSON.[DCp-31054]
        InventoryDataReceiverWrapper.StockedBatch stockedBatchRecords = new InventoryDataReceiverWrapper.StockedBatch();
        stockedBatchRecords.Batch_Number = batchNumber;
        stockedBatchRecords.Quantity = quantity;
        return stockedBatchRecords;
    }
    /*
      *  @author : KD
      *  @description - DCP-46257 : Inventory sync incremental
      */
      static testMethod void testIncrementalSync() {
      
          User objUser = [Select id from User where Profile.Name = 'Integration Service SnapLogic' and IsActive = true].get(0);
          Contact con = new Contact(FirstName = STRING_CONTACT_FIRSTNAME, LastName = STRING_CONTACT_LASTNAME);
  
          Case objCase = TestDataCase.initServiceRequestCase(con);
          insert objCase;
          
          List<Product2> lstProduct = new List<Product2>();
  
          Product2 prod = new Product2(Name='TestProd',
                                          //Auto_Create_Install_Work_Order__c=true,
                                          Auto_Create_Installation_Workflow__c = 'Auto Create Install Work Order and Service Request Case',
                                          Service_Product_Type__c='Instrument',
                                          Regulatory_Type__c='DX',
                                          IsActive=true,
                                          ProductCode=STRING_PRODUCT_CODE,
                                          Material_Number__c = '1111',
                                          Service_Level__c = 'GOLD'
                                      );    
          lstProduct.add(prod);
  
          insert lstProduct;
  
          //Create Source Location
          SVMXC__Site__c sourceLocation = new SVMXC__Site__c();
          sourceLocation.Name = STRING_SOURCE_LOCATION;
          sourceLocation.SVMXC__Stocking_Location__c = true;
          sourceLocation.SVMX_PS_External_ID__c = 'SOURCE1';
          insert sourceLocation;
          
          List<SVMXC__Product_Stock__c> lstProductStock = new List<SVMXC__Product_Stock__c>();
          //Create Product Stock
          SVMXC__Product_Stock__c productStock = new SVMXC__Product_Stock__c(
          CurrencyIsoCode = STRING_CURRENCY_CODE,
          SVMXC__IsPartnerRecord__c = false,
          SVMXC__Location__c = sourceLocation.Id,   
          SVMXC__Product__c = prod.Id,
          SVMXC__Quantity2__c = 1.0,                                                                          
          SVMXC__Status__c = 'Available',
          SVMX_PS_External_ID__c = 'SOURCE143535');
          lstProductStock.add(productStock);
          
          insert lstProductStock;
  
          List<SVMXC__Product_Serial__c> lstStockSerial = new List<SVMXC__Product_Serial__c>();
          //Create Stocked Serial
          SVMXC__Product_Serial__c objStockedSerial = new SVMXC__Product_Serial__c();
          objStockedSerial.SVMXC__Product__c = prod.Id;
          objStockedSerial.SVMXC__Product_Stock__c = productStock.Id;
          lstStockSerial.add(objStockedSerial);
          
          SVMXC__Product_Serial__c objStockedSerial1 = new SVMXC__Product_Serial__c();
          objStockedSerial1.SVMXC__Product__c = prod.Id;
          objStockedSerial1.SVMXC__Product_Stock__c = productStock.Id;
          objStockedSerial1.Batch_Number__c = STRING_BATCH_NUMBER_B2;
          objStockedSerial1.Quantity__c = 1;
          objStockedSerial1.SVMX_PS_External_ID__c = 'SOURCE143535' + STRING_BATCH_NUMBER_B2;
          lstStockSerial.add(objStockedSerial1);
          
          insert lstStockSerial;
                  
          System.runAs(objUser) {
              //holds the wrapper records in list.
              List < InventoryDataReceiverWrapper.Location > lstInventoryRecords = new List < InventoryDataReceiverWrapper.Location > ();
  
              //create header for Location JSON.
              InventoryDataReceiverWrapper.Location locationRecords = new InventoryDataReceiverWrapper.Location();
              locationRecords.Action = 'IncrementStock';
              locationRecords.Location = 'SOURCE1';
              InventoryDataReceiverWrapper.ProductStock serialProductStockRecords = getProductStockJsonForSerialAndBatch('SOURCE1', STRING_PRODUCT_CODE,'1', 'Available');
              
              serialProductStockRecords.StockedSerial.add(getSerialJson('71818'));
              serialProductStockRecords.StockedBatch.add(getBatchJson(STRING_BATCH_NUMBER_B2,1));
  
              locationRecords.ProductStock.add(serialProductStockRecords);
  
              system.debug('## : locationRecords : ' + locationRecords);
              //pass it over to a list.  
              lstInventoryRecords.add(locationRecords);
  
              //convert the apex list into a Json structure.
              String inventoryJSON = JSON.serialize(lstInventoryRecords);
  
              Test.startTest();
  
              //As Per Best Practice it is important to instantiate the Rest Context 
              RestRequest req = new RestRequest();
              RestResponse res = new RestResponse();
              req.requestURI = '/services/apexrest/InventorySyncInterface';
              req.httpMethod = 'POST';
              req.requestBody = Blob.valueof(inventoryJSON);
              RestContext.request = req;
              RestContext.response = res;
              InventoryDataReceiver.upsertIncomingValues();
  
              Test.stopTest();
              //make sure the status is success.
              System.assertequals(200, res.statuscode,'Integration Not Success');
              List<SVMXC__Product_Stock__c> lstProductStockUpdated = [Select id,SVMXC__Quantity2__c from SVMXC__Product_Stock__c where  SVMX_PS_External_ID__c = 'SOURCE143535'];
              system.assertequals(2,lstProductStockUpdated[0].SVMXC__Quantity2__c,'Product Stock quantitity not updated');
              List<SVMXC__Product_Serial__c> lstProductStockBatchUpdated = [Select id,Quantity__c from SVMXC__Product_Serial__c where  SVMX_PS_External_ID__c = 'SOURCE143535B-2'];
              system.assertequals(2,lstProductStockBatchUpdated[0].Quantity__c,'Product Stock Batch quantitity not updated');
              List<SVMXC__Product_Serial__c> lstProductStockSerialUpdated = [Select id,Quantity__c from SVMXC__Product_Serial__c where  SVMX_PS_External_ID__c = 'SOURCE171818'];
              system.assert(!lstProductStockSerialUpdated.isEmpty(),'Product Stock Serial not inserted');
          }
          
      
      }

      /*
*  @author : Sai
*  @description - CM-138 : UNABLE_TO_LOCK_ROW
*/
    static testMethod void testLockRow() {  
        Boolean exceptionThrown = false;
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Integration SAP Service'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
                          EmailEncodingKey='UTF-8', FirstName='SNAP Service', LastName='Integration', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = p.Id,
                          TimeZoneSidKey='America/Los_Angeles',
                          UserName=uniqueUserName);

        System.runAs(u) {
            //holds the wrapper records in list.
            List < InventoryDataReceiverWrapper.Location > lstInventoryRecords = new List < InventoryDataReceiverWrapper.Location > ();

            //get the wrapper object.
            //Passing new unique numbers will insert the data.
            InventoryDataReceiverWrapper.Location inventoryRecords = getInventoryJson('', '0987654321', '799565423655126', '10', 'Available');

            //pass it over to a list.  
            lstInventoryRecords.add(inventoryRecords);

            //convert the apex list into a Json structure.
            String inventoryJSON = JSON.serialize(lstInventoryRecords);
            try{
                Test.startTest();

                //As Per Best Practice it is important to instantiate the Rest Context 
                RestRequest req = new RestRequest();
                RestResponse res = new RestResponse();
                req.requestURI = '/services/apexrest/InventorySyncInterface';
                req.httpMethod = 'POST';
                req.requestBody = Blob.valueof(inventoryJSON);
                RestContext.request = req;
                RestContext.response = res;

                InventoryDataReceiver.testCodeCoverage = true;
                InventoryDataReceiver.upsertIncomingValues();
                Test.stopTest();
            }
            catch(Exception ex) {
                exceptionThrown = ex.getMessage().contains('UNABLE_TO_LOCK_ROW');
            }
            System.assert(exceptionThrown, true);
        }
    }
}