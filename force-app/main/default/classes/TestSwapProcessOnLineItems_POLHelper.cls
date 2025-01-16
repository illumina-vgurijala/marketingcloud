/**
* @author Shivani Jain
* @date 7 Dec 2021
*
* @description DCP-42926 Test class for SwapProcessOnLineItems_POLHelper
*/ 
@IsTest(SeeAllData=True)
private class TestSwapProcessOnLineItems_POLHelper {
    static final String STRING_ACCOUNT_GROUP_SOLD_TO = 'Sold To';
    static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP VM';
    static final string STRING_CURRENCY = 'USD';
    static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    static final string STRING_INSTALLED_PRODUCT_NAME1 = 'Test IP VM1';
    static final string STRING_CONTRACT_STATUS = 'Active';
    static final string STRING_PARTS_ORDER_TYPE_RETURN = 'Return';
    static final string STRING_PARTS_ORDER_LINE_STATUS = 'Open';
    static final string STRING_PARTS_ORDER_LINE_NON_BILLABLE_REASON = 'Goodwill';
    static final string STRING_POL_STATUS_SHIPPED = 'Shipped';
    static final string STRING_PO_TYPE_SHIPMENT = 'Shipment';
    static final string STRING_PO_TYPE_ADV_EXCHANGE = 'Advance Exchange';
    
    /*
    * Test method to test Swap Process On Line Items 
    */
    static testmethod void partsOrderLinesCheckLinkedrecordTest() {
        Channel_Partner_Profile_Settings__c cp =new Channel_Partner_Profile_Settings__c(SetupOwnerId=UserInfo.getUserId(), Is_Channel_Partner__c = false);
        insert cp;
        Account objAccount = TestDataAccount.getAccount('Test1');
        objAccount.Account_Group__c = STRING_ACCOUNT_GROUP_SOLD_TO;
        
        Account objAccount1 = TestDataAccount.getAccount('Test2');
        objAccount1.Account_Group__c = STRING_ACCOUNT_GROUP_SOLD_TO;
        
        insert new list<Account> {objAccount, objAccount1};
        System.assertNotEquals(null, objAccount.Id);
        System.assertNotEquals(null, objAccount1.Id);
        
        Product2 product1 = TestDataMaster.createProduct(false);
        product1.Material_Class__c = 'Consumables';
    
        Product2 product2 = TestDataMaster.createProduct(false);
        product2.Material_Class__c = 'Consumables';
        insert new List<Product2>{product1, product2};
        System.assertNotEquals(null, product1.Id);
        System.assertNotEquals(null, product2.Id);
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        objInstalledProduct.SVMXC__Product__c = product1.Id;
        SVMXC__Installed_Product__c objInstalledProduct1 = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME1, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct1.SVMXC__Company__c = objAccount1.Id;
        objInstalledProduct1.SVMXC__Product__c = product2.Id;
        insert new list<SVMXC__Installed_Product__c> {objInstalledProduct, objInstalledProduct1};
        System.assertNotEquals(null, objInstalledProduct.Id);
        System.assertNotEquals(null, objInstalledProduct1.Id);
        
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.Consumables_Included__c=false;
        objServiceContract.Status__c = STRING_CONTRACT_STATUS;
        
        SVMXC__Service_Contract__c objServiceContract1 = TestDataFieldService.createServiceContract(objAccount1.Id);
        objServiceContract1.Consumables_Included__c=false;
        objServiceContract1.Status__c = STRING_CONTRACT_STATUS;
        
        insert new list<SVMXC__Service_Contract__c> {objServiceContract, objServiceContract1};
        System.assertNotEquals(null, objServiceContract.Id);
        System.assertNotEquals(null, objServiceContract1.Id);
        
        SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(objInstalledProduct.Id);
        objCoveredProduct.SVMXC__Service_Contract__c = objServiceContract.Id;
        
        SVMXC__Service_Contract_Products__c objCoveredProduct1 = TestDataFieldService.createCoveredProduct(objInstalledProduct1.Id);
        objCoveredProduct1.SVMXC__Service_Contract__c = objServiceContract1.Id;
        
        insert new list<SVMXC__Service_Contract_Products__c> {objCoveredProduct, objCoveredProduct1};
        System.assertNotEquals(null, objCoveredProduct.Id);
        System.assertNotEquals(null, objCoveredProduct1.Id);
        
        SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'test');
        insert objLocationRec;
        System.assertNotEquals(null, objLocationRec.Id);

        SVMXC__Service_Order__c objWorkOrder= new SVMXC__Service_Order__c();
        objWorkOrder.RecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByName().get('Service Support').getRecordTypeId();
        objWorkOrder.SVMXC__Order_Status__c = 'Initiated';
        objWorkOrder.SVMXC__Order_Type__c = 'Installation';
        objWorkOrder.Warning_Message__c='tes';
        objWorkOrder.Cost_Center__c = 123456;
        insert objWorkOrder;
        
        List<SVMXC__RMA_Shipment_Order__c> lstPartsOrders= new List<SVMXC__RMA_Shipment_Order__c>();
        SVMXC__RMA_Shipment_Order__c objPartsOrder = TestDataFieldService.createPartsOrder(null);
        objPartsOrder.SVMXC__Order_Type__c = STRING_PO_TYPE_ADV_EXCHANGE;
        objPartsOrder.SVMXC__Order_Status__c = STRING_PARTS_ORDER_LINE_STATUS;
        objPartsOrder.ERP_Sales_Order_Number__c = '144';
        objPartsOrder.Contact_Name__c='Test';
        objPartsOrder.Contact_Phone__c='Test';
        objPartsOrder.Shipping_Location__c=objLocationRec.id;
        objPartsOrder.SVMXC__Service_Order__c = objWorkOrder.id;
        lstPartsOrders.add(objPartsOrder);
        
        SVMXC__RMA_Shipment_Order__c objPartsOrder1 = TestDataFieldService.createPartsOrder(null);
        objPartsOrder1.SVMXC__Order_Type__c = STRING_PARTS_ORDER_TYPE_RETURN;
        objPartsOrder1.SVMXC__Order_Status__c = STRING_PARTS_ORDER_LINE_STATUS;
        objPartsOrder1.ERP_Sales_Order_Number__c = '188';
        objPartsOrder1.Contact_Name__c='Test';
        objPartsOrder1.Contact_Phone__c='Test';
        objPartsOrder1.Shipping_Location__c=objLocationRec.id;
        lstPartsOrders.add(objPartsOrder1);

        insert lstPartsOrders;
        System.assertNotEquals(null, objPartsOrder.Id);
        System.assertNotEquals(null, objPartsOrder1.Id);

        Test.startTest();

        Id shipmentRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get(STRING_PO_TYPE_SHIPMENT).getRecordTypeId();
         
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLineRecord(lstPartsOrders[0].Id, objLocationRec.id,
                                            shipmentRecordTypeId, STRING_PARTS_ORDER_LINE_STATUS, objInstalledProduct.Id, product1.Id);
        objPartsOrderLine.Requested_Delivery_Date__c = Date.today();
        
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine1 = TestDataFieldService.createPartsOrderLineRecord(lstPartsOrders[1].Id, objLocationRec.id,
                                            shipmentRecordTypeId, STRING_PARTS_ORDER_LINE_STATUS, objInstalledProduct1.Id, product2.Id);
        objPartsOrderLine1.Reason__c = STRING_PARTS_ORDER_LINE_NON_BILLABLE_REASON;
        objPartsOrderLine1.Requested_Delivery_Date__c = Date.today();

        SVMXC__RMA_Shipment_Line__c objPartsOrderLine2 = objPartsOrderLine.clone();
        insert new list<SVMXC__RMA_Shipment_Line__c> {objPartsOrderLine1, objPartsOrderLine2};
        System.assertNotEquals(null, objPartsOrderLine1.Id);
        System.assertNotEquals(null, objPartsOrderLine2.Id);
        
        objPartsOrderLine.SVMXC__Master_Order_Line__c = objPartsOrderLine1.Id;
        insert objPartsOrderLine;
        System.assertNotEquals(null, objPartsOrderLine.Id);

        objPartsOrderLine.SVMXC__Line_Status__c = STRING_POL_STATUS_SHIPPED;
        objPartsOrderLine1.SVMXC__Line_Status__c = STRING_POL_STATUS_SHIPPED;
        objPartsOrderLine2.SVMXC__Line_Status__c = STRING_POL_STATUS_SHIPPED;
        update new list<SVMXC__RMA_Shipment_Line__c> {objPartsOrderLine, objPartsOrderLine2};

        Test.stopTest();
        SVMXC__Service_Contract_Products__c updatedCP = [SELECT id, SVMXC__Installed_Product__c 
                                        FROM SVMXC__Service_Contract_Products__c WHERE id =:objCoveredProduct.Id];

        system.assertequals(objInstalledProduct1.Id, updatedCP.SVMXC__Installed_Product__c, 'SwapProcessOnLineItems_POLHelper logic failed');
    }  
}
