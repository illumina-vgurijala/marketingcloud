/**
* @author Shivani Jain
* @date 5th Sep 2022
*
* @description DCP-43629 Test class for ServiceUtility 
*/ 
@IsTest
private class TestServiceUtility {
    /*******************************************************************************************************
    * @description test data setup
    */ 
    @TestSetup
    static void createSetupData() {
        //Creating Account
        

        Account acc = TestDataAccount.getAccount('Test Parent', 'USD');
        acc.Account_Group__c='Sold To';
        acc.ERP_Customer_Id__c = '4000026704';
        insert acc;

        Account acc1 = TestDataAccount.getAccount('Test Child', 'USD');
        acc1.Account_Group__c='Distributor';
        acc1.ParentId = acc.id;
        insert acc1;
        
        //Creating Contact
        Contact con = TestDataContact.getNewContact(acc); 

        //Creating Case      
        Case objectCase = TestDataCase.initServiceRequestCase(con);
        insert objectCase;

        //Creating Work Order
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Remote Support', objectCase.Id, 'Initiated');
        workOrder.SVMXC__Order_Status__c = 'Assigned';
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;

        //Insert Location
        SVMXC__Site__c location = TestDataFieldService.createLocation('ServiceLoc', 'Stringing street New York', 'Sri Lanka', '43527', 'USD');
        location.SVMXC__Account__c = acc.Id;
        SVMXC__Site__c shippingLocation = new SVMXC__Site__c(
                Name = 'testStockingLocation',
                CurrencyIsoCode = 'USD',
                SVMXC__Stocking_Location__c = true,
                SVMX_PS_Active__c = true,
                Type__c = 'Trunk');
        List<SVMXC__Site__c> locList = new list < SVMXC__Site__c > ();
            locList.add(location);
            locList.add(shippingLocation);
        insert locList;

    }

    /*******************************************************************************************************
    * @description test method for updateSoldToOnPO
    */ 
    static testmethod void testSoldToOnHierarchy() {
        Case objectCase = [SELECT id FROM Case LIMIT 1][0];
        List<Account> accList = [SELECT id FROM Account WHERE Name =: 'Test Child' LIMIT 1];
        SVMXC__Service_Order__c workOrder = [SELECT id FROM SVMXC__Service_Order__c LIMIT 1][0];
        List<SVMXC__Site__c> locList = [SELECT id FROM SVMXC__Site__c LIMIT 2];

        Test.startTest();
        //Creating Part Order
        SVMXC__RMA_Shipment_Order__c partOrder = TestDataFieldService.createPartOrder('RMA', objectCase.Id, 'Open');
        partOrder.ERP_Sales_Order_Number__c = '1234';
        partOrder.SVMXC__Service_Order__c = workOrder.id;
        partOrder.Contact_Name__c = 'Test';
        partOrder.Contact_Phone__c = 'Test';
        partOrder.SVMXC__Order_Type__c = 'Shipment';
        partOrder.SVMXC__Destination_Location__c = locList[0].Id;
        partOrder.Shipping_Location__c = locList[1].Id;
        partOrder.SVMXC__Company__c = accList[0].Id;
        partOrder.Sold_To__c = accList[0].Id;
        insert partOrder;
        Test.stopTest();

        List<SVMXC__RMA_Shipment_Order__c> updatedPartsOrder = [SELECT id, Sold_To__r.Name FROM SVMXC__RMA_Shipment_Order__c LIMIT 1];
        System.assertEquals('Test Parent', updatedPartsOrder[0].Sold_To__r.Name, 'Sold To Population logic from Metadata failed');

    }

}