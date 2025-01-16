/**
* @ author       : Akshay Mohan
* @ date         : 23-Sep-2020
* @ Description  : DCP-41751 Test Class for ScheduledBatchPlanOverdueTaskEmail
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Akshay Mohan          23-Sep-2020                 Initial version
* Nishan Shetty         14-Jun-2022                 DCP-50962
*/
@isTest
public with sharing class TestScheduledBatchPlanOverdueTaskEmail {
    
    /**
    * @author Akshay Mohan
    * @date   23-Sep-2020
    * @description  Setup Data
    */
    @TestSetup
    static void makeData(){
        Plan__c objTPlan = TestDataPlan.getPlan(null);
        objTPlan.Name='Dummy Plan';
        insert objTPlan;
        Plan_Strategy__c objPlanStrategy = TestDataPlanStrategy.getPlanStrategy(objTPlan.id);
        insert objPlanStrategy;
        Plan_Objective__c objPlanObjective1 = TestDataPlanObjective.getPlanObjective(objPlanStrategy.id);
        Plan_Objective__c objPlanObjective2 = TestDataPlanObjective.getPlanObjective(objPlanStrategy.id);
        insert new List<Plan_Objective__c>{objPlanObjective1,objPlanObjective2};
        
        Id idRecordType=Schema.SObjectType.Task.getRecordTypeInfosByName().get(Label.TaskRecordTypeMarketing).getRecordTypeId();
        Date dtPast =Date.today().addDays(-2);
        List<Task> lstTasks = new List<Task>();
        for(Integer counter=0;counter<200;counter++){
            Task objTask = new Task(
                                ActivityDate = dtPast,
                                Subject = 'Subject',
                                Description = 'Dummy',
                                Status = 'Open',
                                Priority = 'Normal',
                                RecordTypeid = idRecordType,
                                OwnerId=UserInfo.getUserId(),
                                WhatId=counter<100?objPlanObjective1.Id:objPlanObjective2.Id
                            );
            lstTasks.add(objTask);
        }
        insert lstTasks;
    }

    /**
    * @author Akshay Mohan
    * @date   23-Sep-2020
    * @description  Schedule & run batch
    */
    @isTest
    static void testSchedule() {
        Test.startTest();
        ScheduledBatchPlanOverdueTaskEmail obj =new ScheduledBatchPlanOverdueTaskEmail();
        obj.execute(null);
        Boolean boolScheduledBatch= obj.boolJobRan;//DCP-50962
        System.assert(boolScheduledBatch,'Job not exxecuted');//DCP-50962
        Test.stopTest();
    }
}