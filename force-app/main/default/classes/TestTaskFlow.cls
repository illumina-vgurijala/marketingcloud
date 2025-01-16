/**
*    @author: Kushagra Desai
*    @date:   16-Sept-2019
*    @description:  Test class for  Tasks Controller
*    Modification Log:
*    -----------------------------------------------------------------------------------
*             Developer                      Date                Description
*            Deep Diwakar                 Jul-30-2024           CMCM-7519: Added test method for Marketing task updates
*    ------------------------------------------------------------------------------------ 
*                    
*/
@isTest
public with sharing class TestTaskFlow {
    @isTest
    static void testTasksFlows() {
        List <Task> taskList = new List <Task>();
        Account acc = TestDataAccount.getAccount('TestAccount');
        insert acc;
        Account_Plan__c accPlan = TestDataAccountPlan.getNewAccountPlan(acc);
        Objective__c obj=new Objective__c();
        obj.name='Test Objective';
        obj.Due_Date__c=System.today();
        obj.Objective_Status__c='In Progress';
        Obj.Account_Plan__c=accPlan.id;
        insert obj;
        Task taskT1=new task();
        taskT1.whatid=obj.id;
        taskT1.subject='Next Step';
        taskT1.Priority='Normal';
        taskT1.status='Completed';
        taskT1.Type='Next Step';
        taskT1.ActivityDate=System.today()+10;
        taskList.add(taskT1);
        Insert taskList;
        System.assertEquals(1,taskList.size(),'Task is inserted');
    }
}