/**
* @author Shivani Jain
* @date 8th June 2022
*
* @description DCP-54018 Test class for FAIQueueable_WOHelper
* Dhairya 17April2024 CMCM6760
*/
@IsTest
private class TestFAIQueueable_WOHelper {

    private static final String STRING_ACCOUNT = 'Test Acc';
    private static final String STRING_SERVICE_TEAM_NAME = 'Test Team';
    private static final String STRING_WO_RECORDTYPE_REMOTE_SUPPORT = 'Remote Support';

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
        
        List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service LIMIT 1];
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

    /**
     *  @author Digvijay
    *  @description - test the work order status on case when a new work order is inserted 
    **/
    static testMethod void updateFAIonWO() {

        Case cs = [SELECT id FROM Case LIMIT 1];

        Boolean exceptionThrown = false;
        
        //To create a FAN record of record type "Notification"
        Field_Action_Notification__c fAN =TestDataFieldService.createFAN('Notification');
        
        //changded from field support to Remote support by prashanth
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE_REMOTE_SUPPORT, cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Auto_Created__c = true;
        try {
            Test.startTest();
            FAIQueueable_WOHelper.testClassCoverage = true;
            insert workOrder;
            
            Field_Action_Item__c fAI1 =TestDataFieldService.createFAI(cs.Id, fAN.Id);
            insert fAI1;
            Test.stopTest();
        } catch(Exception ex) {
            exceptionThrown = ex.getMessage().contains('Throwing Exception from Test Class');
            System.assert(exceptionThrown, 'Exception not thrown from queueable class');// CMCM 6760 Changed by dhairya shah
        }
        
        Field_Action_Item__c objFAI=[Select Work_Order__c  from Field_Action_Item__c LIMIT 1];
        System.assertEquals(objFAI.Work_Order__c , workOrder.Id, 'FAI not updated on Work Order');
    }

    /**
     *  @author Digvijay
    *  @description - Update Case on FAI
    **/
    static testMethod void updateFAIonWOOnUpdate() {

        Account acc = [SELECT id FROM Account WHERE Account_Group__c = 'Distributor' LIMIT 1];
        Contact con = [SELECT id, AccountId FROM Contact WHERE AccountId =: acc.Id LIMIT 1];
        Case cs = [SELECT id FROM Case LIMIT 1];
        
        //To create a FAN record of record type "Notification"
        Field_Action_Notification__c fAN =TestDataFieldService.createFAN('Notification');
        
        //changed from field support to Remote support by prashanth
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE_REMOTE_SUPPORT, cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Auto_Created__c = true;
        Test.startTest();
        insert workOrder;
        
        Field_Action_Item__c fAI1 =TestDataFieldService.createFAI(cs.Id, fAN.Id);
        insert fAI1;
        Case cs2=TestDataCase.initServiceRequestCase(con);
        insert cs2;
        workOrder.SVMXC__Case__c=cs2.id;
        update workOrder;
        
        Test.stopTest();
        Field_Action_Item__c objFAI=[Select Case__c from Field_Action_Item__c where Work_Order__c=:workOrder.Id];
        System.assertEquals(objFAI.Case__c, cs2.Id, 'FAI not updated on Case');
    }
}