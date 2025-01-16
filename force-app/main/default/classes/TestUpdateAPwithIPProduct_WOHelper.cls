@isTest
/**
* Test class for UpdateAPwithIPProduct_WOHelper 
* @author Vishal
* @date   18 Dec 2024
*/
public with sharing class TestUpdateAPwithIPProduct_WOHelper {
    
    public static final string STRING_PRODUCT_CODE = 'Test 1234';
    public static final string STRING_PRODUCT_MATERIAL_CLASS = 'Consumable';
    public static final string STRING_LOCATION = 'Test Location';
    public static final string STRING_STREET = 'Test Street';
    public static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP';
    public static final string STRING_CURRENCY = 'USD';
    public static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    public static final String STRING_SNAP_SERVICE_INTEGRATION_USER = 'SNAP Service Integration';
    public static final String STRING_SNAP_SALES_INTEGRATION_USER = 'SNAP Sales Integration';


    /**
    * Test method for IsCaseIPProdchanged
    * @author Vishal
    */
    
    @isTest
    static void testIsCaseIPProdchanged() {
        // Create a test user
        User snapServiceUser1 = new UsersSelector().selectUsersByNames(new Set<String>{STRING_SNAP_SERVICE_INTEGRATION_USER})[0];
        User snapSalesUser = new UsersSelector().selectUsersByNames(new Set<String>{STRING_SNAP_SALES_INTEGRATION_USER})[0];
        // Create test data
        Account objAccount = TestDataAccount.getAccount('Test', 'USD');
        objAccount.Account_Group__c = 'Distributor';
        insert objAccount;
        
        // Create related data
        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        insert objProduct;
        
        // Create a Work Order under SNAP Service Integration user
        SVMXC__Service_Order__c workOrder;
        System.runAs(snapServiceUser1) {
            workOrder = TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
            workOrder.SVMXC__Order_Type__c='Installation';
            workOrder.Is_Auto_Created__c = true;
            workOrder.SVMXC__Product__c = objProduct.Id;
            insert workOrder;
        }
        
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(
        STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS
        );
        objInstalledProduct.SVMXC__Product__c = objProduct.Id;
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        insert objInstalledProduct;
        
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.Status__c = 'Active';
        insert objServiceContract;
        
        Associated_Product__c apc;
        System.runAs(snapSalesUser) {
            apc = new Associated_Product__c(
            Work_Order__c = workOrder.Id,
            Account__c = objAccount.Id,
            Product__c = objProduct.Id,
            Subscription__c = objServiceContract.Id,
            Is_Primary__c = true
            );
            insert apc;
        }
        
        // Simulate Work Order update to trigger the logic
        Test.startTest();
        System.runAs(snapServiceUser1) {
            workOrder.SVMXC__Component__c = objInstalledProduct.Id;
            update workOrder;
        }
        Test.stopTest();
        // Validate that Associated_Product__c was updated
        Associated_Product__c updatedAP = [SELECT Installed_Product__c, Product__c, Subscription__c 
        FROM Associated_Product__c 
        WHERE Id = :apc.Id LIMIT 1];
        
        System.assertEquals(objInstalledProduct.Id, updatedAP.Installed_Product__c, 'Installed_Product__c should be updated.');
        System.assertEquals(objProduct.Id, updatedAP.Product__c, 'Product__c should be updated.');
        System.assertEquals(null, updatedAP.Subscription__c, 'Subscription__c should be null.');
    }
}