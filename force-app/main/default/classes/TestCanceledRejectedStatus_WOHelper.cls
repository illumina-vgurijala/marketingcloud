/**
* @author Shivani Jain
* @date 8th June 2022
*
* @description DCP-54018 Test class for CanceledRejectedStatus_WOHelper
*/
@IsTest
private class TestCanceledRejectedStatus_WOHelper {

    private static final String STRING_ACCOUNT = 'Test Acc';
    private static final String STRING_WO_RECORDTYPE = 'Field Service';
    private static final String STRING_SERVICE_TEAM_NAME = 'Test Team';
    private static final String STRING_WO_ORDER_TYPE = 'Service Activities';

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

    /*******************************************************************************************************
    * @description test method checkPartsOrderStatusChange
    */ 
    static testmethod void testProcessCancelledAutorejectedWorkOrders1() {

        Test.startTest();
         Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
         acc.Account_Group__c='Distributor';
         insert acc;
        List<Case> lstCase = [SELECT id FROM Case LIMIT 1];
        List<SVMXC__Service_Order__c> lstWOToProcess = new List<SVMXC__Service_Order__c>();
        SVMXC__Service_Order__c objCanceledWorkOrder = TestDataFieldService.createWorkOrder('Field Service',lstCase[0].Id,'Initiated');
        objCanceledWorkOrder.SVMXC__Case__c = null;
        objCanceledWorkOrder.SVMXC__Order_Type__c = 'Installation';
        //objCanceledWorkOrder.SVMXC__Order_Type__c='Service Activities;
        objCanceledWorkOrder.Is_Auto_Created__c = true;
        objCanceledWorkOrder.Record_Created_from_SFM__c=true; 
        objCanceledWorkOrder.Reason__c = 'TestingReasonField';
        objCanceledWorkOrder.SVMXC__Company__c = acc.Id;
        //objCanceledWorkOrder.SVMXC__Company__c = lstAccount[0].id;
        SVMXC__Service_Order__c objDowndWorkOrder = TestDataFieldService.createWorkOrder('Field Service',lstCase[0].Id,'Initiated');
        objDowndWorkOrder.SVMXC__Order_Type__c='Service Activities';
        objDowndWorkOrder.Record_Created_from_SFM__c=true;
        lstWOToProcess.add(objCanceledWorkOrder);
        lstWOToProcess.add(objDowndWorkOrder);
        insert lstWOToProcess;
        objCanceledWorkOrder.Reason__c ='Test';
        objCanceledWorkOrder.SVMXC__Order_Status__c = 'Canceled';
        objDowndWorkOrder.SVMXC__Customer_Down__c = true;
        update lstWOToProcess;
        System.assertEquals('Canceled', objCanceledWorkOrder.SVMXC__Order_Status__c, 'Status');     
        Test.stopTest();
    }
        
    /*******************************************************************************************************
    * @description test method checkPartsOrderStatusChange
    */ 
    static testmethod void testProcessCancelledAutorejectedWorkOrders2() {

        Test.startTest();
         Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
         acc.Account_Group__c='Distributor';
         insert acc;
        List<Case> lstCase = [SELECT id FROM Case LIMIT 1];
        List<SVMXC__Service_Order__c> lstWOToProcess = new List<SVMXC__Service_Order__c>();
        SVMXC__Service_Order__c objCanceledWorkOrder = TestDataFieldService.createWorkOrder('Field Service',lstCase[0].Id,'Initiated');
        objCanceledWorkOrder.SVMXC__Case__c = null;
        objCanceledWorkOrder.SVMXC__Order_Type__c = 'Installation';
        //objCanceledWorkOrder.SVMXC__Order_Type__c='Service Activities;
        objCanceledWorkOrder.Is_Auto_Created__c = true;
        objCanceledWorkOrder.Record_Created_from_SFM__c=true; 
        objCanceledWorkOrder.Reason__c = 'TestingReasonField';
        objCanceledWorkOrder.SVMXC__Company__c = acc.Id;
        //objCanceledWorkOrder.SVMXC__Company__c = lstAccount[0].id;
        SVMXC__Service_Order__c objDowndWorkOrder = TestDataFieldService.createWorkOrder('Field Service',lstCase[0].Id,'Initiated');
        objDowndWorkOrder.SVMXC__Order_Type__c='Service Activities';
        objDowndWorkOrder.Record_Created_from_SFM__c=true;
        objCanceledWorkOrder.SVMXC__Order_Status__c = 'Assignment Accepted';
        lstWOToProcess.add(objCanceledWorkOrder);
        lstWOToProcess.add(objDowndWorkOrder);
        insert lstWOToProcess;
        objCanceledWorkOrder.Reason__c ='Test';
        objCanceledWorkOrder.SVMXC__Order_Status__c = 'Scheduled';
        objDowndWorkOrder.SVMXC__Customer_Down__c = true;
        objDowndWorkOrder.Send_Notification_To_Customer__c = true;
        update lstWOToProcess;
        System.assertNotEquals(null,lstWOToProcess.size(), 'Size equals null'); 
        Test.stopTest();
    }
        
 /*******************************************************************************************************
    * @description test method checkPartsOrderStatusChange
    */ 
    static testmethod void testProcessCancelledAutorejectedWorkOrders3() {
        
        Test.startTest();
         Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
         acc.Account_Group__c='Distributor';
         insert acc;
        List<Case> lstCase = [SELECT id FROM Case LIMIT 1];
        List<SVMXC__Service_Order__c> workOrderList = new List<SVMXC__Service_Order__c>();
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, lstCase[0].Id, 'Assigned');
        workOrder.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
        workOrder.Is_Service_Report_Generated__c=true;
        workOrder.Record_Created_from_SFM__c=true;
        workOrder.Evaluation__c='Test';
        workOrder.SVMXC__Work_Performed__c='Test';
        workOrder.Verification_Result__c='Test'; 
        workOrder.PO_Number__c = '12345'; 
        workOrder.Field_Support_User_Role__c = 'Field Service Manager';
        workOrder.SVMXC__Company__c = acc.Id;
        workOrder.Reason__c = 'Testing';
        workOrderList.add(workOrder);
        insert workOrderList;

        workOrderList[0].Reason__c = 'Testing reason';
        workOrderList[0].SVMXC__Order_Status__c = 'Initiated';
        update workOrderList;
        System.assertEquals('Initiated', workOrderList[0].SVMXC__Order_Status__c, 'Diff Status'); 
        Test.stopTest();
    }
   /*******************************************************************************************************
    * @description test method checkPartsOrderStatusChange
    */ 
    static testmethod void testProcessCancelledAutorejectedWorkOrders4() {
        
         Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
         acc.Account_Group__c='Distributor';
         insert acc;

         SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;
        system.assertNotEquals(null,serviceTeam.id);

        SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(UserInfo.getUserId(),'Test Technician',serviceTeam.id);
        technician.SVMXC__Email__c='a@b.com';
        insert technician;
        system.assertNotEquals(null,technician.id);

        Account_to_Field_Support__c accToFieldSupport =TestDataFieldService.createAccountToFieldSupport(acc.id,'Primary Field Service Engineer',technician.id);
        insert accToFieldSupport;
        system.assertNotEquals(null,accToFieldSupport.id);

        List<Case> lstCase = [SELECT id FROM Case LIMIT 1];
        List<SVMXC__Service_Order__c> workOrderList = new List<SVMXC__Service_Order__c>();
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, lstCase[0].Id, 'Assigned');
        workOrder.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
        workOrder.Is_Service_Report_Generated__c=true;
        workOrder.Record_Created_from_SFM__c=true;
        workOrder.Evaluation__c='Test';
        workOrder.SVMXC__Work_Performed__c='Test';
        workOrder.Verification_Result__c='Test'; 
        workOrder.PO_Number__c = '12345'; 
        workOrder.Field_Support_User_Role__c = 'Primary Field Service Engineer';
        workOrder.SVMXC__Company__c = acc.Id;
        workOrder.Reason__c = 'Testing';
        workOrderList.add(workOrder);
        insert workOrderList;
        Test.startTest();
        workOrderList[0].Reason__c = 'Testing reason';
        workOrderList[0].SVMXC__Order_Status__c = 'Initiated';
        update workOrderList;
        Test.stopTest();
    }
       /*******************************************************************************************************
    * @description test method checkPartsOrderStatusChange
    */ 
    static testmethod void testProcessCancelledAutorejectedWorkOrders5() {
        
         Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
         acc.Account_Group__c='Distributor';
         insert acc;
         SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
         insert serviceTeam;
         system.assertNotEquals(null,serviceTeam.id);
 
         SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(UserInfo.getUserId(),'Test Technician',serviceTeam.id);
         technician.SVMXC__Email__c='a@b.com';
         insert technician;
         system.assertNotEquals(null,technician.id);
 
         Account_to_Field_Support__c accToFieldSupport =TestDataFieldService.createAccountToFieldSupport(acc.id,'Primary Field Service Engineer',technician.id);
         insert accToFieldSupport;
         system.assertNotEquals(null,accToFieldSupport.id);
        List<Case> lstCase = [SELECT id FROM Case LIMIT 1];
        List<SVMXC__Service_Order__c> workOrderList = new List<SVMXC__Service_Order__c>();
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, lstCase[0].Id, 'Assigned');
        workOrder.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
        workOrder.Is_Service_Report_Generated__c=true;
        workOrder.Record_Created_from_SFM__c=true;
        workOrder.Evaluation__c='Test';
        workOrder.SVMXC__Work_Performed__c='Test';
        workOrder.Verification_Result__c='Test'; 
        workOrder.PO_Number__c = '12345'; 
        workOrder.Field_Support_User_Role__c = 'Secondary Field Service Engineer';
        workOrder.SVMXC__Company__c = acc.Id;
        workOrder.Reason__c = 'Testing';
        workOrderList.add(workOrder);
        insert workOrderList;
        Test.startTest();
        workOrderList[0].Reason__c = 'Testing reason';
        workOrderList[0].SVMXC__Order_Status__c = 'Initiated';
        update workOrderList;
        Test.stopTest();
    }
    /*******************************************************************************************************
    * @description test method checkPartsOrderStatusChange
    */ 
    static testmethod void testProcessCancelledAutorejectedWorkOrders6() {
        
        Test.startTest();
         Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
         acc.Account_Group__c='Distributor';
         insert acc;
        List<Case> lstCase = [SELECT id FROM Case LIMIT 1];
        List<SVMXC__Service_Order__c> workOrderList = new List<SVMXC__Service_Order__c>();
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, lstCase[0].Id, 'Assigned');
        workOrder.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
        workOrder.Is_Service_Report_Generated__c=true;
        workOrder.Record_Created_from_SFM__c=true;
        workOrder.Evaluation__c='Test';
        workOrder.SVMXC__Work_Performed__c='Test';
        workOrder.Verification_Result__c='Test'; 
        workOrder.PO_Number__c = '12345'; 
        workOrder.SVMXC__Company__c = acc.Id;
        workOrder.Reason__c = 'Testing';
        workOrder.SVMXC__Order_Status__c = 'Assignment Accepted';
        workOrderList.add(workOrder);
        insert workOrderList;

        workOrderList[0].Reason__c = 'Testing reason';
        workOrderList[0].SVMXC__Order_Status__c = 'Scheduled';
        workOrderList[0].Send_Notification_To_Customer__c = true;
        update workOrderList;
        List<SVMXC__Service_Order__c> lstWorkOrder = [Select Id, SVMXC__Order_Status__c from SVMXC__Service_Order__c where id=:workOrder.Id];
        System.assertEquals('Scheduled', lstWorkOrder[0].SVMXC__Order_Status__c, 'Diff Order Status');
        Test.stopTest();
    }
}