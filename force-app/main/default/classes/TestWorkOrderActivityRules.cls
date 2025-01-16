/**
*    @author: Karthik Rayani
*    @date:   11-Nov-2020
*    @description:  Test Class for WorkOrderActivityRules
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Karthik Rayani              11-Nov-2020           Initial Build
*             Raja Siva Krishna           26-Nov-2020           DCP-43185-add method testWorkOrderActivityRuleByCondition             
*    ------------------------------------------------------------------------------------ 
*                    
*/
@isTest(SeeAllData = false)
public class TestWorkOrderActivityRules {

    @testSetup
    static void initializeTestData() 
    {
        Work_Order_Activity_Rules__c objWoActivityRule = new Work_Order_Activity_Rules__c();
        objWoActivityRule.Document_Name__c = 'TestClass1234';
        objWoActivityRule.Document_Number__c = '123456';
        objWoActivityRule.Name = 'TestClass1234';
        objWoActivityRule.Activity_Type__c = 'Calibration';
        objWoActivityRule.Product_Group__c = 'AmpliSeq Library Prep';
        objWoActivityRule.Generic_Document__c = true;
        objWoActivityRule.Required__c = false;
        insert objWoActivityRule;
        //Approving the Record
        Set<Id> pIds = (new Map<Id, ProcessInstance>([SELECT Id,Status,TargetObjectId FROM ProcessInstance where Status='Pending' and TargetObjectId = :objWoActivityRule.Id])).keySet();
        Set<Id> pInstanceWorkitems = (new Map<Id, ProcessInstanceWorkitem>([SELECT Id,ProcessInstanceId FROM ProcessInstanceWorkitem WHERE ProcessInstanceId in :pIds])).keySet();
        //List<Approval.ProcessWorkitemRequest> allReq = new List<Approval.ProcessWorkitemRequest>(); 
        for (Id pInstanceWorkitemsId:pInstanceWorkitems){
            Approval.ProcessWorkitemRequest req2 =  new Approval.ProcessWorkitemRequest();
            req2.setComments('Approving request.');
            req2.setAction('Approve');
            req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
            req2.setWorkitemId(pInstanceWorkitemsId);
            Approval.ProcessResult result = Approval.process(req2);
            system.debug(result);
        }
    }

    static testMethod void workOrderActivityRuleTest() 
    {
        User testUser = TestDataUser.findUserInProfile('System Administrator');
        System.runAs(testUser){
            Work_Order_Activity_Rules__c objWOActivity=[select id,name,Product_Group__c,Old_Field_Values__c from Work_Order_Activity_Rules__c where Name='TestClass1234'];
            System.assertequals('NA', objWOActivity.Old_Field_Values__c,'Template Fields Not Updated');
            objWOActivity.Product_Group__c = 'AmpliSeq Library Prep';
            objWOActivity.Document_Name__c = 'NewTestClass1234';
            objWOActivity.Document_Number__c = '12345678';
            objWOActivity.Name = 'NewTestClass1234';
            objWOActivity.Activity_Type__c = 'Calibration';
            objWOActivity.Generic_Document__c = false;
            objWOActivity.Required__c = true;
          /*  update objWOActivity;
            Work_Order_Activity_Rules__c objWOActivityNew=[select id,name,Product_Group__c,Old_Field_Values__c from Work_Order_Activity_Rules__c where Name='NewTestClass1234'];
            System.assertNotEquals('',objWOActivityNew.Old_Field_Values__c);    */
        }
    }

    /* @author Raja Siva Krishna
    *  @description get work order activity rule selector based on conditions
    */
    @IsTest
    public static void testWorkOrderActivityRuleByCondition(){
        Test.startTest();
        Work_Order_Activity_Rules__c workActivityRec=[select id from Work_Order_Activity_Rules__c where Name='TestClass1234'];
            Work_Order_Activity_Rules__c workActivityRuleRec =  WorkOrderActivityRulesSelector.getWorkOrderActivityRuleById(workActivityRec.Id);
            System.assertequals('TestClass1234',workActivityRuleRec.Document_Name__c,'Document name is not matching');
        try{ 
            WorkOrderActivityRulesSelector.getWorkOrderActivityRuleById(null);
        }
        catch(Exception e){
            system.assert(e.getMessage().contains('Script-thrown exception'),'Error in Script');
        }
        List<String> lstActivities = new List<String>();
        lstActivities.add('Installation');
        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        insert objProduct;
        new WorkOrderActivityRulesSelector().getWorkOrderActivityRuleByConditions(lstActivities,objProduct.Id,'AmpliSeq Library Prep');
        new WorkOrderActivityRulesSelector().getWorkOrderActivityRuleByAcitivity(new Set<String>(lstActivities));
        new WorkOrderActivityRulesSelector().getActiveWorkOrderActivityRules();
        Test.stopTest();
    }
}