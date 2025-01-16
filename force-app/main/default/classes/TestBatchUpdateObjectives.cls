/**
*    @author: Nishan Shetty
*    @date:   08-Dec-2021
*    @description:  Test class for BatchUpdateObjectives.cls
*    Modification Log:
*    -----------------------------------------------------------------------------------
*             Developer                      Date                Description
*          Nishan Shetty                   08-Dec-2021           Initial
*    ------------------------------------------------------------------------------------ 
*                    
*/
@isTest
public with sharing class TestBatchUpdateObjectives {
    /*
    *@author: Nishan Shetty
    *@Desc :  Test Setup Method.
    */
    @testSetup 
    static void setupData() {
        //Account
         Account acc = TestDataAccount.initAccount();
         acc.ERP_Customer_Id__c = '45678';
         acc.Territory_Region__c = 'AMR';
         insert acc;
 
        //Territory
         Territory2 objTr = TestTerritoryPlanStrategyController.getTerritory();
 
        //Associating Account To Territory
         TestDataObjectTerritory2Association.getObjectAssociationFuture(objTr.id,acc.id);
 
        //Creating Plan
        Plan__c objPlan1 = TestDataPlan.getPlan(objTr.id);
        objPlan1.Name='TestPlan1';
        objPlan1.Territory_Name__c = objTr.Name;
        objPlan1.Territory_Code__c = objTr.Territory_Code__c;
        insert objPlan1;
         
        objPlan1.Status__c='Closed';
        update objPlan1;
        

        //Creating Plan Strategy
        Plan_Strategy__c objPlanStrategy1 = TestDataPlanStrategy.getPlanStrategy(objPlan1.id);
        insert objPlanStrategy1;

        //Creating Plan Objectives
        Plan_Objective__c objPlanObjective1 = TestDataPlanObjective.getPlanObjective(objPlanStrategy1.id);
        objPlanObjective1.Name='PlanObjective1';
        objPlanObjective1.Closed_Status__c='Objective Met';
        insert objPlanObjective1;

        //Creating Account Plan
        Account_Plan__c ap1 = TestDataAccountPlan.initAccoutPlan(acc.id);
        ap1.Name='TestAccountPlan1';
        ap1.Plan_Status__c='Draft';
        insert ap1;

        ap1.Plan_Status__c='Closed';
        update ap1;

        //Creating Account Plan Objectives
        Objective__c objOb1 = TestDataObjectives.initObjective(ap1.Id);
        objOb1.Name='AccountPlanObjective1';
        objOb1.Closed_Status__c='Objective Met';
        insert objOb1;

    }


    /*
    *  @AUTHOR: Nishan Shetty
    *  @DESCRIPTION: Method to test Plan Objectives update.
    */
    @isTest
    static void testPlanObjectivesUpdate() {
        Plan_Objective__c objPlanObjective1=[Select Id,Name,Objective_Status__c from Plan_Objective__c where Name='PlanObjective1' Limit 1];
        test.startTest();
        objPlanObjective1.Objective_Status__c='In Progress';
        update objPlanObjective1;
        BatchUpdateObjectives batchPlanObjectiveUpdate=new BatchUpdateObjectives('Plan');
        Database.executeBatch(batchPlanObjectiveUpdate);
        test.stopTest();
        Plan_Objective__c objPlanObjective12=[Select Id,Name,Objective_Status__c from Plan_Objective__c where Name='PlanObjective1' Limit 1];
        System.assertEquals('Closed',objPlanObjective12.Objective_Status__c,'Plan Objective Status Not Set');
    }


    /*
    *  @AUTHOR: Nishan Shetty
    *  @DESCRIPTION: Method to test Account Plan Objectives update.
    */
    @isTest
    static void testAccountPlanObjectivesUpdate() {
        Objective__c objAcctPlanObjective1=[Select Id,Name,Objective_Status__c from Objective__c where Name='AccountPlanObjective1' Limit 1];
        objAcctPlanObjective1.Objective_Status__c='In Progress';
        update objAcctPlanObjective1;
        test.startTest();
        BatchUpdateObjectives batchAcctPlanObjectiveUpdate=new BatchUpdateObjectives('AccountPlan');
        Database.executeBatch(batchAcctPlanObjectiveUpdate);
        test.stopTest();
        Objective__c objAcctPlanObjective12=[Select Id,Name,Objective_Status__c from Objective__c where Name='AccountPlanObjective1' Limit 1];
        System.assertEquals('Closed',objAcctPlanObjective12.Objective_Status__c,'AccountPlan Objective Status Not Set');
    }
}
