/*
* Date                           Name                                        Description
* 18-09-2022                     Sheikh Shahnawaz                            Enhance code coverage above 80%
**/
@isTest(SeeAllData = false)  
/***************************************************************************************************************************************
* NAME   : ScheduledBatchSendWorkOrdersToSAPTest 
* --------------------------------------------------------------------------------------------------------------------------------------
*/	
public class ScheduledBatchSendWorkOrdersToSAPTest{

static Case cs;
    
    @testSetup
	
		/*
         * description - initializeTestData method
		 * return - void
         */ 	
    public static void initializeTestData()
    {
        Contact con = TestDataPerson.getNewContact(null);
        cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
    }
    
		/*
         * description - testSchedule method
		 * return - void
         */ 	
    public static testMethod void testSchedule() {
        Test.StartTest();
        ScheduledBatchSendWorkOrdersToSAP testsche = new ScheduledBatchSendWorkOrdersToSAP();
        String sch = '0 0 23 * * ?';
        system.schedule('Test status Check', sch, testsche );
        Test.stopTest();
    }
    
    /**
    *  @author 
    *  @description - test the work order status on case when a new work order is inserted 
    **/
    static testMethod void newWorkOrderCreation(){
        
        initializeTestData();
       //changded from field support to Remote support by prashanth
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Remote Support', cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Auto_Created__c = true;
        workOrder.Qualified_for_Batched_Sync_to_ERP__c = true;
        Test.startTest();
        insert workOrder;
        /* Enhance test class coverage start */
        List < String > lstErrors = new List < String > ();
        lstErrors.add('Test');
        Map<Id, String> mapRecIdToErrors = new Map<Id, String>();
        mapRecIdToErrors.put(workOrder.Id,'Test');
        ScheduledBatchSendWorkOrdersToSAP objBatch = new ScheduledBatchSendWorkOrdersToSAP();
        ScheduledBatchSendWorkOrdersToSAP.mapRecIdToErrors = mapRecIdToErrors;
        objBatch.lstErrors = lstErrors;
        Feature.setMockFeatureFlag('ServiceBatchErrorNotifications', true);
        /* Enhance test class coverage end */
        database.executebatch(new ScheduledBatchSendWorkOrdersToSAP(), 1);
        Test.stopTest();
		SVMXC__Service_Order__c workOrderAfterBatch = [Select Id,Qualified_for_Batched_Sync_to_ERP__c from SVMXC__Service_Order__c where Id =: workOrder.Id];
        system.assertEquals(false, workOrderAfterBatch.Qualified_for_Batched_Sync_to_ERP__c);
    }
    
  

}