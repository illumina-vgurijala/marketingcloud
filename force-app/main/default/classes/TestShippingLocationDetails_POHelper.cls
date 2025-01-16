/**
* @author Romi Taskar
* @date 1st September 2022
*
* @description DCP-52923 Test class for ShippingLocationDetails_POHelper
*/
@IsTest
public with sharing class TestShippingLocationDetails_POHelper {
    /*
    * Description - Test method to cover ShippingLocationDetails_POHelper class
    */

    static testMethod void testShippingLocDetails() {

        //Account creation 
        Account objAccount = TestDataAccount.getNewAccount();
        objAccount.Account_Group__c = 'Sold To';
        update objAccount;
        System.assert(objAccount.id != null, 'Account not inserted');

        //Contact creation
        Contact objContact = TestDataContact.getNewContact(objAccount);
        System.assert(objContact.id != null, 'Contact not inserted');

        //Case Creation
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        insert objCase;
        System.assert(objCase.id != null, 'Case not inserted');

        //Location creation
        SVMXC__Site__c location1 = TestDataFieldService.createLocation('ServiceLoc1', 'Stringing street New York1', 'USA1', '435271', 'USD');
        insert location1;
        System.assert(location1.id != null, 'Location1 not inserted');
        SVMXC__Site__c location2 = TestDataFieldService.createLocation('ServiceLoc2', 'Stringing street New York2', 'USA2', '435272', 'USD');
        insert location2;
        System.assert(location2.id != null, 'Location2 not inserted');

        Test.startTest();
        //Parts Order Creation
        SVMXC__RMA_Shipment_Order__c partOrder = TestDataFieldService.createPartOrder('RMA', objCase.Id, 'Open');
        partOrder.Contact_Name__c = 'Test';
        partOrder.Contact_Phone__c = 'Test';
        partOrder.SVMXC__Order_Status__c = 'Open';
        partOrder.SVMXC__Order_Type__c = 'Shipment';
        partOrder.Shipping_Location__c = location1.Id;
        insert partOrder;

        Test.stopTest();
        List<SVMXC__RMA_Shipment_Order__c> partsOrder =  [SELECT id, Shipping_Location_Details__c FROM SVMXC__RMA_Shipment_Order__c LIMIT 1];
        System.assert(partsOrder[0].Shipping_Location_Details__c != NULL, 'Parts Order Shipping Location Details field didnt populate');

    }
}
