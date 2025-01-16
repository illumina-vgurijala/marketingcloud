/**
* @author Shivani Jain
* @date 5 Jan 2022
*
* @description DCP-42926 Test class for Location_POLHelper
*/ 
@IsTest(SeeAllData=True)
private class TestLocation_POLHelper {

    static Account objAccountTest;
    static Product2 nonSerializedProdTest;
    static SVMXC__Site__c location1Test;
    static SVMXC__Site__c objLocationRecTest;
    static SVMXC__Installed_Product__c objInstalledProductTest;
    static Case objCaseTest;
    static final String STRING_PARTS_ORDER_LINE_IS_NULL = 'objPartsOrderLine is null';
    static final String STRING_WORK_ORDER_TYPE_INSTALLATION = 'Installation';
    static final string STRING_PARTS_ORDER_TYPE_RETURN = 'Return';
    static final String STRING_WORK_ORDER_STATUS_INITIATED ='Initiated';

    /*******************************************************************************************************
    * @description test data setup
    */
    public static void testDataCreation() {
        objAccountTest = TestDataAccount.getNewAccount(); //create account
        objAccountTest.Account_Group__c = 'Distributor';
        update objAccountTest;

        Contact objContact = TestDataContact.getNewContact(objAccountTest); //create contact.
        
        nonSerializedProdTest = new Product2();
        nonSerializedProdTest.Name = 'Test Non Serialized Product';
        nonSerializedProdTest.IsActive = true;
        nonSerializedProdTest.SVMXC__Tracking__c = 'Non-Tracked';
        nonSerializedProdTest.SVMXC__Stockable__c = true;
        nonSerializedProdTest.SVMXC__Enable_Serialized_Tracking__c = false;
        insert nonSerializedProdTest;
        System.assertNotEquals(null, nonSerializedProdTest.Id, 'Non serialized product not inserted');
        
        List<SVMXC__Site__c> lstSites = new LIst<SVMXC__Site__c>();
        location1Test = new SVMXC__Site__c();
        location1Test.Name = 'Test Location 1';
        location1Test.SVMXC__Account__c = objAccountTest.Id;
        location1Test.SVMXC__Stocking_Location__c = true;
        lstSites.add(location1Test);

        objLocationRecTest = new SVMXC__Site__c(Name = 'test');
        lstSites.add(objLocationRecTest);

        insert lstSites;
        System.assertNotEquals(null, location1Test.Id, 'Location not inserted successfully');
        System.assertNotEquals(null, objLocationRecTest.Id, 'Location not inserted successfully');
        
        objInstalledProductTest = TestDataFieldService.createInstalledProduct('Test IP VM', 'USD', 'New');
        objInstalledProductTest.SVMXC__Company__c = objAccountTest.Id;
        insert objInstalledProductTest;
        System.assertNotEquals(null, objInstalledProductTest.Id, 'Installed Product not inserted successfully');

        objCaseTest = TestDataCase.initServiceRequestCase(objContact);
        objCaseTest.SVMXC__Component__c = objInstalledProductTest.Id;
        insert objCaseTest;
        System.assertNotEquals(null, objCaseTest.Id, 'Service Request Case not inserted successfully');
        
    }

    /*******************************************************************************************************
    * @description test method to test Trunk Locker error
    */
    static testMethod void trunkLockerErrorTest() {  
        cs_Apex_Settings__c cs=cs_Apex_Settings__c.getInstance(UserInfo.getUserId());             
        cs.Bypass_Triggers_By_Object_1__c = 'Associated_Product__c';
        upsert cs cs_Apex_Settings__c.Id; 
        Boolean expectedExceptionThrown;
        testDataCreation();

        SVMXC__Service_Group__c objGroup = TestDataFieldService.createServiceTeam('TestServiceTeam','Antarctica');
        insert objGroup;
        System.assertNotEquals(null, objGroup.Id, 'Service Group not inserted successfully');

        SVMXC__Service_Group_Members__c objGroupMember = TestDataFieldService.createTechnician(UserInfo.getUserId(), 'Test', objGroup.id);
        objGroupMember.SVMXC__Inventory_Location__c = location1Test.Id;
        insert objGroupMember;
        System.assertNotEquals(null, objGroupMember.Id, 'Service Group Member not inserted successfully');

        SVMXC__Service_Group_Site__c objLocationCovered = TestDataFieldService.createLocationCovered(objGroupMember.id, location1Test.id, objGroup.id);
        insert objLocationCovered;
        System.assertNotEquals(null, objLocationCovered.Id, 'Service Group Site not inserted successfully');
        
        SVMXC__Service_Order__c wOrder = TestDataFieldService.createWorkOrder('Field Service', objCaseTest.Id, STRING_WORK_ORDER_STATUS_INITIATED);
        wOrder.SVMXC__Company__c = objAccountTest.id;
        wOrder.SVMXC__Component__c = objInstalledProductTest.Id;
        wOrder.SVMXC__Order_Type__c = STRING_WORK_ORDER_TYPE_INSTALLATION;
        wOrder.SVMXC__Group_Member__c = objGroupMember.Id;
        wOrder.Is_Auto_Created__c = true;
        insert wOrder; 
        System.assertNotEquals(null, wOrder.Id, 'Work Order not inserted successfully');  
        
        SVMXC__RMA_Shipment_Order__c objPartsOrder = TestDataFieldService.createPartsOrderRecord(STRING_PARTS_ORDER_TYPE_RETURN,
                'Open', '188', 'Test', 'Test', null);
        objPartsOrder.SVMXC__Source_Location__c = objLocationRecTest.id;
        objPartsOrder.SVMXC__Service_Order__c = wOrder.Id;
        
        Test.startTest();
        insert objPartsOrder;
        System.assertNotEquals(null, objPartsOrder.Id, 'Parts Order not inserted successfully');
        
        Id shipmentRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get('Shipment').getRecordTypeId();
        
        SVMXC__RMA_Shipment_Line__c objPol = TestDataFieldService.createPartsOrderLineRecord(objPartsOrder.Id, 
                    objLocationRecTest.Id, shipmentRecordTypeId, 'Open', objInstalledProductTest.id, nonSerializedProdTest.Id);
        objPol.Requested_Delivery_Date__c = Date.today();
        objPol.To_Location__c = location1Test.id;
        objPol.Batch_Number__c = '123456';
        objPol.SVMXC__Actual_Quantity2__c = 2;
        objPol.Consumed_QTY__c = 0;

        try {
            insert objPol;
        } catch(Exception ex){
            expectedExceptionThrown = ex.getMessage().contains(Label.Trunk_Locker_Error) ? true : false;
        }
        System.assert(expectedExceptionThrown, 'Location_POLHelper failed');
        
        Test.stoptest();
    }   
}