/**
*    @author: Vinay 
*    @date:   27-Aug-2024
*    @description:  Test class for ScheduleBatchTerritoryPlanClosure 
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Vinay                        27-Aug-2024        Initial Development
*    ------------------------------------------------------------------------------------ 
*                    
*/
@isTest
public class TestScheduleBatchTerritoryPlanClosure {
    
    @testSetup
       /**
* @author rohit sahu
* @description setup test data for plan records
**/
public static void setupData()
    {
     List<Plan__c> testPlanRecords = new List<Plan__c>();
     Plan__c test1 = new Plan__c();
     test1.Name='Test1';
     test1.Plan_Target__c=100;
     test1.Status__c='Draft';
     test1.End_Date__c=system.today().addDays(-40);
     testPlanRecords.add(test1);
     
     Plan__c test2 = new Plan__c();
     test2.Name='Test2';
     test2.Plan_Target__c=100;
     test2.Status__c='Draft';
     test2.End_Date__c=system.today().addDays(-50);
     testPlanRecords.add(test2);
     
     Plan__c test3 = new Plan__c();
     test3.Name='Test3';
     test3.Plan_Target__c=100;
     test3.Status__c='Draft';
     test3.End_Date__c=system.today().addDays(-20);
     testPlanRecords.add(test3);
     
     insert testPlanRecords;
     
     List<Plan_Strategy__c> planStrat = new List<Plan_Strategy__c>();
     
     Plan_Strategy__c strategy1 = new Plan_Strategy__c();
     strategy1.Name='Strategy1';
     strategy1.Plan__c=test1.Id;
     strategy1.Due_Date__c=system.today().addDays(20);
     PlanStrat.add(strategy1);
     
     Plan_Strategy__c strategy2 = new Plan_Strategy__c();
     strategy2.Name='Strategy2';
     strategy2.Plan__c=test2.Id;
     strategy2.Due_Date__c=system.today().addDays(30);
     PlanStrat.add(strategy2);
     
     Plan_Strategy__c strategy3 = new Plan_Strategy__c();
     strategy3.Name='Strategy3';
     strategy3.Plan__c=test3.Id;
     strategy3.Due_Date__c=system.today().addDays(20);
     PlanStrat.add(strategy3);
     
     insert PlanStrat;
     
     
     List<Plan_Objective__c> planObj = new List<Plan_Objective__c>();
     
     Plan_Objective__c plnaobj1 = new Plan_Objective__c();
     plnaobj1.Name='Objective1';
     plnaobj1.Plan_Strategy__c=Strategy1.Id;
     plnaobj1.Due_Date__c=system.today().addDays(20);
     plnaobj1.Objective_Status__c='Closed';
     plnaobj1.Closed_Status__c='Objective Not Met';
     planObj.add(plnaobj1);
     
     Plan_Objective__c plnaobj2 = new Plan_Objective__c();
     plnaobj2.Name='Objective2';
     plnaobj2.Plan_Strategy__c=Strategy1.Id;
     plnaobj2.Due_Date__c=system.today().addDays(20);
     plnaobj2.Objective_Status__c='Closed';
     plnaobj2.Closed_Status__c='Objective Not Met';
     planObj.add(plnaobj2);
     
     Plan_Objective__c plnaobj3 = new Plan_Objective__c();
     plnaobj3.Name='Objective3';
     plnaobj3.Plan_Strategy__c=Strategy2.Id;
     plnaobj3.Due_Date__c=system.today().addDays(20);
     plnaobj3.Objective_Status__c='Closed';
     plnaobj3.Closed_Status__c='Objective Not Met';
     planObj.add(plnaobj3);
     
     Plan_Objective__c plnaobj4 = new Plan_Objective__c();
     plnaobj4.Name='Objective4';
     plnaobj4.Plan_Strategy__c=Strategy2.Id;
     plnaobj4.Due_Date__c=system.today().addDays(20);
     plnaobj4.Objective_Status__c='At Risk';
     planObj.add(plnaobj4);
     
     
     Plan_Objective__c plnaobj5 = new Plan_Objective__c();
     plnaobj5.Name='Objective5';
     plnaobj5.Plan_Strategy__c=Strategy3.Id;
     plnaobj5.Due_Date__c=system.today().addDays(20);
     plnaobj5.Objective_Status__c='Closed';
     plnaobj5.Closed_Status__c='Objective Not Met';
     planObj.add(plnaobj5);
     
     Plan_Objective__c plnaobj6 = new Plan_Objective__c();
     plnaobj6.Name='Objective6';
     plnaobj6.Plan_Strategy__c=Strategy3.Id;
     plnaobj6.Due_Date__c=system.today().addDays(20);
     plnaobj6.Objective_Status__c='Closed';
     plnaobj6.Closed_Status__c='Objective Not Met';
     planObj.add(plnaobj6);
     
     insert planObj;
    }
    
    
    @isTest
           /**
* @author rohit sahu
* @description execute the test data
**/
    public static void method1(){
        Test.startTest();
        //string cronexp = '0 0 2 * * ?';
        //String jobId = system.schedule('ScheduleBatchTerritoryPlanClosure',cronexp,new ScheduleBatchTerritoryPlanClosure());
        Database.executeBatch(new ScheduleBatchTerritoryPlanClosure(),2);
        Test.stopTest();
        //CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered,NextFireTime FROM CronTrigger WHERE id = :jobId];
        List<Plan__c> querPlans = new List<Plan__c>();
        querPlans = [select Id, Name,Status__c From Plan__c Limit 3];
        Integer i=0, j=0;
        
        for(Plan__c tesmp: querPlans){
            if(tesmp.Status__c == 'Closed') i=i+1;
            else j=j+1;
        }
        
        
        //System.assertEquals(ct.CronExpression,cronexp,'Batch not scheduled!');
        System.assertEquals(1,i,'Required Closed batch not working');
        System.assertEquals(2,j,'Required Not Closed batch not working');
        
    }
}