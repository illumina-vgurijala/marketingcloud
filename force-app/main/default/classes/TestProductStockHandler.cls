/***************************************************************************************************************************************
 * NAME   : TestProductStockHandler
 * DESCRIPTION  : TestClass for ProductStockHandler class. 
 * @AUTHOR : Prashanth
 * @DATE   : 07-Oct-2021
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Prashanth             07-Oct-2021             Initial Version
  ***************************************************************************************************************************************
*/
@isTest(SeeAllData=True)
public class TestProductStockHandler 
{
    
    public static final String STRING_SHIPPING_TYPE_TRUNK = 'Trunk';
    public static final String STRING_WORK_ORDER_RECORD_TYPE_SERVICE_SUPPORT = 'Service Support';
    public static final String STRING_WORK_ORDER_STATUS_INITIATED ='Initiated';
    public static final String STRING_WORK_ORDER_TYPE_INSTALLATION = 'Installation';
    public static final string STRING_COST_CENTER_CODE = '123';
    public static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP VM';
    public static final string STRING_CURRENCY = 'USD';
    public static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    public static final string STRING_PARTS_ORDER_LINE_NON_BILLABLE_REASON = 'Goodwill';
    public static final String STRING_PRODUCT_STOCK_STATUS_AVAILABLE = 'Available';
    public static final string STRING_PARTS_ORDER_TYPE_RETURN = 'Return';
    public static final String STRING_PARTS_ORDER_TYPE_REPLENISHMENT = 'Replenishment';
    //public static final String STRING_PARTS_ORDER_TYPE_STOCK_TRANSFER = 'Stock Transfer';

    static testmethod void validateWorkDetailCreationFromPO(){
    List<SVMXC__Site__c> lstLocations = new List<SVMXC__Site__c>();
        SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'test',SVMXC__Stocking_Location__c=true,Type__c=STRING_SHIPPING_TYPE_TRUNK);
    lstLocations.add(objLocationRec);
        SVMXC__Site__c objLocationRec1 = new SVMXC__Site__c(Name = 'test1',SVMXC__Stocking_Location__c=true,Type__c=STRING_SHIPPING_TYPE_TRUNK);
        lstLocations.add(objLocationRec1);
        insert lstLocations;
        
        //SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrderWithoutCase(STRING_WORK_ORDER_RECORD_TYPE_SERVICE_SUPPORT,STRING_WORK_ORDER_STATUS_INITIATED, STRING_WORK_ORDER_TYPE_INSTALLATION);
        SVMXC__Service_Order__c objWorkOrder= new SVMXC__Service_Order__c();
        objWorkOrder.RecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByName().get(STRING_WORK_ORDER_RECORD_TYPE_SERVICE_SUPPORT).getRecordTypeId();
        objWorkOrder.SVMXC__Order_Status__c =STRING_WORK_ORDER_STATUS_INITIATED;
        objWorkOrder.SVMXC__Order_Type__c = STRING_WORK_ORDER_TYPE_INSTALLATION;
        objWorkOrder.Warning_Message__c='tes';
        objWorkOrder.Cost_Center__c = 123456;
        insert objWorkOrder;

        //Serialized spare
        List<Product2> lstProduct = new List<Product2>();
        Product2 product1 = TestDataMaster.createProduct(false);
        product1.Material_Group__c  = '41';
        product1.Serial_Number_Profile__c = STRING_COST_CENTER_CODE;
        lstProduct.add(product1);

        //Batched spare
        Product2 product2 = TestDataMaster.createProduct(false);
        product2.Material_Group__c  = '41';
        product2.Batch_Management__c = true;
        lstProduct.add(product2);

        insert lstProduct;

        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Product__c=product1.Id;
        insert objInstalledProduct;

        
        SVMXC__RMA_Shipment_Order__c objPartsOrder = TestDataFieldService.createPartsOrderForInstallationWO(objWorkOrder.Id);
        objPartsOrder.SVMXC__Order_Status__c = 'Open';
        objPartsOrder.ERP_Sales_Order_Number__c = '132';
        objPartsOrder.Contact_Name__c='Test';
        objPartsOrder.Contact_Phone__c='Test';
        objPartsOrder.SVMXC__Order_Type__c='Advance Exchange';
        objPartsOrder.SVMXC__Destination_Location__c=objLocationRec.id;
        objPartsOrder.Ship_To_Company__c='test';
        objPartsOrder.Care_Of__c='test';
        objPartsOrder.Shipping_Street__c='test'; 
        objPartsOrder.Shipping_City__c='test'; 
        objPartsOrder.Shipping_Postal_Code__c='test'; 
        objPartsOrder.Shipping_Country__c='Angola [AO]';
        objPartsOrder.Shipping_State_Province__c='N/A';
        insert objPartsOrder;
        
        Test.startTest();
        Product2 insertedProduct = [Select id,Material_Group__c,Service_Product_Type__c from Product2 where id =:product1.id][0];
        system.assertequals('Spare',insertedProduct.Service_Product_Type__c);
        
        Id shipmentRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get('Shipment').getRecordTypeId();
        
        //SVMXC__Product_Stock__c objProductStock = TestDataFieldService.getNewProductStock(objLocationRec.Id,product1.id);

        List<SVMXC__RMA_Shipment_Line__c> lstPartsOrderLine = new List<SVMXC__RMA_Shipment_Line__c>() ;   
        List<SVMXC__RMA_Shipment_Line__c> lstUpdatePartsOrderLine = new List<SVMXC__RMA_Shipment_Line__c>() ;  
        
        //Create shipment POL for serialized product
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        objPartsOrderLine.From_Location__c = objLocationRec.id;
        objPartsOrderLine.RecordTypeId = shipmentRecordTypeId; 
        objPartsOrderLine.Reason__c = STRING_PARTS_ORDER_LINE_NON_BILLABLE_REASON;
        objPartsOrderLine.SVMXC__Actual_Quantity2__c= 1;
        objPartsOrderLine.SVMXC__Line_Status__c = 'Open';
        objPartsOrderLine.Requested_Delivery_Date__c = Date.today();
        objPartsOrderLine.SVMXC__Product__c = product1.Id;
        objPartsOrderLine.SVMXC__Serial_Number__c=objInstalledProduct.id;
        lstPartsOrderLine.add(objPartsOrderLine);
        
        //Create shipment POL for Batched product
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine1 = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        objPartsOrderLine1.RecordTypeId = shipmentRecordTypeId; 
        objPartsOrderLine1.Reason__c = STRING_PARTS_ORDER_LINE_NON_BILLABLE_REASON;
        objPartsOrderLine1.SVMXC__Actual_Quantity2__c= 2;
        objPartsOrderLine1.SVMXC__Line_Status__c = 'Open';
        objPartsOrderLine1.Requested_Delivery_Date__c = Date.today() +1;
        objPartsOrderLine1.SVMXC__Product__c = product2.Id;
        objPartsOrderLine1.Batch_Number__c = '1234';
        lstPartsOrderLine.add(objPartsOrderLine1);

        insert lstPartsOrderLine;

        objPartsOrderLine.SVMXC__Line_Status__c = 'Shipped';
        objPartsOrderLine1.SVMXC__Line_Status__c = 'Shipped';
        lstUpdatePartsOrderLine.add(objPartsOrderLine);
        lstUpdatePartsOrderLine.add(objPartsOrderLine1);
        update lstUpdatePartsOrderLine;
        Test.stopTest();

        //DCP-43634 - to cover VF component controller POLGoodwillApprovalTableController
        POLGoodwillApprovalTableController objClass = new POLGoodwillApprovalTableController();
        objClass.partsOrderId = [select id from SVMXC__RMA_Shipment_Order__c where GoodWill_Order_Lines__c > 0 limit 1].Id;
        System.assert(objClass.getListPartsOrderLines().size() > 0);
  }
    static testmethod void validateReturnFromLocation(){
    List<SVMXC__Site__c> lstLocations = new List<SVMXC__Site__c>();
        SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'test',SVMXC__Stocking_Location__c=true,Type__c=STRING_SHIPPING_TYPE_TRUNK,ERP_Customer_ID__c=STRING_COST_CENTER_CODE);
    lstLocations.add(objLocationRec);
        insert lstLocations;
        
        //Serialized spare
        List<Product2> lstProduct = new List<Product2>();
        Product2 product1 = TestDataMaster.createProduct(false);
        product1.ProductCode = 'XXX';
        product1.Material_Group__c  = '41';
        product1.Serial_Number_Profile__c = STRING_COST_CENTER_CODE;
        lstProduct.add(product1);

        //Batched spare
        Product2 product2 = TestDataMaster.createProduct(false);
        product2.ProductCode = 'YYY';
        product2.Material_Group__c  = '41';
        product2.Batch_Management__c = true;
        product2.SVMXC__Enable_Serialized_Tracking__c = false;
        lstProduct.add(product2);
    insert lstProduct;

        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Product__c=product1.Id;
        insert objInstalledProduct;

        List<SVMXC__Product_Stock__c> lstProductStock = new List<SVMXC__Product_Stock__c>();
        SVMXC__Product_Stock__c prodStock1 = new SVMXC__Product_Stock__c();
        prodStock1.SVMXC__Location__c = objLocationRec.Id;
        prodStock1.SVMX_PS_External_ID__c = objLocationRec.ERP_Customer_ID__c + product1.ProductCode;
        prodStock1.SVMXC__Product__c = product1.Id;
        prodStock1.SVMXC__Quantity2__c = 1;
        prodStock1.SVMXC__Status__c = STRING_PRODUCT_STOCK_STATUS_AVAILABLE;
        lstProductStock.add(prodStock1);

        SVMXC__Product_Stock__c prodStock2 = new SVMXC__Product_Stock__c();
        prodStock2.SVMXC__Location__c = objLocationRec.Id;
        prodStock2.SVMX_PS_External_ID__c = objLocationRec.ERP_Customer_ID__c + product2.ProductCode;
        prodStock2.SVMXC__Product__c = product2.Id;
        prodStock2.SVMXC__Quantity2__c = 1;
        prodStock2.SVMXC__Status__c = STRING_PRODUCT_STOCK_STATUS_AVAILABLE;
        lstProductStock.add(prodStock2);
        insert lstProductStock;

        List<SVMXC__Product_Serial__c> lstStockSerials = new List<SVMXC__Product_Serial__c>();
        SVMXC__Product_Serial__c serializedStock = new SVMXC__Product_Serial__c();
        serializedStock.Name = 'Serial123';
        serializedStock.Location__c = objLocationRec.Id;
        serializedStock.SVMXC__Product__c = product1.Id;
        serializedStock.SVMXC__Product_Stock__c = prodStock1.Id;
        serializedStock.SVMXC__Active__c = true;
        serializedStock.SVMX_PS_VS_Linked_Installed_Product__c = objInstalledProduct.Id;
        serializedStock.SVMX_PS_External_ID__c = objLocationRec.ERP_Customer_ID__c + 'Serial123';
        lstStockSerials.add(serializedStock);

        SVMXC__Product_Serial__c batchedStock = new SVMXC__Product_Serial__c();
        batchedStock.Name = 'Batch123';
        batchedStock.Batch_Number__c = 'Batch123';
        batchedStock.Location__c = objLocationRec.Id;
        batchedStock.SVMXC__Product__c = product2.Id;
        batchedStock.SVMXC__Product_Stock__c = prodStock2.Id;
        batchedStock.SVMXC__Active__c = true;
        batchedStock.SVMX_PS_External_ID__c = objLocationRec.ERP_Customer_ID__c + product2.ProductCode + 'Batch123';
        lstStockSerials.add(batchedStock);
        insert lstStockSerials;

        SVMXC__RMA_Shipment_Order__c objPartsOrder = new SVMXC__RMA_Shipment_Order__c();
        objPartsOrder.SVMXC__Order_Status__c = 'Open';
        objPartsOrder.ERP_Sales_Order_Number__c = '132';
        objPartsOrder.Contact_Name__c='Test';
        objPartsOrder.Contact_Phone__c='Test';
        objPartsOrder.SVMXC__Order_Type__c=STRING_PARTS_ORDER_TYPE_RETURN;
        objPartsOrder.SVMXC__Source_Location__c=objLocationRec.id;
        objPartsOrder.Ship_To_Company__c='test';
        objPartsOrder.Care_Of__c='test';
        objPartsOrder.Shipping_Street__c='test'; 
        objPartsOrder.Shipping_City__c='test'; 
        objPartsOrder.Shipping_Postal_Code__c='test'; 
        objPartsOrder.Shipping_Country__c='Angola [AO]';
        objPartsOrder.Shipping_State_Province__c='N/A';
        objPartsOrder.SVMXC__Destination_Location__c=objLocationRec.id;
        insert objPartsOrder;
        
        Test.startTest();
        Product2 insertedProduct = [Select id,Material_Group__c,Service_Product_Type__c from Product2 where id =:product1.id][0];
        system.assertequals('Spare',insertedProduct.Service_Product_Type__c);
        
        Id returnRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get('Shipment').getRecordTypeId();
        
        List<SVMXC__RMA_Shipment_Line__c> lstPartsOrderLine = new List<SVMXC__RMA_Shipment_Line__c>() ;   
        List<SVMXC__RMA_Shipment_Line__c> lstUpdatePartsOrderLine = new List<SVMXC__RMA_Shipment_Line__c>() ;  
        
        //Create return POL for serialized product
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        objPartsOrderLine.From_Location__c = objLocationRec.id;
        objPartsOrderLine.RecordTypeId = returnRecordTypeId; 
        objPartsOrderLine.Reason__c = STRING_PARTS_ORDER_LINE_NON_BILLABLE_REASON;
        objPartsOrderLine.SVMXC__Actual_Quantity2__c= 1;
        objPartsOrderLine.SVMXC__Line_Status__c = 'Open';
        objPartsOrderLine.Requested_Delivery_Date__c = Date.today();
        objPartsOrderLine.SVMXC__Product__c = product1.Id;
        objPartsOrderLine.Stocked_Serial__c = serializedStock.Id;
        objPartsOrderLine.SVMXC__Serial_Number__c = objInstalledProduct.Id;

        lstPartsOrderLine.add(objPartsOrderLine);
        
        //Create return POL for Batched product
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine1 = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        objPartsOrderLine1.RecordTypeId = returnRecordTypeId; 
        objPartsOrderLine1.Reason__c = STRING_PARTS_ORDER_LINE_NON_BILLABLE_REASON;
        objPartsOrderLine1.SVMXC__Actual_Quantity2__c= 2;
        objPartsOrderLine1.SVMXC__Line_Status__c = 'Open';  
        objPartsOrderLine1.Requested_Delivery_Date__c = Date.today() +1;
        objPartsOrderLine1.SVMXC__Product__c = product2.Id;
        objPartsOrderLine1.Batch_Lookup__c = batchedStock.Id;
        lstPartsOrderLine.add(objPartsOrderLine1);
        
        insert lstPartsOrderLine;

        objPartsOrderLine.SVMXC__Line_Status__c = 'Shipped';
        objPartsOrderLine1.SVMXC__Line_Status__c = 'Shipped';
        lstUpdatePartsOrderLine.add(objPartsOrderLine);
        lstUpdatePartsOrderLine.add(objPartsOrderLine1);
        update lstUpdatePartsOrderLine;

        Set<Id> setPOL = new Set<Id>();
        setPOL.add(lstPartsOrderLine[0].Id);

        ProductStockHandler.partsOrderShippedMechanism(setPOL);
        Test.stopTest();
    }
    static testmethod void validateReplenishmentType(){
        List<SVMXC__Site__c> lstLocations = new List<SVMXC__Site__c>();
        SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'test',SVMXC__Stocking_Location__c=true,Type__c=STRING_SHIPPING_TYPE_TRUNK,ERP_Customer_ID__c=STRING_COST_CENTER_CODE);
        lstLocations.add(objLocationRec);
        insert lstLocations;
            
        //Serialized spare
        List<Product2> lstProduct = new List<Product2>();
        Product2 product1 = TestDataMaster.createProduct(false);
        product1.ProductCode = 'XXX';
        product1.Material_Group__c  = '41';
        product1.Serial_Number_Profile__c = STRING_COST_CENTER_CODE;
        product1.Replenishment_Eligible__c = 'Field Stock';
        lstProduct.add(product1);

        //Batched spare
        Product2 product2 = TestDataMaster.createProduct(false);
        product2.ProductCode = 'YYY';
        product2.Material_Group__c  = '41';
        product2.Batch_Management__c = true;
        product2.SVMXC__Enable_Serialized_Tracking__c = false;
        product2.Replenishment_Eligible__c = 'Field Stock';
        lstProduct.add(product2);
        insert lstProduct;
    
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Product__c=product1.Id;
        insert objInstalledProduct;

        List<SVMXC__Product_Stock__c> lstProductStock = new List<SVMXC__Product_Stock__c>();
        SVMXC__Product_Stock__c prodStock1 = new SVMXC__Product_Stock__c();
        prodStock1.SVMXC__Location__c = objLocationRec.Id;
        prodStock1.SVMX_PS_External_ID__c = objLocationRec.ERP_Customer_ID__c + product1.ProductCode;
        prodStock1.SVMXC__Product__c = product1.Id;
        prodStock1.SVMXC__Quantity2__c = 1;
        prodStock1.SVMXC__Status__c = STRING_PRODUCT_STOCK_STATUS_AVAILABLE;
        lstProductStock.add(prodStock1);

        SVMXC__Product_Stock__c prodStock2 = new SVMXC__Product_Stock__c();
        prodStock2.SVMXC__Location__c = objLocationRec.Id;
        prodStock2.SVMX_PS_External_ID__c = objLocationRec.ERP_Customer_ID__c + product2.ProductCode;
        prodStock2.SVMXC__Product__c = product2.Id;
        prodStock2.SVMXC__Quantity2__c = 1;
        prodStock2.SVMXC__Status__c = STRING_PRODUCT_STOCK_STATUS_AVAILABLE;
        lstProductStock.add(prodStock2);
        insert lstProductStock;
    
        List<SVMXC__Product_Serial__c> lstStockSerials = new List<SVMXC__Product_Serial__c>();
        SVMXC__Product_Serial__c serializedStock = new SVMXC__Product_Serial__c();
        serializedStock.Name = 'Serial123';
        serializedStock.Location__c = objLocationRec.Id;
        serializedStock.SVMXC__Product__c = product1.Id;
        serializedStock.SVMXC__Product_Stock__c = prodStock1.Id;
        serializedStock.SVMXC__Active__c = true;
        serializedStock.SVMX_PS_VS_Linked_Installed_Product__c = objInstalledProduct.Id;
        serializedStock.SVMX_PS_External_ID__c = objLocationRec.ERP_Customer_ID__c + 'Serial123';
        lstStockSerials.add(serializedStock);

        SVMXC__Product_Serial__c batchedStock = new SVMXC__Product_Serial__c();
        batchedStock.Name = 'Batch123';
        batchedStock.Batch_Number__c = 'Batch123';
        batchedStock.Location__c = objLocationRec.Id;
        batchedStock.SVMXC__Product__c = product2.Id;
        batchedStock.SVMXC__Product_Stock__c = prodStock2.Id;
        batchedStock.SVMXC__Active__c = true;
        batchedStock.SVMX_PS_External_ID__c = objLocationRec.ERP_Customer_ID__c + product2.ProductCode + 'Batch123';
        lstStockSerials.add(batchedStock);
        insert lstStockSerials;
    
        SVMXC__RMA_Shipment_Order__c objPartsOrder = new SVMXC__RMA_Shipment_Order__c();
        objPartsOrder.SVMXC__Order_Status__c = 'Open';
        objPartsOrder.ERP_Sales_Order_Number__c = '132';
        objPartsOrder.Contact_Name__c='Test';
        objPartsOrder.Contact_Phone__c='Test';
        objPartsOrder.SVMXC__Order_Type__c=STRING_PARTS_ORDER_TYPE_REPLENISHMENT;
        objPartsOrder.SVMXC__Source_Location__c=objLocationRec.id;
        objPartsOrder.Ship_To_Company__c='test';
        objPartsOrder.Care_Of__c='test';
        objPartsOrder.Shipping_Street__c='test'; 
        objPartsOrder.Shipping_City__c='test'; 
        objPartsOrder.Shipping_Postal_Code__c='test'; 
        objPartsOrder.Shipping_Country__c='Angola [AO]';
        objPartsOrder.Shipping_State_Province__c='N/A';
        objPartsOrder.SVMXC__Destination_Location__c=objLocationRec.id;
        insert objPartsOrder;
            
        Test.startTest();
        Product2 insertedProduct = [Select id,Material_Group__c,Service_Product_Type__c from Product2 where id =:product1.id][0];
        system.assertequals('Spare',insertedProduct.Service_Product_Type__c);
        
        Id returnRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get('Shipment').getRecordTypeId();
        
        List<SVMXC__RMA_Shipment_Line__c> lstPartsOrderLine = new List<SVMXC__RMA_Shipment_Line__c>() ;   
        List<SVMXC__RMA_Shipment_Line__c> lstUpdatePartsOrderLine = new List<SVMXC__RMA_Shipment_Line__c>() ;  
        
        //Create return POL for serialized product
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        objPartsOrderLine.From_Location__c = objLocationRec.id;
        objPartsOrderLine.RecordTypeId = returnRecordTypeId; 
        objPartsOrderLine.Reason__c = STRING_PARTS_ORDER_LINE_NON_BILLABLE_REASON;
        objPartsOrderLine.SVMXC__Actual_Quantity2__c= 1;
        objPartsOrderLine.SVMXC__Line_Status__c = 'Open';
        objPartsOrderLine.Requested_Delivery_Date__c = Date.today();
        objPartsOrderLine.SVMXC__Product__c = product1.Id;
        objPartsOrderLine.Stocked_Serial__c = serializedStock.Id;
        objPartsOrderLine.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        objPartsOrderLine.Shipped_Qty__c = 1;

        lstPartsOrderLine.add(objPartsOrderLine);
        
        //Create return POL for Batched product
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine1 = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        objPartsOrderLine1.RecordTypeId = returnRecordTypeId; 
        objPartsOrderLine1.Reason__c = STRING_PARTS_ORDER_LINE_NON_BILLABLE_REASON;
        objPartsOrderLine1.SVMXC__Actual_Quantity2__c= 2;
        objPartsOrderLine1.SVMXC__Line_Status__c = 'Open';  
        objPartsOrderLine1.Requested_Delivery_Date__c = Date.today() +1;
        objPartsOrderLine1.SVMXC__Product__c = product2.Id;
        objPartsOrderLine1.Batch_Lookup__c = batchedStock.Id;
        objPartsOrderLine1.Shipped_Qty__c = 1;
        lstPartsOrderLine.add(objPartsOrderLine1);
        
        insert lstPartsOrderLine;

        objPartsOrderLine.SVMXC__Line_Status__c = 'Shipped';
        objPartsOrderLine1.SVMXC__Line_Status__c = 'Shipped';
        lstUpdatePartsOrderLine.add(objPartsOrderLine);
        lstUpdatePartsOrderLine.add(objPartsOrderLine1);
        update lstUpdatePartsOrderLine;

        Set<Id> setPOL = new Set<Id>();
        setPOL.add(lstPartsOrderLine[0].Id);

        ProductStockHandler.partsOrderShippedMechanism(setPOL);
        Test.stopTest();
    }
    static testmethod void validateShipment(){
        List<SVMXC__Site__c> lstLocations = new List<SVMXC__Site__c>();
        SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'test',SVMXC__Stocking_Location__c=true,Type__c=STRING_SHIPPING_TYPE_TRUNK,ERP_Customer_ID__c=STRING_COST_CENTER_CODE);
        lstLocations.add(objLocationRec);
        insert lstLocations;
        
        //Serialized spare
        List<Product2> lstProduct = new List<Product2>();
        Product2 product1 = TestDataMaster.createProduct(false);
        product1.ProductCode = 'XXX';
        product1.Material_Group__c  = '41';
        product1.Serial_Number_Profile__c = STRING_COST_CENTER_CODE;
        product1.Replenishment_Eligible__c = 'Field Stock';
        lstProduct.add(product1);

        //Batched spare
        Product2 product2 = TestDataMaster.createProduct(false);
        product2.ProductCode = 'YYY';
        product2.Material_Group__c  = '41';
        product2.Batch_Management__c = true;
        product2.SVMXC__Enable_Serialized_Tracking__c = false;
        product2.Replenishment_Eligible__c = 'Field Stock';
        lstProduct.add(product2);
        insert lstProduct;

        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Product__c=product1.Id;
        insert objInstalledProduct;

        List<SVMXC__Product_Stock__c> lstProductStock = new List<SVMXC__Product_Stock__c>();
        SVMXC__Product_Stock__c prodStock1 = new SVMXC__Product_Stock__c();
        prodStock1.SVMXC__Location__c = objLocationRec.Id;
        prodStock1.SVMX_PS_External_ID__c = objLocationRec.ERP_Customer_ID__c + product1.ProductCode;
        prodStock1.SVMXC__Product__c = product1.Id;
        prodStock1.SVMXC__Quantity2__c = 1;
        prodStock1.SVMXC__Status__c = STRING_PRODUCT_STOCK_STATUS_AVAILABLE;
        lstProductStock.add(prodStock1);

        SVMXC__Product_Stock__c prodStock2 = new SVMXC__Product_Stock__c();
        prodStock2.SVMXC__Location__c = objLocationRec.Id;
        prodStock2.SVMX_PS_External_ID__c = objLocationRec.ERP_Customer_ID__c + product2.ProductCode;
        prodStock2.SVMXC__Product__c = product2.Id;
        prodStock2.SVMXC__Quantity2__c = 1;
        prodStock2.SVMXC__Status__c = STRING_PRODUCT_STOCK_STATUS_AVAILABLE;
        lstProductStock.add(prodStock2);
        insert lstProductStock;

        List<SVMXC__Product_Serial__c> lstStockSerials = new List<SVMXC__Product_Serial__c>();
        SVMXC__Product_Serial__c serializedStock = new SVMXC__Product_Serial__c();
        serializedStock.Name = 'Serial123';
        serializedStock.Location__c = objLocationRec.Id;
        serializedStock.SVMXC__Product__c = product1.Id;
        serializedStock.SVMXC__Product_Stock__c = prodStock1.Id;
        serializedStock.SVMXC__Active__c = true;
        serializedStock.SVMX_PS_VS_Linked_Installed_Product__c = objInstalledProduct.Id;
        serializedStock.SVMX_PS_External_ID__c = objLocationRec.ERP_Customer_ID__c + 'Batch123';
        lstStockSerials.add(serializedStock);

        SVMXC__Product_Serial__c batchedStock = new SVMXC__Product_Serial__c();
        batchedStock.Name = 'Batch123';
        batchedStock.Batch_Number__c = 'Batch123';
        batchedStock.Location__c = objLocationRec.Id;
        batchedStock.SVMXC__Product__c = product2.Id;
        batchedStock.SVMXC__Product_Stock__c = prodStock2.Id;
        batchedStock.SVMXC__Active__c = true;
        batchedStock.SVMX_PS_External_ID__c = objLocationRec.ERP_Customer_ID__c + product2.ProductCode + 'Batch123';
        lstStockSerials.add(batchedStock);
        insert lstStockSerials;

        SVMXC__RMA_Shipment_Order__c objPartsOrder = new SVMXC__RMA_Shipment_Order__c();
        objPartsOrder.SVMXC__Order_Status__c = 'Open';
        objPartsOrder.ERP_Sales_Order_Number__c = '132';
        objPartsOrder.Contact_Name__c='Test';
        objPartsOrder.Contact_Phone__c='Test';
        objPartsOrder.SVMXC__Order_Type__c=STRING_PARTS_ORDER_TYPE_RETURN;
        objPartsOrder.SVMXC__Source_Location__c=objLocationRec.id;
        objPartsOrder.Ship_To_Company__c='test';
        objPartsOrder.Care_Of__c='test';
        objPartsOrder.Shipping_Street__c='test'; 
        objPartsOrder.Shipping_City__c='test'; 
        objPartsOrder.Shipping_Postal_Code__c='test'; 
        objPartsOrder.Shipping_Country__c='Angola [AO]';
        objPartsOrder.Shipping_State_Province__c='N/A';
        objPartsOrder.SVMXC__Destination_Location__c=objLocationRec.id;
        insert objPartsOrder;
        
        Test.startTest();
        Product2 insertedProduct = [Select id,Material_Group__c,Service_Product_Type__c from Product2 where id =:product1.id][0];
        system.assertequals('Spare',insertedProduct.Service_Product_Type__c);
        
        Id returnRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get('Shipment').getRecordTypeId();
        
        List<SVMXC__RMA_Shipment_Line__c> lstPartsOrderLine = new List<SVMXC__RMA_Shipment_Line__c>() ;   
        List<SVMXC__RMA_Shipment_Line__c> lstUpdatePartsOrderLine = new List<SVMXC__RMA_Shipment_Line__c>() ;  
        
        //Create return POL for Batched product
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine1 = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        objPartsOrderLine1.RecordTypeId = returnRecordTypeId; 
        objPartsOrderLine1.Reason__c = STRING_PARTS_ORDER_LINE_NON_BILLABLE_REASON;
        objPartsOrderLine1.SVMXC__Actual_Quantity2__c= 2;
        objPartsOrderLine1.SVMXC__Product__c = Product2.Id;
        objPartsOrderLine1.SVMXC__Line_Status__c = 'Open';  
        objPartsOrderLine1.Requested_Delivery_Date__c = Date.today() +1;
        objPartsOrderLine1.SVMXC__Product__c = product2.Id;
        objPartsOrderLine1.Batch_Number__c='Batch123';
        objPartsOrderLine1.Batch_Lookup__c = batchedStock.Id;
        objPartsOrderLine1.Shipped_Qty__c = 1;
        lstPartsOrderLine.add(objPartsOrderLine1);
        
        insert lstPartsOrderLine;

        Set<Id> setPOL = new Set<Id>();
        setPOL.add(lstPartsOrderLine[0].Id);

        ProductStockHandler.partsOrderShippedMechanism(setPOL);
        Test.stopTest(); 
    } 
}