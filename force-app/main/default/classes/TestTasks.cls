/**
*    @author: Kushagra Desai
*    @date:   16-Sept-2019
*    @description:  Test class for  Tasks Controller
*    Modification Log:
*    -----------------------------------------------------------------------------------
*             Developer                      Date                Description
*            Deep Diwakar                 Jul-30-2024           CMCM-7519: Added test method for Marketing task updates
*            Deep Diwakar                 Dec-11-2024           CMCM-12470: Updated test method to adjust Task subject change
*    ------------------------------------------------------------------------------------ 
*                    
*/
@isTest
public with sharing class TestTasks {
    @isTest
    static void testTasksTrigger(){
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
        taskT1.subject='task subject 1';
        taskT1.Priority='Normal';
        taskT1.ActivityDate=System.today()+10;
        insert taskT1;
        taskT1.status='Completed';
        update taskT1;

        lead objLead = TestDataMarketing.createLeadForMarketable('testfirstname2','testlastname2','test2@gmail.com','Germany','test2Company');
        insert objLead;
        Task taskT2 = new task();
        taskT2.whoid=objLead.id;
        taskT2.subject='task subject 2';
        taskT2.Priority='Normal';
        taskT2.ActivityDate=System.today()+15;
        insert taskT2;
        taskT2.status='Completed';
        update taskT2;

        lead objLead2 = TestDataMarketing.createLeadForMarketable('testfirstname3','testlastname3','test3@gmail.com','Germany','test3Company');
        insert objLead2;
        Task taskT3 = new task();
        taskT3.whoid=objLead2.id;
        taskT3.subject='task subject 3';
        taskT3.Priority='Normal';
        taskT3.status = 'Completed';
        taskT3.ActivityDate = System.today()+15;
        insert taskT3;

        Objective__c objObjective=[select id,Total_Task__c,Total_Closed_Task__c from Objective__c where id=:obj.id];
        System.assertEquals(1, objObjective.Total_Task__c);
        System.assertEquals(1, objObjective.Total_Closed_Task__c);
        delete taskT1;
        objObjective=[select id,Total_Task__c,Total_Closed_Task__c from Objective__c where id=:obj.id];
        System.assertEquals(0, objObjective.Total_Task__c);


    }
    
    @isTest
    static void testMktgTaskUpdates() {
        Lead testLead = TestDataMarketing.createLeadForMarketable('Marketing', 'Testing', 'marketing_task@testing.com', 'USA', 'Marketing Task Testing Inc');
        testLead.Form_Type__c = 'Gated Files';
        testLead.Product_Interest__c = 'Consumables';
        testLead.Questions_For_Rep__c = 'Please refer to the Questions for Rep field for more information about this Lead inquiry';
        testLead.Last_Form_Submission_URL__c = 'www.test.com';

        insert testLead;

        Task mktgTestTask = new Task();
        mktgTestTask.Subject = 'A new Lead has submitted a Contact Me request! Please review!';
        mktgTestTask.WhoId = testLead.Id;
        mktgTestTask.Priority = 'Normal';
        mktgTestTask.Status = 'Open';

        //query for pardot user
        User pardotUser = [Select Id From User Where Name = 'Integration Pardot' Limit 1];

        Test.startTest();
        System.runAs(pardotUser) {
            insert mktgTestTask;
        }
        Test.stopTest();

        Task resultTask = [Select Id, Subject From Task Where Id =: mktgTestTask.Id];

        Assert.isTrue(resultTask.Subject.contains('Form Type'), 'Marketing Task updates did not work');

    }
}