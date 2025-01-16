/***************************************************************************************************************************************
 * NAME   : TestWorkOrderActivityRulesSelector
 * DESCRIPTION  : TestClass for WorkOrderActivityRulesSelector class.
 *    
 * @AUTHOR : Prashanth
 * @DATE   : 29-Aug-2021  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Prashanth             29-Aug-2021             Initial Version
  ***************************************************************************************************************************************
  */ 
  @isTest(seeAllData = false)
  public with sharing class TestWorkOrderActivityRulesSelector {
      static final String PRODUCT_GROUP_AMPLISEQ = 'AmpliSeq Library Prep';
      static final String ACTIVITY_TYPE = 'Installation';
      
      /**
        *  @author Prashanth
        *  @description - test the WorkOrderactivityrulesseclector class 
      **/
      @IsTest
      static void  workOrderActivityRulesTest(){
          Product2 objProduct1=TestDataFieldService.createProduct('Test Product','Instrument');
          objProduct1.product_Group__c=PRODUCT_GROUP_AMPLISEQ;
          insert objProduct1;
          System.assert(objProduct1.Id != null, 'Product creation Failed');
  
          Work_Order_Activity_Rules__c objWoActivityRule = new Work_Order_Activity_Rules__c();
          objWoActivityRule.Document_Name__c = 'TestLWC1';
          objWoActivityRule.Document_Number__c = '123456';
          objWoActivityRule.Name = 'TestClass1234';
          objWoActivityRule.Activity_Type__c = ACTIVITY_TYPE;
          objWoActivityRule.Product_Code__c = objProduct1.Id;
          objWoActivityRule.Product_Group__c = PRODUCT_GROUP_AMPLISEQ;
          objWoActivityRule.Generic_Document__c = true;
          objWoActivityRule.Required__c = true;
          objWoActivityRule.Active__c = true;
          insert objWoActivityRule;
          Set<Id> pIds = new Map<Id, ProcessInstance>([SELECT Id,Status,TargetObjectId FROM ProcessInstance where Status='Pending' and TargetObjectId = :objWoActivityRule.Id]).keySet();
          Set<Id> pInstanceWorkitems = new Map<Id, ProcessInstanceWorkitem>([SELECT Id,ProcessInstanceId FROM ProcessInstanceWorkitem WHERE ProcessInstanceId in :pIds limit 1]).keySet();
          for (Id pInstanceWorkitemsId:pInstanceWorkitems){
              Approval.ProcessWorkitemRequest req2 =  new Approval.ProcessWorkitemRequest();
              req2.setComments('Approving request.');
              req2.setAction('Approve');
              req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
              req2.setWorkitemId(pInstanceWorkitemsId);
              Approval.process(req2);
          }
          Test.startTest();
          WorkOrderActivityRulesSelector selector = new WorkOrderActivityRulesSelector();
          System.assertEquals(objWoActivityRule.Id, WorkOrderActivityRulesSelector.getWorkOrderActivityRuleById(objWoActivityRule.Id).Id, 'WorkOrder Activity rule not matching');
          System.assertEquals(1, selector.getWorkOrderActivityRuleByConditions(new List<String>{ACTIVITY_TYPE}, objProduct1.Id, PRODUCT_GROUP_AMPLISEQ).size(), 'Assertion Failed');
          System.assertEquals(1, selector.getWorkOrderActivityRuleByAcitivity(new Set<String>{ACTIVITY_TYPE}).size(), 'Assertion Failed');
          System.assertEquals(1, selector.getActiveWorkOrderActivityRules().size(), 'Assertion Failed');
          Test.stopTest();
          
      }
  }