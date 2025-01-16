/**
* @author Shivani Jain
* @date 29 Nov 2021
*
* @description DCP-42926 Test class for CheckDCIR_POLHelper
*/ 
@IsTest(SeeAllData=True)
private class TestCheckDCIR_POLHelper {

    static final String STRING_ACCOUNT_GROUP_SOLD_TO = 'Sold To';
    static final string STRING_CURRENCY = 'USD';
    static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    static final string STRING_PARTS_ORDER_TYPE_RETURN = 'Return';
    static final string STRING_PARTS_ORDER_LINE_STATUS = 'Open';

    static Account objAccountTest;
    static Product2 nonSerializedProdTest;
    static SVMXC__Site__c location1Test;
    static SVMXC__Site__c objLocationRecTest;
    static SVMXC__Installed_Product__c objInstalledProductTest;
    static Case objCaseTest;

    /*******************************************************************************************************
    * @description test data setup
    */ 
    static void testDataCreation() {
        objAccountTest = TestDataAccount.getNewAccount(); //create account
        System.assertNotEquals(null, objAccountTest.Id);

        objAccountTest.Account_Group__c = 'Distributor';
        update objAccountTest;
        Contact objContact = TestDataContact.getNewContact(objAccountTest); //create contact.
        System.assertNotEquals(null, objContact.Id);
        
        //Create non serialized product
        nonSerializedProdTest = new Product2();
        nonSerializedProdTest.Name = 'Test Non-Serialized Product';
        nonSerializedProdTest.IsActive = true;
        nonSerializedProdTest.SVMXC__Tracking__c = 'Non-Tracked';
        nonSerializedProdTest.SVMXC__Stockable__c = true;
        nonSerializedProdTest.SVMXC__Enable_Serialized_Tracking__c = false;
        nonSerializedProdTest.Decontamination_Required__c  = true;
        insert nonSerializedProdTest;
        System.assertNotEquals(null, nonSerializedProdTest.Id);
        
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
        System.assertNotEquals(null, location1Test.Id);
        
        //create Installed Product
        objInstalledProductTest = TestDataFieldService.createInstalledProduct('Test IP VM', STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProductTest.SVMXC__Company__c = objAccountTest.Id;
        insert objInstalledProductTest;
        System.assertNotEquals(null, objInstalledProductTest.Id);
        
        //create case
        objCaseTest = TestDataCase.initServiceRequestCase(objContact);
        objCaseTest.SVMXC__Component__c = objInstalledProductTest.Id;
        insert objCaseTest;
        System.assertNotEquals(null, objCaseTest.Id);
    }

    /*******************************************************************************************************
    * @description test method checkDCIR
    */ 
    static testmethod void testDCIRValidation() {
        Boolean expectedExceptionThrown;
        cs_Apex_Settings__c cs = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        cs.Bypass_Triggers_By_Object_1__c = 'Case';
        cs.Bypass_Triggers_By_Object_2__c = 'SVMXC__Service_Order__c';
        upsert cs cs_Apex_Settings__c.Id; 
        testDataCreation();
		Test.startTest();
        Id shipmentRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get('Shipment').getRecordTypeId();
        Channel_Partner_Profile_Settings__c cp = Channel_Partner_Profile_Settings__c.getInstance(Userinfo.getProfileId());
        cp.Is_Channel_Partner__c = true;
        upsert cp Channel_Partner_Profile_Settings__c.Id;
        System.assertNotEquals(null, cp.Id);
        //create work order
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', objCaseTest.Id, 'Initiated');
        workOrder.SVMXC__Company__c = objAccountTest.id;
        workOrder.SVMXC__Component__c = objInstalledProductTest.Id;
        workOrder.SVMXC__Order_Type__c = 'Installation';
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;   
        System.assertNotEquals(null, workOrder.Id);
        SVMXC__RMA_Shipment_Order__c objPartsOrder = TestDataFieldService.createPartsOrder(null);
        objPartsOrder.SVMXC__Order_Type__c = STRING_PARTS_ORDER_TYPE_RETURN;
        objPartsOrder.SVMXC__Order_Status__c = 'Open';
        objPartsOrder.ERP_Sales_Order_Number__c = '188';
        objPartsOrder.Contact_Name__c='Test';
        objPartsOrder.Contact_Phone__c='Test';
        objPartsOrder.SVMXC__Source_Location__c=objLocationRecTest.id;
        objPartsOrder.SVMXC__Service_Order__c = workOrder.Id;
        objPartsOrder.Submit_for_Approval_CP__c = true;

        insert objPartsOrder;
        System.assertNotEquals(null, objPartsOrder.Id);
       
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
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
        objPartsOrderLine.Name__c = Userinfo.getUserId();
        
        try {
            insert objPartsOrderLine;
        } catch(Exception ex){
            expectedExceptionThrown = ex.getMessage().contains(Label.PODCIRCheckErrorCP) ? true : false;
        }
        System.assert(expectedExceptionThrown, 'checkDCIR method failed');

        Test.stopTest();

    }

}