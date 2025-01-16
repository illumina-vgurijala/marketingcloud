/***************************************************************************************************************************************
 * NAME   : TestUpdateWorkOrderPreviousStatusFromCase
 * DESCRIPTION  : Test Class for UpdateWOPreviousStatusFromCase
 *           DCP-12485  : Work Order and Case Reopening Process 
 *    
 * @AUTHOR : Dipika Gupta
 * @DATE   : 3-Oct-2018  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Dipika             3-Oct-2018             Initial Version
  ****************************************************************************************************************************************/ 
@isTest(SeeAllData = false)  
public class TestUpdateWorkOrderPreStatusFromCase {
    static Case cs;
    
    @testSetup
		/*Test Data*/
    public static void initializeTestData() {
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
        cs = TestDataCase.initServiceRequestCase(con);
        cs.Reason_for_Reopen__c = 'Test Reason';
        insert cs;
    }
    
    static testMethod void updateWorkOrderStatus(){
        initializeTestData();
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Installation';
		workOrder.Is_Auto_Created__c = true;
        Test.startTest();
        insert workOrder;
        
        workOrder.SVMXC__Order_Status__c='Closed';
		workOrder.Has_Verification_Code__c= true ;
        update workOrder;
        
        UpdateWOPreviousStatusFromCase.updateWorkOrdersPreviousStatus(new list<Case>{cs});
        workOrder = [SELECT SVMXC__Order_Status__c,Order_Previous_Status__c 
                        From SVMXC__Service_Order__c
                        WHERE ID =: workOrder.Id  ];
        system.assertEquals('Closed',workOrder.Order_Previous_Status__c) ; 
        system.assertEquals(workOrder.SVMXC__Order_Status__c,Label.ReopenRequested) ; 
        Test.stopTest();
    }
}