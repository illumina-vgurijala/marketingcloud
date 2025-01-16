/**
 * Class Name: TestTPSPWorkOrderShareService
 * Description: This is a test class for TPSPWorkOrderShareService class.
 */
@isTest
public with sharing class TestTPSPWorkOrderShareService {
    private static final String STRING_USER_EMAIL = 'testuser@tpsp.com';
    private static final String STRING_TIMEZONE = 'America/Los_Angeles';
    private static final String STRING_ACCOUNT = 'Test Acc';
    private static final String STRING_WO_RECORDTYPE_REMOTE_SUPPORT = 'Remote Support';
    private static final String STRING_WO_RECORDTYPE_FIELD_SERVICE = 'Field Service';
    private static final String STRING_USD = 'USD';
    private static final String STRING_LANGUAGE_KEY = 'en_US';
    
    /**
     * method name: createShareRecordsForRelatedRecsOnWO
     * Description: Tests create sharing records for TPSP users
     */
    @isTest
    static void createShareRecordsForRelatedRecsOnWOTest(){
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, STRING_USD);
        acc.Account_Group__c='Distributor';
        insert acc;
        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assertNotEquals(null, con.Id, 'Contact is not inserted');
        
        //insert case     
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;

        //create a TPSP user
         User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name =: Label.Field_Service_Third_Party].Id,
            LastName = 'last_tpsp',
            Email = STRING_USER_EMAIL,
            Username = STRING_USER_EMAIL + System.currentTimeMillis(),
            CompanyName = 'TEST_tptp',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = STRING_TIMEZONE,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = STRING_LANGUAGE_KEY,
            LocaleSidKey = STRING_LANGUAGE_KEY
            
       );
       insert u;

        //insert Installed product
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', STRING_USD, 'New');
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        objInstalledProduct.Operation_Status__c='Off';
        insert objInstalledProduct;
        
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE_REMOTE_SUPPORT, cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Auto_Created__c = true;
        workOrder.SVMXC__Company__c = acc.Id;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        insert workOrder;
        System.assertNotEquals(null, workorder.Id, 'Work order is not inserted');
        
        Test.startTest();
        //update the owner to TPSP user
        workOrder.OwnerId = u.Id;
        update workOrder;
        Test.stoptest();
        //assert for share records on case,account
        List<CaseShare> lstCaseShare = [Select Id from CaseShare where CaseId = :cs.Id and UserOrGroupId=:u.Id];
        System.assertEquals(1, lstCaseShare.size(),'Case record is Not shared with TPSP user');
       
    }
    /**
     * method name: removeShareRecordsForRelatedRecsOnWO
     * Descrption: Tests remove sharing records for TPSP users.
    *            - seeAllData = true because it is needed for parts order insertion.
     */
    @isTest(SeeAlldata = true)
    static void removeShareRecordsForRelatedRecsOnWOTest(){
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, STRING_USD);
        acc.Account_Group__c='Distributor';
        insert acc;
        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assertNotEquals(null, con.id, 'Contact not inserted');
        
        //insert case     
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
        //insert Installed product
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', STRING_USD, 'New');
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        objInstalledProduct.Operation_Status__c='Off';
        insert objInstalledProduct;

        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE_REMOTE_SUPPORT, cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Auto_Created__c = true;
        workOrder.SVMXC__Company__c = acc.Id;
        insert workOrder;
        System.assertNotEquals(null, workorder.Id, 'Work order is not inserted');
        //create a TPSP user
        User u = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name =: Label.Field_Service_Third_Party].Id,
             LastName = 'last_tpsp',
             Email = STRING_USER_EMAIL,
             Username = STRING_USER_EMAIL + System.currentTimeMillis(),
             CompanyName = 'TEST_tptp',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = STRING_TIMEZONE,
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = STRING_LANGUAGE_KEY,
             LocaleSidKey = STRING_LANGUAGE_KEY
             
        );
        insert u;
        
        //insert parts order for the work order
        SVMXC__RMA_Shipment_Order__c partOrder = TestDataFieldService.createPartOrder('RMA', cs.Id, 'Open');
        //Parts Order creation in SAP (Inbound to SAP from SVMX)
        integer stringLength = 4;
        double maxLimit = Math.pow(10,stringLength) - 1; // Returns 9999
        String randomNumber = String.valueOf(Math.Round(Math.Random() * maxLimit)).leftPad(stringLength,'0'); //Generate random 4 digit number
        partOrder.ERP_Sales_Order_Number__c = randomNumber;
        partOrder.Contact_Name__c='Test';
        partOrder.Contact_Phone__c='Test';
        partOrder.SVMXC__Order_Type__c='Return';
        partOrder.Svmxc__service_order__c = workOrder.Id;
        insert partOrder;
        
        Test.startTest();

        //update the owner to TPSP user
        Id oldOwnerId = UserInfo.getUserId();
        workOrder.OwnerId = u.Id;
        update workOrder;
        
        /** ================*/
        //log in as TPSP user
        System.runAs(u){
            //assign back the owner to the internal user.
            workOrder.OwnerId = oldOwnerId;
            update workOrder;
        }
        
        Test.stoptest();
        //assertion for removal of share records
        List<CaseShare> lstCaseShare2 = [Select Id from CaseShare where CaseId = :cs.Id and UserOrGroupId=:u.Id];
        System.assertEquals(true, lstCaseShare2.isEmpty(), 'Case Sharing not removed');
    }
    
    @isTest
    static void createShareRecordsForRelatedIPOnWOTest(){
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, STRING_USD);
        acc.Account_Group__c='Distributor';
        insert acc;
        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assertNotEquals(null, con.Id, 'Contact is not inserted');

        //create a TPSP user
         User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name =: Label.Field_Service_Third_Party].Id,
            LastName = 'last_tpsp',
            Email = STRING_USER_EMAIL,
            Username = STRING_USER_EMAIL + System.currentTimeMillis(),
            CompanyName = 'TEST_tptp',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = STRING_TIMEZONE,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = STRING_LANGUAGE_KEY,
            LocaleSidKey = STRING_LANGUAGE_KEY
            
       );
       insert u;

        //insert Installed product
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', STRING_USD, 'New');
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        insert objInstalledProduct;
        
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE_FIELD_SERVICE, null, 'Initiated');
        workOrder.SVMXC__Order_Type__c= 'Preventative Maintenance';
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        insert workOrder;
        System.assertNotEquals(null, workorder.Id, 'Work order is not inserted');
        
        Test.startTest();
        //update the owner to TPSP user
        workOrder.OwnerId = u.Id;
        update workOrder;
        Test.stoptest();
        List<SVMXC__Installed_Product__Share> lstIPShare = [Select Id, AccessLevel from SVMXC__Installed_Product__Share where ParentId = :objInstalledProduct.Id and UserOrGroupId=:u.Id];
        //assert for share records on case,account
        System.assertEquals(1, lstIPShare.size(),'Installed Product record is not shared with TPSP user');
        System.assertEquals('Edit', lstIPShare[0].AccessLevel,'TPSP user does not have Edit access to the IP');
    }
}
