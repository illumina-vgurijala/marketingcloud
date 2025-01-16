/**
* @author Gagan Sindwani
* @date 7 Dec 2021
*
* @description DCP-42926 Test class for CheckLinkedrecord_POLHelper
*/ 
@IsTest(SeeAllData=True)
private class TestCheckLinkedrecord_POLHelper {
    
    static final String STRING_ACCOUNT_GROUP_SOLD_TO = 'Sold To';
    static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP VM';
    static final string STRING_CURRENCY = 'USD';
    static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    static final string STRING_INSTALLED_PRODUCT_NAME1 = 'Test IP VM1';
    static final string STRING_CONTRACT_STATUS = 'Active';
    static final string STRING_PARTS_ORDER_TYPE_RETURN = 'Return';
    static final string STRING_PARTS_ORDER_LINE_STATUS = 'Open';
    static final string STRING_PARTS_ORDER_LINE_NON_BILLABLE_REASON = 'Goodwill';
    static final String STRING_PART_ORDER_TYPE_ADVANCEEXCHANGE = 'Advance Exchange';
    
    /*******************************************************************************************************
    * @description test method for CheckLinkedrecord_POLHelper
    */
    static testmethod void partsOrderLinesCheckLinkedrecordTest() {
        Boolean expectedExceptionThrown;
        Channel_Partner_Profile_Settings__c cp =new Channel_Partner_Profile_Settings__c(SetupOwnerId=UserInfo.getUserId(), Is_Channel_Partner__c = false);
        insert cp;
        Account objAccount = TestDataAccount.getAccount('TestAccount1');
        objAccount.Account_Group__c = STRING_ACCOUNT_GROUP_SOLD_TO;
        
        Account objAccount1 = TestDataAccount.getAccount('TestAccount2');
        objAccount1.Account_Group__c = STRING_ACCOUNT_GROUP_SOLD_TO;
        
        insert new list<Account> {objAccount,objAccount1};
        
        Product2 product1 = TestDataMaster.createProduct(false);
        product1.Material_Class__c = 'Consumables';
    
        Product2 product2 = TestDataMaster.createProduct(false);
        product2.Material_Class__c = 'Consumables';
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
        
        SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'testLocation');
        insert objLocationRec;
        
        
        List<SVMXC__RMA_Shipment_Order__c> lstPartsOrders= new List<SVMXC__RMA_Shipment_Order__c>();
        SVMXC__RMA_Shipment_Order__c objPartsOrder = TestDataFieldService.createPartsOrderRecord(STRING_PART_ORDER_TYPE_ADVANCEEXCHANGE, 
                        STRING_PARTS_ORDER_LINE_STATUS, '142', 'Test Contact Name', 'Test Phone', objLocationRec.Id);
        lstPartsOrders.add(objPartsOrder);
        
        SVMXC__RMA_Shipment_Order__c objPartsOrder1 = TestDataFieldService.createPartsOrderRecord(STRING_PARTS_ORDER_TYPE_RETURN, 
                        STRING_PARTS_ORDER_LINE_STATUS, '182', 'Test Contact Name', 'Test Phone', objLocationRec.Id);
        lstPartsOrders.add(objPartsOrder1);

        insert lstPartsOrders;
        Test.startTest();
        Id shipmentRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get('Shipment').getRecordTypeId();
         
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLineRecord(lstPartsOrders[0].Id, objLocationRec.id,
                                            shipmentRecordTypeId, STRING_PARTS_ORDER_LINE_STATUS, objInstalledProduct.Id, product1.Id);
        objPartsOrderLine.Requested_Delivery_Date__c = Date.today();
        
        
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine1 = TestDataFieldService.createPartsOrderLineRecord(lstPartsOrders[1].Id, objLocationRec.id,
        shipmentRecordTypeId, STRING_PARTS_ORDER_LINE_STATUS, objInstalledProduct1.Id, product2.Id);
        objPartsOrderLine1.Requested_Delivery_Date__c = Date.today();
        objPartsOrderLine1.Reason__c = STRING_PARTS_ORDER_LINE_NON_BILLABLE_REASON;

        SVMXC__RMA_Shipment_Line__c objPartsOrderLine2 = objPartsOrderLine1.clone();
        insert new list<SVMXC__RMA_Shipment_Line__c> {objPartsOrderLine1, objPartsOrderLine2};
        
        objPartsOrderLine.SVMXC__Master_Order_Line__c = objPartsOrderLine1.Id;
        insert objPartsOrderLine;
        System.assert(objPartsOrderLine.id!=null, 'objPartsOrderLine id not inserted succesfully'); 

        try{
            objPartsOrderLine2.SVMXC__Master_Order_Line__c = objPartsOrderLine1.Id;
            update objPartsOrderLine2;
        } catch(Exception ex){
            expectedExceptionThrown = ex.getMessage().contains(Label.Linked_Return_PO_Error) ? true : false;
        }
        System.assert(expectedExceptionThrown, 'Logic for Return Linked Parts Order Line failed to run');

        Test.stopTest();
    }  
}
