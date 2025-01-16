//TestManageAssociatedProductsController 
/*
* @ author       : Siddartha Reddy Kalam
* @ date         : 28-Nov-2023
* @ Description  : Test class for ManageAssociatedProductsController class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                              Date                               Description
* Siddartha Reddy Kalam                  28-Nov-2023                        Initial version - CMCM-3980
* Dhairya Shah					  25-Jan-24	.        CMCM-3591
* ---------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class TestManageAssociatedProductsController {

    public static final String STRING_WO_RECORDTYPE = 'Field Service';
    public static final string STRING_PRODUCT_NAME = 'Test Product VM';
    public static final string STRING_PRODUCT_MATERIAL_CLASS = 'Consumable';
    public static final string STRING_PRODUCT_SERVICE_TYPE = 'Instrument';
    public static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP VM';
    public static final string STRING_CURRENCY = 'USD';
    public static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    public static final string STRING_CASE_RECORDTYPENAME = 'Business Issue';
    public static final string STRING_CASE_SUB_TYPE = 'Complaint';
    public static final string STRING_PRODUCT_CODE = 'Test 1234';
    public static final string STRING_PRODUCT_SERVICE_LEVEL = 'Dedicate';
    public static final String STRING_SERIAL_NUMBER = 'IL02';


    @isTest
    static void testWrapperProperties() {
        // Create an instance of AssociatedProductsWrapper
        AssociatedProductsWrapper wrapper = new AssociatedProductsWrapper();

        // Test setting and getting values for each property
        wrapper.name = 'Test Product';
        wrapper.productName = 'Test Product Name';
        wrapper.productCode = 'PROD123';
        wrapper.type = 'Product';
        wrapper.isPrimary = true;
        wrapper.installedProductName = 'Installed Product';
        wrapper.serialNumber = 'SN123';
        wrapper.ivdIdentifier = false;
        wrapper.subscription = 'Test Subscription';
        wrapper.lotNumber = 'LOT456';
        wrapper.expiredDate = Date.today();
        wrapper.isExpired = false;
        wrapper.version = '1.0';
        wrapper.location = 'Test Location';

        // Verify the values are set correctly
        System.assertEquals('Test Product', wrapper.name, 'Name should be set correctly.');
        System.assertEquals('Test Product Name', wrapper.productName, 'Product Name should be set correctly.');
        System.assertEquals('PROD123', wrapper.productCode, 'Product Code should be set correctly.');
        System.assertEquals('Product', wrapper.type, 'Type should be set correctly.');
        System.assertEquals(true, wrapper.isPrimary, 'Is Primary should be set correctly.');
        System.assertEquals('Installed Product', wrapper.installedProductName, 'Installed Product should be set correctly.');
        System.assertEquals('SN123', wrapper.serialNumber, 'Serial Number should be set correctly.');
        System.assertEquals(false, wrapper.ivdIdentifier, 'IVD Identifier should be set correctly.');
        System.assertEquals('Test Subscription', wrapper.subscription, 'Subscription should be set correctly.');
        System.assertEquals('LOT456', wrapper.lotNumber, 'Lot Number should be set correctly.');
        System.assertEquals(Date.today(), wrapper.expiredDate, 'Expired Date should be set correctly.');
        System.assertEquals(false, wrapper.isExpired, 'Is Expired should be set correctly.');
        System.assertEquals('1.0', wrapper.version, 'Version should be set correctly.');
        System.assertEquals('Test Location', wrapper.location, 'Location should be set correctly.');
    }

    @isTest
    static void testMainMethodIP() {
        //insert Account
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c = 'Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;
        System.assert(acc.Id != null,'Account got created');
        
        //insert Contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null, 'Contact got created');
            
        //insert Case
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.Status = 'Initiated';
        insert cs;
        System.assert(cs.Id != null, 'Case got created');

        List<SVMXC__Installed_Product__c> lstIP = new List<SVMXC__Installed_Product__c>();
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        lstIP.add(objInstalledProduct);
        
        SVMXC__Installed_Product__c objInstalledProduct1 = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME+'1', STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct1.SVMXC__Company__c = acc.Id;
        lstIP.add(objInstalledProduct1);

        SVMXC__Installed_Product__c objInstalledProduct2 = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME+'2', STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct2.SVMXC__Company__c = acc.Id;

        insert lstIP;

        SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        wo.Evaluation__c='Test';
        wo.SVMXC__Work_Performed__c = 'Test';
        wo.Verification_Result__c = 'Test'; 
        insert wo;
        System.assert(wo.Id != null, 'Work order got created');

        Test.startTest();
        Case cs1 = [SELECT Id FROM case LIMIT 1];
        System.assert(cs1.Id != null, 'fetched Case id');

        SVMXC__Service_Order__c wo1 = [SELECT id FROM SVMXC__Service_Order__c LIMIT 1];
        System.assert(wo1.Id != null, 'fetched WO id');

        List<SVMXC__Installed_Product__c> lstIP1 = [SELECT Id, Name FROM 
                                                    SVMXC__Installed_Product__c 
                                                    WHERE NAME = 'Test IP VM1' LIMIT 10];

        System.assert(lstIP1[0].Id != null, 'fetched IP id');
        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = lstIP1[0].Id;
        Test.setFixedSearchResults(fixedSearchResults);
        // Call the mainMethod
        List<AssociatedProductsWrapper> wrapperListCase = ManageAssociatedProductsController.mainMethod(cs1.Id, 'Test IP VM1', 'option1');
        List<AssociatedProductsWrapper> wrapperListWO = ManageAssociatedProductsController.mainMethod(wo1.Id, 'Test IP VM1', 'option1');
        
        //Perform assertions
        System.assertEquals(lstIP1[0].Id, wrapperListCase[0].id, 'Installed Products IDs should match');
        System.assertEquals(lstIP1[0].Id, wrapperListWO[0].id, 'Installed Products IDs should match');
        Test.stopTest();
    }


    @isTest
    static void testMainMethodProd() {
        //insert Account
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c = 'Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;
        System.assert(acc.Id != null,'Account got created');
        
        //insert Contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null, 'Contact got created');
            
        //insert Case
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.Status = 'Initiated';
        insert cs;
        System.assert(cs.Id != null, 'Case got created');

        List<Product2> lstpro = new List<Product2>();

        Product2 objProduct = new Product2(Name = STRING_PRODUCT_NAME, Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS, Material_Class__c = 'Consumables');
        lstpro.add(objProduct);
        
        
        Product2 objProduct1 = new Product2(Name = STRING_PRODUCT_NAME+'1',Service_Product_Type__c = 'Core', Source_System__c='SAP');
        lstpro.add(objProduct1);
        
        Product2 objProduct2 = new Product2(Name = STRING_PRODUCT_NAME+'2',Service_Product_Type__c = 'Spare');
        lstpro.add(objProduct2);
        
        insert lstpro;

        SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        wo.Evaluation__c='Test';
        wo.SVMXC__Work_Performed__c = 'Test';
        wo.Verification_Result__c = 'Test'; 
        insert wo;
        System.assert(wo.Id != null, 'Work order got created');

        Test.startTest();
        Case cs1 = [SELECT id FROM case LIMIT 1];
        System.assert(cs1.Id != null, 'fetched Case id');

        SVMXC__Service_Order__c wo1 = [SELECT id FROM SVMXC__Service_Order__c LIMIT 1];
        System.assert(wo1.Id != null, 'fetched WO id');

        List<Product2> lstProd1 = [SELECT Id, Name FROM Product2 WHERE name = 'Test Product VM1' LIMIT 10];
        System.assert(lstProd1[0].Id != null, 'fetched Product id');
        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = lstProd1[0].Id;
        Test.setFixedSearchResults(fixedSearchResults);
        // Call the mainMethod
        List<AssociatedProductsWrapper> wrapperListCase = ManageAssociatedProductsController.mainMethod(cs1.Id, 'Test Product VM1', 'option2');

        List<AssociatedProductsWrapper> wrapperListWO = ManageAssociatedProductsController.mainMethod(wo1.Id, 'Test Product VM1', 'option2');
        
        //Perform assertions
        System.assertEquals(lstProd1[0].Id, wrapperListCase[0].id, 'Products IDs should match');
        System.assertEquals(lstProd1[0].Id, wrapperListWO[0].id, 'Products IDs should match');
        Test.stopTest();
    }

    @isTest
    static void testMainMethodServCon() {
        //insert Account
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c = 'Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;
        System.assert(acc.Id != null,'Account got created');
        
        //insert Contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null, 'Contact got created');
            
        //insert Case
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.Status = 'Initiated';
        insert cs;
        System.assert(cs.Id != null, 'Case got created');

        List<SVMXC__Service_Contract__c> lstSrvCon = new List<SVMXC__Service_Contract__c>();

        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(acc.Id);
        objServiceContract.Zuora_Subscription_ID__c = '808080';
        objServiceContract.ERP_Contract_Type__c = 'Software (ZWS)';
        lstSrvCon.add(objServiceContract);
        
        SVMXC__Service_Contract__c objServiceContract1 = TestDataFieldService.createServiceContract(acc.Id);
        objServiceContract1.Name = 'Testinger';
        objServiceContract1.ERP_Contract_Type__c = 'Software (ZWS)';
        lstSrvCon.add(objServiceContract1);

        SVMXC__Service_Contract__c objServiceContract2 = TestDataFieldService.createServiceContract(acc.Id);
        objServiceContract2.Name = 'Testinger1';
        objServiceContract2.ERP_Contract_Type__c = 'Software (ZWS)';
        lstSrvCon.add(objServiceContract2);

        insert lstSrvCon; 

        SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        wo.Evaluation__c='Test';
        wo.SVMXC__Work_Performed__c = 'Test';
        wo.Verification_Result__c = 'Test'; 
        insert wo;
        System.assert(wo.Id != null, 'Work order got created');

        Case cs1 = [SELECT Id FROM Case LIMIT 1];
        System.assert(cs1!= null, 'fetched Case id');

        SVMXC__Service_Order__c wo1 = [SELECT Id FROM SVMXC__Service_Order__c LIMIT 1];
        System.assert(wo1!= null, 'fetched WO id');

        List<SVMXC__Service_Contract__c> lstSrvCon1 = [SELECT Id, Name 
                                                      FROM SVMXC__Service_Contract__c 
                                                      WHERE Name = 'Testinger1' LIMIT 10];
        System.assert(lstSrvCon1[0].Id != null, 'fetched Service Contract id');

        List<SVMXC__Service_Contract__c> lstSrvCon2 = [SELECT Id, Zuora_Subscription_ID__c 
                                                      FROM SVMXC__Service_Contract__c 
                                                      WHERE Zuora_Subscription_ID__c = '808080' LIMIT 10];
        System.assert(lstSrvCon2[0].Id != null, 'fetched Service Contract id');

        Test.startTest();

        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = lstSrvCon1[0].Id;
        Test.setFixedSearchResults(fixedSearchResults);
        // Call the mainMethod
        List<AssociatedProductsWrapper> wrapperListCase = ManageAssociatedProductsController.mainMethod(cs1.Id, 'Testinger1', 'option3');

        List<AssociatedProductsWrapper> wrapperListWO = ManageAssociatedProductsController.mainMethod(wo1.Id, 'Testinger1', 'option3');
        fixedSearchResults[0] = lstSrvCon2[0].Id;
        Test.setFixedSearchResults(fixedSearchResults);
        List<AssociatedProductsWrapper> wrapperListCaseZuora = ManageAssociatedProductsController.mainMethod(cs1.Id, '808080', 'option3');

        List<AssociatedProductsWrapper> wrapperListWOZuora = ManageAssociatedProductsController.mainMethod(wo1.Id, '808080', 'option3');
        //CMCM-5309 FR change 7th March 2024 ==> to cover the coverage of newly created method
        wrapperListWOZuora = ManageAssociatedProductsController.findProductsImp(wo1.Id, '808080', 'option3');

        
        //Perform assertions
        System.assertEquals(lstSrvCon1[0].Id, wrapperListCase[0].id, 'Service Contract IDs should match');
        System.assertEquals(lstSrvCon1[0].Id, wrapperListWO[0].id, 'Service Contract IDs should match');
        System.assertEquals(lstSrvCon2[0].Id, wrapperListCaseZuora[0].id, 'Service Contract IDs should match');
        System.assertEquals(lstSrvCon2[0].Id, wrapperListWOZuora[0].id, 'Service Contract IDs should match');
        Test.stopTest();
        Set<String> uniqueNames = new Set<String>();
        for (AssociatedProductsWrapper wrapper : wrapperListWO) {
            System.assert(!uniqueNames.contains(wrapper.name), 'Duplicate name found: ' + wrapper.name);
            uniqueNames.add(wrapper.name);
        }
    }

    @isTest
    static void testgetInstalledProductsListByAccount() {
        //insert Account
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c = 'Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;
        System.assert(acc.Id != null,'Account got created');

        //create product to add in installed product records related to CMCM-5309
        /*Product2 objProduct1 = new Product2(Name = STRING_INSTALLED_PRODUCT_NAME+'1',Service_Product_Type__c = 'Instrument');
        INSERT objProduct1;*/

        Product2 objProduct1 = TestDataMaster.initProduct(STRING_PRODUCT_CODE, STRING_PRODUCT_SERVICE_TYPE);
        objProduct1.Service_Product_Type__c = STRING_PRODUCT_SERVICE_TYPE;
        objProduct1.Service_Level__c = STRING_PRODUCT_SERVICE_LEVEL;
        objProduct1.Serial_Number_Profile__c = STRING_SERIAL_NUMBER;
        insert objProduct1;
        System.assert(objProduct1.id!=null, 'Product got created');

        //insert Contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null, 'Contact got created');
            
        //insert Case
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.Status = 'Initiated';
        cs.AccountId =acc.Id;
        insert cs;
        System.assert(cs.Id != null, 'Case got created');

        List<SVMXC__Installed_Product__c> lstIP = new List<SVMXC__Installed_Product__c>();
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        objInstalledProduct.SVMXC__Product__c = objProduct1.Id;
        lstIP.add(objInstalledProduct);
        
        SVMXC__Installed_Product__c objInstalledProduct1 = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME+'1', STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct1.SVMXC__Company__c = acc.Id;
        objInstalledProduct1.SVMXC__Product__c = objProduct1.Id;
        lstIP.add(objInstalledProduct1);

        SVMXC__Installed_Product__c objInstalledProduct2 = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME+'2', STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct2.SVMXC__Company__c = acc.Id;
        objInstalledProduct2.SVMXC__Product__c = objProduct1.Id;
        lstIP.add(objInstalledProduct2);
        insert lstIP;

        SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        wo.Evaluation__c='Test';
        wo.SVMXC__Work_Performed__c = 'Test';
        wo.Verification_Result__c = 'Test';
        wo.SVMXC__Company__c = acc.Id; 
        insert wo;
        System.assert(wo.Id != null, 'Work order got created');

        Test.startTest();
        Case cs1 = [SELECT id FROM case LIMIT 1];
        System.assert(cs1.Id != null, 'fetched Case id');

        SVMXC__Service_Order__c wo1 = [SELECT id FROM SVMXC__Service_Order__c LIMIT 1];
        System.assert(wo1.Id != null, 'fetched WO id');

        Account acc1 = [SELECT id FROM Account LIMIT 1];
        System.assert(acc1.Id != null,'Account got created');

        List<SVMXC__Installed_Product__c> lstIP1 = [SELECT id, name FROM SVMXC__Installed_Product__c WHERE SVMXC__Company__c =: acc1.Id LIMIT 10];
        System.assert(lstIP1[0].Id != null, 'fetched IP id');

        // Call the getInstalledProductsListByAccount
        List<SVMXC__Installed_Product__c> lstIPListByAccount = ManageAssociatedProductsController.getInstalledProductsListByAccount(cs1.Id,'Test IP VM');
        List<SVMXC__Installed_Product__c> lstIPListByAccount1 = ManageAssociatedProductsController.getInstalledProductsListByAccount(wo1.Id,'');
        System.assertEquals(3, lstIPListByAccount.size(),'List of Installed Products should have three item');
        System.assertEquals(3, lstIPListByAccount1.size(),'List of Installed Products should have three item');
        List<AssociatedProductsWrapper> wrapperCaseList = ManageAssociatedProductsController.mainMethod(cs1.Id, 'Test IP', 'option4');
        List<AssociatedProductsWrapper> wrapperWOList = ManageAssociatedProductsController.mainMethod(wo1.Id, 'Test IP', 'option4');
        Assert.isTrue(wrapperCaseList != null , 'wrapperCaseList is not null');
        Assert.isTrue(wrapperWOList != null, 'wrapperWOList is not null');
        Test.stopTest();
    }

    @isTest
    static void testgetServiceContractsListByAccount() {
        //insert Account
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c = 'Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;
        System.assert(acc.Id != null,'Account got created');
        
        //insert Contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null, 'Contact got created');
            
        //insert Case
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.Status = 'Initiated';
        insert cs;
        System.assert(cs.Id != null, 'Case got created');

        List<SVMXC__Service_Contract__c> lstSrvCon = new List<SVMXC__Service_Contract__c>();

        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(acc.Id);
        objServiceContract.Zuora_Subscription_ID__c = '808080';
        objServiceContract.ERP_Contract_Type__c = 'Software (ZWS)';
        lstSrvCon.add(objServiceContract);
        
        SVMXC__Service_Contract__c objServiceContract1 = TestDataFieldService.createServiceContract(acc.Id);
        objServiceContract1.Name = 'Testinger';
        objServiceContract1.ERP_Contract_Type__c = 'Software (ZWS)';
        lstSrvCon.add(objServiceContract1);

        SVMXC__Service_Contract__c objServiceContract2 = TestDataFieldService.createServiceContract(acc.Id);
        objServiceContract2.Name = 'Testinger1';
        objServiceContract2.ERP_Contract_Type__c = 'Software (ZWS)';
        lstSrvCon.add(objServiceContract2);

        insert lstSrvCon; 

        SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        wo.Evaluation__c='Test';
        wo.SVMXC__Work_Performed__c = 'Test';
        wo.Verification_Result__c = 'Test'; 
        insert wo;
        System.assert(wo.Id != null, 'Work order got created');

        Case cs1 = [SELECT id FROM Case LIMIT 1];
        System.assert(cs1.Id != null, 'fetched Case id');

        SVMXC__Service_Order__c wo1 = [SELECT id FROM SVMXC__Service_Order__c LIMIT 1];
        System.assert(wo1.Id != null, 'fetched WO id');

        Account acc1 = [select id from Account limit 1];
        System.assert(acc1.Id != null,'Account got created');

        List<SVMXC__Service_Contract__c> lstServCon1 = [SELECT id,name,Zuora_Subscription_ID__c 
                                                        FROM SVMXC__Service_Contract__c 
                                                        WHERE SVMXC__Company__c =: acc1.Id LIMIT 10];
        System.assert(lstServCon1[0].Id != null, 'fetched ServCon id');

        Test.startTest();
        // Call the getServiceContractsListByAccount
        List<SVMXC__Service_Contract__c> lstServConListByAccount = ManageAssociatedProductsController.getServiceContractsListByAccount(cs1.Id,'Testinger');
        System.assertEquals(2, lstServConListByAccount.size(),'List of Service Contracts should have two item');
        Test.stopTest();
    }

    @isTest
    static void testCreateAssociatdInstalledProducts() {
        //insert Account
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c = 'Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;
        System.assert(acc.Id != null,'Account got created');
        
        //insert Contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null, 'Contact got created');
            
        //insert Case
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.Status = 'Initiated';
        cases.skipCaseTrigger = true;// test class fix
        insert cs;
        System.assert(cs.Id != null, 'Case got created');

        SVMXC__Site__c objLocation = TestDataFieldService.createLocation('Test Location','Test Street','Ireland','123456','USD');
        insert objLocation;

        List<Product2> lstpro = new List<Product2>();

        Product2 objProduct = new Product2(Name = STRING_PRODUCT_NAME, Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS, Material_Class__c = 'Consumables',Source_System__c= 'SAP');
        lstpro.add(objProduct);
        
        
        Product2 objProduct1 = new Product2(Name = STRING_PRODUCT_NAME+'1',Service_Product_Type__c = 'Core',Source_System__c= 'SAP');
        lstpro.add(objProduct1);
        
        Product2 objProduct2 = new Product2(Name = STRING_PRODUCT_NAME+'2',Service_Product_Type__c = 'Spare',Source_System__c= 'SAP');
        lstpro.add(objProduct2);
        
        insert lstpro;

        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;

        Opportunity objOpportunity = TestDataOpportunity.getNewOpportunity(acc);

        Apttus_Proposal__Proposal__c objProposal = TestDataProposal.initProposal(acc.id, objOpportunity.id, 'Test Proposal', priceList.id, true, 'Draft', 'None');
        insert objProposal;

        Apttus_Config2__Order__c objOrder = new Apttus_Config2__Order__c();
    	objOrder.Apttus_QPConfig__ProposalId__c = objProposal.Id;
    	insert objOrder;

        Apttus_Config2__OrderLineItem__c orderLineItem = new Apttus_Config2__OrderLineItem__c();
        orderLineItem.Apttus_Config2__ProductId__c = objProduct.id;
        orderLineItem.Apttus_Config2__OrderId__c = objOrder.id;
        insert orderLineItem;

        List<SVMXC__Installed_Product__c> lstIP = new List<SVMXC__Installed_Product__c>();
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        objInstalledProduct.SVMXC__Site__c = objLocation.id;
        objInstalledProduct.SVMXC__Product__c = objProduct.id;
        lstIP.add(objInstalledProduct);
        
        SVMXC__Installed_Product__c objInstalledProduct1 = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME+'1', STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct1.SVMXC__Company__c = acc.Id;
        lstIP.add(objInstalledProduct1);

        SVMXC__Installed_Product__c objInstalledProduct2 = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME+'2', STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct2.SVMXC__Company__c = acc.Id;
        lstIP.add(objInstalledProduct2);
        insert lstIP;

        List<SVMXC__Service_Contract__c> lstSrvCon = new List<SVMXC__Service_Contract__c>();

        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(acc.Id);
        objServiceContract.Zuora_Subscription_ID__c = '808080';
        lstSrvCon.add(objServiceContract);
        
        SVMXC__Service_Contract__c objServiceContract1 = TestDataFieldService.createServiceContract(acc.Id);
        objServiceContract1.Name = 'Testinger';
        objServiceContract1.Order_Line_Item__c = orderLineItem.id;
        lstSrvCon.add(objServiceContract1);

        SVMXC__Service_Contract__c objServiceContract2 = TestDataFieldService.createServiceContract(acc.Id);
        objServiceContract2.Name = 'Testinger1';
        lstSrvCon.add(objServiceContract2);

        insert lstSrvCon; 

        SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        wo.Evaluation__c='Test';
        wo.SVMXC__Work_Performed__c = 'Test';
        wo.Verification_Result__c = 'Test'; 
        WorkOrders.skipWOTrigger = true;
        
        insert wo;
        System.assert(wo.Id != null, 'Work order got created');

        Test.startTest();
        Case cs1 = [SELECT Id FROM Case LIMIT 1];
        System.assert(cs1.Id != null, 'fetched Case id');

        SVMXC__Service_Order__c wo1 = [SELECT Id FROM SVMXC__Service_Order__c LIMIT 1];
        System.assert(wo1.Id != null, 'fetched WO id');

        Account acc1 = [SELECT Id FROM Account LIMIT 1];
        System.assert(acc1.Id != null,'Account got created');

        List<SVMXC__Installed_Product__c> lstIP1 = [SELECT Id,Name FROM SVMXC__Installed_Product__c WHERE Name = 'Test IP VM' LIMIT 10];

        List<Product2> lstProd1 = [SELECT id, Name FROM Product2 WHERE Name = 'Test Product VM' limit 10];

        List<SVMXC__Service_Contract__c> lstSrvCon1 = [SELECT id, Name FROM SVMXC__Service_Contract__c WHERE Name = 'Testinger' LIMIT 10];
        // Create test data, such as wrapperString with necessary fields
        List<Map<String, Object>> wrapperString = new List<Map<String, Object>>();

        // Populate test data in the wrapperString
        Map<String, Object> testData = new Map<String, Object>{
            'id' => lstIP1[0].id,
            'workOrderId' => wo1.Id,
            'caseId' => 'null'
        };
        wrapperString.add(testData);

        Map<String, Object> testServConData = new Map<String, Object>{
            'id' => lstSrvCon1[0].id,
            'workOrderId' => 'null',
            'caseId' => cs1.id
        };
        wrapperString.add(testServConData);
        Map<String, Object> testProdData = new Map<String, Object>{
            'id' => lstProd1[0].id,
            'workOrderId' => 'null',
            'caseId' => cs1.id
        };
        wrapperString.add(testProdData);

        ManageAssociatedProductsController.createAssociatdInstalledProducts(wrapperString);
        List<AssociatedProductsWrapper> wrapperListbyCase = ManageAssociatedProductsController.getAssociatedProductsList(cs1.Id);

        List<AssociatedProductsWrapper> wrapperListbyWO = ManageAssociatedProductsController.getAssociatedProductsList(wo1.Id);

        List<Associated_Product__c> lstassocProductsbyWO = ManageAssociatedProductsController.getAssociatedProductsListByCaseId(wo1.Id);

        List<Associated_Product__c> lstassocProductsbyCase = ManageAssociatedProductsController.getAssociatedProductsListByCaseId(cs1.Id);
        //CMCM-5309 FR change 7th March 2024 ==> START to cover the coverage of newly created methods
        lstassocProductsbyWO = ManageAssociatedProductsController.getAssociatedProductsListByCaseIdImp(wo1.Id);

        lstassocProductsbyCase = ManageAssociatedProductsController.getAssociatedProductsListByCaseIdImp(cs1.Id);
        //CMCM-5309 FR change 7th March 2024 ==> END
        List<Associated_Product__c> insertedRecords = [SELECT Id FROM Associated_Product__c limit 10];
        System.assertEquals(wrapperString.size(), insertedRecords.size(), 'Number of records inserted should match the input data');

        ManageAssociatedProductsController.createPrimaryAssociatdInstalledProducts(wrapperString,cs1.Id);//added by Dhairya Shah for CMCM - 8090
        List<Associated_Product__c> updatedRecords = [SELECT Id, Is_Primary__c FROM Associated_Product__c WHERE Is_Primary__c = false];
        System.assert(!updatedRecords.isEmpty(), 'There should be Associated_Product__c records with Is_Primary__c set to false.');
        System.assertNotEquals(null, wrapperListbyCase, 'wrapperListbyCase records should not be null');
        System.assertNotEquals(null, wrapperListbyWO, 'wrapperListbyWO records should not be null');
        System.assertNotEquals(null, lstassocProductsbyWO, 'lstassocProductsbyWO records should not be null');
        System.assertNotEquals(null, lstassocProductsbyCase, 'lstassocProductsbyCase records should not be null');
        Test.stopTest();
    }

    @isTest
    static void testCreatePrimaryAssociatdProducts() {
        //insert Account
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c = 'Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;
        System.assert(acc.Id != null,'Account got created');
        
        //insert Contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null, 'Contact got created');
            
        //insert Case
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.Status = 'Initiated';
        cases.skipCaseTrigger = true;// test class fix
        insert cs;
        System.assert(cs.Id != null, 'Case got created');

        SVMXC__Site__c objLocation = TestDataFieldService.createLocation('Test Location','Test Street','Ireland','123456','USD');
        insert objLocation;

        List<Product2> lstpro = new List<Product2>();

        Product2 objProduct = new Product2(Name = STRING_PRODUCT_NAME, Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS, Material_Class__c = 'Consumables',Source_System__c= 'SAP');
        lstpro.add(objProduct);
        
        
        Product2 objProduct1 = new Product2(Name = STRING_PRODUCT_NAME+'1',Service_Product_Type__c = 'Core',Source_System__c= 'SAP');
        lstpro.add(objProduct1);
        
        Product2 objProduct2 = new Product2(Name = STRING_PRODUCT_NAME+'2',Service_Product_Type__c = 'Spare',Source_System__c= 'SAP');
        lstpro.add(objProduct2);
        
        insert lstpro;

        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;

        Opportunity objOpportunity = TestDataOpportunity.getNewOpportunity(acc);

        Apttus_Proposal__Proposal__c objProposal = TestDataProposal.initProposal(acc.id, objOpportunity.id, 'Test Proposal', priceList.id, true, 'Draft', 'None');
        insert objProposal;

        Apttus_Config2__Order__c objOrder = new Apttus_Config2__Order__c();
    	objOrder.Apttus_QPConfig__ProposalId__c = objProposal.Id;
    	insert objOrder;

        Apttus_Config2__OrderLineItem__c orderLineItem = new Apttus_Config2__OrderLineItem__c();
        orderLineItem.Apttus_Config2__ProductId__c = objProduct.id;
        orderLineItem.Apttus_Config2__OrderId__c = objOrder.id;
        insert orderLineItem;

        List<SVMXC__Installed_Product__c> lstIP = new List<SVMXC__Installed_Product__c>();
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        objInstalledProduct.SVMXC__Site__c = objLocation.id;
        objInstalledProduct.SVMXC__Product__c = objProduct.id;
        lstIP.add(objInstalledProduct);
        
        SVMXC__Installed_Product__c objInstalledProduct1 = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME+'1', STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct1.SVMXC__Company__c = acc.Id;
        lstIP.add(objInstalledProduct1);

        SVMXC__Installed_Product__c objInstalledProduct2 = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME+'2', STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct2.SVMXC__Company__c = acc.Id;
        lstIP.add(objInstalledProduct2);
        insert lstIP;

        List<SVMXC__Service_Contract__c> lstSrvCon = new List<SVMXC__Service_Contract__c>();

        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(acc.Id);
        objServiceContract.Zuora_Subscription_ID__c = '808080';
        lstSrvCon.add(objServiceContract);
        
        SVMXC__Service_Contract__c objServiceContract1 = TestDataFieldService.createServiceContract(acc.Id);
        objServiceContract1.Name = 'Testinger';
        objServiceContract1.Order_Line_Item__c = orderLineItem.id;
        lstSrvCon.add(objServiceContract1);

        SVMXC__Service_Contract__c objServiceContract2 = TestDataFieldService.createServiceContract(acc.Id);
        objServiceContract2.Name = 'Testinger1';
        lstSrvCon.add(objServiceContract2);

        insert lstSrvCon; 

        SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        wo.Evaluation__c='Test';
        wo.SVMXC__Work_Performed__c = 'Test';
        wo.Verification_Result__c = 'Test'; 
        WorkOrders.skipWOTrigger = true;
        
        insert wo;
        System.assert(wo.Id != null, 'Work order got created');

        Test.startTest();
        Case cs1 = [SELECT Id FROM Case LIMIT 1];
        System.assert(cs1.Id != null, 'fetched Case id');

        SVMXC__Service_Order__c wo1 = [SELECT Id FROM SVMXC__Service_Order__c LIMIT 1];
        System.assert(wo1.Id != null, 'fetched WO id');

        Account acc1 = [SELECT Id FROM Account LIMIT 1];
        System.assert(acc1.Id != null,'Account got created');

        List<SVMXC__Installed_Product__c> lstIP1 = [SELECT Id,Name FROM SVMXC__Installed_Product__c WHERE Name = 'Test IP VM' LIMIT 10];

        List<Product2> lstProd1 = [SELECT id, Name FROM Product2 WHERE Name = 'Test Product VM' limit 10];

        List<SVMXC__Service_Contract__c> lstSrvCon1 = [SELECT id, Name FROM SVMXC__Service_Contract__c WHERE Name = 'Testinger' LIMIT 10];
        // Create test data, such as wrapperString with necessary fields
        List<Map<String, Object>> wrapperString = new List<Map<String, Object>>();

        // Populate test data in the wrapperString
        Map<String, Object> testData = new Map<String, Object>{
            'id' => lstIP1[0].id,
            'workOrderId' => wo1.Id,
            'caseId' => 'null'
        };
        wrapperString.add(testData);

        Map<String, Object> testServConData = new Map<String, Object>{
            'id' => lstSrvCon1[0].id,
            'workOrderId' => 'null',
            'caseId' => cs1.id
        };
        wrapperString.add(testServConData);
        Map<String, Object> testProdData = new Map<String, Object>{
            'id' => lstProd1[0].id,
            'workOrderId' => 'null',
            'caseId' => cs1.id
        };
        wrapperString.add(testProdData);
        //ManageAssociatedProductsController.createPrimaryAssociatdInstalledProducts(wrapperString,cs1.Id);//added by Dhairya Shah for CMCM - 8090
        ManageAssociatedProductsController.createPrimaryAssociatdInstalledProducts(wrapperString,wo1.Id);//added by Dhairya Shah for CMCM - 8090
        Test.stopTest();
    }

    /* //CMCM-6367 change on 29th March 2024 ==>Added below testmethod to cover -'updategetAssociatedProductsList' method */

    @IsTest
    static void testUpdategetAssociatedProductsList() {
        List<Associated_Product__c> recordsList = new List<Associated_Product__c>();
        for(Integer i = 0; i < 5; i++) {
            Associated_Product__c record = new Associated_Product__c(
                Is_Primary__c = false,
                Software_Version__c = 'Test Version'
            );
            recordsList.add(record);
        }
        insert recordsList;

        String jsonData = JSON.serialize(recordsList);
        Test.startTest();
        ManageAssociatedProductsController.updategetAssociatedProductsList(jsonData);
        Test.stopTest();

        List<Associated_Product__c> updatedRecords = [
            SELECT Id, Name, Is_Primary__c, Software_Version__c
            FROM Associated_Product__c
            WHERE Id IN :recordsList
        ];

        for(Associated_Product__c record : updatedRecords) {
            System.assertEquals(false, record.Is_Primary__c);
            System.assertEquals('Test Version', record.Software_Version__c);
        }
    }
}