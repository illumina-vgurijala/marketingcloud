/***************************************************************************************************************************************
 * NAME   : TestServiceOrderEmailFlow
 * DESCRIPTION  : TestClass for Assignment_for_Quote_Creation flow
 *    
 * @AUTHOR : Dhairya
 * @DATE   : 12th Sept 2024 
 *
 * MODIFICATION LOG:   
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Dhairya             12th Sept 2024           Initial Version
  ***************************************************************************************************************************************
*/ 
@isTest
public class TestServiceOrderEmailFlow {

    public static final String STRING_WO_RECORDTYPE = 'Field Service';

    @testSetup
    static void setupTestData() {        
        
        // Create Test Data: Accounts and Service Orders
        Account acc = TestDataAccount.getAccount('TestAccount Level2','USD');
        acc.Account_Group__c='Sold To';
        insert acc;   

        // Create Service Orders for each region
        List<SVMXC__Service_Order__c> serviceOrders = new List<SVMXC__Service_Order__c>();

        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Preventative Maintenance';
        workOrder.SVMXC__Company__c = acc.Id;
        workOrder.OwnerId = UserInfo.getUserId();
        workOrder.Send_for_Quote_Creation__c = false;
        serviceOrders.add(workOrder);
                
        WorkOrders.skipWOTrigger = true;
        insert serviceOrders;
    }

    @isTest
    static void testFlowEmailAlerts() {

        Integer initialEmailLimit = Limits.getEmailInvocations();

        SVMXC__Service_Order__c amrOrder = [SELECT Id, OwnerId FROM SVMXC__Service_Order__c LIMIT 1];
        Test.startTest();
        
        amrOrder.OwnerId = System.Label.AMRWorkOrderEstimatesQueueId;  // Simulate owner change
        WorkOrders.skipWOTrigger = true;
        update amrOrder;
        System.assertEquals(initialEmailLimit, Limits.getEmailInvocations(), 'AMR email alert should be sent');

        amrOrder.OwnerId = System.Label.EURWorkOrderEstimatesQueueId;
        WorkOrders.skipWOTrigger = true;
        update amrOrder;
        System.assertEquals(initialEmailLimit, Limits.getEmailInvocations(), 'EUR email alert should be sent');

        amrOrder.OwnerId = System.Label.AMEAWorkOrderEstimatesQueueId;
        WorkOrders.skipWOTrigger = true;
        update amrOrder;
        System.assertEquals(initialEmailLimit, Limits.getEmailInvocations(), 'AMEA email alert should be sent');        

        amrOrder.OwnerId = System.Label.GCWorkOrderEstimatesQueueId;
        WorkOrders.skipWOTrigger = true;
        update amrOrder;
        Test.stopTest();
        System.assertEquals(initialEmailLimit, Limits.getEmailInvocations(), 'GC email alert should be sent');
    }
}