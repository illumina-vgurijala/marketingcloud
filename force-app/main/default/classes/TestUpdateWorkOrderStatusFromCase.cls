/***************************************************************************************************************************************
 * NAME   : TestUpdateWorkOrderStatusFromCase
 * DESCRIPTION  : Test Class for UpdateWOStatusFromCase
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
public class TestUpdateWorkOrderStatusFromCase {
    static Case cs;
    static Case cs1;
    
    @testSetup
		/*Test Data*/
    public static void initializeTestData() {
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
        cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
        System.assertNotEquals(null, cs.Id);
        cs1 = TestDataCase.initServiceRequestCase(con);
        insert cs1;
        System.assertNotEquals(null, cs1.Id);
        cs1.Status = 'In Progress';
        update cs1;
    }
    
    static testMethod void updateWorkOrderStatus(){
        initializeTestData();
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Installation';
    	workOrder.Is_Auto_Created__c = true;
        Test.startTest();
        insert workOrder;
        System.assertNotEquals(null, workOrder.Id);
        workOrder.SVMXC__Order_Status__c='Reopen Requested';
        workOrder.Reason_for_Reopen__c = 'reopen';
        workOrder.Order_Previous_Status__c = 'Closed';
        workOrder.Reopen_Requester__c = userInfo.getUserId();
   	 	workOrder.Has_Verification_Code__c= true;
        update workOrder;
        SVMXC__Service_Order__c workOrder1 = TestDataFieldService.createWorkOrder('Field Service', cs1.Id, 'Initiated');
        workOrder1.SVMXC__Order_Type__c='Installation';
        workOrder1.Is_Auto_Created__c = true;
        insert workOrder1;
        System.assertNotEquals(null, workOrder1.Id);
        workOrder1.SVMXC__Order_Status__c='Reopen Requested';
        workOrder1.Reason_for_Reopen__c = 'reopen';
        workOrder1.Order_Previous_Status__c = 'Closed';
        workOrder1.Reopen_Requester__c = userInfo.getUserId();
    	workOrder1.Has_Verification_Code__c= true;
        update workOrder1;        
        

        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'SS_Reopen_Work_Order'];
        
        Id idUser = [select id,AssigneeId from PermissionSetAssignment where PermissionSetId =: ps.Id][0].AssigneeId;
        try{
            System.runAs([select id from user where id =: idUser][0]){
                UpdateWOStatusFromCase.updateWorkOrdersStatus(new list<Case>{cs,cs1});        
            }
            /*  workOrder = [SELECT SVMXC__Order_Status__c,Order_Previous_Status__c 
From SVMXC__Service_Order__c
WHERE ID =: workOrder.Id  ]; */
        }
        catch(Exception e){
            System.debug('**tc the error message is '+e.getMessage());
        }
        //system.assertEquals('Closed',[select id,SVMXC__Order_Status__c from SVMXC__Service_Order__c where id =: workOrder.Id][0].SVMXC__Order_Status__c);
        //system.assertEquals(Label.WorkOrderStatusAssigned,
        //                    [select id,SVMXC__Order_Status__c from SVMXC__Service_Order__c where id =: workOrder1.Id][0].SVMXC__Order_Status__c);
        

        Test.stopTest();
    }
}