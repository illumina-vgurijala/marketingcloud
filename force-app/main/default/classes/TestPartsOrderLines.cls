/***************************************************************************************************************************************
 * NAME   : TestPartsOrder
 * DESCRIPTION  : TestClass for Parts Order Lines Trigger
 *        DCP-326  :Validation the open parts orders on Case
 *                Annotated with SeeAllData=true due to dependency on ServiceMax managed trigger
 *    
 * @AUTHOR : Veerendra 
 * @DATE   : 16-Jun-2018  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Veerendra             16-Jun-2018            Initial Version
 * Soumya                21-Aug-2018            Added validatePartsOrderLineForInstallationWorkOrder method
 * Prashanth             14-Jun-2019            Added partsOrderReApprovalTest method
 * Adyasha               09-Mar-2021            DCP-41580: Added autoCreateReturnPO method
  ****************************************************************************************************************************************/ 
@IsTest(SeeAllData=True)
public class TestPartsOrderLines {
    
    public static final boolean BOOLEAN_CONSUMABLES_INCLUDED = false;
    public static final string STRING_PRODUCT_MATERIAL_CLASS = 'Consumable';
    public static final string STRING_PRODUCT_INSTRUMENT_CLASS = 'Instrument';
    public static final string STRING_CASE_RECORDTYPENAME = 'Service Request';
    public static final string STRING_PRODUCT_CODE = 'Test 123';
    public static final string STRING_PRODUCT_CODE1 = 'Test 1234';
    public static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP VM';
    public static final string STRING_CURRENCY = 'USD';
    public static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    public static final string STRING_CONTRACT_STATUS = 'Active';
    public static final string STRING_PARTS_ORDER_TYPE = 'Shipment';
    public static final string STRING_PARTS_ORDER_TYPE_RETURN = 'Return';
    public static final string STRING_PARTS_ORDER_LINE_NON_BILLABLE_REASON = 'Goodwill';
    public static final string STRING_PARTS_ORDER_LINE_STATUS = 'Open';
    public static final string STRING_INSTALLED_PRODUCT_NAME1 = 'Test IP VM1';
    public static final String STRING_TIMEZONE = 'America/Los_Angeles';   
    public static final string STRING_COST_CENTER_CODE = '123';
    public static final String STRING_PRODUCT_STOCK_STATUS_AVAILABLE = 'Available';
    public static final String STRING_PARTS_ORDER_LINE_IS_NULL = 'objPartsOrderLine is null';

    //DCP-41580 
    public static final String STRING_ACCOUNT_GROUP_SOLD_TO = 'Sold To';
    public static final String STRING_WORK_ORDER_TYPE_INSTALLATION = 'Installation';
    public static final String STRING_FROM_LOCATION = 'testing';
    public static final String STRING_TO_LOCATION = 'testingTwo';
    public static final String STRING_SHIPPING_TYPE_TRUNK = 'Trunk';
    public static final String STRING_WORK_ORDER_RECORD_TYPE_SERVICE_SUPPORT = 'Service Support';
    public static final String STRING_WORK_ORDER_STATUS_INITIATED ='Initiated';
    public static final String STRING_PARTS_ORDER_CONTACT_NAME ='Test Parts Order Name';
    public static final String STRING_PARTS_ORDER_CONTACT_PHONE = '12322';
    public static final String STRING_PARTS_ORDER_LINE_SERIAL_NUMBER_LIST = '1234';
    //End of DCP-41580
    
    static Account objAccountTest;
    static Product2 nonSerializedProdTest;
    static Product2 serializedProdTest;
    static SVMXC__Site__c location1Test;
    static SVMXC__Site__c objLocationRecTest;
    static SVMXC__Installed_Product__c objInstalledProductTest;
    static Case objCaseTest;
    
    /*******************************************************************************************************
    * @description test data setup
    */
    public static void testDataCreation() {
        objAccountTest = TestDataAccount.getNewAccount(); //create account
        //Account objAccupdateTest = [select id, Account_Group__c from Account where id =: objAccount.id];
        objAccountTest.Account_Group__c = 'Distributor';
        update objAccountTest;
        Contact objContact = TestDataContact.getNewContact(objAccountTest); //create contact.
        
        //Create non serialized product
        List<Product2> productLst = new List<Product2>();
        nonSerializedProdTest = new Product2();
        nonSerializedProdTest.Name = 'Test Non-Serialized Product';
        nonSerializedProdTest.IsActive = true;
        nonSerializedProdTest.SVMXC__Tracking__c = 'Non-Tracked';
        nonSerializedProdTest.SVMXC__Stockable__c = true;
        nonSerializedProdTest.SVMXC__Enable_Serialized_Tracking__c = false;
        productLst.add(nonSerializedProdTest);  
        
        //Create serialized product
        serializedProdTest = new Product2();
        serializedProdTest.Name = 'Test Serialized Product';
        serializedProdTest.IsActive = true;
        serializedProdTest.SVMXC__Tracking__c = 'Serialized';
        serializedProdTest.SVMXC__Stockable__c = true;
        serializedProdTest.SVMXC__Enable_Serialized_Tracking__c = true;
        serializedProdTest.Serial_Number_Profile__c = 'IL01';
        serializedProdTest.FRU_Eligible__c = 'FRU use only';
        productLst.add(serializedProdTest);  
        insert productLst;
        
        //Create Location
        List<SVMXC__Site__c> lstSites = new LIst<SVMXC__Site__c>();
        location1Test = new SVMXC__Site__c();
        location1Test.Name = 'Test Location 1';
        location1Test.SVMXC__Account__c = objAccountTest.Id;
        location1Test.SVMXC__Stocking_Location__c = true;
        lstSites.add(location1Test);//insert location1;
        objLocationRecTest = new SVMXC__Site__c(Name = 'test');
        lstSites.add(objLocationRecTest);
        insert lstSites;
        
        //create Installed Product
        objInstalledProductTest = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProductTest.SVMXC__Company__c = objAccountTest.Id;
        insert objInstalledProductTest;
        
        
        //create case
        objCaseTest = TestDataCase.initServiceRequestCase(objContact);
        objCaseTest.SVMXC__Component__c = objInstalledProductTest.Id;
        insert objCaseTest;
    } 
  
    /*******************************************************************************************************
     * @description test method for insert of Parts Order Lines
    */
    static testmethod void newPartsOrderLinesCreation() {
        cs_Apex_Settings__c cs=cs_Apex_Settings__c.getInstance(UserInfo.getProfileID());
		cs.Bypass_All_Validations__c = true;
		upsert cs cs_Apex_Settings__c.Id;

        Channel_Partner_Profile_Settings__c cp = Channel_Partner_Profile_Settings__c.getInstance(UserInfo.getProfileID());
        cp.Is_Channel_Partner__c= false;
        upsert cp;
        
        Account objAccount = TestDataAccount.getNewAccount();
        objAccount.Account_Group__c = STRING_ACCOUNT_GROUP_SOLD_TO;
        update objAccount;
        Contact objContact = TestDataContact.getNewContact(objAccount);


        List<Product2> lstProducts = new List<Product2>();
        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = STRING_PRODUCT_INSTRUMENT_CLASS;
        objProduct.Source_System__c = 'SAP';
        lstProducts.add(objProduct);
        insert lstProducts;
        
    
        //creating FRU List
        FRU_List__c objFRUList = new FRU_List__c(ERP_Parent_Product__c = lstProducts[0].id, ERP_Product__c = lstProducts[0].id);
        insert objFRUList;

        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Product__c=lstProducts[0].Id;
        objInstalledProduct.SVMXC__Company__c= objAccount.Id;
        
        insert objInstalledProduct;
        

        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.Consumables_Included__c=false;
        objServiceContract.Status__c = STRING_CONTRACT_STATUS;
        insert objServiceContract;
        

        SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(objInstalledProduct.Id);
        objCoveredProduct.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert objCoveredProduct;
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        objCase.SVMXC__Component__c = objInstalledProduct.Id;
        insert objCase;
        
        SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'test');
        insert objLocationRec;
        
        
        SVMXC__Service_Group__c objGrp = TestDataFieldService.createServiceTeam('TestServiceTeamName','Antarctica');
        insert objGrp;
        
        SVMXC__Service_Group_Members__c objGrpMember = TestDataFieldService.createTechnician(userInfo.getUserId(),'Test',objGrp.id);
        objGrpMember.SVMXC__Inventory_Location__c = objLocationRec.Id;
        insert objGrpMember;
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WORK_ORDER_RECORD_TYPE_SERVICE_SUPPORT, objCase.Id, STRING_WORK_ORDER_STATUS_INITIATED);
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Order_Type__c = STRING_WORK_ORDER_TYPE_INSTALLATION;
        workOrder.SVMXC__Group_Member__c = objGrpMember.Id;
        workOrder.Record_Created_from_SFM__c=true;
        workOrder.Cost_Center__c = 123456;
        Test.startTest();
        insert workOrder;

        Applied_Contract__c objEntitlement = TestDataFieldService.createEntitlement(objCase.Id, workOrder.Id, objServiceContract.Id);
        insert objEntitlement;
        Applied_Contract__c insertedEntitlement = [Select Case_Number__c from Applied_Contract__c where Id =: objEntitlement.Id];
        System.assertEquals(insertedEntitlement.Case_Number__c, objCase.Id);
        
        List<SVMXC__RMA_Shipment_Order__c> lstPartsOrders= new List<SVMXC__RMA_Shipment_Order__c>();
        SVMXC__RMA_Shipment_Order__c objPartsOrder = TestDataFieldService.createPartsOrder(objCase.Id);
        objPartsOrder.SVMXC__Service_Order__c = workOrder.Id;
        objPartsOrder.SVMXC__Order_Status__c = 'Open';
        objPartsOrder.ERP_Sales_Order_Number__c = '10';
        objPartsOrder.Contact_Name__c='Test';
        objPartsOrder.Contact_Phone__c='Test';
        objPartsOrder.Requested_By__c=userInfo.getUserId();//added for 38817
        objPartsOrder.Shipping_Location__c=objLocationRec.id;
        lstPartsOrders.add(objPartsOrder);
        
        insert lstPartsOrders;
        
        Id shipmentRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get('Shipment').getRecordTypeId();
        
        Test.StopTest();
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(lstPartsOrders[0].Id);
        objPartsOrderLine.SVMXC__Product__c = lstProducts[0].Id;
        objPartsOrderLine.From_Location__c = objLocationRec.id;
        objPartsOrderLine.RecordTypeId = shipmentRecordTypeId; 
        objPartsOrderLine.Reason__c = STRING_PARTS_ORDER_LINE_NON_BILLABLE_REASON;
        //objPartsOrderLine.Reason__c = 'Consumable Warranty';
        objPartsOrderLine.SVMXC__Line_Status__c = STRING_PARTS_ORDER_LINE_STATUS;
        insert objPartsOrderLine;
        
        Integer invocations = Limits.getEmailInvocations(); //added for DCP-38817
        PartsOrderLineNonBillableNotification obj = new PartsOrderLineNonBillableNotification(); //added for DCP-38817
        obj.partsOrderId = lstPartsOrders[0].Id;
        List < SVMXC__RMA_Shipment_Line__c > lstpartsOrderLines = obj.getListPartsOrderLines(); 
        
        SVMXC__RMA_Shipment_Line__c insertedPartsOrderLine = [Select  PO_Number__c, SVMXC__RMA_Shipment_Order__c, Is_Billable__c from SVMXC__RMA_Shipment_Line__c where SVMXC__RMA_Shipment_Order__c =: objPartsOrder.Id limit 1];
            
        System.assertEquals(insertedPartsOrderLine.SVMXC__RMA_Shipment_Order__c, objPartsOrder.Id);
        System.assertEquals(false, insertedPartsOrderLine.Is_Billable__c);
        //System.assertEquals(1, invocations, 'An email has not been sent'); //added for DCP-38817
        System.assertEquals(1,lstpartsOrderLines.size(),'Parts Order Line Not Qualified for NonBillable Notification.'); //added for DCP-38817
        
    }
        
    /*******************************************************************************************************
     * @description test method for insert of Parts Order Lines
    */
    static testmethod void newPartsOrderLinesCreation1() {
        List<Product2> lstProducts = new List<Product2>();
        List<SVMXC__RMA_Shipment_Order__c> lstPartsOrders= new List<SVMXC__RMA_Shipment_Order__c>();
        
        Account objAccount = TestDataAccount.getNewAccount();
        objAccount.Account_Group__c = STRING_ACCOUNT_GROUP_SOLD_TO;
        update objAccount;
        Contact objContact = TestDataContact.getNewContact(objAccount);
        Test.startTest();
        Product2 objProduct1 = TestDataMaster.initProduct(STRING_PRODUCT_CODE1);
        objProduct1.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        objProduct1.Source_System__c = 'SAP';
        lstProducts.add(objProduct1);
        insert lstProducts; 
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Company__c= objAccount.Id;
        objInstalledProduct.SVMXC__Product__c=lstProducts[0].Id;
        insert objInstalledProduct;
        
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        objCase.SVMXC__Component__c = objInstalledProduct.Id;
        insert objCase;
        
        SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'test');
        insert objLocationRec;
        
        SVMXC__Site__c toLocation = new SVMXC__Site__c(Name = 'test1',SVMXC__Stocking_Location__c=true,Type__c=STRING_SHIPPING_TYPE_TRUNK);
        
        insert toLocation;
        SVMXC__RMA_Shipment_Order__c objPartsOrder1 = TestDataFieldService.createPartsOrder(objCase.Id);
        objPartsOrder1.SVMXC__Order_Type__c = STRING_PARTS_ORDER_TYPE;
        objPartsOrder1.SVMXC__Order_Status__c = 'Open';
        objPartsOrder1.ERP_Sales_Order_Number__c = '11';
        objPartsOrder1.Contact_Name__c='Test';
        objPartsOrder1.Contact_Phone__c='Test';
        objPartsOrder1.Shipping_Location__c=objLocationRec.id;
        objPartsOrder1.SVMXC__Destination_Location__c=toLocation.id;
        lstPartsOrders.add(objPartsOrder1);
        insert lstPartsOrders;
        system.assert(objPartsOrder1.id!=null, 'objPartsOrder1 Id is null');
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine1 = TestDataFieldService.createPartsOrderLines(lstPartsOrders[0].Id);
        objPartsOrderLine1.SVMXC__Product__c = lstProducts[0].Id;
        objPartsOrderLine1.Is_Part_Order_Line_for_Spare_Parts__c = true;
        
        try{
            insert objPartsOrderLine1;          
        }catch(exception ex){
            system.debug(ex.getMessage());
        }
        Test.stopTest();
    }   
        
    /*******************************************************************************************************
     * @description test method for insert of Parts Order Lines for Installtion Work Order
    */
    static testmethod void validatePartsOrderLineForInstallationWorkOrder(){
        SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'test');
        insert objLocationRec;
        objAccountTest = TestDataAccount.getNewAccount(); //create account
        objAccountTest.Account_Group__c = 'Distributor';
        update objAccountTest;
        Test.startTest();
        Contact objContact = TestDataContact.getNewContact(objAccountTest); //create contact.
        Case objCaseTest = TestDataCase.initServiceRequestCase(objContact);
        
        insert objCaseTest;

        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder('Field Service',objCaseTest.Id,STRING_WORK_ORDER_STATUS_INITIATED);
        objWorkOrder.SVMXC__Order_Type__c = STRING_WORK_ORDER_TYPE_INSTALLATION;
        objWorkOrder.Is_Auto_Created__c=true;
        insert objWorkOrder; 
        Test.stopTest();
        SVMXC__RMA_Shipment_Order__c objPartsOrder = TestDataFieldService.createPartsOrderForInstallationWO(objWorkOrder.Id);
        objPartsOrder.SVMXC__Order_Status__c = 'Open';
        objPartsOrder.ERP_Sales_Order_Number__c = String.valueOf(Math.random());
        objPartsOrder.Contact_Name__c='Test';
        objPartsOrder.Contact_Phone__c='Test';
        objPartsOrder.Shipping_Location__c=objLocationRec.id;
        insert objPartsOrder;
            
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        insert objPartsOrderLine;

        List<SVMXC__RMA_Shipment_Line__c> lstPartsOrderLines = [Select id, Is_Billable__c from SVMXC__RMA_Shipment_Line__c where Id=:objPartsOrderLine.Id];
        
        system.assert(!lstPartsOrderLines[0].Is_Billable__c);
        
    }
  
    /*******************************************************************************************************
     * @description test method for Billable logic
    */
    @IsTest
    static void testUpdateIsBillable(){

        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId()); 
            setting.Bypass_Triggers_By_Object_1__c = 'SVMXC__Service_Order__c';
            setting.Bypass_Triggers_By_Object_2__c = 'SVMXC__RMA_Shipment_Order__c';
            upsert setting; 
        //Create Account
        Account objAcc = TestDataAccount.getAccount('TestAccount','USD');
        objAcc.Account_Group__c='Distributor';
        insert objAcc;

        //Create Case
        Contact objCon = TestDataPerson.getNewContact(objAcc.Id);
        Case objCase = TestDataCase.getNewComplaintCase(objCon);
        objCase.RecordTypeId = ServiceUtilityCollection.getRecordTypeId('Case', 'Service Request');
        update objCase;
        
        SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'test');
        insert objLocationRec;
        
        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrderWithoutCase(STRING_WORK_ORDER_RECORD_TYPE_SERVICE_SUPPORT,STRING_WORK_ORDER_STATUS_INITIATED, STRING_WORK_ORDER_TYPE_INSTALLATION);
        Test.startTest();
        SVMXC__RMA_Shipment_Order__c objPartsOrder = TestDataFieldService.createPartsOrderForInstallationWO(objWorkOrder.Id);
        objPartsOrder.SVMXC__Order_Status__c = 'Open';
        objPartsOrder.ERP_Sales_Order_Number__c = '13';
        objPartsOrder.Contact_Name__c='Test';
        objPartsOrder.Contact_Phone__c='Test';
        objPartsOrder.Shipping_Location__c=objLocationRec.id;
        insert objPartsOrder;
        
        Product2 product1 = TestDataMaster.createProduct(false);
        product1.Material_Class__c = 'Consumables';
        insert product1;
        
        SVMXC__RMA_Shipment_Order__c objPartsOrderWithoutCase = TestDataFieldService.createPartsOrderForInstallationWO(objWorkOrder.Id);
        objPartsOrderWithoutCase.SVMXC__Case__c = NULL;
        objPartsOrderWithoutCase.SVMXC__Order_Status__c = 'Open';
        objPartsOrderWithoutCase.ERP_Sales_Order_Number__c = '19';
        objPartsOrderWithoutCase.Contact_Name__c='Test';
        objPartsOrderWithoutCase.Contact_Phone__c='Test';
        objPartsOrderWithoutCase.Shipping_Location__c=objLocationRec.id;
        
        insert objPartsOrderWithoutCase;
       
        objPartsOrder.SVMXC__Case__c = objCase.Id;
        objPartsOrder.Allow_Parts_Order_Line_Deletion__c=true;
        update objPartsOrder;


        List<SVMXC__RMA_Shipment_Line__c> listPartLinesToInsert = new List<SVMXC__RMA_Shipment_Line__c>();
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        objPartsOrderLine.SVMXC__Product__c = product1.Id;
        listPartLinesToInsert.add(objPartsOrderLine);

        System.debug('objPartsOrderWithoutCase-->'+objPartsOrderWithoutCase.SVMXC__Case__c);
        SVMXC__RMA_Shipment_Line__c objPartsOrderLineNoCase = TestDataFieldService.createPartsOrderLines(objPartsOrderWithoutCase.Id);
        listPartLinesToInsert.add(objPartsOrderLineNoCase);
        
        insert listPartLinesToInsert;

        //Test delete event
        PartsOrders.allowDeletion = true;
        delete listPartLinesToInsert;

        //Test undelete event
        undelete listPartLinesToInsert;
        
        //Test before / afterupdate event
        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        insert objProduct;
        Test.stopTest();
        for(SVMXC__RMA_Shipment_Line__c objPOLine : listPartLinesToInsert){
            objPOLine.SVMXC__Line_Status__c = 'Requested';
            objPOLine.SVMXC__Product__c = objProduct.Id;
            //objPOLine.Reason__c = STRING_PARTS_ORDER_LINE_NON_BILLABLE_REASON;
            objPOLine.Reason__c = 'Consumable Warranty';
            objPOLine.Cost_Center__c = 1234;
            objPOLine.PO_Number__c = STRING_COST_CENTER_CODE;
        }
        update listPartLinesToInsert;
        
        System.assertEquals(true, listPartLinesToInsert.size() > 1);
    }
  
    /*
    *  @AUTHOR:  Dipika 
    *  @DESCRIPTION: If the Parts Order line is updated to shipped, swap covered product and update IP 
    */  
    static testmethod void testSwapProcessOnShippedPOL() {
        
        Account objAccount = TestDataAccount.getAccount('Test1');
        objAccount.Account_Group__c = STRING_ACCOUNT_GROUP_SOLD_TO;
        
        Account objAccount1 = TestDataAccount.getAccount('Test2');
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
        
        SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'test');
        insert objLocationRec;
        
        List<SVMXC__RMA_Shipment_Order__c> lstPartsOrders= new List<SVMXC__RMA_Shipment_Order__c>();
        SVMXC__RMA_Shipment_Order__c objPartsOrder = TestDataFieldService.createPartsOrder(null);
        objPartsOrder.SVMXC__Order_Type__c = 'Advance Exchange';
        objPartsOrder.SVMXC__Order_Status__c = 'Open';
        objPartsOrder.ERP_Sales_Order_Number__c = '144';
        objPartsOrder.Contact_Name__c='Test';
        objPartsOrder.Contact_Phone__c='Test';
        objPartsOrder.Shipping_Location__c=objLocationRec.id;
        lstPartsOrders.add(objPartsOrder);
        
        SVMXC__RMA_Shipment_Order__c objPartsOrder1 = TestDataFieldService.createPartsOrder(null);
        objPartsOrder1.SVMXC__Order_Type__c = STRING_PARTS_ORDER_TYPE_RETURN;
        objPartsOrder1.SVMXC__Order_Status__c = 'Open';
        objPartsOrder1.ERP_Sales_Order_Number__c = '188';
        objPartsOrder1.Contact_Name__c='Test';
        objPartsOrder1.Contact_Phone__c='Test';
        objPartsOrder1.Shipping_Location__c=objLocationRec.id;
        lstPartsOrders.add(objPartsOrder1);

        insert lstPartsOrders;
        Test.startTest();
        Id shipmentRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get('Shipment').getRecordTypeId();
        
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(lstPartsOrders[0].Id);
        objPartsOrderLine.From_Location__c = objLocationRec.id;
        objPartsOrderLine.RecordTypeId = shipmentRecordTypeId; 
        objPartsOrderLine.SVMXC__Line_Status__c = STRING_PARTS_ORDER_LINE_STATUS;
        objPartsOrderLine.Requested_Delivery_Date__c = Date.today();
        objPartsOrderLine.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        objPartsOrderLine.SVMXC__Product__c = product1.Id;
        
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine1 = TestDataFieldService.createPartsOrderLines(lstPartsOrders[1].Id);
        objPartsOrderLine1.From_Location__c = objLocationRec.id;
        objPartsOrderLine1.RecordTypeId = shipmentRecordTypeId; 
        //objPartsOrderLine1.Reason__c = STRING_PARTS_ORDER_LINE_NON_BILLABLE_REASON;
        objPartsOrderLine1.Reason__c = 'Consumable Warranty';
        objPartsOrderLine1.SVMXC__Line_Status__c = STRING_PARTS_ORDER_LINE_STATUS;
        objPartsOrderLine1.Requested_Delivery_Date__c = Date.today();
        objPartsOrderLine1.SVMXC__Serial_Number__c = objInstalledProduct1.Id;
        objPartsOrderLine1.SVMXC__Product__c = product2.Id;
        insert new list<SVMXC__RMA_Shipment_Line__c> {objPartsOrderLine1};
        
        objPartsOrderLine.SVMXC__Master_Order_Line__c = objPartsOrderLine1.Id;
        insert objPartsOrderLine;
        Test.stopTest();
        system.assert(objPartsOrderLine.id!=null, 'objPartsOrderLine id is null');            
        objPartsOrderLine.SVMXC__Line_Status__c = 'Shipped';
        update objPartsOrderLine;
        
    }

     /*******************************************************************************************************
     * @description test method for Work Detail Creation
    */
    static testmethod void validateWorkDetailCreationFromPO() {

        cs_Apex_Settings__c cs=cs_Apex_Settings__c.getInstance(UserInfo.getProfileID());
		cs.Bypass_All_Validations__c = true;
		upsert cs cs_Apex_Settings__c.Id;

        Channel_Partner_Profile_Settings__c cp = Channel_Partner_Profile_Settings__c.getInstance(UserInfo.getProfileID());
        cp.Is_Channel_Partner__c= false;
        upsert cp;
        
        // Insert locations
        List<SVMXC__Site__c> lstLocations = new List<SVMXC__Site__c>();
        SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'test', SVMXC__Stocking_Location__c = true, Type__c = STRING_SHIPPING_TYPE_TRUNK);
        lstLocations.add(objLocationRec);
        SVMXC__Site__c objLocationRec1 = new SVMXC__Site__c(Name = 'test1', SVMXC__Stocking_Location__c = true, Type__c = STRING_SHIPPING_TYPE_TRUNK);
        lstLocations.add(objLocationRec1);
        insert lstLocations;
    
        // Insert Work Order
        SVMXC__Service_Order__c objWorkOrder = new SVMXC__Service_Order__c();
        objWorkOrder.RecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByName().get(STRING_WORK_ORDER_RECORD_TYPE_SERVICE_SUPPORT).getRecordTypeId();
        objWorkOrder.SVMXC__Order_Status__c = STRING_WORK_ORDER_STATUS_INITIATED;
        objWorkOrder.SVMXC__Order_Type__c = STRING_WORK_ORDER_TYPE_INSTALLATION;
        objWorkOrder.Warning_Message__c = 'tes';
        objWorkOrder.Cost_Center__c = 123456;
        insert objWorkOrder;
    
        // Insert Products (Serialized and Batched)
        List<Product2> lstProduct = new List<Product2>();
        Product2 product1 = TestDataMaster.createProduct(false);
        product1.Material_Group__c = '41';
        product1.Serial_Number_Profile__c = STRING_COST_CENTER_CODE;
        lstProduct.add(product1);
    
        Product2 product2 = TestDataMaster.createProduct(false);
        product2.Material_Group__c = '41';
        product2.Batch_Management__c = true;
        lstProduct.add(product2);
        insert lstProduct;
    
        Test.startTest();
        // Insert Installed Product
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Product__c = product1.Id;
        insert objInstalledProduct;
    
        // Insert Parts Order
        SVMXC__RMA_Shipment_Order__c objPartsOrder = TestDataFieldService.createPartsOrderForInstallationWO(objWorkOrder.Id);
        objPartsOrder.SVMXC__Order_Status__c = 'Open';
        objPartsOrder.ERP_Sales_Order_Number__c = '132';
        objPartsOrder.Contact_Name__c = 'Test';
        objPartsOrder.Contact_Phone__c = 'Test';
        objPartsOrder.SVMXC__Order_Type__c = 'Advance Exchange';
        objPartsOrder.SVMXC__Destination_Location__c = objLocationRec.id;
        objPartsOrder.Ship_To_Company__c = 'test';
        objPartsOrder.Care_Of__c = 'test';
        objPartsOrder.Shipping_Street__c = 'test';
        objPartsOrder.Shipping_City__c = 'test';
        objPartsOrder.Shipping_Postal_Code__c = 'test';
        objPartsOrder.Shipping_Country__c = 'Angola [AO]';
        objPartsOrder.Shipping_State_Province__c = 'N/A';
        insert objPartsOrder;
    
        // Debugging parts order insert
        System.debug('Inserted Parts Order: ' + objPartsOrder.Id);
    
        // Insert Shipment Lines (Serialized and Batched)
        Id shipmentRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get('Shipment').getRecordTypeId();
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        objPartsOrderLine.From_Location__c = objLocationRec.id;
        objPartsOrderLine.RecordTypeId = shipmentRecordTypeId;
        objPartsOrderLine.SVMXC__Actual_Quantity2__c = 1;
        objPartsOrderLine.SVMXC__Line_Status__c = 'Open';
        objPartsOrderLine.Requested_Delivery_Date__c = Date.today();
        objPartsOrderLine.SVMXC__Product__c = product1.Id;
        objPartsOrderLine.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        objPartsOrderLine.Reason__c = 'Goodwill';
    
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine1 = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        objPartsOrderLine1.RecordTypeId = shipmentRecordTypeId;
        objPartsOrderLine1.SVMXC__Actual_Quantity2__c = 2;
        objPartsOrderLine1.SVMXC__Line_Status__c = 'Open';
        objPartsOrderLine1.Requested_Delivery_Date__c = Date.today() + 1;
        objPartsOrderLine1.SVMXC__Product__c = product2.Id;
        objPartsOrderLine1.Batch_Number__c = '1234';
        objPartsOrderLine1.Reason__c = 'Goodwill';
    
        insert new List<SVMXC__RMA_Shipment_Line__c>{objPartsOrderLine, objPartsOrderLine1};
    
        // Debugging shipment line insert
        System.debug('Inserted Shipment Lines: ' + objPartsOrderLine.Id + ', ' + objPartsOrderLine1.Id);
    
        // Update Shipment Lines
        objPartsOrderLine.SVMXC__Line_Status__c = 'Shipped';
        objPartsOrderLine1.SVMXC__Line_Status__c = 'Shipped';
        update new List<SVMXC__RMA_Shipment_Line__c>{objPartsOrderLine, objPartsOrderLine1};
    
        // Test controller
        POLGoodwillApprovalTableController objClass = new POLGoodwillApprovalTableController();
        objClass.partsOrderId = [select id from SVMXC__RMA_Shipment_Order__c where id =: objPartsOrder.Id].Id;
    
        // Debugging parts order lines fetched by controller
        System.debug('Parts Order Lines returned by controller: ' + objClass.getListPartsOrderLines().size());
    
        // Assertion
        System.assert(objClass.getListPartsOrderLines().size() > 0, 'No Parts Order Lines returned by the controller');
        
        Test.stopTest();
    }

    static testmethod void validateWorkDetailCreationFromPOScenario2(){
        List<SVMXC__Site__c> lstLocations = new List<SVMXC__Site__c>();
        SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'test',SVMXC__Stocking_Location__c=true,Type__c=STRING_SHIPPING_TYPE_TRUNK,ERP_Customer_ID__c='000');
        lstLocations.add(objLocationRec);
        insert lstLocations;
        
        SVMXC__Service_Order__c objWorkOrder= new SVMXC__Service_Order__c();
        objWorkOrder.RecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByName().get(STRING_WORK_ORDER_RECORD_TYPE_SERVICE_SUPPORT).getRecordTypeId();
        objWorkOrder.SVMXC__Order_Status__c =STRING_WORK_ORDER_STATUS_INITIATED;
        objWorkOrder.SVMXC__Order_Type__c = STRING_WORK_ORDER_TYPE_INSTALLATION;
        objWorkOrder.Warning_Message__c='tes';
        objWorkOrder.Cost_Center__c = 123456;
        insert objWorkOrder;

        //Serialized spare
        List<Product2> lstProduct = new List<Product2>();
        
        Product2 product3 = TestDataMaster.createProduct(false);
		product3.ProductCode = '789';
        product3.Material_Class__c  = 'Consumables';
        lstProduct.add(product3);

        insert lstProduct;

        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Product__c=product3.Id;
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
        
		//Insert Product Stock records
		List<SVMXC__Product_Stock__c> lstProductStock = new List<SVMXC__Product_Stock__c>();
		SVMXC__Product_Stock__c prodStock3 = new SVMXC__Product_Stock__c(SVMXC__Location__c = objLocationRec.Id ,SVMXC__Status__c = 'Available', SVMXC__Quantity2__c = 1, SVMXC__Product__c = product3.Id, SVMX_PS_External_ID__c = '000789');
		lstProductStock.add(prodStock3);
		insert lstProductStock;
		
        Test.startTest();
        Id shipmentRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get('Shipment').getRecordTypeId();
        
        List<SVMXC__RMA_Shipment_Line__c> lstPartsOrderLine = new List<SVMXC__RMA_Shipment_Line__c>() ;   
        List<SVMXC__RMA_Shipment_Line__c> lstUpdatePartsOrderLine = new List<SVMXC__RMA_Shipment_Line__c>() ;  
        
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine3 = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        objPartsOrderLine3.To_Location__c = objLocationRec.id;
        objPartsOrderLine3.RecordTypeId = shipmentRecordTypeId; 
        //objPartsOrderLine3.Reason__c = STRING_PARTS_ORDER_LINE_NON_BILLABLE_REASON;
        objPartsOrderLine3.Reason__c = 'Consumable Warranty';
        objPartsOrderLine3.SVMXC__Actual_Quantity2__c= 5;
        objPartsOrderLine3.Consumed_QTY__c = 2;
        objPartsOrderLine3.Batch_Number__c = '123456';
        objPartsOrderLine3.SVMXC__Line_Status__c = 'Open';
        objPartsOrderLine3.Requested_Delivery_Date__c = Date.today();
        objPartsOrderLine3.SVMXC__Product__c = product3.Id;
        objPartsOrderLine3.SVMXC__Serial_Number__c=objInstalledProduct.id;
        lstPartsOrderLine.add(objPartsOrderLine3);

        insert lstPartsOrderLine;

        objPartsOrderLine3.SVMXC__Line_Status__c = 'Shipped';
        lstUpdatePartsOrderLine.add(objPartsOrderLine3);
        update lstUpdatePartsOrderLine;
        Test.stopTest();

        list<SVMXC__Service_Order_Line__c> lstWD = [select id from SVMXC__Service_Order_Line__c WHERE SVMXC__Service_Order__c =  :objWorkOrder.Id ];
        system.assert(!lstWD.isEmpty() , 'Work Detail Creation failed.' );   
    }

    /*******************************************************************************************************
     * @description test method for From Location validation
    */
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
        //objPartsOrderLine.Reason__c = STRING_PARTS_ORDER_LINE_NON_BILLABLE_REASON;
        objPartsOrderLine.Reason__c = 'Consumable Warranty';
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
        //objPartsOrderLine1.Reason__c = STRING_PARTS_ORDER_LINE_NON_BILLABLE_REASON;
        objPartsOrderLine1.Reason__c = 'Consumable Warranty';
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
        Test.stopTest();
    }
    
    /*******************************************************************************************************
     * @description test method for POL Restriction
    */
    static testmethod void testPOLRestrictions(){
        SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'test',SVMXC__Stocking_Location__c=true,Type__c=STRING_SHIPPING_TYPE_TRUNK);

        insert objLocationRec;      
        SVMXC__Service_Order__c objWorkOrder= new SVMXC__Service_Order__c();
        objWorkOrder.RecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByName().get(STRING_WORK_ORDER_RECORD_TYPE_SERVICE_SUPPORT).getRecordTypeId();
        objWorkOrder.SVMXC__Order_Status__c =STRING_WORK_ORDER_STATUS_INITIATED;
        objWorkOrder.SVMXC__Order_Type__c = STRING_WORK_ORDER_TYPE_INSTALLATION;
        objWorkOrder.Warning_Message__c='tes';
        objWorkOrder.Cost_Center__c = 123456;
        insert objWorkOrder;

        
        Product2 product3 = TestDataMaster.createProduct(false);
        product3.Service_Product_Type__c = 'Spare';
        product3.ProductCode='12345';
        product3.Material_Group__c = '41';
        insert product3;
        
        Parts_Ordering_Restrictions__c objPOR = new Parts_Ordering_Restrictions__c();
        objPOR.Product__c=product3.id;
        objPOR.Clinical_Type__c='Clinical';
        objPOR.Customer_Type__c = 'Commercial';
        objPOR.Territory_Region__c = 'AMR';
        insert objPOR;

        Account objAcc = TestDataAccount.getAccount('TestAccount','USD');
        objAcc.Account_Group__c='Distributor';
        objAcc.Clinical_Type__c='Clinical';
        objAcc.Customer_Type__c = 'Commercial';
        objAcc.Customer_Sub_Type__c = 'CRO';
        objAcc.Territory_Region__c = 'AMR';
        insert objAcc;
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Product__c=product3.Id;
        objInstalledProduct.SVMXC__Company__c= objAcc.Id;
        
        insert objInstalledProduct;     
        SVMXC__RMA_Shipment_Order__c objPartsOrder5 = TestDataFieldService.createPartsOrderForInstallationWO(objWorkOrder.Id);

        objPartsOrder5.SVMXC__Order_Status__c = 'Open';
        objPartsOrder5.SVMXC__Company__c=objAcc.id;
        objPartsOrder5.ERP_Sales_Order_Number__c = '1323006';
        objPartsOrder5.Contact_Name__c='Test';
        objPartsOrder5.Contact_Phone__c='Test';
        objPartsOrder5.SVMXC__Order_Type__c='Shipment';
        objPartsOrder5.SVMXC__Destination_Location__c=objLocationRec.id;
        objPartsOrder5.SVMXC__Source_Location__c = objLocationRec.id;
        objPartsOrder5.Ship_To_Company__c='test';
        objPartsOrder5.Care_Of__c='test';
        objPartsOrder5.Shipping_Street__c='test'; 
        objPartsOrder5.Shipping_City__c='test'; 
        objPartsOrder5.Shipping_Postal_Code__c='test'; 
        objPartsOrder5.Shipping_Country__c='Angola [AO]';
        objPartsOrder5.Shipping_State_Province__c='N/A';
            
        insert objPartsOrder5;
        Id shipmentRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get('Shipment').getRecordTypeId();      
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine3 = TestDataFieldService.createPartsOrderLines(objPartsOrder5.Id);
        objPartsOrderLine3.To_Location__c = objLocationRec.id;
        objPartsOrderLine3.RecordTypeId = shipmentRecordTypeId; 
        objPartsOrderLine3.Reason__c = STRING_PARTS_ORDER_LINE_NON_BILLABLE_REASON;
        objPartsOrderLine3.SVMXC__Actual_Quantity2__c= 5;
        objPartsOrderLine3.Consumed_QTY__c = 2;
        objPartsOrderLine3.Batch_Number__c = '123456';
        objPartsOrderLine3.SVMXC__Line_Status__c = 'Open';
        objPartsOrderLine3.Requested_Delivery_Date__c = Date.today();
        objPartsOrderLine3.SVMXC__Product__c = product3.Id;
        objPartsOrderLine3.SVMXC__Serial_Number__c=objInstalledProduct.id;
        try{
        insert objPartsOrderLine3;      
        }
        Catch(exception e){
            system.assert(e.getMessage().contains('is not approved to order'));
        }
    }
  
    /**
     * @Author: Prashanth
     * @Description: If the Parts Order Line's product/quanity changed, respective parts order should be re-approved.
     **/
    static testmethod void partsOrderReApprovalTest(){
        SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'test');
        insert objLocationRec;
        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrderWithoutCase(STRING_WORK_ORDER_RECORD_TYPE_SERVICE_SUPPORT,STRING_WORK_ORDER_STATUS_INITIATED, STRING_WORK_ORDER_TYPE_INSTALLATION);
        SVMXC__RMA_Shipment_Order__c objPartsOrder = TestDataFieldService.createPartsOrderForInstallationWO(objWorkOrder.Id);
        objPartsOrder.SVMXC__Order_Status__c = 'Open';
        objPartsOrder.ERP_Sales_Order_Number__c = String.valueOf(Math.random());
        objPartsOrder.Contact_Name__c='Test';
        objPartsOrder.Contact_Phone__c='Test';
        objPartsOrder.Shipping_Location__c=objLocationRec.id;
        insert objPartsOrder;
        
        objPartsOrder.SVMXC__Order_Status__c = 'Approved';
        update objPartsOrder;
        
        Product2 product1 = TestDataMaster.createProduct(false);
        product1.Material_Class__c = 'Consumables';
        insert product1;

        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        objPartsOrderLine.SVMXC__Product__c = product1.Id;
        objPartsOrderLine.Service_Product_Type_Instrument__c = true;
        objPartsOrderLine.SVMXC__Actual_Quantity2__c = 1;
        insert objPartsOrderLine;
        system.assert(objPartsOrderLine.id!=null, STRING_PARTS_ORDER_LINE_IS_NULL);
        Test.startTest();
        objPartsOrderLine.SVMXC__Actual_Quantity2__c = 2;
        update objPartsOrderLine;
        Test.stopTest();

    }

    /**
     * @Author: Soumya
     * @Description: To check if To and From Location is derived from Parts Order
     **/
    static testmethod void testToAndFromLocationFromPO(){
        SVMXC__Site__c fromLocation = new SVMXC__Site__c(Name = 'test',SVMXC__Stocking_Location__c=true,Type__c=STRING_SHIPPING_TYPE_TRUNK);
        insert fromLocation;

        SVMXC__Site__c toLocation = new SVMXC__Site__c(Name = 'test1',SVMXC__Stocking_Location__c=true,Type__c=STRING_SHIPPING_TYPE_TRUNK);
        insert toLocation;

        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrderWithoutCase(STRING_WORK_ORDER_RECORD_TYPE_SERVICE_SUPPORT,STRING_WORK_ORDER_STATUS_INITIATED, STRING_WORK_ORDER_TYPE_INSTALLATION);
        SVMXC__RMA_Shipment_Order__c objPartsOrder = TestDataFieldService.createPartsOrderForInstallationWO(objWorkOrder.Id);
        objPartsOrder.SVMXC__Order_Status__c = 'Open';
        objPartsOrder.ERP_Sales_Order_Number__c =String.valueOf(Math.random());
        objPartsOrder.Contact_Name__c='Test';
        objPartsOrder.Contact_Phone__c='Test';
        objPartsOrder.Shipping_Location__c=fromLocation.id;
        objPartsOrder.SVMXC__Source_Location__c=fromLocation.id;
        objPartsOrder.SVMXC__Destination_Location__c=toLocation.id;
        insert objPartsOrder;

        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        insert objPartsOrderLine;

        SVMXC__RMA_Shipment_Line__c insertedPartsOrderLine = [Select Id,From_Location__c,To_Location__c from SVMXC__RMA_Shipment_Line__c where id = :objPartsOrderLine.id][0];
        system.assertEquals(insertedPartsOrderLine.From_Location__c,fromLocation.id);
        system.assertEquals(insertedPartsOrderLine.To_Location__c,toLocation.id);

    }
    

    /*******************************************************************************************************
     * @description test method for Contract Update logic
    */
    static testmethod void testupdateContractOnPO(){
        Account objAccount = TestDataAccount.getNewAccount();
        objAccount.Account_Group__c = STRING_ACCOUNT_GROUP_SOLD_TO;
        update objAccount;
        Contact objContact = TestDataContact.getNewContact(objAccount);


        List<Product2> lstProducts = new List<Product2>();
        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = 'Spare';
        lstProducts.add(objProduct);
        //added by prashanth
        //start
        Product2 objProduct1 = TestDataMaster.initProduct(STRING_PRODUCT_CODE1);
        objProduct1.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        lstProducts.add(objProduct1);
        //end
    
        insert lstProducts;
        
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.Consumables_Included__c=true;
        objServiceContract.Parts_Included__c=true;
        objServiceContract.Status__c = STRING_CONTRACT_STATUS;
        insert objServiceContract;
        

        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        
        insert objCase;
        SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'test');
        insert objLocationRec;
        
        SVMXC__Service_Group__c objGrp = TestDataFieldService.createServiceTeam('TestServiceTeamName','Antarctica');
        insert objGrp;
        
        SVMXC__Service_Group_Members__c objGrpMember = TestDataFieldService.createTechnician(userInfo.getUserId(),'Test',objGrp.id);
        objGrpMember.SVMXC__Inventory_Location__c = objLocationRec.Id;
        insert objGrpMember;
        Test.startTest(); /// moved here to avoid 101 exception
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WORK_ORDER_RECORD_TYPE_SERVICE_SUPPORT, objCase.Id, STRING_WORK_ORDER_STATUS_INITIATED);
    
        workOrder.SVMXC__Order_Type__c = STRING_WORK_ORDER_TYPE_INSTALLATION;
        workOrder.SVMXC__Group_Member__c = objGrpMember.Id;
        workOrder.Record_Created_from_SFM__c=true;
        workOrder.Cost_Center__c = 123456;
        insert workOrder;
        set<Id> setWOID = new set<Id>();
        setWOId.add(workOrder.Id);
        Applied_Contract__c objEntitlement = TestDataFieldService.createEntitlement(objCase.Id, workOrder.Id, objServiceContract.Id);
        insert objEntitlement;
        
        SVMXC__Site__c toLocation = new SVMXC__Site__c(Name = 'test1',SVMXC__Stocking_Location__c=true,Type__c=STRING_SHIPPING_TYPE_TRUNK);
        
        insert toLocation;
        
        List<SVMXC__RMA_Shipment_Order__c> lstPartsOrders= new List<SVMXC__RMA_Shipment_Order__c>();
        SVMXC__RMA_Shipment_Order__c objPartsOrder = TestDataFieldService.createPartsOrder(objCase.Id);
        objPartsOrder.SVMXC__Service_Order__c = workOrder.Id;
        objPartsOrder.SVMXC__Order_Type__c = 'Shipment';
        //end
        objPartsOrder.SVMXC__Order_Status__c = 'Open';
        objPartsOrder.ERP_Sales_Order_Number__c = '10';
        objPartsOrder.Contact_Name__c='Test';
        objPartsOrder.Contact_Phone__c='Test';
        objPartsOrder.Shipping_Location__c=objLocationRec.id;
        objPartsOrder.Requested_Delivery_Date__c = system.today();
        objPartsOrder.SVMXC__Destination_Location__c=toLocation.id;
        lstPartsOrders.add(objPartsOrder);
      
        insert lstPartsOrders;
        Test.stopTest(); // moved here to avoid 101 exception  

        Id shipmentRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get('Shipment').getRecordTypeId();
        
        
        List<SVMXC__RMA_Shipment_Line__c> lstPartsOrds = new List<SVMXC__RMA_Shipment_Line__c>();
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(lstPartsOrders[0].Id);
        objPartsOrderLine.SVMXC__Product__c = lstProducts[0].Id;
        
        objPartsOrderLine.RecordTypeId = shipmentRecordTypeId; 
        //objPartsOrderLine.Reason__c = STRING_PARTS_ORDER_LINE_NON_BILLABLE_REASON;
        objPartsOrderLine.Reason__c = 'Consumable Warranty';
        objPartsOrderLine.SVMXC__Line_Status__c = 'Open';
        objPartsOrderLine.Requested_Delivery_Date__c = system.today();
        lstPartsOrds.add(objPartsOrderLine);
       // insert objPartsOrderLine;
       
        //added by prashanth
        system.debug('lstProducts:'+lstProducts);
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine1 = TestDataFieldService.createPartsOrderLines(lstPartsOrders[0].Id);
        objPartsOrderLine1.SVMXC__Product__c = lstProducts[1].Id;
        objPartsOrderLine1.From_Location__c = objLocationRec.id;
        objPartsOrderLine1.RecordTypeId = shipmentRecordTypeId; 
        objPartsOrderLine1.Requested_Delivery_Date__c = system.today();
        objPartsOrderLine1.SVMXC__Line_Status__c = 'Open';
        lstPartsOrds.add(objPartsOrderLine1);
        //insert objPartsOrderLine1; 
        insert lstPartsOrds;
        
        objPartsOrderLine1.SVMXC__Product__c = lstProducts[1].Id;
        update objPartsOrderLine1;
        List<Applied_Contract__c> lst = new List<Applied_Contract__c>();
        lst = new AppliedContractsSelector().selectWOEntitlements(setWOId);
        system.assert(!lst.isEmpty(), 'lst is empty');
    }
        
    /*******************************************************************************************************
     * @description test method for Contract Update logic
    */
    static testmethod void testupdateContractOnPO2() {
        Account objAccount = TestDataAccount.getNewAccount();
        objAccount.Account_Group__c = STRING_ACCOUNT_GROUP_SOLD_TO;
        update objAccount;
        Contact objContact = TestDataContact.getNewContact(objAccount);
        
        
        List<Product2> lstProducts = new List<Product2>();
        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Material_Group__c = '41';
        objProduct.Service_Product_Type__c = 'Spare';
        lstProducts.add(objProduct);
        //added by prashanth
        //start
        Product2 objProduct1 = TestDataMaster.initProduct(STRING_PRODUCT_CODE1);
        objProduct1.Material_Class__c = 'Consumables';
        objProduct1.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        lstProducts.add(objProduct1);
        //end
        
        insert lstProducts;
        System.debug('ttcc the lstProducts '+lstProducts[0].Service_Product_Type__c+lstProducts[1].Service_Product_Type__c); 
        System.debug('ttcc the lstProducts '+lstProducts[0].Id+lstProducts[1].Id);
        
        
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.Consumables_Included__c=true;
        objServiceContract.Parts_Included__c=true;
        objServiceContract.Status__c = STRING_CONTRACT_STATUS;
        insert objServiceContract;
        
        
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        
        insert objCase;
        SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'test',Type__c = STRING_SHIPPING_TYPE_TRUNK);
        insert objLocationRec;
        
        SVMXC__Service_Group__c objGrp = TestDataFieldService.createServiceTeam('TestServiceTeamName','Antarctica');
        insert objGrp;
        
        SVMXC__Service_Group_Members__c objGrpMember = TestDataFieldService.createTechnician(userInfo.getUserId(),'Test',objGrp.id);
        objGrpMember.SVMXC__Inventory_Location__c = objLocationRec.Id;
        insert objGrpMember;
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WORK_ORDER_RECORD_TYPE_SERVICE_SUPPORT, objCase.Id, STRING_WORK_ORDER_STATUS_INITIATED);
        
        workOrder.SVMXC__Order_Type__c = STRING_WORK_ORDER_TYPE_INSTALLATION;
        workOrder.SVMXC__Group_Member__c = objGrpMember.Id;
        workOrder.Record_Created_from_SFM__c=true;
        insert workOrder;
        set<Id> setWOID = new set<Id>();
        setWOId.add(workOrder.Id);
        Test.startTest();
        Applied_Contract__c objEntitlement = TestDataFieldService.createEntitlement(objCase.Id, workOrder.Id, objServiceContract.Id);
        insert objEntitlement;
        System.debug('ttcc objEntitlement '+objEntitlement);
        
        List<SVMXC__RMA_Shipment_Order__c> lstPartsOrders= new List<SVMXC__RMA_Shipment_Order__c>();
        SVMXC__RMA_Shipment_Order__c objPartsOrder = TestDataFieldService.createPartsOrder(objCase.Id);
        objPartsOrder.SVMXC__Service_Order__c = workOrder.Id;
        objPartsOrder.SVMXC__Order_Type__c = 'Shipment';
        //end
        objPartsOrder.SVMXC__Order_Status__c = 'Open';
        objPartsOrder.ERP_Sales_Order_Number__c = '10';
        objPartsOrder.Contact_Name__c='Test';
        objPartsOrder.Contact_Phone__c='Test';
        objPartsOrder.Shipping_Location__c=objLocationRec.id;
        objPartsOrder.SVMXC__Destination_Location__c=objLocationRec.id;
        objPartsOrder.Requested_Delivery_Date__c = system.today();
        lstPartsOrders.add(objPartsOrder);
        insert lstPartsOrders;
        
        
        Id shipmentRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get('Shipment').getRecordTypeId();
        
        List<SVMXC__RMA_Shipment_Line__c> objPartsOrderLineList = new List<SVMXC__RMA_Shipment_Line__c>();
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(lstPartsOrders[0].Id);
        objPartsOrderLine.SVMXC__Product__c = lstProducts[0].Id;
        
        objPartsOrderLine.RecordTypeId = shipmentRecordTypeId; 
        objPartsOrderLine.SVMXC__Line_Status__c = 'Open';
        objPartsOrderLine.Requested_Delivery_Date__c = system.today();
        objPartsOrderLineList.add(objPartsOrderLine);
        
        //added by prashanth
        system.debug('lstProducts:'+lstProducts);
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine1 = TestDataFieldService.createPartsOrderLines(lstPartsOrders[0].Id);
        objPartsOrderLine1.SVMXC__Product__c = lstProducts[1].Id;
        objPartsOrderLine1.From_Location__c = objLocationRec.id;
        objPartsOrderLine1.RecordTypeId = shipmentRecordTypeId; 
        objPartsOrderLine1.Requested_Delivery_Date__c = system.today();
        objPartsOrderLine1.SVMXC__Line_Status__c = 'Open';
        objPartsOrderLineList.add(objPartsOrderLine1);
        insert objPartsOrderLineList;
        Test.stopTest();
        System.debug('ttcc objPartsOrderLine1 Service_Product_Type__c '+objPartsOrderLine1.Service_Product_Type__c+objPartsOrderLine1.Id+' '+objPartsOrderLine1.SVMXC__Product__c);
        objPartsOrderLine1.SVMXC__Product__c = lstProducts[0].Id;
        update objPartsOrderLine1;
        
        List<Applied_Contract__c> lst = new List<Applied_Contract__c>();
        lst = new AppliedContractsSelector().selectWOEntitlements(setWOId);
        system.assert(!lst.isEmpty(), 'lst is empty');
    }
    
    /*******************************************************************************************************
     * @description test method for new Parts Order Line Creation
    */
    static testmethod void newPartsOrderLinesCreation3() {
        Account objAccount = TestDataAccount.getNewAccount();
        objAccount.Account_Group__c = STRING_ACCOUNT_GROUP_SOLD_TO;
        update objAccount;
        Contact objContact = TestDataContact.getNewContact(objAccount);
        
        
        List<Product2> lstProducts = new List<Product2>();
        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Material_Group__c = '41';
        objProduct.Service_Product_Type__c = 'Spare';
        lstProducts.add(objProduct);
        
        insert lstProducts;
        
        SVMXC__Service_Plan__c objServicePlan = new SVMXC__Service_Plan__c(Name = 'Parts Only',Parts_Included__c=true,SVMXC__Active__c = true );
        insert objServicePlan;
        
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.SVMXC__Service_Plan__c = objServicePlan.Id;
        objServiceContract.Parts_Included__c=true;
        objServiceContract.Status__c = STRING_CONTRACT_STATUS;
        insert objServiceContract;
        
        
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        
        insert objCase;
        SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'test',Type__c = STRING_SHIPPING_TYPE_TRUNK);
        insert objLocationRec;
        
        SVMXC__Service_Group__c objGrp = TestDataFieldService.createServiceTeam('TestServiceTeamName','Antarctica');
        insert objGrp;
        
        SVMXC__Service_Group_Members__c objGrpMember = TestDataFieldService.createTechnician(userInfo.getUserId(),'Test',objGrp.id);
        objGrpMember.SVMXC__Inventory_Location__c = objLocationRec.Id;
        insert objGrpMember;
        
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, STRING_WORK_ORDER_STATUS_INITIATED);
        
        workOrder.SVMXC__Order_Type__c = 'Service Activities';
        workOrder.SVMXC__Group_Member__c = objGrpMember.Id;
        workOrder.Record_Created_from_SFM__c=true;
        insert workOrder;
        set<Id> setWOID = new set<Id>();
        setWOId.add(workOrder.Id);
        Applied_Contract__c objEntitlement = TestDataFieldService.createEntitlement(objCase.Id, workOrder.Id, objServiceContract.Id);
        insert objEntitlement;
        
        List<SVMXC__RMA_Shipment_Order__c> lstPartsOrders= new List<SVMXC__RMA_Shipment_Order__c>();
        SVMXC__RMA_Shipment_Order__c objPartsOrder = TestDataFieldService.createPartsOrder(objCase.Id);
        objPartsOrder.SVMXC__Service_Order__c = workOrder.Id;
        objPartsOrder.SVMXC__Order_Type__c = 'Shipment';
        //end
        objPartsOrder.SVMXC__Order_Status__c = 'Open';
        objPartsOrder.ERP_Sales_Order_Number__c = '10';
        objPartsOrder.Contact_Name__c='Test';
        objPartsOrder.Contact_Phone__c='Test';
        objPartsOrder.Shipping_Location__c=objLocationRec.id;
        objPartsOrder.SVMXC__Destination_Location__c=objLocationRec.id;
        objPartsOrder.Requested_Delivery_Date__c = system.today();
        lstPartsOrders.add(objPartsOrder);
        Test.startTest();
        insert lstPartsOrders;
        
        
        Id shipmentRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get('Shipment').getRecordTypeId();
        
        
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(lstPartsOrders[0].Id);
        objPartsOrderLine.SVMXC__Product__c = lstProducts[0].Id;
        
        objPartsOrderLine.RecordTypeId = shipmentRecordTypeId; 
        objPartsOrderLine.SVMXC__Line_Status__c = 'Open';
        objPartsOrderLine.Requested_Delivery_Date__c = system.today();
        insert objPartsOrderLine;
        system.assert(objPartsOrderLine.id!=null, STRING_PARTS_ORDER_LINE_IS_NULL);
        
    }
    
    /**
     * @Author: Digvijay 
     * @Description: To Validate DCIR error validation
     **/
    static testmethod void testvalidateIfDCIRAgreementIsGenerated(){
        List<SVMXC__Site__c> lstlocation =new List<SVMXC__Site__c>();
        SVMXC__Site__c fromLocation = new SVMXC__Site__c(Name = 'test',SVMXC__Stocking_Location__c=true,Type__c=STRING_SHIPPING_TYPE_TRUNK);
        lstlocation.add(fromLocation);

        SVMXC__Site__c toLocation = new SVMXC__Site__c(Name = 'test1',SVMXC__Stocking_Location__c=true,Type__c=STRING_SHIPPING_TYPE_TRUNK);
        lstlocation.add(toLocation);

        insert lstlocation;

        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrderWithoutCase(STRING_WORK_ORDER_RECORD_TYPE_SERVICE_SUPPORT,STRING_WORK_ORDER_STATUS_INITIATED, STRING_WORK_ORDER_TYPE_INSTALLATION);
        SVMXC__RMA_Shipment_Order__c objPartsOrder = TestDataFieldService.createPartsOrderForInstallationWO(objWorkOrder.Id);
        objPartsOrder.SVMXC__Order_Status__c = 'Open';
        objPartsOrder.ERP_Sales_Order_Number__c = String.valueOf(Math.random());
        objPartsOrder.Contact_Name__c='Test';
        objPartsOrder.Contact_Phone__c='Test';
        objPartsOrder.Shipping_Location__c=FromLocation.id;
        objPartsOrder.SVMXC__Source_Location__c=FromLocation.id;
        objPartsOrder.SVMXC__Destination_Location__c=toLocation.id;
        insert objPartsOrder;

        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        objPartsOrderLine.Is_DCIR_Filled__c = false;
        objPartsOrderLine.Enable_DCIR__c = false;
        insert objPartsOrderLine;
        
        test.startTest();
        
        try{
            objPartsOrderLine.Is_DCIR_Filled__c=true;
            objPartsOrderLine.Enable_DCIR__c = true;
            update objPartsOrderLine;
        }Catch(Exception ex){
                system.assert(ex.getMessage().contains(Label.POLDCIRCheckError));
        }
        
        test.stopTest();
    }
  
    /**
     * @Author: Harsh Shukla 
     * @Description: To Validate Service Loaner Agreement error validation
     **/
    static testmethod void testvalidateIfLoanerAgreementIsGenerated() {
        Channel_Partner_Profile_Settings__c cp = Channel_Partner_Profile_Settings__c.getInstance(UserInfo.getProfileID());
        cp.Is_Channel_Partner__c= false;
        upsert cp;
        
        Boolean expectedExceptionThrown = false;
    
        // Create and insert locations
        List<SVMXC__Site__c> lstlocation = new List<SVMXC__Site__c>();
        SVMXC__Site__c fromLocation = new SVMXC__Site__c(Name = 'test', SVMXC__Stocking_Location__c = true, Type__c = STRING_SHIPPING_TYPE_TRUNK);
        lstlocation.add(fromLocation);
    
        SVMXC__Site__c toLocation = new SVMXC__Site__c(Name = 'test1', SVMXC__Stocking_Location__c = true, Type__c = STRING_SHIPPING_TYPE_TRUNK);
        lstlocation.add(toLocation);
    
        insert lstlocation;
    
        // Create a work order and parts order
        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrderWithoutCase(STRING_WORK_ORDER_RECORD_TYPE_SERVICE_SUPPORT, STRING_WORK_ORDER_STATUS_INITIATED, STRING_WORK_ORDER_TYPE_INSTALLATION);
        SVMXC__RMA_Shipment_Order__c objPartsOrder = TestDataFieldService.createPartsOrderForInstallationWO(objWorkOrder.Id);
        objPartsOrder.SVMXC__Order_Status__c = 'Open';
        objPartsOrder.ERP_Sales_Order_Number__c = String.valueOf(Math.random());
        objPartsOrder.Contact_Name__c = 'Test';
        objPartsOrder.Contact_Phone__c = 'Test';
        objPartsOrder.Shipping_Location__c = fromLocation.Id;
        objPartsOrder.SVMXC__Source_Location__c = fromLocation.Id;
        objPartsOrder.SVMXC__Destination_Location__c = toLocation.Id;
        insert objPartsOrder;
    
        // Create and insert parts order line
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        objPartsOrderLine.Loaner_Agreement_Signed__c = false;
        insert objPartsOrderLine;
    
        // Start test execution
        Test.startTest();
        
        // Debugging before updating the Loaner Agreement Signed flag
        System.debug('Before updating Loaner Agreement Signed: ' + objPartsOrderLine.Loaner_Agreement_Signed__c);
        
        try {
            // Attempt to update the Loaner Agreement Signed flag
            objPartsOrderLine.Loaner_Agreement_Signed__c = true;
            update objPartsOrderLine;
            
            // If no exception is thrown, the flow did not work as expected
            System.debug('Update successful, no exception thrown');
            
        } catch (Exception ex) {
            // Check if the exception contains the expected error message
            expectedExceptionThrown = ex.getMessage().contains(Label.POLLoanerAgreementCheckError) ? true : ex.getMessage().contains(Label.POLLoanerAgreementCheckErrorCP) ? true : false;
            
            // Debugging the exception message
            System.debug('Exception thrown: ' + ex.getMessage());
            // Assert that the exception was thrown
        System.AssertEquals(true, expectedExceptionThrown, 'Loaner agreement check failed to throw the expected exception');
        }
        
        
        
        // Stop test execution
        Test.stopTest();
    }
  
    /**
     * @Author: Harsh Shukla 
     * @Description: To copy the date and file from POL to IP on update;DCP-41581.
     **/
    static testmethod void testDateStamponIPfromPOL(){
        List<SVMXC__Site__c> lstlocation =new List<SVMXC__Site__c>();
        SVMXC__Site__c fromLocation = new SVMXC__Site__c(Name = 'test',SVMXC__Stocking_Location__c=true,Type__c=STRING_SHIPPING_TYPE_TRUNK);
        lstlocation.add(fromLocation);

        SVMXC__Site__c toLocation = new SVMXC__Site__c(Name = 'test1',SVMXC__Stocking_Location__c=true,Type__c=STRING_SHIPPING_TYPE_TRUNK);
        lstlocation.add(toLocation);

        insert lstlocation;
        Account objAccount = TestDataAccount.getNewAccount();
        Product2 objProduct1 = TestDataMaster.initProduct('12419677', STRING_PRODUCT_INSTRUMENT_CLASS);
        objProduct1.Serial_Number_Profile__c = 'IL02';
        objProduct1.Service_Product_Type__c = STRING_PRODUCT_INSTRUMENT_CLASS;
        objProduct1.Condition_Type__c = 'LOANER';
        objProduct1.Custom_Product__c = true;
        objProduct1.CurrencyIsoCode = 'USD';
        insert objProduct1;
        
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Product__c = objProduct1.Id;
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        objInstalledProduct.Latest_Loaner_Agreement_Signature_Date__c = '';
        insert objInstalledProduct;
        
        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrderWithoutCase(STRING_WORK_ORDER_RECORD_TYPE_SERVICE_SUPPORT,STRING_WORK_ORDER_STATUS_INITIATED, STRING_WORK_ORDER_TYPE_INSTALLATION);
        SVMXC__RMA_Shipment_Order__c objPartsOrder = TestDataFieldService.createPartsOrderForInstallationWO(objWorkOrder.Id);
        objPartsOrder.SVMXC__Order_Status__c = 'Open';
        objPartsOrder.ERP_Sales_Order_Number__c = String.valueOf(Math.random());
        objPartsOrder.Contact_Name__c = 'Test';
        objPartsOrder.Contact_Phone__c = 'Test';
        objPartsOrder.Shipping_Location__c = fromLocation.id;
        objPartsOrder.SVMXC__Order_Type__c = 'Shipment';
        objPartsOrder.SVMXC__Source_Location__c = fromLocation.id;
        objPartsOrder.SVMXC__Destination_Location__c = toLocation.id;
        insert objPartsOrder;

        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        objPartsOrderLine.SVMXC__Serial_Number__c = objInstalledProduct.id;
        objPartsOrderLine.SVMXC__Product__c = objProduct1.Id;
        insert objPartsOrderLine;
        // DCP-43163 KD
        //insert service contract
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.ERP_Contract_Line_Number__c = '20';
        objServiceContract.ERP_Header_Contract_Number__c = '23456';
        objServiceContract.Consumables_Included__c = true;
        objServiceContract.Labor_Included__c = true;
        objServiceContract.Parts_Included__c = true;
        insert objServiceContract;
        //insert applied contracts
        Applied_contract__c contract = new Applied_contract__c();
        contract.work_order__c = objWorkOrder.Id;
        contract.Service_Contract__c = objServiceContract.id;
        List<Applied_contract__c> lstAppliedContracts = new List<Applied_contract__c>{contract};
        insert lstAppliedContracts;
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Penguins',
            PathOnClient = 'Penguins.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion;    
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument Limit 1];
        test.startTest();
        //create ContentDocumentLink  record 
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = objPartsOrderLine.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl;
        
        
        try{
            
            objPartsOrderLine.SVMXC__Line_Status__c = 'Shipped';
            update objPartsOrderLine;
        }Catch(Exception ex){
            system.debug('Exception Error: ' + ex.getMessage());
        }
        test.stopTest();
        List<ContentDocumentLink> lstcontentDoc = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId=:objInstalledProduct.id];
        system.assertEquals(1, lstcontentDoc.size(), 'Content Document is not linked in IP');

    }
    
    /**
     * @Author: Harsh Shukla 
     * @Description: Code To copy the date and file from POL to IP on After Insert (CDL Class coverage);DCP-41581.
     **/
    static testmethod void dateStamponIPfromPOL(){
        List<User> lstUsers = new List<User>();
        lstUsers = [SELECT Id FROM User WHERE Profile.Name ='Integration SAP Service' AND IsActive=true LIMIT 1];
        List<SVMXC__Site__c> lstlocation =new List<SVMXC__Site__c>();
        SVMXC__Site__c fromLocation = new SVMXC__Site__c(Name = 'test',SVMXC__Stocking_Location__c=true,Type__c=STRING_SHIPPING_TYPE_TRUNK);
        lstlocation.add(fromLocation);

        SVMXC__Site__c toLocation = new SVMXC__Site__c(Name = 'test1',SVMXC__Stocking_Location__c=true,Type__c=STRING_SHIPPING_TYPE_TRUNK);
        lstlocation.add(toLocation);
        insert lstlocation;
        
        Account objAccount = TestDataAccount.getNewAccount();
        
        Product2 objProduct1 = TestDataMaster.initProduct('12419677', STRING_PRODUCT_INSTRUMENT_CLASS);
        objProduct1.Serial_Number_Profile__c = 'IL02';
        objProduct1.Service_Product_Type__c = STRING_PRODUCT_INSTRUMENT_CLASS;
        objProduct1.Condition_Type__c = 'LOANER';
        objProduct1.Custom_Product__c = true;
        objProduct1.CurrencyIsoCode = 'USD';
        insert objProduct1;
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Product__c = objProduct1.Id;
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        objInstalledProduct.Latest_Loaner_Agreement_Signature_Date__c = '';
        insert objInstalledProduct;
        
        test.startTest();
        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrderWithoutCase(STRING_WORK_ORDER_RECORD_TYPE_SERVICE_SUPPORT,STRING_WORK_ORDER_STATUS_INITIATED, STRING_WORK_ORDER_TYPE_INSTALLATION);
        SVMXC__RMA_Shipment_Order__c objPartsOrder = TestDataFieldService.createPartsOrderForInstallationWO(objWorkOrder.Id);
        objPartsOrder.SVMXC__Order_Status__c = 'Open';
        objPartsOrder.ERP_Sales_Order_Number__c = String.valueOf(Math.random());
        objPartsOrder.Contact_Name__c = 'Test';
        objPartsOrder.Contact_Phone__c = 'Test';
        objPartsOrder.Shipping_Location__c = fromLocation.id;
        objPartsOrder.SVMXC__Order_Type__c = 'Shipment';
        objPartsOrder.SVMXC__Source_Location__c = fromLocation.id;
        objPartsOrder.SVMXC__Destination_Location__c = toLocation.id;
        insert objPartsOrder;

        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        objPartsOrderLine.SVMXC__Serial_Number__c = objInstalledProduct.id;
        objPartsOrderLine.SVMXC__Product__c = objProduct1.Id;
        objPartsOrderLine.SVMXC__Line_Status__c = 'Shipped';
        system.runAs(lstUsers[0]){          
            insert objPartsOrderLine; 
        }
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Penguins',
            PathOnClient = 'Penguins.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion;    
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument Limit 1];
        
        //create ContentDocumentLink  record 
        
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = objPartsOrderLine.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl;  
        test.stopTest();
        system.assertNotEquals(null, cdl.id, 'Content Document link is not created');
    }

    /*******************************************************************************************************
     * @description test method for new Parts Order Line creation
    */
    static testmethod void newPartsOrderLinesCreation4() {
        cs_Apex_Settings__c cs=cs_Apex_Settings__c.getInstance(UserInfo.getProfileID());
		cs.Bypass_All_Validations__c = true;
        cs.Bypass_Triggers_By_Object_1__c = 'SVMXC__Work_Order_Resource__c';
        cs.Bypass_Triggers_By_Object_2__c = 'SVMXC__Service_Order__c';
		upsert cs cs_Apex_Settings__c.Id;
        Account objAccount = TestDataAccount.getNewAccount();
        objAccount.Account_Group__c = STRING_ACCOUNT_GROUP_SOLD_TO;
        update objAccount;
        Contact objContact = TestDataContact.getNewContact(objAccount);
        List<Product2> lstProducts = new List<Product2>();
        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Material_Group__c = '41';
        objProduct.Service_Product_Type__c = 'Spare';
        lstProducts.add(objProduct);
        insert lstProducts;
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        insert objCase;
        SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'test',Type__c = STRING_SHIPPING_TYPE_TRUNK);
        insert objLocationRec;
        SVMXC__Service_Group__c objGrp = TestDataFieldService.createServiceTeam('TestServiceTeamName','Antarctica');
        insert objGrp;
        SVMXC__Service_Group_Members__c objGrpMember = TestDataFieldService.createTechnician(userInfo.getUserId(),'Test',objGrp.id);
        objGrpMember.SVMXC__Inventory_Location__c = objLocationRec.Id;
        insert objGrpMember;
        
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, STRING_WORK_ORDER_STATUS_INITIATED);
        workOrder.SVMXC__Order_Type__c = 'Service Activities';
        workOrder.SVMXC__Group_Member__c = objGrpMember.Id;
        workOrder.Record_Created_from_SFM__c=true;
        insert workOrder;
        set<Id> setWOID = new set<Id>();
        setWOId.add(workOrder.Id);
        
        List<SVMXC__RMA_Shipment_Order__c> lstPartsOrders= new List<SVMXC__RMA_Shipment_Order__c>();
        SVMXC__RMA_Shipment_Order__c objPartsOrder = TestDataFieldService.createPartsOrder(objCase.Id);
        objPartsOrder.SVMXC__Service_Order__c = workOrder.Id;
        objPartsOrder.SVMXC__Order_Type__c = 'Shipment';
        objPartsOrder.SVMXC__Order_Status__c = 'Open';
        objPartsOrder.ERP_Sales_Order_Number__c = '10';
        objPartsOrder.Contact_Name__c='Test';
        objPartsOrder.Contact_Phone__c='Test';
        objPartsOrder.Shipping_Location__c=objLocationRec.id;
        objPartsOrder.SVMXC__Destination_Location__c=objLocationRec.id;
        objPartsOrder.Requested_Delivery_Date__c = system.today();
        lstPartsOrders.add(objPartsOrder);
        
        Test.startTest();
        insert lstPartsOrders;
        Id shipmentRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get('Shipment').getRecordTypeId();
        
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(lstPartsOrders[0].Id);
        objPartsOrderLine.SVMXC__Product__c = lstProducts[0].Id;
        objPartsOrderLine.RecordTypeId = shipmentRecordTypeId; 
        objPartsOrderLine.SVMXC__Line_Status__c = 'Open';
        objPartsOrderLine.Requested_Delivery_Date__c = system.today();
        insert objPartsOrderLine;

        system.assert(objPartsOrderLine.id!=null, STRING_PARTS_ORDER_LINE_IS_NULL);
        
        workOrder.Evaluation__c='Test';
        workOrder.SVMXC__Work_Performed__c='Test';
        workOrder.Verification_Result__c='Test'; 
        workOrder.PO_Number__c = '12345';
        workOrder.Is_Service_Report_Generated__c = true;
        workOrder.Has_Verification_Code__c = true;
        workOrder.Training_Required__c = false;  
        workOrder.SVMXC__Is_PM_Work_Order__c = true;
        workOrder.svmxc__order_status__c = 'Completed';
        try{
            update workOrder;
        }
        catch(Exception ee){
            System.debug('The WO completion error is '+ee.getMessage());
        }
        Test.stopTest();        
        
    }
      
    /*******************************************************************************************************
     * @description test method for DCP-33467
    */
    static testMethod void testPartsReservation(){   
        testDataCreation();
        Test.startTest();
        //create work order
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', objCaseTest.Id, STRING_WORK_ORDER_STATUS_INITIATED);
        workOrder.SVMXC__Company__c = objAccountTest.id;
        workOrder.SVMXC__Component__c = objInstalledProductTest.Id;
        workOrder.SVMXC__Order_Type__c = STRING_WORK_ORDER_TYPE_INSTALLATION;
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;   
        
        //Create non serialized product stock
        List<SVMXC__Product_Stock__c> productStockLst = new List<SVMXC__Product_Stock__c>();
        SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
        nonSerializedProdStock.SVMXC__Location__c = location1Test.id;
        nonSerializedProdStock.SVMXC__Product__c = nonSerializedProdTest.Id;
        nonSerializedProdStock.SVMXC__Status__c = STRING_PRODUCT_STOCK_STATUS_AVAILABLE;
        nonSerializedProdStock.SVMXC__Quantity2__c = 2;
        productStockLst.add(nonSerializedProdStock);
        
        //Create serialized product stock
        SVMXC__Product_Stock__c serializedProdStock = new SVMXC__Product_Stock__c();
        serializedProdStock.SVMXC__Location__c = location1Test.id;
        serializedProdStock.SVMXC__Product__c = serializedProdTest.Id;
        serializedProdStock.SVMXC__Status__c = STRING_PRODUCT_STOCK_STATUS_AVAILABLE;
        serializedProdStock.SVMXC__Quantity2__c = 2;
        productStockLst.add(serializedProdStock);
        insert productStockLst;
        
        //Insert stock serials for serialized product stock
        List<SVMXC__Product_Serial__c> stockedSerialList = new List<SVMXC__Product_Serial__c>();
        SVMXC__Product_Serial__c stockSerial1 = new SVMXC__Product_Serial__c();
        stockSerial1.SVMXC__Active__c = true;
        stockSerial1.SVMXC__Product__c = serializedProdTest.Id;
        stockSerial1.SVMXC__Product_Stock__c = serializedProdStock.Id;
        stockSerial1.Name = '0987654321';
        stockedSerialList.add(stockSerial1);
        
        SVMXC__Product_Serial__c stockSerial2 = new SVMXC__Product_Serial__c();
        stockSerial2.SVMXC__Active__c = true;
        stockSerial2.SVMXC__Product__c = serializedProdTest.Id;
        stockSerial2.SVMXC__Product_Stock__c = serializedProdStock.Id;
        stockSerial2.Name = '1234567890';
        stockedSerialList.add(stockSerial2);
        insert stockedSerialList;

        
        //create a work detail 
        List<SVMXC__Service_Order_Line__c> wdList = new List<SVMXC__Service_Order_Line__c>();
        SVMXC__Service_Order_Line__c objOrderDetail = TestDataFieldService.createPartTypeWorkDetail(workOrder.Id, null, null);
        objOrderDetail.SVMXC__Consumed_From_Location__c = location1Test.Id;
        objOrderDetail.SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.Id;
        objOrderDetail.SVMXC__Line_Status__c = 'Open';
        objOrderDetail.SVMXC__Actual_Quantity2__c = 1;
        wdList.add(objOrderDetail);
        
        SVMXC__Service_Order_Line__c objOrderDetail1 = objOrderDetail.clone();
        objOrderDetail1.SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStock.Id;
        objOrderDetail1.SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial1.Id;
        wdList.add(objOrderDetail1);
        
        SVMXC__Service_Order_Line__c objOrderDetail2 = objOrderDetail1.clone();
        objOrderDetail2.SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial2.Id;
        wdList.add(objOrderDetail2);        
        
        SVMXC__Service_Order_Line__c objOrderDetail3 = objOrderDetail.clone();
        objOrderDetail3.SVMXC__Actual_Quantity2__c = 2;
        objOrderDetail3.Batch_Number__c = '123456';
        wdList.add(objOrderDetail3);
        
        
        insert wdList;
        
        SVMXC__RMA_Shipment_Order__c objPartsOrder1 = TestDataFieldService.createPartsOrderRecord(STRING_PARTS_ORDER_TYPE_RETURN, 'Open',
                                                                                                    '188', 'Test', 'Test', null);
        objPartsOrder1.SVMXC__Source_Location__c=objLocationRecTest.id;
        insert objPartsOrder1;
        Test.stopTest();
        Id shipmentRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get('Shipment').getRecordTypeId();
        
        //pooja
        List<SVMXC__RMA_Shipment_Line__c> lstPartsOrderLine= new List<SVMXC__RMA_Shipment_Line__c>();

        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLineRecord(objPartsOrder1.Id, objLocationRecTest.Id, 
        shipmentRecordTypeId, 'Open', objInstalledProductTest.Id, nonSerializedProdTest.Id);
        objPartsOrderLine.To_Location__c = location1Test.id;
        objPartsOrderLine.Requested_Delivery_Date__c = Date.today();
        objPartsOrderLine.Batch_Number__c = '123456';
        objPartsOrderLine.SVMXC__Actual_Quantity2__c = 2;
        objPartsOrderLine.Consumed_QTY__c = 0;
        lstPartsOrderLine.add(objPartsOrderLine);//pooja
        
        //cover the error condition for POL with Stocked Serial
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine1 = TestDataFieldService.createPartsOrderLineRecord(objPartsOrder1.Id, objLocationRecTest.Id,
        shipmentRecordTypeId, STRING_PARTS_ORDER_LINE_STATUS, null, serializedProdTest.Id);
        objPartsOrderLine1.Stocked_Serial__c = stockSerial1.Id;
        objPartsOrderLine1.Is_Part_Order_Line_for_Spare_Parts__c = true;
        lstPartsOrderLine.add(objPartsOrderLine1);//pooja
        
        //cover the error condition for POL with non Serialised product
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine2 = TestDataFieldService.createPartsOrderLineRecord(objPartsOrder1.Id, location1Test.Id,
                                                                shipmentRecordTypeId, STRING_PARTS_ORDER_LINE_STATUS, null, null);
        objPartsOrderLine2.Product_Stock__c = nonSerializedProdStock.Id;
        objPartsOrderLine2.SVMXC__Actual_Quantity2__c = 2;
        objPartsOrderLine2.To_Location__c = objLocationRecTest.id;
        objPartsOrderLine2.Is_Part_Order_Line_for_Spare_Parts__c = true;
        lstPartsOrderLine.add(objPartsOrderLine2);//pooja
        
        //cover the error condition for POL with non serialised product with batch number on POL
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine3 = TestDataFieldService.createPartsOrderLineRecord(objPartsOrder1.Id, location1Test.id,
                                                                        shipmentRecordTypeId, 'Open', null, null);
        objPartsOrderLine3.To_Location__c = objLocationRecTest.id;
        objPartsOrderLine3.Product_Stock__c = nonSerializedProdStock.Id;
        objPartsOrderLine3.Requested_Delivery_Date__c = Date.today().adddays(2);
        objPartsOrderLine3.Batch_Number__c = '123456';
        objPartsOrderLine3.SVMXC__Actual_Quantity2__c = 2;
        objPartsOrderLine3.Consumed_QTY__c = 0;
        lstPartsOrderLine.add(objPartsOrderLine3);//pooja
        try{
            insert lstPartsOrderLine;
        }
        catch(Exception ee){
            System.Assert(ee.getMessage().contains('#'));
        }
       
    }
    
    /*******************************************************************************************************
     * @description test method for Parts Order Lines
    */
    static testMethod void codeCoverageEnhancer1(){   
        testDataCreation();
        Test.startTest();
        //create work order
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', objCaseTest.Id, STRING_WORK_ORDER_STATUS_INITIATED);
        workOrder.SVMXC__Company__c = objAccountTest.id;
        workOrder.SVMXC__Component__c = objInstalledProductTest.Id;
        workOrder.SVMXC__Order_Type__c = STRING_WORK_ORDER_TYPE_INSTALLATION;
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;   
        List<SVMXC__RMA_Shipment_Order__c> lstPOs = new List<SVMXC__RMA_Shipment_Order__c>();
        SVMXC__RMA_Shipment_Order__c objPartsOrder1 = TestDataFieldService.createPartsOrder(null);
        objPartsOrder1.SVMXC__Order_Type__c = STRING_PARTS_ORDER_TYPE_RETURN;
        objPartsOrder1.SVMXC__Order_Status__c = 'Open';
        objPartsOrder1.ERP_Sales_Order_Number__c = '188';
        objPartsOrder1.Contact_Name__c='Test';
        objPartsOrder1.Contact_Phone__c='Test';
        objPartsOrder1.SVMXC__Source_Location__c=objLocationRecTest.id;
        objPartsOrder1.SVMXC__Service_Order__c = workOrder.Id;
        lstPOs.add(objPartsOrder1);
        
        insert lstPOs;
        Test.stoptest();
        
        Id shipmentRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get('Shipment').getRecordTypeId();
        
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder1.Id);
        objPartsOrderLine.From_Location__c = objLocationRecTest.id;
        objPartsOrderLine.To_Location__c = location1Test.id;
        objPartsOrderLine.RecordTypeId = shipmentRecordTypeId;
        objPartsOrderLine.SVMXC__Line_Status__c = 'open';
        objPartsOrderLine.Requested_Delivery_Date__c = Date.today();
        objPartsOrderLine.SVMXC__Serial_Number__c = objInstalledProductTest.Id;
        objPartsOrderLine.SVMXC__Product__c = nonSerializedProdTest.Id;
        objPartsOrderLine.Batch_Number__c = '123456';
        objPartsOrderLine.SVMXC__Actual_Quantity2__c = 2;
        objPartsOrderLine.Consumed_QTY__c = 0;
        objPartsOrderLine.Name__c = [select id from user where IsActive = true and CompanyName != null and MobilePhone != null LIMIT 1][0].Id;
        insert objPartsOrderLine;
        system.assert(objPartsOrderLine.id!=null, STRING_PARTS_ORDER_LINE_IS_NULL);
        objPartsOrderLine.Name__c = [select id from user where IsActive = true and CompanyName != null and MobilePhone != null and id !=: objPartsOrderLine.Name__c LIMIT 1][0].Id;
        update objPartsOrderLine;
        
        
    }   
    
    /*******************************************************************************************************
     * @description test method for new Parts Order Line
    */
    static testmethod void newPartsOrderLinesCreation10() {
        
        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId()); 
            setting.Bypass_Triggers_By_Object_1__c = 'SVMXC__Service_Order__c';
            upsert setting; 

        Account objAccount = TestDataAccount.getNewAccount();
        objAccount.Account_Group__c = STRING_ACCOUNT_GROUP_SOLD_TO;
        update objAccount;
        Contact objContact = TestDataContact.getNewContact(objAccount);


        List<Product2> lstProducts = new List<Product2>();
        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = STRING_PRODUCT_INSTRUMENT_CLASS;
        objProduct.Source_System__c = 'SAP';
        lstProducts.add(objProduct);
        //added by prashanth
        //start
        Product2 objProduct1 = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct1.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        lstProducts.add(objProduct1);
        //end
    
        insert lstProducts;
        
        Product2 insertedProduct = [Select Service_Product_Type__c from Product2 where Name = :STRING_PRODUCT_CODE limit 1];
        
        //creating FRU List
        FRU_List__c objFRUList = new FRU_List__c(ERP_Parent_Product__c = insertedProduct.id, ERP_Product__c = insertedProduct.id);
        insert objFRUList;

        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Product__c=objProduct.Id;
        objInstalledProduct.SVMXC__Company__c= objAccount.Id;
        
        insert objInstalledProduct;

        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.Consumables_Included__c=false;
        objServiceContract.Status__c = STRING_CONTRACT_STATUS;
        insert objServiceContract;

        SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(objInstalledProduct.Id);
        objCoveredProduct.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert objCoveredProduct;
        
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        objCase.SVMXC__Component__c = objInstalledProduct.Id;
        insert objCase;
        Case insertedCase = [Select SVMXC__Component__c from Case where Id =: objCase.Id];
        System.assertEquals(InsertedCase.SVMXC__Component__c, objInstalledProduct.Id);
        
        SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'test');
        insert objLocationRec;
        
        SVMXC__Service_Group__c objGrp = TestDataFieldService.createServiceTeam('TestServiceTeamName','Antarctica');
        insert objGrp;
        
        SVMXC__Service_Group_Members__c objGrpMember = TestDataFieldService.createTechnician(userInfo.getUserId(),'Test',objGrp.id);
        objGrpMember.SVMXC__Inventory_Location__c = objLocationRec.Id;
        insert objGrpMember;
        Test.startTest();
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WORK_ORDER_RECORD_TYPE_SERVICE_SUPPORT, objCase.Id, STRING_WORK_ORDER_STATUS_INITIATED);
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Order_Type__c = STRING_WORK_ORDER_TYPE_INSTALLATION;
        workOrder.SVMXC__Group_Member__c = objGrpMember.Id;
        workOrder.Record_Created_from_SFM__c=true;
        
        insert workOrder;
        
        List<SVMXC__RMA_Shipment_Order__c> lstPartsOrders= new List<SVMXC__RMA_Shipment_Order__c>();
        SVMXC__RMA_Shipment_Order__c objPartsOrder = TestDataFieldService.createPartsOrder(objCase.Id);
        objPartsOrder.SVMXC__Service_Order__c = workOrder.Id;
        //added by prashanth 
        //start
        objPartsOrder.SVMXC__Order_Type__c = 'Stock Transfer';
        //end
        objPartsOrder.SVMXC__Order_Status__c = 'Open';
        objPartsOrder.ERP_Sales_Order_Number__c = '10';
        objPartsOrder.Contact_Name__c='Test';
        objPartsOrder.Contact_Phone__c='Test';
        objPartsOrder.Requested_By__c=userInfo.getUserId();//added for 38817
        objPartsOrder.Shipping_Location__c=objLocationRec.id;
        lstPartsOrders.add(objPartsOrder);
        
        insert lstPartsOrders;
         
        
        //added by prashanth
        //start
        SVMXC__Product_Stock__c objProductStock = TestDataFieldService.getNewProductStock(objLocationRec.Id,lstProducts[0].id);
        
        SVMXC__Product_Serial__c createStockSerial = new SVMXC__Product_Serial__c();
                    createStockSerial.Name = objInstalledProduct.id;
                    createStockSerial.SVMX_PS_VS_Linked_Installed_Product__c = objInstalledProduct.id;                        
                    createStockSerial.SVMXC__Product_Stock__c = objProductStock.Id;
                    createStockSerial.SVMXC__Product__c = lstProducts[0].id;
                    createStockSerial.SVMXC__Active__c = true;
                    insert createStockSerial;
        //end
        
        Id shipmentRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get('Shipment').getRecordTypeId();
        //added by prashanth
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine1 = TestDataFieldService.createPartsOrderLines(lstPartsOrders[0].Id);
        objPartsOrderLine1.SVMXC__Product__c = lstProducts[0].Id;
        objPartsOrderLine1.From_Location__c = objLocationRec.id;
        objPartsOrderLine1.RecordTypeId = shipmentRecordTypeId; 
        objPartsOrderLine1.Stocked_Serial__c = createStockSerial.Id;
        objPartsOrderLine1.SVMXC__Line_Status__c = STRING_PARTS_ORDER_LINE_STATUS;
        objPartsOrderLine1.Is_Part_Order_Line_for_Spare_Parts__c = true;
        insert objPartsOrderLine1;
    
        objPartsOrderLine1.SVMXC__Product__c = lstProducts[1].Id;
        update objPartsOrderLine1;
        //end
        SVMXC__RMA_Shipment_Line__c insertedPartsOrderLine = [Select  PO_Number__c, SVMXC__RMA_Shipment_Order__c, Is_Billable__c from SVMXC__RMA_Shipment_Line__c where SVMXC__RMA_Shipment_Order__c =: objPartsOrder.Id limit 1];
        System.assertEquals(insertedPartsOrderLine.SVMXC__RMA_Shipment_Order__c, objPartsOrder.Id);
        Test.stopTest(); 
    }
      
    /**
       *  @author Adyasha Satapathy
       *  @description - DCP-41580: Method to check autocreation of Return Parts Order from Shipment Parts Order
       **/
      static testmethod void autoCreateReturnPO() {
            
        //Create Account, Contact
        Account objAccount = TestDataAccount.getNewAccount();
        objAccount.Account_Group__c = STRING_ACCOUNT_GROUP_SOLD_TO;
        update objAccount;
        Contact objContact = TestDataContact.getNewContact(objAccount);

        //Create Case
        objCaseTest = TestDataCase.initServiceRequestCase(objContact);
        insert objCaseTest;
        
        //Create Product
        Product2 prod = TestDataMaster.createProduct(false);
        prod.Condition_Type__c = PartsOrderLines.STRING_CONDITION_TYPE_LOANER;
        prod.Serial_Number_Profile__c = PartsOrderLines.STRING_SERIAL_NUMBER_PROFILE_IL02;
        prod.Service_Product_Type__c = PartsOrderLines.STRING_PRODUCT_TYPE_INSTRUMENT;
        insert prod;
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        objInstalledProduct.SVMXC__Product__c = prod.Id;
        insert objInstalledProduct;

        List<SVMXC__Site__c> lstLocation = new List<SVMXC__Site__c>();
        SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = STRING_FROM_LOCATION);
        lstLocation.add(objLocationRec);
        
        SVMXC__Site__c toLocation = new SVMXC__Site__c(Name = STRING_TO_LOCATION,SVMXC__Stocking_Location__c=true,Type__c=STRING_SHIPPING_TYPE_TRUNK);
        lstLocation.add(toLocation);
        
        insert lstLocation;
        
        //Create Workorder
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WORK_ORDER_RECORD_TYPE_SERVICE_SUPPORT, objCaseTest.Id, STRING_WORK_ORDER_STATUS_INITIATED);
        workOrder.SVMXC__Order_Type__c = STRING_WORK_ORDER_TYPE_INSTALLATION;
        workOrder.SVMXC__Company__c = objAccount.Id;
        workOrder.SVMXC__Site__c = lstLocation.get(0).Id;
        workOrder.SVMXC__Contact__c = objContact.Id;
        workOrder.Record_Created_from_SFM__c=true;
        insert workOrder;

        //Create Parts Order
        SVMXC__RMA_Shipment_Order__c objPartsOrder = TestDataFieldService.createPartsOrder(objCaseTest.Id);
        objPartsOrder.SVMXC__Service_Order__c = workOrder.Id;
        objPartsOrder.SVMXC__Order_Status__c = STRING_PARTS_ORDER_LINE_STATUS;
        objPartsOrder.SVMXC__Order_Type__c = STRING_PARTS_ORDER_TYPE;
        objPartsOrder.Contact_Name__c = STRING_PARTS_ORDER_CONTACT_NAME;
        objPartsOrder.Contact_Phone__c = STRING_PARTS_ORDER_CONTACT_PHONE;
        objPartsOrder.Shipping_Location__c = lstLocation.get(0).id;
        objPartsOrder.SVMXC__Destination_Location__c = lstLocation.get(1).id;
        WorkOrders.skipWOTrigger = true;       
        insert objPartsOrder;
        
        Test.startTest();
        //Create Parts Order Line
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        objPartsOrderLine.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        objPartsOrderLine.SVMXC__Product__c = prod.Id;
        objPartsOrderLine.From_Location__c = lstLocation.get(0).id;
        
        insert objPartsOrderLine;

        SVMXC__RMA_Shipment_Line__c objPOL = [Select Id, SVMXC__Serial_Number_List__c,Parts_Order_Type__c,Service_Product_Type__c,SVMXC__Product__r.Condition_Type__c,SVMXC__Product__r.Serial_Number_Profile__c,SVMXC__Product__c,SVMXC__Line_Status__c from SVMXC__RMA_Shipment_Line__c where SVMXC__RMA_Shipment_Order__c = :objPartsOrder.Id];
        objPOL.SVMXC__Serial_Number_List__c = STRING_PARTS_ORDER_LINE_SERIAL_NUMBER_LIST;
        objPOL.SVMXC__Line_Status__c = PartsOrderLines.STRING_PART_ORDER_LINE_STATUS_SHIPPED;
        update objPOL;
        Test.stopTest();

        SVMXC__RMA_Shipment_Order__c returnPartsOrder = [Select Id,SVMXC__Order_Type__c from SVMXC__RMA_Shipment_Order__c where SVMXC__Shipment_Reference__c = :objPartsOrder.Id];
        System.assertEquals(STRING_PARTS_ORDER_TYPE_RETURN,returnPartsOrder.SVMXC__Order_Type__c);
    }

    /**
     * @Author: Vignesh Sethuramalingam 
     * @Description: DCP-42724: Method to test logic to autopopulate Dangerous Goods.
     **/
    static testmethod void testPopulateDangerousGoods() {
            
        //Create Account, Contact
        Account objAccount = TestDataAccount.getNewAccount();
        objAccount.Account_Group__c = STRING_ACCOUNT_GROUP_SOLD_TO;
        update objAccount;
        Contact objContact = TestDataContact.getNewContact(objAccount);

        //Create Case
        objCaseTest = TestDataCase.initServiceRequestCase(objContact);
        insert objCaseTest;
        
        //Create Product
        list<Product2> lstprod = new list<Product2>();
        Product2 prod = TestDataMaster.createProduct(false);
        prod.Condition_Type__c = PartsOrderLines.STRING_CONDITION_TYPE_LOANER;
        prod.Serial_Number_Profile__c = PartsOrderLines.STRING_SERIAL_NUMBER_PROFILE_IL02;
        prod.Service_Product_Type__c = PartsOrderLines.STRING_PRODUCT_TYPE_INSTRUMENT;
        prod.Dangerous_Goods__c = true;
        lstprod.add(prod);
        
        Product2 prod1 = TestDataMaster.createProduct(false);
        prod1.Condition_Type__c = PartsOrderLines.STRING_CONDITION_TYPE_LOANER;
        prod1.Serial_Number_Profile__c = PartsOrderLines.STRING_SERIAL_NUMBER_PROFILE_IL02;
        prod1.Service_Product_Type__c = PartsOrderLines.STRING_PRODUCT_TYPE_INSTRUMENT;
        prod1.Dangerous_Goods__c = false;
        lstprod.add(prod1);
        insert lstprod;
        
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        objInstalledProduct.SVMXC__Product__c = prod.Id;
        //insert objInstalledProduct;

        List<SVMXC__Site__c> lstLocation = new List<SVMXC__Site__c>();
        SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = STRING_FROM_LOCATION);
        lstLocation.add(objLocationRec);
        
        SVMXC__Site__c toLocation = new SVMXC__Site__c(Name = STRING_TO_LOCATION,SVMXC__Stocking_Location__c=true,Type__c=STRING_SHIPPING_TYPE_TRUNK);
        lstLocation.add(toLocation);
        
        insert lstLocation;
        
        
        //Create Workorder
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WORK_ORDER_RECORD_TYPE_SERVICE_SUPPORT, objCaseTest.Id, STRING_WORK_ORDER_STATUS_INITIATED);
        workOrder.SVMXC__Order_Type__c = STRING_WORK_ORDER_TYPE_INSTALLATION;
        workOrder.SVMXC__Company__c = objAccount.Id;
        workOrder.SVMXC__Site__c = lstLocation.get(0).Id;
        workOrder.SVMXC__Contact__c = objContact.Id;
        workOrder.Record_Created_from_SFM__c=true;
        insert workOrder;

        //Create Parts Order
        SVMXC__RMA_Shipment_Order__c objPartsOrder = TestDataFieldService.createPartsOrder(objCaseTest.Id);
        objPartsOrder.SVMXC__Service_Order__c = workOrder.Id;
        objPartsOrder.SVMXC__Order_Status__c = STRING_PARTS_ORDER_LINE_STATUS;
        objPartsOrder.SVMXC__Order_Type__c = STRING_PARTS_ORDER_TYPE;
        objPartsOrder.Contact_Name__c = STRING_PARTS_ORDER_CONTACT_NAME;
        objPartsOrder.Contact_Phone__c = STRING_PARTS_ORDER_CONTACT_PHONE;
        objPartsOrder.Shipping_Location__c = lstLocation.get(0).id;
        objPartsOrder.SVMXC__Destination_Location__c = lstLocation.get(1).id;
        
        insert objPartsOrder;
        
        Test.startTest();
        //Create Parts Order Line
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        //objPartsOrderLine.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        objPartsOrderLine.SVMXC__Product__c = prod.Id;
        objPartsOrderLine.From_Location__c = lstLocation.get(0).id;
        insert objPartsOrderLine;

        SVMXC__RMA_Shipment_Line__c objPOL = [Select Id, Dangerous_Goods__c from SVMXC__RMA_Shipment_Line__c  where SVMXC__RMA_Shipment_Order__c = :objPartsOrder.Id];
        System.assertEquals(true,objPOL.Dangerous_Goods__c);

        objPartsOrderLine.SVMXC__Product__c = prod1.Id;
        update objPartsOrderLine;
        
        SVMXC__RMA_Shipment_Line__c objPOL1 = [Select Id, Dangerous_Goods__c from SVMXC__RMA_Shipment_Line__c  where SVMXC__RMA_Shipment_Order__c = :objPartsOrder.Id];
        System.assertEquals(false, objPOL1.Dangerous_Goods__c);

        Test.stopTest();
    }    
    /*******************************************************************************************************
     * @description DCP-50097 Method to test logic to make Batch number null when Batch lookup is null;
     * @method testMakeBatchNumberNull
     * @return
    * @author Harsh Shukla
    */
    static testMethod void testMakeBatchNumberNull(){
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
        insert objPartsOrder;
        
        Test.startTest();
        Product2 insertedProduct = [Select id,Material_Group__c,Service_Product_Type__c from Product2 where id =:product2.id][0];
        system.assertequals('Spare',insertedProduct.Service_Product_Type__c);
        
        Id returnRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get('Shipment').getRecordTypeId();
        
        List<SVMXC__RMA_Shipment_Line__c> lstPartsOrderLine = new List<SVMXC__RMA_Shipment_Line__c>() ;   
        List<SVMXC__RMA_Shipment_Line__c> lstUpdatePartsOrderLine = new List<SVMXC__RMA_Shipment_Line__c>() ;  
        
        //Create return POL for Batched product
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine1 = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        objPartsOrderLine1.RecordTypeId = returnRecordTypeId; 
        //objPartsOrderLine1.Reason__c = STRING_PARTS_ORDER_LINE_NON_BILLABLE_REASON;
        objPartsOrderLine1.Reason__c = 'Consumable Warranty';
        objPartsOrderLine1.SVMXC__Actual_Quantity2__c= 2;
        objPartsOrderLine1.SVMXC__Line_Status__c = 'Open';  
        objPartsOrderLine1.Requested_Delivery_Date__c = Date.today() +1;
        objPartsOrderLine1.SVMXC__Product__c = product2.Id;
        objPartsOrderLine1.Batch_Lookup__c = null;
        objPartsOrderLine1.Batch_Number__c = '123456';
        lstPartsOrderLine.add(objPartsOrderLine1);
        insert lstPartsOrderLine;
        SVMXC__RMA_Shipment_Line__c objPOL = [Select Id, Batch_Number__c from SVMXC__RMA_Shipment_Line__c where SVMXC__RMA_Shipment_Order__c = :objPartsOrder.Id];
        system.assertEquals(null, objPOL.Batch_Number__c);
        
        objPartsOrderLine1.SVMXC__Line_Status__c = 'Shipped';
        objPartsOrderLine1.Batch_Number__c = '123456';
        lstUpdatePartsOrderLine.add(objPartsOrderLine1);
        update lstUpdatePartsOrderLine;

        SVMXC__RMA_Shipment_Line__c objPOL1 = [Select Id, Batch_Number__c from SVMXC__RMA_Shipment_Line__c where SVMXC__RMA_Shipment_Order__c = :objPartsOrder.Id];
        system.assertEquals(null, objPOL1.Batch_Number__c);
        Test.stopTest();
        
    }
}