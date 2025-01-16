/**
* @author Shivani Jain
* @date 13th June 2022
*
* @description DCP-54018 Test class for WorkDetail_WOHelper
*/
@IsTest
public with sharing class TestWorkDetail_WOHelper {

    private static final String STRING_ACCOUNT = 'Test Acc';
    private static final String STRING_SERVICE_TEAM_NAME = 'Test Team';

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
        cs.Has_Additional_Product__c = true;
        insert cs;
        
    }

    
    /**
    *  DCP-45746
    *  @author : Adyasha
    *  @description - test method to verify Creation of CS Review Activity for System Health Check Labor Line
    **/
    static testMethod void testWOCompletionWithCSReviewActivityForSystemHealthCheckLabor() {
        
        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        setting.Bypass_All_Validations__c = true;
        upsert setting;
        
        Account acc = [SELECT id FROM Account WHERE Account_Group__c = 'Distributor' LIMIT 1];
      
        Case objCase = [SELECT id, Has_Resolution_Code__c FROM Case WHERE RecordType.Name = 'Service Request' LIMIT 1];
        objCase.Has_Resolution_Code__c = true;
        update objCase;

        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(Label.WorkOrderRecordTypeServiceSupport, objCase.Id, 'Assigned');
        workOrder.SVMXC__Company__c = acc.id;
        workOrder.SVMXC__Order_Type__c = Label.WorkOrderTypeProfessionalServices;
        workOrder.Is_Auto_Created__c=true;
        workOrder.SVMXC__Billing_Type__c = 'Billable';
        
        insert workOrder; 

        List<SVMXC__Service_Order_Line__c> lstWorkDetails = new List<SVMXC__Service_Order_Line__c>();
        SVMXC__Service_Order_Line__c objOrderDetail = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,TestWorkDetails.STRING_USAGE_CONSUMPTION);
        objOrderDetail.SVMXC__Line_Type__c = 'Labor';
        objOrderDetail.SVMXC__Activity_Type__c ='System Health Check';
        objOrderDetail.SVMXC__Is_Billable__c = true;
        lstWorkDetails.add(objOrderDetail);     
        

        Test.startTest();  
        insert lstWorkDetails;
        WorkOrders.hasDMLonafterupdateran = true;
        workOrder.SVMXC__Order_Status__c = 'Completed';
        workOrder.No_Calibrated_Tools_Used__c = true;
        workOrder.Is_Service_Report_Generated__c =true;
        workOrder.Evaluation__c ='test';
        workOrder.SVMXC__Work_Performed__c ='test';
        workOrder.Verification_Result__c ='test';
        workOrder.Has_Verification_Code__c =true;
        workOrder.PO_Number__c ='127845';
        workOrder.Signature_Type__c='Manual Sign';
        workOrder.Manual_Sign_Captured__c=true;
        workOrder.Is_Customer_Sign_Captured__c=true;
        workOrder.Cost_Center__c=6776;
        
        update workOrder;
        Test.stopTest();

        List<SVMXC__Service_Order_Line__c> lstWDs=[select id, SVMXC__Service_Order__c from SVMXC__Service_Order_Line__c where SVMXC__Activity_Type__c = 'Customer Service Review' AND SVMXC__Service_Order__c =: workOrder.id];
        System.assert(lstWDs.isEmpty(), 'CS Review Activity Not Created');
  
    }

    /**
    *  DCP-45746
    *  @author : Adyasha
    *  @description - test method to verify Creation of CS Review Activity for Installation WO
    **/
    static testMethod void testWOCompletionWithCSReviewActivityForBillableWO() {
        Account acc = [SELECT id FROM Account WHERE Account_Group__c = 'Distributor' LIMIT 1];
        Case objCase = [SELECT id FROM Case WHERE RecordType.Name = 'Service Request' LIMIT 1];
        objCase.Has_Resolution_Code__c = true;
        update objCase;
        
        List<SVMXC__Service_Order__c> lstWorkOrder = new List<SVMXC__Service_Order__c>();
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(Label.WorkOrderRecordTypeFieldService, objCase.Id, 'Initiated');
        workOrder.SVMXC__Company__c = acc.id;
        workOrder.SVMXC__Order_Type__c = 'Installation';
        workOrder.Is_Auto_Created__c=true;
        lstWorkOrder.add(workOrder);

        SVMXC__Service_Order__c workOrder1 = TestDataFieldService.createWorkOrder(Label.WorkOrderRecordTypeFieldService, objCase.Id, 'Initiated');
        workOrder1.SVMXC__Company__c = acc.id;
        workOrder1.SVMXC__Order_Type__c = 'Service Activities';
        workOrder1.SVMXC__Billing_Type__c = 'Billable';
        workOrder1.Is_Auto_Created__c = true;
        lstWorkOrder.add(workOrder1);
        
        insert lstWorkOrder;
        Test.startTest();
        try {

            SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
            objOrderDetail.SVMXC__Service_Order__c = workOrder.id;
            objOrderDetail.SVMXC__Activity_Type__c ='Training';
            insert objOrderDetail;
            WorkOrders.hasDMLonafterupdateran = false;
            lstWorkOrder[0].SVMXC__Order_Status__c = 'Completed';
            lstWorkOrder[0].No_Calibrated_Tools_Used__c = true;
            lstWorkOrder[0].Is_Service_Report_Generated__c =true;
            lstWorkOrder[0].Evaluation__c ='test';
            lstWorkOrder[0].SVMXC__Work_Performed__c ='test';
            lstWorkOrder[0].Verification_Result__c ='test';
            lstWorkOrder[0].Has_Verification_Code__c =true;
            lstWorkOrder[0].PO_Number__c ='127845';
            lstWorkOrder[0].Signature_Type__c='Manual Sign';
            lstWorkOrder[0].Manual_Sign_Captured__c=true;
            lstWorkOrder[0].Is_Customer_Sign_Captured__c=true;
            lstWorkOrder[0].Cost_Center__c=6776;

            lstWorkOrder[1].SVMXC__Order_Status__c = 'Completed';
            lstWorkOrder[1].No_Calibrated_Tools_Used__c = true;
            lstWorkOrder[1].Is_Service_Report_Generated__c =true;
            lstWorkOrder[1].Evaluation__c ='test';
            lstWorkOrder[1].SVMXC__Work_Performed__c ='test';
            lstWorkOrder[1].Verification_Result__c ='test';
            lstWorkOrder[1].Has_Verification_Code__c =true;
            lstWorkOrder[1].PO_Number__c ='127845';
            lstWorkOrder[1].Signature_Type__c='Manual Sign';
            lstWorkOrder[1].Manual_Sign_Captured__c=true;
            lstWorkOrder[1].Is_Customer_Sign_Captured__c=true;
            lstWorkOrder[1].Cost_Center__c=67776;
            lstWorkOrder[1].Abandoned_Reason__c = 'No Customer Response';
            lstWorkOrder[1].SVMX_PS_Subject__c = 'ABANDONED - Workorder';
            
            update lstWorkOrder;

            Test.stopTest();
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Work Order cannot be edited when status is Completed/Closed'), 'Exception not thrown');
        }

        List<SVMXC__Service_Order_Line__c> lstWD1s=[select id, SVMXC__Service_Order__c from SVMXC__Service_Order_Line__c where SVMXC__Activity_Type__c = 'Customer Service Review'];
        System.debug('@@@@ in TestWorkOrders, lstWD1s: '+lstWD1s);
        //Assert.isTrue(!lstWD1s.isEmpty(),'CS Review Activity Not Created');
  
    }
}