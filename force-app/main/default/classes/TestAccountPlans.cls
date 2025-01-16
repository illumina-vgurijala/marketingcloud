/**
*    @author: Kushagra Desai
*    @date:   05-Sept-2019
*    @description:  Test class for  NewAccountPLan Controller
*    Modification Log:
*    -----------------------------------------------------------------------------------
*             Developer                      Date                Description
*    ------------------------------------------------------------------------------------ 
*                    
*/
@isTest
public with sharing class TestAccountPlans {
    /**
     *  @author Bharath Varma
     *  @description  
     **/
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
        Territory2 objTr = TestTerritoryPlanStrategyController.getTerritory();
        TestDataObjectTerritory2Association.getObjectAssociationFuture(objTr.id,lstAcc[0].id);
        Plan__c objPlan = TestDataPlan.getPlan(objTr.id);
        objPlan.Name = 'Test Plan 1';
        objPlan.Territory_Name__c = objTr.Name;
        objPlan.Territory_Code__c = objTr.Territory_Code__c;
        insert objPlan;
        Plan_Strategy__c objPlanStrategy = TestDataPlanStrategy.getPlanStrategy(objPlan.id);
        insert objPlanStrategy;
        Plan_Objective__c objPlanObjective = TestDataPlanObjective.getPlanObjective(objPlanStrategy.id);
        insert objPlanObjective;
        Plan_Objective_Account__c objAPO = new Plan_Objective_Account__c(Account__c = lstAcc[0].id,Plan_Objective__c = objPlanObjective.id);
        insert objAPO;

        Account_Plan__c ap = TestDataAccountPlan.getNewAccountPlan(lstAcc[0]);
        // Account_Plan__c ap1 = TestDataAccountPlan.getNewAccountPlan(lstAcc[1]);
        ap.Name = 'Test Account Plan';
        update ap;
        Objective__c objOb1 = TestDataObjectives.getNewObjective(ap);
        // Objective__c objOb2 = TestDataObjectives.getNewObjective(ap);
        // Objective__c objOb3 = TestDataObjectives.getNewObjective(ap);

        List<Task> lstTsk = new List<Task>();
        Task objtsk = new Task();
        objtsk.WhatId = objOb1.id;
        lstTsk.add(objtsk);

        Task objtsk2 = new Task();
        objtsk2.WhatId = objPlanObjective.id;
        lstTsk.add(objtsk2);
        insert lstTsk;
    }

    /**
     *  @author Kushagra Desai
     *  @description  
     **/
    @isTest
    static void testAccountPlanDelete(){
        String strErrorMessage;
        Account acc = TestDataAccount.getAccount('TestAccount');
        insert acc;
        Account_Plan__c accPlan = TestDataAccountPlan.getNewAccountPlan(acc);
        accPlan.Plan_Status__c = 'Active';
        update accPlan;
        Test.StartTest();
        try {
            delete accPlan;
        } catch(Exception e) {
            System.debug('@@@'+e.getMessage());
            strErrorMessage = e.getMessage();
        }
        Test.stopTest();
        System.assert(strErrorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') && strErrorMessage.contains(Label.UI_AccountPlan_Restrict_Delete));
    
    }

}