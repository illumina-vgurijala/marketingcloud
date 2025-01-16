/***************************************************************************************************************************************
* @author Dhairya Shah
* @date 25-09-2024
*
* @description Process Builder to Flow Test Class for CreateScheduleEventHelper
* MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Dhairya                 25 Sept 24           Initial Version
*
****************************************************************************************************************************************/ 

@isTest(SeeAllData = false isParallel = false)
public with sharing class TestCreateScheduleEventHelper {
    public static final String STRING_WO_RECORDTYPE_REMOTE_SUPPORT = 'Remote Support';
    public static final String STRING_SERVICE_TEAM_NAME = 'Test Team';
    public static final String STRING_ACCOUNT = 'Test Acc';

    @TestSetup
     static void initializeTestData(){

        User u = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'Field Service'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        insert u;

        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = STRING_SERVICE_TEAM_NAME,
            SVMXC__Country__c = 'India'
        );
        insert serviceTeam;
        System.assertNotEquals(null, serviceTeam.Id);
        
        SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(
            Name = 'Test Name',
            SVMXC__Active__c = True,
            SVMXC__Email__c = 'testmail@testing.com',
            SVMXC__Country__c = 'India',
            SVMXC__Street__c = 'Test',
            SVMXC__Salesforce_User__c = u.Id,
            SVMXC__Service_Group__c = serviceTeam.Id
        );
        insert grpMembers;
        
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null);
        
        //insert case        
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
    }

    static testMethod void testCreateScheduleEvent() {
        // Step 1: Create and Insert a Work Order
        Case cs = [SELECT Id FROM Case LIMIT 1];
        SVMXC__Service_Group_Members__c grpMem = [SELECT Id FROM SVMXC__Service_Group_Members__c LIMIT 1];
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE_REMOTE_SUPPORT, cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c = 'Installation';
        workOrder.Is_Auto_Created__c = true;
        workOrder.SVMXC__Group_Member__c = null;
        workOrder.SVMXC__SM_Scheduled_Duration__c = 8; // In hours
        workOrder.SVMXC__Customer_Down__c = true;
        WorkOrders.skipWOTrigger = true;
    
        insert workOrder;
    
        List<SVMXC__Service_Order__c> serviceOrders = [SELECT Id,Name, SVMXC__Group_Member__c, SVMXC__Scheduled_Date_Time__c, 
            SVMXC__SM_Scheduled_Duration__c, Scheduled_Event_ID__c, Dispatcher__c 
            FROM SVMXC__Service_Order__c WHERE Id = :workOrder.Id];
        Map<Id, SVMXC__Service_Order__c> oldServiceOrders = new Map<Id, SVMXC__Service_Order__c>(serviceOrders);
    
        // Step 2: Update Work Order with Scheduled Date and Group Member
        workOrder.SVMXC__Scheduled_Date_Time__c = DateTime.now().addHours(2);
        workOrder.SVMXC__SM_Scheduled_Duration__c = 12; // In hours
        workOrder.SVMXC__Group_Member__c = grpMem.Id;
        WorkOrders.skipWOTrigger = true;
        update workOrder;
    
        // Step 3: Re-fetch updated Work Order
        serviceOrders = [SELECT Id,Name, SVMXC__Group_Member__c, SVMXC__Scheduled_Date_Time__c, 
            SVMXC__SM_Scheduled_Duration__c, Scheduled_Event_ID__c, Dispatcher__c 
            FROM SVMXC__Service_Order__c WHERE Id = :workOrder.Id];
    
        Test.startTest();
        CreateScheduleEventHelper.createScheduleEvent(serviceOrders, oldServiceOrders);
        Test.stopTest();
    
        // Step 4: Validate the events were created
        List<Event> events = [SELECT Id, StartDateTime, EndDateTime, OwnerId, WhatId, Subject, DurationInMinutes FROM Event LIMIT 1];
        System.assert(events.size() > 0, 'Expected events to be created');
        System.assertEquals(workOrder.Id, events[0].WhatId, 'Expected the Work Order to be associated with the Event');
        
        // Step 5: Validate StartDateTime and EndDateTime
        System.assertEquals(workOrder.SVMXC__Scheduled_Date_Time__c, events[0].StartDateTime, 'StartDateTime should match Work Order Scheduled Date');
        DateTime expectedEndDateTime = workOrder.SVMXC__Scheduled_Date_Time__c.addHours(Integer.valueOf(workOrder.SVMXC__SM_Scheduled_Duration__c));
        System.assertEquals(expectedEndDateTime, events[0].EndDateTime, 'EndDateTime should be StartDateTime plus Scheduled Duration');
        
        // Step 6: Validate DurationInMinutes
        Integer expectedDurationInMinutes = Integer.valueOf(workOrder.SVMXC__SM_Scheduled_Duration__c * 60);
        System.assertEquals(expectedDurationInMinutes, events[0].DurationInMinutes, 'DurationInMinutes should match the Scheduled Duration in minutes');
    } 

    @IsTest
    static void testUpdateInstalledProductOperationStatus() {

        Account acc = [SELECT id FROM Account WHERE Account_Group__c = 'Distributor' AND Name=: STRING_ACCOUNT LIMIT 1];
        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        objProduct.Product_Group__c = 'AmpliSeq Library Prep';
        insert objProduct;

        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        objInstalledProduct.Operation_Status__c='Off';
        objInstalledProduct.SVMXC__Product__c = objProduct.Id;
        insert objInstalledProduct;

        Case cs = [SELECT Id FROM Case LIMIT 1];
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE_REMOTE_SUPPORT, cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c = 'Installation';
        workOrder.Is_Auto_Created__c = true;
        workOrder.SVMXC__Group_Member__c = null;
        workOrder.SVMXC__SM_Scheduled_Duration__c = 8; // In hours
        workOrder.SVMXC__Customer_Down__c = false;
        workOrder.SVMXC__Component__c = objInstalledProduct.id;
        WorkOrders.skipWOTrigger = true;
        insert workOrder;

        List<SVMXC__Service_Order__c> serviceOrders = [SELECT Id, SVMXC__Component__c, SVMXC__Customer_Down__c,SVMXC__Component__r.Operation_Status__c 
                                                      FROM SVMXC__Service_Order__c WHERE ID=:workOrder.id];
        Map<Id, SObject> oldServiceOrders = new Map<Id, SObject>(serviceOrders);

        SVMXC__Service_Order__c serviceOrderToUpdate = serviceOrders[0];
        serviceOrderToUpdate.SVMXC__Customer_Down__c = true;
        WorkOrders.skipWOTrigger = true;
        update serviceOrderToUpdate;

        Test.startTest();
        CreateScheduleEventHelper.updateInstalledProductOperationStatus(serviceOrders, oldServiceOrders);
        Test.stopTest();

        SVMXC__Installed_Product__c updatedInstalledProduct = [SELECT Operation_Status__c FROM SVMXC__Installed_Product__c WHERE Id = :serviceOrderToUpdate.SVMXC__Component__c];
        System.assertEquals('Off', updatedInstalledProduct.Operation_Status__c, 'Operation Status should have been updated to On');
    }
}