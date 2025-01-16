/***************************************************************************************************************************************
 * NAME   : TestWorkOrderStatusChangeReason
 * DESCRIPTION  : for WorkOrderStatusChangeReason.cls and WorkOrderStatusChangeReason.cmp. 
 				  DCP-720 Display popup to enter Reason while Work Order status change.
 *    
 * @AUTHOR : Debalina
 * @DATE   : 16-May-2018  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Debalina             16-May-2018          	 Initial Version
 * Debalina             13-June-2018			 802 Code Review Comments
  ****************************************************************************************************************************************/ 
@isTest(SeeAllData = false) 
public with sharing class TestWorkOrderStatusChangeReason {

	testMethod static void testLoadPageData(){
		String strJSONData = '';
		List<User> lstUsers = [SELECT Id 
	    							FROM User 
	    						WHERE Profile.Name =: System.label.Field_Service  AND isActive = true
	    						LIMIT 1];
        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
        insert objWorkOrder;
		Test.startTest();
		if(!lstUsers.isEmpty())
		{
			 System.runAs(lstUsers[0]){
				strJSONData = WorkOrderStatusChangeReason.loadPageData(objWorkOrder.Id);
		    }
		} 
		Test.stopTest();
		System.assertEquals(false,'Fail'.equals(strJSONData)); 
	}
	
}