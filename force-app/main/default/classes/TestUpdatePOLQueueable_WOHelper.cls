/**
* @author Shivani Jain
* @date 13th June 2022
*
* @description DCP-54018 Test class for UpdatePOLQueueable_WOHelper
*/
@IsTest(seeAllData = true)
public with sharing class TestUpdatePOLQueueable_WOHelper {

    private static final String STRING_WORK_ORDER_RECORD_TYPE_SERVICE_SUPPORT = 'Service Support';
    private static final String STRING_WORK_ORDER_STATUS_INITIATED ='Initiated';
    private static final String STRING_WORK_ORDER_TYPE_INSTALLATION = 'Installation';

    /**
    * DCP-1047, DCP-1053
    *  @author 
    *  @description - test the work order status on case when a new work order is inserted 
    */
    static testMethod void testUpdatePOLQueueable() {

        //Create Account, Contact
        Account objAccount = TestDataAccount.getNewAccount();
        objAccount.Account_Group__c = 'Sold To';
        update objAccount;
        Contact objContact = TestDataContact.getNewContact(objAccount);

        //Create Product
        Product2 prod = TestDataMaster.createProduct(false);
        prod.Service_Product_Type__c = 'Core';
        prod.CurrencyIsoCode = 'USD';
        prod.Source_System__c = 'SAP';
        insert prod;

        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('test', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        objInstalledProduct.SVMXC__Product__c = prod.Id;
        objInstalledProduct.Asset_Type__c = 'Customer 3rd Party Owned';
        insert objInstalledProduct;

        //Create Case
        Case objCaseTest = TestDataCase.initServiceRequestCase(objContact);
        objCaseTest.SVMXC__Component__c = objInstalledProduct.Id;
        insert objCaseTest;
            
        List<SVMXC__Site__c> lstLocation = new List<SVMXC__Site__c>();
        SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'locationtwo');
        lstLocation.add(objLocationRec);
        
        SVMXC__Site__c toLocation = new SVMXC__Site__c(Name = 'locationone',SVMXC__Stocking_Location__c=true,Type__c='Trunk');
        lstLocation.add(toLocation);
        
        insert lstLocation;

        //insert service contract
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.Consumables_Included__c=false;
        objServiceContract.Status__c = 'Active';
        objServiceContract.Parts_Included__c = false;
        insert objServiceContract;
        
        //Create Workorder
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WORK_ORDER_RECORD_TYPE_SERVICE_SUPPORT, objCaseTest.Id, STRING_WORK_ORDER_STATUS_INITIATED);
        workOrder.SVMXC__Order_Type__c = STRING_WORK_ORDER_TYPE_INSTALLATION;
        workOrder.SVMXC__Company__c = objAccount.Id;
        workOrder.SVMXC__Site__c = lstLocation.get(0).Id;
        workOrder.SVMXC__Contact__c = objContact.Id;
        workOrder.Record_Created_from_SFM__c=true;
        workOrder.SVMXC__Component__c= objInstalledProduct.Id;
        insert workOrder;

        //insert applied contract
        Applied_Contract__c objEntitlement = new Applied_Contract__c();
        objEntitlement.CurrencyIsoCode='USD';
        objEntitlement.Work_Order__c = workOrder.id;
        objEntitlement.Service_Contract__c = objServiceContract.Id;
        insert objEntitlement;
        
        Test.startTest();
        //Create Parts Order
        SVMXC__RMA_Shipment_Order__c objPartsOrder = TestDataFieldService.createPartsOrder(objCaseTest.Id);
        objPartsOrder.SVMXC__Service_Order__c = workOrder.Id;
        objPartsOrder.SVMXC__Order_Status__c = 'Open';
        objPartsOrder.SVMXC__Order_Type__c = 'Shipment';
        objPartsOrder.Contact_Name__c = 'Test';
        objPartsOrder.Contact_Phone__c = '87897';
        objPartsOrder.Shipping_Location__c = lstLocation.get(0).id;
        objPartsOrder.SVMXC__Destination_Location__c = lstLocation.get(1).id;
        
        insert objPartsOrder;
        

        //Create Parts Order Line
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        objPartsOrderLine.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        objPartsOrderLine.SVMXC__Product__c = prod.Id;
        objPartsOrderLine.From_Location__c = lstLocation.get(0).id;
        
        insert objPartsOrderLine;
        
        workOrder.SVMXC__Scheduled_Date_Time__c=system.now();
        workOrder.SVMXC__SM_Scheduled_Duration__c=1.2;
        workOrder.SVMXC__Order_Status__c = 'Scheduled'; 
        update workOrder;
        System.assert(workOrder.Id != null, 'Work Order Update failed!');
        Test.stopTest();

    }
}