/**
* @author Gagan Sindwani
* @date 7 Dec 2021
*
* @description DCP-42926 Test class for TestUpdatePO_StatusPendingReview_POLHelper
*/ 
@IsTest(SeeAllData=True)
private class TestUpdatePendingReview_POLHelper {
    
    public static final String STRING_ACCOUNT_GROUP_SOLD_TO = 'Sold To';
    public static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP VM';
    public static final string STRING_CURRENCY = 'USD';
    public static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    public static final string STRING_INSTALLED_PRODUCT_NAME1 = 'Test IP VM1';
    public static final string STRING_CONTRACT_STATUS = 'Active';
    public static final string STRING_PARTS_ORDER_TYPE_RETURN = 'Return';
    public static final string STRING_PARTS_ORDER_LINE_STATUS = 'Open';
    public static final string STRING_PARTS_ORDER_LINE_NON_BILLABLE_REASON = 'Goodwill';
    
    /*
    * Test method to test Parts Order Status update 
    */
    static testmethod void updatePartsOrderStatusTest() {

        Channel_Partner_Profile_Settings__c cp =new Channel_Partner_Profile_Settings__c(SetupOwnerId=Userinfo.getUserId(), Is_Channel_Partner__c = true);
        insert cp;
        
        Account objAccount = TestDataAccount.getAccount('Test1');
        objAccount.Account_Group__c = STRING_ACCOUNT_GROUP_SOLD_TO;
        
        Account objAccount1 = TestDataAccount.getAccount('Test2');
        objAccount1.Account_Group__c = STRING_ACCOUNT_GROUP_SOLD_TO;
        
        insert new list<Account> {objAccount,objAccount1};
        
        Product2 product1 = TestDataMaster.createProduct(false);
        product1.Material_Class__c = 'Consumables';
    
        Product2 product2 = TestDataMaster.createProduct(false);
        product2.Material_Class__c = 'Consumables';
        product2.Decontamination_Required__c = true;
        insert new List<Product2>{product1,product2};
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        objInstalledProduct.SVMXC__Product__c = product1.Id;
        SVMXC__Installed_Product__c objInstalledProduct1 = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME1, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct1.SVMXC__Company__c = objAccount1.Id;
        objInstalledProduct1.SVMXC__Product__c = product2.Id;
        insert new list<SVMXC__Installed_Product__c> {objInstalledProduct,objInstalledProduct1};
        
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.Consumables_Included__c=false;
        objServiceContract.Status__c = STRING_CONTRACT_STATUS;
        
        SVMXC__Service_Contract__c objServiceContract1 = TestDataFieldService.createServiceContract(objAccount1.Id);
        objServiceContract1.Consumables_Included__c=false;
        objServiceContract1.Status__c = STRING_CONTRACT_STATUS;
        
        insert new list<SVMXC__Service_Contract__c> {objServiceContract,objServiceContract1};
        
        SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(objInstalledProduct.Id);
        objCoveredProduct.SVMXC__Service_Contract__c = objServiceContract.Id;
        
        SVMXC__Service_Contract_Products__c objCoveredProduct1 = TestDataFieldService.createCoveredProduct(objInstalledProduct1.Id);
        objCoveredProduct1.SVMXC__Service_Contract__c = objServiceContract1.Id;
        
        insert new list<SVMXC__Service_Contract_Products__c> {objCoveredProduct,objCoveredProduct1};
        
        SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'test');
        insert objLocationRec;
        
        SVMXC__RMA_Shipment_Order__c objPartsOrder = TestDataFieldService.createPartsOrder(null);
        objPartsOrder.SVMXC__Order_Type__c = 'Return';
        objPartsOrder.SVMXC__Order_Status__c = 'Open';
        objPartsOrder.ERP_Sales_Order_Number__c = '144';
        objPartsOrder.Contact_Name__c='Test';
        objPartsOrder.Contact_Phone__c='Test';
        objPartsOrder.SVMXC__Source_Location__c=objLocationRec.id;
        objPartsOrder.Ship_To_Company__c='test';
        objPartsOrder.Care_Of__c='test';
        objPartsOrder.Shipping_Street__c='test'; 
        objPartsOrder.Shipping_City__c='test'; 
        objPartsOrder.Shipping_Postal_Code__c='test'; 
        objPartsOrder.Shipping_Country__c='Angola [AO]';
        objPartsOrder.Shipping_State_Province__c='N/A';
        objPartsOrder.Submit_for_Approval_CP__c=true;
        insert objPartsOrder;
        
        SVMXC__RMA_Shipment_Order__c objPartsOrder1 = TestDataFieldService.createPartsOrder(null);
        objPartsOrder1.SVMXC__Order_Type__c = STRING_PARTS_ORDER_TYPE_RETURN;
        objPartsOrder1.SVMXC__Order_Status__c = 'Open';
        objPartsOrder1.ERP_Sales_Order_Number__c = '188';
        objPartsOrder1.Contact_Name__c='Test';
        objPartsOrder1.Contact_Phone__c='Test';
        objPartsOrder1.SVMXC__Source_Location__c=objLocationRec.id;
        objPartsOrder1.Ship_To_Company__c='test';
        objPartsOrder1.Care_Of__c='test';
        objPartsOrder1.Shipping_Street__c='test'; 
        objPartsOrder1.Shipping_City__c='test'; 
        objPartsOrder1.Shipping_Postal_Code__c='test'; 
        objPartsOrder1.Shipping_Country__c='Angola [AO]';
        objPartsOrder1.Shipping_State_Province__c='N/A';
        objPartsOrder1.Submit_to_SAP__c=true;
        objPartsOrder1.Submit_for_Approval_CP__c=true;
        insert objPartsOrder1;

        Test.startTest();
        Id shipmentRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get('Shipment').getRecordTypeId();
         
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        objPartsOrderLine.From_Location__c = objLocationRec.id;
        objPartsOrderLine.RecordTypeId = shipmentRecordTypeId; 
        objPartsOrderLine.SVMXC__Line_Status__c = STRING_PARTS_ORDER_LINE_STATUS;
        objPartsOrderLine.Requested_Delivery_Date__c = Date.today();
        objPartsOrderLine.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        objPartsOrderLine.SVMXC__Actual_Quantity2__c = 2;
        objPartsOrderLine.SVMXC__Product__c = product1.Id;
        
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine1 = TestDataFieldService.createPartsOrderLines(objPartsOrder1.Id);
        objPartsOrderLine1.From_Location__c = objLocationRec.id;
        objPartsOrderLine1.RecordTypeId = shipmentRecordTypeId; 
        objPartsOrderLine1.SVMXC__Line_Status__c = STRING_PARTS_ORDER_LINE_STATUS;
        objPartsOrderLine1.Requested_Delivery_Date__c = Date.today();
        objPartsOrderLine1.SVMXC__Serial_Number__c = objInstalledProduct1.Id;
        objPartsOrderLine1.SVMXC__Product__c = product2.Id;
        objPartsOrderLine1.SVMXC__Actual_Quantity2__c = 2;
        objPartsOrderLine1.Consumed_QTY__c = 0;
        objPartsOrderLine1.Is_DCIR_Filled__c=true;
        insert new list<SVMXC__RMA_Shipment_Line__c> {objPartsOrderLine1};
        //create ContentDocumentLink  record 
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument Limit 1];
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = objPartsOrderLine1.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';

        echosign_dev1__SIGN_Agreement__c agreement = new echosign_dev1__SIGN_Agreement__c();
        agreement.Name = 'Testagreement';
        agreement.echosign_dev1__Status__c = 'Signed';   
        agreement.Parts_Order_Line__c=objPartsOrderLine1.Id;
        insert cdl; 
        System.assertNotEquals(null, cdl.Id);

        insert agreement;  
        System.assertNotEquals(null, agreement.Id);
        
        insert objPartsOrderLine;
        Test.stopTest();
        system.assert(objPartsOrderLine.id!=null, 'objPartsOrderLine id is null');            
        
    }  
}
