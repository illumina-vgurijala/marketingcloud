/**
 *    @author Nishan Shetty
 *    @date   08-12-2021
 *    @description  Test class for CloseRelatedObjectives
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------------------
 *     Developer                      Date                Description
 *   Nishan Shetty				    08-12-2021		       Initial
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
 */
@isTest
public with sharing class TestCloseRelatedObjectives {

    /*
    *@author: Nishan Shetty
    *@Desc: Test Setup method 
    */
    @testSetup 
    static void setupData() {
       
        //Account
        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = '45678';
        acc.Territory_Region__c = 'AMR';
        insert acc;

        //Contact
        Contact con= TestDataContact.getNewContact(acc);

        //Territory
        Territory2 objTr = TestTerritoryPlanStrategyController.getTerritory();

        //Associating Account To Territory
        TestDataObjectTerritory2Association.getObjectAssociationFuture(objTr.id,acc.id);

        //Creating Plan
        List<Plan__c> lstPlan=new List<Plan__c>();
        Plan__c objPlan1 = TestDataPlan.getPlan(objTr.id);
        objPlan1.Name='TestPlan1';
        objPlan1.Territory_Name__c = objTr.Name;
        objPlan1.Territory_Code__c = objTr.Territory_Code__c;
        Plan__c objPlan2 = TestDataPlan.getPlan(objTr.id);
        objPlan2.Name='TestPlan2';
        objPlan2.Territory_Name__c = objTr.Name;
        objPlan2.Territory_Code__c = objTr.Territory_Code__c;
        Plan__c objPlan3 = TestDataPlan.getPlan(objTr.id);
        objPlan3.Name='TestPlan11';
        objPlan3.Territory_Name__c = objTr.Name;
        objPlan3.Territory_Code__c = objTr.Territory_Code__c;
        Plan__c objPlan4 = TestDataPlan.getPlan(objTr.id);
        objPlan4.Name='TestPlan21';
        objPlan4.Territory_Name__c = objTr.Name;
        objPlan4.Territory_Code__c = objTr.Territory_Code__c;
        lstPlan.add(objPlan1);
        lstPlan.add(objPlan2);
        lstPlan.add(objPlan3);
        lstPlan.add(objPlan4);
        insert lstPlan;

        //Creating Plan Strategy
        Plan_Strategy__c objPlanStrategy1 = TestDataPlanStrategy.getPlanStrategy(lstPlan[0].id);
        insert objPlanStrategy1;
        Plan_Strategy__c objPlanStrategy2 = TestDataPlanStrategy.getPlanStrategy(lstPlan[1].id);
        insert objPlanStrategy2;
        Plan_Strategy__c objPlanStrategy3 = TestDataPlanStrategy.getPlanStrategy(lstPlan[2].id);
        insert objPlanStrategy3;
        Plan_Strategy__c objPlanStrategy4 = TestDataPlanStrategy.getPlanStrategy(lstPlan[3].id);
        insert objPlanStrategy4;

        //Creating Plan Objectives
        Plan_Objective__c objPlanObjective1 = TestDataPlanObjective.getPlanObjective(objPlanStrategy1.id);
        objPlanObjective1.Name='PlanObjective1';
        objPlanObjective1.Closed_Status__c='Objective Met';
        insert objPlanObjective1;

        Plan_Objective__c objPlanObjective2 = TestDataPlanObjective.getPlanObjective(objPlanStrategy2.id);
        objPlanObjective2.Name='PlanObjective2';
        insert objPlanObjective2;

        Plan_Objective__c objPlanObjective3 = TestDataPlanObjective.getPlanObjective(objPlanStrategy3.id);
        objPlanObjective3.Name='PlanObjective11';
        objPlanObjective3.Closed_Status__c='Objective Met';
        insert objPlanObjective3;

        Plan_Objective__c objPlanObjective4 = TestDataPlanObjective.getPlanObjective(objPlanStrategy4.id);
        objPlanObjective4.Name='PlanObjective21';
        objPlanObjective4.Closed_Status__c='Objective Met';
        insert objPlanObjective4;

         //Creating Plan Objectives Task
         Task objPlanObjTask1=new Task();
         objPlanObjTask1.WhatId=objPlanObjective3.id;
         objPlanObjTask1.WhoId=con.Id;
         objPlanObjTask1.Subject='Call';
         objPlanObjTask1.RecordTypeId=Schema.SObjectType.Task.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
         objPlanObjTask1.Call_Result__c='Busy';
         insert objPlanObjTask1;
 
         Task objPlanObjTask2=new Task();
         objPlanObjTask2.WhatId=objPlanObjective4.id;
         objPlanObjTask2.Subject='Call';
         objPlanObjTask2.RecordTypeId=Schema.SObjectType.Task.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
         objPlanObjTask2.Call_Result__c='Busy';
         insert objPlanObjTask2;

        //Creating Account Plan
        Account_Plan__c ap1 = TestDataAccountPlan.initAccoutPlan(acc.id);
        ap1.Name='TestAccountPlan1';
        insert ap1;

        Account_Plan__c ap2 = TestDataAccountPlan.initAccoutPlan(acc.id);
        ap2.Name='TestAccountPlan2';
        insert ap2;

        Account_Plan__c ap3 = TestDataAccountPlan.initAccoutPlan(acc.id);
        ap3.Name='TestAccountPlan11';
        insert ap3;

        Account_Plan__c ap4 = TestDataAccountPlan.initAccoutPlan(acc.id);
        ap4.Name='TestAccountPlan21';
        insert ap4;

        //Creating Account Plan Objectives
        Objective__c objOb1 = TestDataObjectives.initObjective(ap1.Id);
        objOb1.Name='AccountPlanObjective1';
        objOb1.Closed_Status__c='Objective Met';
        insert objOb1;

        Objective__c objOb2 = TestDataObjectives.initObjective(ap2.Id);
        objOb2.Name='AccountPlanObjective2';
        insert objOb2;

        Objective__c objOb3 = TestDataObjectives.initObjective(ap3.Id);
        objOb3.Name='AccountPlanObjective11';
        objOb3.Closed_Status__c='Objective Met';
        insert objOb3;

        Objective__c objOb4 = TestDataObjectives.initObjective(ap4.Id);
        objOb4.Name='AccountPlanObjective21';
        objOb4.Closed_Status__c='Objective Met';
        insert objOb4;

        //Creating Account Plan Objectives Task
        Task objAcctPlanObjTask1=new Task();
        objAcctPlanObjTask1.WhatId=objOb3.id;
        objAcctPlanObjTask1.WhoId=con.Id;
        objAcctPlanObjTask1.Subject='Call';
        objAcctPlanObjTask1.RecordTypeId=Schema.SObjectType.Task.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
        objAcctPlanObjTask1.Call_Result__c='Busy';
        insert objAcctPlanObjTask1;

        Task objAcctPlanObjTask2=new Task();
        objAcctPlanObjTask2.WhatId=objOb4.id;
        objAcctPlanObjTask2.Subject='Call';
        objAcctPlanObjTask2.RecordTypeId=Schema.SObjectType.Task.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
        objAcctPlanObjTask2.Call_Result__c='Busy';
        insert objAcctPlanObjTask2;
    }


   /*
    *  @AUTHOR: Nishan Shetty
    *  @DESCRIPTION: Method to test Plan Objective Closure when Plan is closed.
    */
    @isTest
    static void testPlanObjectiveClosureWithoutError() {
        Plan__c objPlan1=[Select Id,Name,Status__c from Plan__c where Name='TestPlan1' Limit 1];
        test.startTest();
        objPlan1.Status__c='Closed';
        update objPlan1;
        test.stopTest();
        List<Plan_Objective__c> objPlanObjective1=[Select Id,Name,Objective_Status__c from Plan_Objective__c where Name='PlanObjective1'];
        System.assertEquals('Closed',objPlanObjective1[0].Objective_Status__c,'Plan Objective Status Not Set');
    }
    
    
    /*
    *  @AUTHOR: Nishan Shetty
    *  @DESCRIPTION: Method to test Plan Closure throws validation error when Plan Objective Closed Status is blank.
    */
    @isTest
    static void testPlanObjectiveClosureWithError() {
        Plan__c objPlan2=[Select Id,Name,Status__c from Plan__c where Name='TestPlan2' Limit 1];
        String strPlanException;
        test.startTest();
        try {
            objPlan2.Status__c='Closed';
            update objPlan2;
        } catch (Exception e) {
            strPlanException=e.getMessage();
        }
        test.stopTest();
        System.assert(strPlanException.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'),'Plan Exception Not Raised');
    }

    /*
    *  @AUTHOR: Nishan Shetty
    *  @DESCRIPTION: Method to test Account Plan Objective Closure when Account Plan is closed.
    */
    @isTest
    static void testAccountPlanObjectiveClosureWithoutError() {
        Account_Plan__c objAcctPlan1=[Select Id,Name,Plan_Status__c from Account_Plan__c where Name='TestAccountPlan1' Limit 1];
        test.startTest();
        objAcctPlan1.Plan_Status__c='Closed';
        update objAcctPlan1;
        test.stopTest();
        List<Objective__c> objAcctPlanObjective1=[Select Id,Name,Objective_Status__c from Objective__c where Name='AccountPlanObjective1' LIMIT 1];
        System.assertEquals('Closed',objAcctPlanObjective1[0].Objective_Status__c,'Account Plan Objective Status Not Set');
    }


    /*
    *  @AUTHOR: Nishan Shetty
    *  @DESCRIPTION: Method to test Account Plan  Closure throws validation error when Account Plan Objective Closed Status is blank.
    */
    @isTest
    static void testAccountPlanObjectiveClosureWithError() {
        Account_Plan__c objAcctPlan2=[Select Id,Name,Plan_Status__c from Account_Plan__c where Name='TestAccountPlan2' Limit 1];
        String strAccountPlanException;
        test.startTest();
        try {
            objAcctPlan2.Plan_Status__c='Closed';
            update objAcctPlan2;
        } catch(Exception e) {
            strAccountPlanException=e.getMessage();
        }
       
        test.stopTest();
        System.assert(strAccountPlanException.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'),'AccountPlan Exception Not Raised');
    }


    /*
    *  @AUTHOR: Nishan Shetty
    *  @DESCRIPTION: Method to test Plan Closure will complete related actions.
    */
    @isTest
    static void testPlanActionWithoutError() {
        Plan__c objPlan1=[Select Id,Name,Status__c from Plan__c where Name='TestPlan11' Limit 1];
        Plan_Objective__c objPlanObjective=[Select Id,Name from Plan_Objective__c where Name='PlanObjective11' Limit 1];
        test.startTest();
        objPlan1.Status__c='Closed';
        update objPlan1;
        test.stopTest();
        List<Task> objTask1=[Select Id,Subject,Status,WhatId from Task where WhatId=:objPlanObjective.Id];
        System.assertEquals('Completed',objTask1[0].Status,'Task Status Not Set');
    }


    /*
    *  @AUTHOR: Nishan Shetty
    *  @DESCRIPTION: Method to test Plan Closure throws validation error when Task is Completed.
    */
    @isTest
    static void testPlanActionWithError() {
        Plan__c objPlan2=[Select Id,Name,Status__c from Plan__c where Name='TestPlan21' Limit 1];
        String strPlanException;
        test.startTest();
        try {
            objPlan2.Status__c='Closed';
            update objPlan2;
        } catch (Exception e) {
            strPlanException=e.getMessage();
        }
        test.stopTest();
        System.assert(strPlanException.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'),'Task Exception Not Raised');
    }


    /*
    *  @AUTHOR: Nishan Shetty
    *  @DESCRIPTION: Method to test Account Plan Objective Closure when Account Plan is closed.
    */
    @isTest
    static void testAccountPlanActionWithoutError() {
        Account_Plan__c objAcctPlan1=[Select Id,Name,Plan_Status__c from Account_Plan__c where Name='TestAccountPlan11' Limit 1];
        Objective__c objAcctPlanObjective=[Select Id,Name from Objective__c where Name='AccountPlanObjective11'];
        test.startTest();
        objAcctPlan1.Plan_Status__c='Closed';
        update objAcctPlan1;
        test.stopTest();
        List<Task> objTask1=[Select Id,Subject,Status,WhatId from Task where WhatId=:objAcctPlanObjective.Id];
        System.assertEquals('Completed',objTask1[0].Status,'Plan Task Status Not Set');
    }

    /*
    *  @AUTHOR: Nishan Shetty
    *  @DESCRIPTION: Method to test Account Plan  Closure throws validation error when Task is completed.
    */
    @isTest
    static void testAccountPlanActionClosureWithError() {
        Account_Plan__c objAcctPlan2=[Select Id,Name,Plan_Status__c from Account_Plan__c where Name='TestAccountPlan21' Limit 1];
        String strAccountPlanException;
        test.startTest();
        try {
            objAcctPlan2.Plan_Status__c='Closed';
            update objAcctPlan2;
        } catch(Exception e) {
            strAccountPlanException=e.getMessage();
        }
       
        test.stopTest();
        System.assert(strAccountPlanException.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'),'AccountPlan Task Status is not Set');
    }
   
}
