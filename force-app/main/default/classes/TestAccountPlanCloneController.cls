/**
 *    @author Bharath Varma
 *    @date   07-Sep-2021
 *    @description : Test class for Account Plan Clone Controller
 *    Modification Log:
 *   ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 *       Developer                        Date               Description
 *     Bharath Varma                   07-Sep-2021          Initial Version
 *     Adyasha Satapathy               30-Aug-2022          DCP-54419: Added Coverage for cloning of related Opportunities while cloning Account plan
 *    ------------------------------------------------------------------------------------------------------------------------------------
 */

@isTest
public with sharing class TestAccountPlanCloneController {

    @testSetup 
    static void setupData(){
        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = '123456';
        acc.Territory_Region__c = 'AMR';    
        Account acc2 = TestDataAccount.initAccount();
        List<Account> lstAcc = new List<Account>();
        lstAcc.add(acc);
        lstAcc.add(acc2);
        insert lstAcc;

        Contact c= TestDataContact.getNewContact(acc);

        Account_Plan__c ap = TestDataAccountPlan.getNewAccountPlan(lstAcc[0]);
        ap.Name = 'Test Account Plan';
        update ap;
        Objective__c objOb1 = TestDataObjectives.getNewObjective(ap);
        List<Key_Stakeholder_Analysis__c> lstStakeholder = new List<Key_Stakeholder_Analysis__c>();   
        Key_Stakeholder_Analysis__c stakeholder = TestDataStakeholder.getNewStakehoder(lstAcc[0], ap, c);
        lstStakeholder.add(stakeholder);
        update lstStakeholder;

        List<Task> lstTsk = new List<Task>();
        Task objtsk = new Task();
        objtsk.WhatId = objOb1.id;
        lstTsk.add(objtsk);

        insert lstTsk;
        ContentNote contentNote = new ContentNote();
        contentNote.Title = 'Test Note';
        insert contentNote;
        ContentDocumentLink objCDL = TestDataFieldService.createDocLink(contentNote.Id, ap.Id,'V','AllUsers');
        insert objCDL;

        //Start of DCP-54419
        Opportunity opp1 = TestDataOpportunity.initOpportunity(acc);
        opp1.Name = TestPlanAssociatedOppsController.OPPORTUNITY_NAME;
        insert opp1;

        Objective_Opportunity_Relationship__c oor1 = new Objective_Opportunity_Relationship__c(Opportunity__c = opp1.Id, Account_Plan_Objective__c = objOb1.Id,Account_Plan__c = ap.Id);
        insert oor1;
        //End of DCP-54419

    }

    @isTest
    static void testAccountPlanClone() {
        Account_Plan__c accountPlan = [SELECT Id, Gap_Analysis__c from Account_Plan__c WHERE Name = 'Test Account Plan' LIMIT 1];
        accountPlan.Gap_Analysis__c = 'Test Gap Plan';
        update accountPlan;
        String strAccountPlanCloneId = '';
        Test.startTest();
        Map<String, String> mapClonePlanDetails = new Map<String, String>{'Name'=>'test','Plan_Target__c'=>'1000','Start_Date__c'=>'2021-06-07','End_Date__c'=>'2021-10-22'};
        String strClonePlanDetails = JSON.serialize(mapClonePlanDetails);
        String strLstObjectivesActions = AccountPlanCloneController.getObjectivesAndActions(accountPlan.Id, 'Account_Plan__c');
        Map<String, String> planDetails = new Map<String, String>{'strLstObjectivesActions'=>strLstObjectivesActions, 'strRecordId'=>accountPlan.Id,'objectApiName'=>'Account_Plan__c', 'strClonePlanDetails'=>strClonePlanDetails};
        strAccountPlanCloneId = AccountPlanCloneController.cloneAccountPlan(JSON.serialize(planDetails));
        Test.stopTest();

        System.assert(strAccountPlanCloneId != '', 'New Account plan is not cloned');
        List<Objective__c> lstObjective = [Select Id from Objective__c where Account_Plan__c = :strAccountPlanCloneId];
        List<Objective_Opportunity_Relationship__c> lstClonedOOR = [Select Id from Objective_Opportunity_Relationship__c where Account_Plan_Objective__c = :lstObjective[0].id];
        System.assertEquals(1,lstClonedOOR.size(),'Associated opportunities are not Cloned');
    }

}