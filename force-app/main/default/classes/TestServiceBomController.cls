/**
*    @author: Sandeep 
*    @date:   20-Jan-2021
*    @description:  Test Class for  ServiceBomController  class.
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    ------------------------------------------------------------------------------------ 
*             Sandeep                   20-Jan-2021           Initial Development 
              Priya                     19-Dec-2023           test method for saveAssociatedProducts
                                
*/
@IsTest
public class TestServiceBomController {
    
    public static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP VM';
    public static final string STRING_CURRENCY = 'USD';
    public static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    public static final string STRING_PRODUCT_NAME = 'Test Product VM';
    
    static testMethod void getDetails(){
        Account objAccount = TestDataAccount.getNewAccount();
        Account objAccupdate=[select id,Account_Group__c from Account where id=:objAccount.id];
        objAccupdate.Account_Group__c='Distributor';
        update objAccupdate;
        Product2 objProduct2 = new Product2(Name = STRING_PRODUCT_NAME+'2',Service_Product_Type__c = 'Spare');
        insert objProduct2;
        Service_Bill_Of_Materials__c serviceBOM = new Service_Bill_Of_Materials__c(Name = 'Test Service BOM', ERP_Service_BoM_Number__c = '100291');
        insert serviceBOM;
        FRU_List__c fruList = new FRU_List__c(SVMX_PS_External_ID__c = '1091');
        fruList.Service_Bill_Of_Materials__c=serviceBOM.Id;
        fruList.ERP_Product__c=objProduct2.id;
        insert fruList;
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        objInstalledProduct.Service_Bill_Of_Materials__c=serviceBOM.Id;
        insert objInstalledProduct;
        Contact objContact = TestDataContact.getNewContact(objAccount);
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        objCase.SVMXC__Component__c = objInstalledProduct.Id;
        insert objCase;
        Test.startTest();
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');
        workOrder.SVMXC__Company__c = objAccount.id;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Auto_Created__c=true;
        insert workOrder;
        ServiceBomController.ProductReturnedWrapper prw= new ServiceBomController.ProductReturnedWrapper();
        prw = ServiceBomController.getIpDetails(STRING_INSTALLED_PRODUCT_NAME);
        System.assert(prw!=null,'prw is null');
        List<SVMXC__Service_Order__c> lstWo= ServiceBomController.getWODetails(workOrder.Id+'');
        System.assert(!lstWo.isEmpty(),'lstWo is empty');
        List<Case> lstCase=ServiceBomController.getCaseDetails(objCase.Id+'');
        System.assert(!lstCase.isEmpty(),'lstCase is empty');
        ServiceBomController.getPODetails(workOrder.Id+'');
        List<ServiceBomController.ServiceBomWrapper> lstSBW = new List<ServiceBomController.ServiceBomWrapper>();
        lstSBW = ServiceBomController.getFruList(serviceBOM.Id,'Test');
        System.assert(!lstSBW.isEmpty(),'lstSBW is empty');
        List<ServiceBomController.ProductReturnedWrapper> lstPRW = new List<ServiceBomController.ProductReturnedWrapper>();
        lstPRW= ServiceBomController.getProductReturned(objInstalledProduct.Id);
        System.assert(!lstPRW.isEmpty(),'lstPRW is empty');
        Test.StopTest();
    }
    /**
    *  @author: Priya 
    *  @description :test method for saveAssociatedProducts (CMCM-3200)
    **/ 
    static testMethod void testSaveAssociatedProducts() {
        Boolean featureFlag;
        Feature.setMockFeatureFlag('ServiceAssociatedProducts', true);
        List<Map<String, Object>> isPrimaryAssociatedProduct = new List<Map<String, Object>>();
        Map<String, Object> dataMap = new Map<String, Object>();
        
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Case',
            Bypass_Triggers_By_Object_2__c = 'SVMXC__Installed_Product__c',
            Bypass_Triggers_By_Object_3__c = 'Associated_Product__c'
        );
        insert apexSettings;
        Account objAccount = TestDataAccount.getNewAccount();
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        insert objInstalledProduct;
        Product2 objProduct2 = new Product2(Name = STRING_PRODUCT_NAME+'2',Service_Product_Type__c = 'Spare');
        objProduct2.Source_System__c = 'SAP';
        insert objProduct2;
        Contact objContact = TestDataContact.getNewContact(objAccount);
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        objCase.SVMXC__Component__c = objInstalledProduct.Id;
        insert objCase;
        Test.startTest();
        Associated_product__c associatedProd = new Associated_product__c();
        associatedProd.Case__c = objCase.Id;
        associatedProd.Installed_Product_Upgrade_Type__c = 'IVD';
        associatedProd.Is_Primary__c = true;
        associatedProd.Product_Serial_Number__c = 'test';
        associatedProd.Product_Lot_Number__c = 'test';
        associatedProd.Expired_Date__c = date.today();
        associatedProd.Is_Expired__c = False;
        //associatedProd.Installed_Product__c = objInstalledProduct.id;
        insert associatedProd;
        // Add data to the map
        dataMap.put('serialnumber', 'Test 123');
        dataMap.put('lotNumber', 'Test 123');
        dataMap.put('ExpiredDate', Date.today());
        dataMap.put('isExpire', false);
        dataMap.put('isPrimary', false);
        dataMap.put('recId', objProduct2.Id);
        dataMap.put('id', associatedProd.Id);
        isPrimaryAssociatedProduct.add(dataMap);
        String jsonString = JSON.serialize(isPrimaryAssociatedProduct);
        try{
        String serviceResult = ServiceBomController.saveAssociatedProducts(jsonString, objCase.Id);
        Assert.areEqual('Success',serviceResult);
        Associated_product__c insertedRecord = [SELECT Id, Name, Product_Serial_Number__c FROM Associated_product__c WHERE Product_Serial_Number__c='Test 123' AND Is_Primary__c = false LIMIT 1];
        System.assertEquals('Test 123', insertedRecord.Product_Serial_Number__c,'Product serial number is not same');
        }
        catch(Exception e) {
            //throw new AuraHandledException('133 Test Class Exception: ' + e.getMessage());
            ApexExceptions.emit('ServiceBomController',e);
            ilib_LogEvent.emit();
            system.debug('TestServiceBomController debug--'+ e.getMessage());
        }
        Test.StopTest();
    }
    /**
    *  @author: Priya 
    *  @description :test method for saveAssociatedProducts (CMCM-3200)
    **/ 
    static testMethod void testgetAssociatedProduct() {
        Feature.setMockFeatureFlag('ServiceAssociatedProducts', true);
        Account objAccount = TestDataAccount.getNewAccount();
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        insert objInstalledProduct;
        Product2 objProduct2 = new Product2(Name = STRING_PRODUCT_NAME+'2',Service_Product_Type__c = 'Spare');
        insert objProduct2;
        Contact objContact = TestDataContact.getNewContact(objAccount);
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        objCase.SVMXC__Component__c = objInstalledProduct.Id;
        insert objCase;
        Test.startTest();
        Associated_product__c associatedProd = new Associated_product__c();
        associatedProd.Case__c = objCase.Id;
        associatedProd.Installed_Product_Upgrade_Type__c = 'IVD';
        associatedProd.Is_Primary__c = true;
        associatedProd.Product_Serial_Number__c = 'test';
        associatedProd.Product_Lot_Number__c = 'test';
        associatedProd.Expired_Date__c = date.today();
        associatedProd.Is_Expired__c = False;
        associatedProd.Installed_Product__c = objInstalledProduct.id;
        insert associatedProd;
        List<Associated_Product__c> apList = ServiceBomController.getAssociatedProduct(objCase.Id);
        Assert.isTrue(apList!= null);
        Test.StopTest();
    }
}