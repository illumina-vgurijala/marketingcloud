/*
*    @author Nishan Shetty
*    @date   2021-12-06
*    @description-Class to Close Objective Related to Account Plan,Plan.
*    Test Classes for 75%: TestCloseRelatedObjectives
*    Test Classes for 90%: TestCloseRelatedObjectives
*    Modification Log:
*    -------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*            Nishan Shetty                06-Dec-2021            DCP-50978 -Close Objectives And Actions related to Account Plan,Plan. 
*            Vishal Reddy                 30-Aug-2022            CMSI-217 Instrumentation       		
*    --------------------------------------------------------------------------------------------------------
*                    
*/
public with sharing class CloseRelatedObjectives {

    private static final String STRING_CLOSED = 'Closed';
    private static final String LOG_TITLE = 'CloseRelatedObjectives';
    private static final String TASK_STATUS_COMPLETED = 'Completed';

    /*
    *  @author       : Nishan Shetty
    *  @description  : Method to close Account Plan Objectives and Actions Related to Account Plans.[DCP-50978]
    *  @Test Class   : TestCloseRelatedObjectives.cls
    *  @return       : void
    */
    @future
    public static void performClosureForAcctPlanObjectiveAndTask(String strLstTaskToUpdate,String strLstObjectivesToUpdate) {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SALES);
        ilib_LogEvent.push(LOG_TITLE + '.performClosureForAcctPlanObjectiveAndTask()');
        ilib_LogEvent.info('JSON Acct Plan Task : '+strLstTaskToUpdate);
        ilib_LogEvent.info('JSON Acct Plan Objectives : '+strLstObjectivesToUpdate);
        List<Task> lstAcctPlanTasks = (List<Task>) JSON.deserialize(strLstTaskToUpdate, List<Task>.class);
        List<Objective__c> lstAcctPlanObjectives = (List<Objective__c>) JSON.deserialize(strLstObjectivesToUpdate, List<Objective__c>.class);
        List<Task> lstAcctTaskToUpdate=new List<Task>();
        List<Objective__c> lstAcctPlanObjectiveToUpdate=new List<Objective__c>();


        for(Objective__c objObjective:lstAcctPlanObjectives) {
            if(objObjective.Objective_Status__c!=STRING_CLOSED) {
                objObjective.Objective_Status__c=STRING_CLOSED;
                lstAcctPlanObjectiveToUpdate.add(objObjective);
            }
        }
       
        
        for(Task task: lstAcctPlanTasks) {
            if(task.status != TASK_STATUS_COMPLETED) {
                task.status = TASK_STATUS_COMPLETED;
                lstAcctTaskToUpdate.add(task);
            }
        }
        ilib_LogEvent.info('Task Updated : '+UtilsCollection.getSetOfIds(lstAcctTaskToUpdate));
        ilib_LogEvent.info('Account Plan Objective Updated : '+UtilsCollection.getSetOfIds(lstAcctPlanObjectiveToUpdate));
        if(!lstAcctPlanObjectiveToUpdate.isEmpty()) {
            Database.update(lstAcctPlanObjectiveToUpdate,false);
        }

        if(!lstAcctTaskToUpdate.isEmpty()) {
            Database.update(lstAcctTaskToUpdate,false);
        }
        ilib_LogEvent.pop(); 
    }

    /*
    *  @author       : Nishan Shetty
    *  @description  : Method to close Plan Objectives and Actions Related to Plans.[DCP-50978]
    *  @Test Class   : TestCloseRelatedObjectives.cls
    *  @return       : void
    */
    @future
    public static void performClosureForPlanObjectiveAndTask(String strLstTaskToUpdate,String strLstObjectivesToUpdate) {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SALES);
        ilib_LogEvent.push(LOG_TITLE + '.performClosureForPlanObjectiveAndTask()');
        ilib_LogEvent.info('JSON Task : '+strLstTaskToUpdate);
        ilib_LogEvent.info('JSON Objectives : '+strLstObjectivesToUpdate);
        List<Task> lstTasks = (List<Task>) JSON.deserialize(strLstTaskToUpdate, List<Task>.class);
        List<Plan_Objective__c> lstPlanObjectives = (List<Plan_Objective__c>) JSON.deserialize(strLstObjectivesToUpdate, List<Plan_Objective__c>.class);
        List<Task> lstTaskToUpdate=new List<Task>();
        List<Plan_Objective__c> lstPlanObjectiveToUpdate=new List<Plan_Objective__c>();


        for(Plan_Objective__c objPlanObjective:lstPlanObjectives) {
            if(objPlanObjective.Objective_Status__c!=STRING_CLOSED) {
                objPlanObjective.Objective_Status__c=STRING_CLOSED;
                lstPlanObjectiveToUpdate.add(objPlanObjective);
            }
        }
       
        
        for(Task task: lstTasks) {
            if(task.status != TASK_STATUS_COMPLETED) {
                task.status = TASK_STATUS_COMPLETED;
                lstTaskToUpdate.add(task);
            }
        }
        ilib_LogEvent.info('Task Updated : '+UtilsCollection.getSetOfIds(lstTaskToUpdate));
        ilib_LogEvent.info('Plan Objective Updated : '+UtilsCollection.getSetOfIds(lstPlanObjectiveToUpdate));
        if(!lstPlanObjectiveToUpdate.isEmpty()) {
            Database.update(lstPlanObjectiveToUpdate,false);
        }

        if(!lstTaskToUpdate.isEmpty()) {
            Database.update(lstTaskToUpdate,false);
        }
        ilib_LogEvent.pop(); 
    }
}
