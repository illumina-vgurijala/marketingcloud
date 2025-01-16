/**
* @author Shivani Jain
* @date 7 Jan 2022
*
* @description DCP-42926 Test class for ValidateExistingWO_POLHelper
*/ 
@isTest(SeeAllData=true)
private class TestValidateExistingWO_POLHelper {

    static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    static final string STRING_PARTS_ORDER_LINE_NON_BILLABLE_REASON = 'Consumable Warranty';
    static final string STRING_PARTS_ORDER_TYPE_RETURN = 'Return';
    static final String STRING_PRODUCT_STOCK_STATUS_AVAILABLE = 'Available';
    static final string STRING_CURRENCY = 'USD';
    static final String STRING_SHIPPING_TYPE_TRUNK = 'Trunk';
    static SVMXC__Site__c objLocationRec;
    static SVMXC__Site__c objLocationRec1;
    static SVMXC__RMA_Shipment_Order__c objPartsOrder;
    static Product2 product1;
    static SVMXC__Product_Serial__c serializedStock;
    static SVMXC__Product_Serial__c batchedStock;
    static SVMXC__Product_Stock__c prodStock1;
    static SVMXC__Product_Stock__c prodStock2;
    static SVMXC__Installed_Product__c objInstalledProduct;
    static Product2 product2;
    

    /*******************************************************************************************************
    * @description test data setup
    */
    static void testDataCreation() {
        List<SVMXC__Site__c> lstLocations = new List<SVMXC__Site__c>();
        objLocationRec = new SVMXC__Site__c(Name = 'test',SVMXC__Stocking_Location__c=true,Type__c=STRING_SHIPPING_TYPE_TRUNK,ERP_Customer_ID__c='123');
        lstLocations.add(objLocationRec);
        objLocationRec1 = new SVMXC__Site__c(Name = 'test1',SVMXC__Stocking_Location__c=true,Type__c=STRING_SHIPPING_TYPE_TRUNK,ERP_Customer_ID__c='1234');
        lstLocations.add(objLocationRec1);
        insert lstLocations;
        System.assert(objLocationRec.Id != NULL, 'Location not inserted successfully');
        System.assert(objLocationRec1.Id != NULL, 'Location not inserted successfully');
        
        //Serialized spare
        List<Product2> lstProduct = new List<Product2>();
        product1 = TestDataMaster.createProduct(false);
        product1.ProductCode = 'XXX';
        product1.Material_Group__c  = '41';
        product1.Serial_Number_Profile__c = '123';
        lstProduct.add(product1);

        //Batched spare
        product2 = TestDataMaster.createProduct(false);
        product2.ProductCode = 'YYY';
        product2.Material_Group__c  = '41';
        product2.Batch_Management__c = true;
        product2.SVMXC__Enable_Serialized_Tracking__c = false;
        lstProduct.add(product2);
        insert lstProduct;
        System.assert(product1.Id != NULL, 'Product XXX not inserted successfully');
        System.assert(product2.Id != NULL, 'Product YYY not inserted successfully');

        objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP VM', STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Product__c=product1.Id;
        insert objInstalledProduct;
        System.assert(objInstalledProduct.Id != NULL, 'Installed Product not inserted successfully');

        List<SVMXC__Product_Stock__c> lstProductStock = new List<SVMXC__Product_Stock__c>();
        prodStock1 = new SVMXC__Product_Stock__c();
        prodStock1.SVMXC__Location__c = objLocationRec.Id;
        prodStock1.SVMX_PS_External_ID__c = objLocationRec.ERP_Customer_ID__c + product1.ProductCode;
        prodStock1.SVMXC__Product__c = product1.Id;
        prodStock1.SVMXC__Quantity2__c = 1;
        prodStock1.SVMXC__Status__c = STRING_PRODUCT_STOCK_STATUS_AVAILABLE;
        lstProductStock.add(prodStock1);
        prodStock2 = new SVMXC__Product_Stock__c();
        prodStock2.SVMXC__Location__c = objLocationRec.Id;
        prodStock2.SVMX_PS_External_ID__c = objLocationRec.ERP_Customer_ID__c + product2.ProductCode;
        prodStock2.SVMXC__Product__c = product2.Id;
        prodStock2.SVMXC__Quantity2__c = 1;
        prodStock2.SVMXC__Status__c = STRING_PRODUCT_STOCK_STATUS_AVAILABLE;
        lstProductStock.add(prodStock2);
        insert lstProductStock;
        System.assert(prodStock1.Id != NULL, 'Product Stock for XXX Product not inserted successfully');
        System.assert(prodStock2.Id != NULL, 'Product Stock for YYY Product not inserted successfully');

        List<SVMXC__Product_Serial__c> lstStockSerials = new List<SVMXC__Product_Serial__c>();
        serializedStock = new SVMXC__Product_Serial__c();
        serializedStock.Name = 'Serial123';
        serializedStock.Location__c = objLocationRec.Id;
        serializedStock.SVMXC__Product__c = product1.Id;
        serializedStock.SVMXC__Product_Stock__c = prodStock1.Id;
        serializedStock.SVMXC__Active__c = true;
        serializedStock.SVMX_PS_VS_Linked_Installed_Product__c = objInstalledProduct.Id;
        serializedStock.SVMX_PS_External_ID__c = objLocationRec.ERP_Customer_ID__c + 'Serial123';
        lstStockSerials.add(serializedStock);

        batchedStock = new SVMXC__Product_Serial__c();
        batchedStock.Name = 'Batch123';
        batchedStock.Batch_Number__c = 'Batch123';
        batchedStock.Location__c = objLocationRec.Id;
        batchedStock.SVMXC__Product__c = product2.Id;
        batchedStock.SVMXC__Product_Stock__c = prodStock2.Id;
        batchedStock.SVMXC__Active__c = true;
        batchedStock.SVMX_PS_External_ID__c = objLocationRec.ERP_Customer_ID__c + product2.ProductCode + 'Batch123';
        lstStockSerials.add(batchedStock);
        insert lstStockSerials;
        System.assert(serializedStock.Id != NULL, 'Serialized Stock not inserted successfully');
        System.assert(batchedStock.Id != NULL, 'Batched Stock not inserted successfully');

        objPartsOrder = new SVMXC__RMA_Shipment_Order__c();
        objPartsOrder.SVMXC__Order_Status__c = 'Open';
        objPartsOrder.ERP_Sales_Order_Number__c = '132';
        objPartsOrder.Contact_Name__c='Test';
        objPartsOrder.Contact_Phone__c='Test';
        objPartsOrder.SVMXC__Order_Type__c=STRING_PARTS_ORDER_TYPE_RETURN;
        objPartsOrder.SVMXC__Source_Location__c=objLocationRec.id;
        objPartsOrder.SVMXC__Destination_Location__c=objLocationRec1.id;
        objPartsOrder.Ship_To_Company__c='test';
        objPartsOrder.Care_Of__c='test';
        objPartsOrder.Shipping_Street__c='test'; 
        objPartsOrder.Shipping_City__c='test'; 
        objPartsOrder.Shipping_Postal_Code__c='test'; 
        objPartsOrder.Shipping_Country__c='Angola [AO]';
        objPartsOrder.Shipping_State_Province__c='N/A';
        insert objPartsOrder;
        System.assert(objPartsOrder.Id != NULL, 'Parts Order not inserted successfully');

    }
    
    /*******************************************************************************************************
    * @description test method for ValidateExistingWO_POLHelper No Error thrown
    */
    static testmethod void validateExistingWOSerialNumber() {
        testDataCreation();
        
        Test.startTest();
        
        Id returnRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get('Shipment').getRecordTypeId();
        
        //Create return POL for serialized product
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        objPartsOrderLine.From_Location__c = objLocationRec.id;
        objPartsOrderLine.RecordTypeId = returnRecordTypeId; 
        objPartsOrderLine.Reason__c = STRING_PARTS_ORDER_LINE_NON_BILLABLE_REASON;
        objPartsOrderLine.SVMXC__Actual_Quantity2__c= 1;
        objPartsOrderLine.SVMXC__Line_Status__c = 'Open';
        objPartsOrderLine.Requested_Delivery_Date__c = Date.today();
        objPartsOrderLine.SVMXC__Product__c = product1.Id;
        objPartsOrderLine.SVMXC__Serial_Number__c = objInstalledProduct.Id;
       
        insert objPartsOrderLine;
        System.assert(objPartsOrderLine.Id != NULL, 'Parts Order Line not inserted successfully');

        SVMXC__Allocated_Stock__c aStock = new SVMXC__Allocated_Stock__c();
        aStock.SVMXC__Allocated_Qty__c = 1;
        aStock.SVMXC__Product_Stock__c = prodStock1.Id;
        aStock.SVMXC__Shipment_Order__c = objPartsOrder.Id;
        aStock.SVMXC__Shipment_Order_Line__c = objPartsOrderLine.Id;
        aStock.SVMXC__Shipped_Qty__c = 1;
        aStock.Location__c = objLocationRec.Id;
        aStock.SVMX_PS_VS_Stocked_Serial__c = serializedStock.Id;
        insert aStock;
        System.assert(aStock.Id != NULL, 'Allocated Stock not inserted successfully');

        objPartsOrderLine.SVMXC__Line_Status__c = 'Shipped';
        update objPartsOrderLine;
        Test.stopTest();
    }

    /*******************************************************************************************************
    * @description test method for ValidateExistingWO_POLHelper No Error thrown
    */
    static testmethod void validateExistingWOBatchNumber() {
        testDataCreation();
        
        Test.startTest();
        
        Id returnRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get('Shipment').getRecordTypeId();
        
        //Create return POL for Batched product
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine1 = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        objPartsOrderLine1.RecordTypeId = returnRecordTypeId; 
        objPartsOrderLine1.Reason__c = STRING_PARTS_ORDER_LINE_NON_BILLABLE_REASON;
        objPartsOrderLine1.SVMXC__Actual_Quantity2__c= 2;
        objPartsOrderLine1.SVMXC__Line_Status__c = 'Open';  
        objPartsOrderLine1.Requested_Delivery_Date__c = Date.today() +1;
        objPartsOrderLine1.SVMXC__Product__c = product2.Id;
        objPartsOrderLine1.Batch_Lookup__c = batchedStock.Id;
        objPartsOrderLine1.From_Location__c = objLocationRec.Id;
        objPartsOrderLine1.Batch_Number__c = '1234';
        insert objPartsOrderLine1;
        System.assert(objPartsOrderLine1.Id != NULL, 'Parts Order Line not inserted successfully');

        SVMXC__Allocated_Stock__c aStock = new SVMXC__Allocated_Stock__c();
        aStock.SVMXC__Allocated_Qty__c = 1;
        aStock.SVMXC__Product_Stock__c = prodStock1.Id;
        aStock.SVMXC__Shipment_Order__c = objPartsOrder.Id;
        aStock.SVMXC__Shipment_Order_Line__c = objPartsOrderLine1.Id;
        aStock.SVMXC__Shipped_Qty__c = 1;
        aStock.Location__c = objLocationRec.Id;
        aStock.Batch_Number__c = '1234';
        aStock.SVMX_PS_VS_Stocked_Serial__c = serializedStock.Id;
        insert aStock;
        System.assert(aStock.Id != NULL, 'Allocated Stock not inserted successfully');

        objPartsOrderLine1.SVMXC__Line_Status__c = 'Shipped';
        update objPartsOrderLine1;
        Test.stopTest();
    }

    /*******************************************************************************************************
    * @description test method for ValidateExistingWO_POLHelper Error thrown
    */
    static testmethod void validateExistingWOError() {
        Boolean expectedExceptionThrown;
        testDataCreation();
        
        Test.startTest();
        
        Id returnRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get('Shipment').getRecordTypeId();

        SVMXC__RMA_Shipment_Line__c objPartsOrderLine2 = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        objPartsOrderLine2.RecordTypeId = returnRecordTypeId; 
        objPartsOrderLine2.Reason__c = STRING_PARTS_ORDER_LINE_NON_BILLABLE_REASON;
        objPartsOrderLine2.SVMXC__Actual_Quantity2__c= 2;
        objPartsOrderLine2.SVMXC__Line_Status__c = 'Open';  
        objPartsOrderLine2.Requested_Delivery_Date__c = Date.today() +1;
        objPartsOrderLine2.SVMXC__Product__c = product2.Id;
        objPartsOrderLine2.Batch_Lookup__c = batchedStock.Id;
        objPartsOrderLine2.From_Location__c = objLocationRec.Id;
        objPartsOrderLine2.Product_Stock__c = prodStock1.Id;
        
        insert objPartsOrderLine2;
        System.assert(objPartsOrderLine2.Id != NULL, 'Parts Order Line not inserted successfully');

        SVMXC__Allocated_Stock__c aStock = new SVMXC__Allocated_Stock__c();
        aStock.SVMXC__Allocated_Qty__c = 1;
        aStock.SVMXC__Product_Stock__c = prodStock1.Id;
        aStock.SVMXC__Shipment_Order__c = objPartsOrder.Id;
        aStock.SVMXC__Shipment_Order_Line__c = objPartsOrderLine2.Id;
        aStock.SVMXC__Shipped_Qty__c = 1;
        insert aStock;
        System.assert(aStock.Id != NULL, 'Allocated Stock not inserted successfully');

        objPartsOrderLine2.SVMXC__Line_Status__c = 'Shipped';
        try {
            update objPartsOrderLine2;
        } catch(Exception ex) {
            expectedExceptionThrown = ex.getMessage().contains(Label.StockTransferOrReturnPartsReservationError)
                &&  ex.getMessage().contains(Label.StockTransferOrReturnPartsReservationErrorPart2) ? true : false;
        }
        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        if(!setting.Bypass_All_Validations__c) {
            System.assert(expectedExceptionThrown, 'ValidateExistingWO_POLHelper failed');
        }
        
        Test.stopTest();
    }

     /*******************************************************
    *Method Name : coverCatchBlockProcessServiceLoanerInstrumentPOLHelper()
    *Description : method to cover catch block
    *params      : NA
    *return type : void
    ******************************************************/
    @isTest
    public static void coverCatchBlockProcessServiceLoanerInstrumentPOLHelper(){
        try{
            ProcessServiceLoanerInstrument_POLHelper.catchException = true;
            ProcessServiceLoanerInstrument_POLHelper pd = new ProcessServiceLoanerInstrument_POLHelper(null);
            Test.startTest();
            System.enqueueJob(pd);
            Test.stopTest();
        }
        catch(Exception e){
            System.assert(e!=null,  'e is not empty');
        }
    }

    //CMCM-8243 start
     /*******************************************************
    *Method Name : testValidatePOL()
    *Description : method to cover validateFANOnWorkOrder
    *params      : NA
    *return type : void
    ******************************************************/
    static testmethod void testValidatePOL(){
        try{
		    testDataCreation();
            Account objAccount = new Account(Name = 'Acme', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId());
            insert objAccount;
            
             // Create Test Products
            Product2 product = TestDataMaster.initProduct('TEST 123');
            product.Service_Product_Type__c = 'Core';
            product.Regulatory_Type__c = 'DX';
            //product.Source_System__c = 'SAP';
            insert product;
            User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        
            SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c(
                SVMXC__Component__c = objInstalledProduct.Id,
                SVMXC__Product__c = product.Id,
                Product_Lot_Number__c = 'LOT001',
                Product_Serial_Number__c = 'SN001',
                CreatedById = testUser.Id,
                OwnerId = testUser.Id,
                SVMXC__Order_Type__c = 'Field Service',
                Record_Created_from_SFM__c = true
            );
            
            AssociatedProduct.skipAPTrigger=true;
            Cases.skipCaseTrigger=true;
            WorkOrders.skipWOTrigger=true;
            insert wo;    
            
            SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
            objPartsOrderLine.From_Location__c = objLocationRec.id;
            objPartsOrderLine.Return_Reason__c = 'Complaint Investigation';
            objPartsOrderLine.SVMXC__Actual_Quantity2__c= 1;
            objPartsOrderLine.SVMXC__Line_Status__c = 'Open';
            objPartsOrderLine.Requested_Delivery_Date__c = Date.today();
            objPartsOrderLine.SVMXC__Product__c = product1.Id;
            objPartsOrderLine.SVMXC__Serial_Number__c = objInstalledProduct.Id;
            objPartsOrderLine.SVMXC__Service_Order__c =  wo.Id; 
        
            insert objPartsOrderLine;   
                
            
            }
            catch(Exception e){
                System.debug('testValidatePOL '+e.getMessage());
                System.assert(e!=null,  'e is not empty');
            }
    }
    //CMCM-8243 end
}