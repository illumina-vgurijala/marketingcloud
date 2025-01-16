/**
* @author Romi Taskar
* @date 1st September 2022
*
* @description DCP-52923 Test class for ShippingLocationAddress_WOHelper
*/
@IsTest
public with sharing class TestShippingLocationAddress_WOHelper {

    public static final String STRING_WO_RECORDTYPE = 'Field Service';
    public static final String STRING_WO_ORDER_TYPE = 'Service Activities';
   /*
    * Description - Test method to cover ShippingLocationDetails_POHelper class
    */

    static testMethod void testShippingLocAddress() {
    
        //Account creation 
        Account objAccount = TestDataAccount.getNewAccount();
        objAccount.Account_Group__c = 'Sold To';
        update objAccount;
        System.assert(objAccount.id != null, 'Account not inserted');

        //Contact creation
        Contact objContact = TestDataContact.getNewContact(objAccount);
        System.assert(objContact.id != null, 'Contact not inserted');

        //Location creation
        SVMXC__Site__c location1 = TestDataFieldService.createLocation('ServiceLoc1', 'Stringing street New York1', 'USA1', '435271', 'USD');
        insert location1;
        System.assert(location1.id != null, 'Location1 not inserted');
        SVMXC__Site__c location2 = TestDataFieldService.createLocation('ServiceLoc2', 'Stringing street New York2', 'USA2', '435272', 'USD');
        insert location2;
        System.assert(location2.id != null, 'Location2 not inserted');

        //Case Creation
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        objCase.SVMXC__Site__c = location1.id;
        insert objCase;
        System.assert(objCase.id != null, 'Case not inserted');
        system.debug('Location----------->'+objCase.SVMXC__Site__c);

        //Work Order Creation
        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        Test.startTest();
        objWorkOrder.SVMXC__Company__c=objAccount.Id;
        objWorkOrder.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
        objWorkOrder.SVMXC__Case__c = objCase.Id;
        objWorkOrder.SVMXC__Site__c = location1.Id;
        objWorkOrder.Is_Auto_Created__c=true;
        insert objWorkOrder;
        System.assert(objWorkOrder.id != null, 'Work not inserted');

        Test.stopTest();
        List<SVMXC__Service_Order__c> workOrder =  [SELECT id, Shipping_Location_Address__c, SVMXC__Site__c FROM SVMXC__Service_Order__c where id =: objWorkOrder.id LIMIT 1];
        System.assert(workOrder[0].Shipping_Location_Address__c != NULL, 'Work Order Shipping Location Address field didnt populate');
    }
}