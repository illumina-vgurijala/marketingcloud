/**
*    @author Ritika
*    @date  
*    @description    Test class for AutoCloseWOHelper
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer               Date                Description
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public with sharing class TestAutoCloseWOHelper {
    public static final String STRING_WO_RECORDTYPE = 'Field Service';
    public static final String STRING_WO_ORDER_TYPE = 'Service Activities';
    /**
    *   @author Ritika  
    **/
    @isTest
    public static void testWOClosure(){
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        
        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
                
        //insert case        
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;

        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
        workOrder.Is_Service_Report_Generated__c=true;
        workOrder.Record_Created_from_SFM__c=true;
        workOrder.Evaluation__c='Test';
        workOrder.SVMXC__Work_Performed__c='Test';
        workOrder.Verification_Result__c='Test'; 
        insert workOrder;
        
        Test.startTest();
        workOrder.PO_Number__c='12';
        workOrder.SVMXC__Order_Status__c = 'Completed';
        workOrder.No_Calibrated_Tools_Used__c = true;
        update workOrder;
        Test.getEventBus().deliver();
        Test.stopTest();
        SVMXC__Service_Order__c resultWorkOrder = [Select id,SVMXC__Order_Status__c from SVMXC__Service_Order__c where Id = :workOrder.Id];
        System.assertEquals(resultWorkOrder.SVMXC__Order_Status__c, 'Closed');
    }
}