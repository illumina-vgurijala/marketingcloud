/**
* @author Shivani Jain
* @date 8th June 2022
*
* @description DCP-54018 Test class for CheckDataIntegrity_WOHelper
*/
@IsTest
private class TestCheckDataIntegrity_WOHelper {

    private static final String STRING_ACCOUNT = 'Test Acc';
    private static final String STRING_SERVICE_TEAM_NAME = 'Test Team';
    private static final String STRING_WO_ORDER_TYPE = 'Service Activities';
    private static final String STRING_WO_RECORDTYPE = 'Field Service';

    /**
    *  @description - initialize test data
    **/
    @testSetup
    public static void initializeTestData() {
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = STRING_SERVICE_TEAM_NAME,
            SVMXC__Country__c = 'India'
        );
        insert serviceTeam;
        System.assertNotEquals(null, serviceTeam.Id);
        
        List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service AND IsActive=true LIMIT 1];
        SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(
            Name = 'Test Name',
            SVMXC__Active__c = True,
            SVMXC__Email__c = 'testmail@testing.com',
            SVMXC__Country__c = 'India',
            SVMXC__Street__c = 'Test',
            SVMXC__Salesforce_User__c = lstUsers[0].Id,
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

     /*
      *  @description -
      **/    
    static testMethod void testCheckDataIntegrity() {
        Case cs = [SELECT id FROM Case LIMIT 1];
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'SVMXC__Service_Order__c'
        );
        insert apexSettings;
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
        workOrder.Record_Created_from_SFM__c = true;
        workOrder.SVMXC__Billing_Type__c = 'Billable';
        insert workOrder;

        workOrder.RecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByName().get('Estimates').getRecordTypeId();
        update workOrder;
        List<SVMXC__Service_Order__c> lstWorkOrder = [Select Id, SVMXC__Billing_Type__c from SVMXC__Service_Order__c where id=:workOrder.Id];
        System.assertEquals('Billable', lstWorkOrder[0].SVMXC__Billing_Type__c, 'Diff Billing Type');
    }

}