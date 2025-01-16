/* @ author       : KD
* @ date         : 5-Sept-2019
* @ Description  : AccountPlan Trigger helper class contains all Business logic implementation
* Test Class for 75% coverage : TestAccountPlanCloneController, TestAccountPlanMobileNavController, TestAccountPlanObjectivesController, TestAccountPlans, TestBatchAccountPlanPopulateRegion, 
*                               TestBatchCloseOpenActionsOnClosedPlans, TestBatchUpdateObjectives, TestCloseRelatedObjectives, TestCompetitiveDataRollUpSummaryCtrl, TestContentDocumentLinks, 
*                               TestNewAccountPlanController, TestPlanAssociatedOppsController, TestPlans, TestSegmentationSelectionController, TestStakeHolderController, TestTAPS_AccountPlans, 
*                               TestTAPS_ObjectiveOppRelationships, TestTasks, TestViewActivePlansController, TestViewActivePlansTerritoryController, Test_batchToMarkIsFileAttached
* Test Class for 90% coverage : TestAccountPlanCloneController, TestAccountPlanMobileNavController, TestAccountPlanObjectivesController, TestAccountPlans, TestBatchAccountPlanPopulateRegion, 
*                               TestBatchCloseOpenActionsOnClosedPlans, TestBatchUpdateObjectives, TestCloseRelatedObjectives, TestCompetitiveDataRollUpSummaryCtrl, TestContentDocumentLinks, 
*                               TestNewAccountPlanController, TestPlanAssociatedOppsController, TestPlans, TestSegmentationSelectionController, TestStakeHolderController, TestTAPS_AccountPlans, 
*                               TestTAPS_ObjectiveOppRelationships, TestTasks, TestViewActivePlansController, TestViewActivePlansTerritoryController, Test_batchToMarkIsFileAttached
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* Akshay Mohan             05-Sep-19              DCP-27435             TAPS Logic for Account Plan sharing
* Bharath Varma            24-Aug-21              DCP-49635             Methd to close all open tasks on Account Plan, when the plan is closed
* Nishan Shetty            06-Dec-21              DCP-50978             Method to close related Account Plan Objectives and Actions once Account Plan is closed.
* Nishan Shetty            24-Aug-2022            DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
* Anshaj Sinha             12-Sep-2022                CMSI-207 Instrumented class for PS Log Framework
* ---------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class AccountPlans extends ilib_SObjectDomain {
    private static final String TASK_STATUS_COMPLETED = 'Completed';  //DCP-49635
    private static final String PLAN_STATUS_CLOSED = 'Closed';//DCP-49635
    private static final String LOG_TITLE = 'AccountPlans';//DCP-50978
    private static final String TASK_SALES_RECORDTYPE_NAME='Sales';//DCP-50978
    private static final String TASK_SUBJECT_CALL='Call';//DCP-50978
    public static Boolean stopRecursiveForAcctPlanObjectiveStatusClose = false;//DCP-50978
    /*
     * Constructor for Account Plans
     */
    public AccountPlans(List<Account_Plan__c> sObjectList) {
        super(sObjectList);
    }
    /**
    *  @author Anshaj
    *  @description  CMSI-207,method will return the workstream
    *  @return string
    **/
    public override string getWorkstream(){
        return ilib_LogEvent.SALES;
    }
    /*
* Boilerplate which is required for base class instantiation logic
*/
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /*
         * Constructor for Account Plans
         */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new AccountPlans(sObjectList);
        }
    }
    /**
     *  @author       : Kushagra Desai
     *  @description  :  Prevent delete of Account plan if status not Draft
     *  @return       : void
     */
    public override void onBeforeDelete(){
        List<Account_Plan__c> lstTempAccPlan = (List<Account_Plan__c>) records;
        for(Account_Plan__c accplan : lstTempAccPlan){
            if(accplan.Plan_Status__c != Label.AccountPlanStatusDraft){
                accplan.addError(Label.UI_AccountPlan_Restrict_Delete);
            }
        }
    }

    /**
     *  @author       : Akshay Mohan
     *  @description  : Add afterinsert handler for TAPS(DCP-27435)
     *  @return       : void
     */
    public override void onAfterInsert(){
        TAPS_OrchestratorInterface tapsOrchestrator = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
        tapsOrchestrator.recalculateRecordChanges(UtilsCollection.getSetOfIds(records, 'Id'), getSObjectType());//DCP-44091
    }

    /**
     *  @author       : Bharath Varma
     *  @description  : Add afterupdate handler for DCP-49635
     *  @return       : void
     */
    public override void onAfterUpdate(Map<Id, sObject> idToOldRecords){

        //START DCP-50978
        if(!stopRecursiveForAcctPlanObjectiveStatusClose && !System.isBatch() && !System.isFuture()) {
          closeAccountPlanObjectivesAndActions((List<Account_Plan__c>)records,(Map<Id,Account_Plan__c>)idToOldRecords);
          stopRecursiveForAcctPlanObjectiveStatusClose=true;
        }
        //END DCP-50978

    }

    /*
    *  @author       : Nishan Shetty
    *  @description  : Method to close Account Plan Objectives and Account Plan Objectives Action when Account Plan is closed[DCP-50978]
    *  @param        : lstAccountPlan -List of Account Plan Records.
    *  @param        : mapIdToOldAccountPlan - Old Map of Id to Account Plan.
    *  @return       : void
    */
    public static void closeAccountPlanObjectivesAndActions(List<Account_Plan__c> lstAccountPlan,Map<Id,Account_Plan__c> mapIdToOldAccountPlan) {
        ilib_LogEvent.push(LOG_TITLE + '.closeAccountPlanObjectivesAndActions');
        Set<Id> setAcctPlanIdsWithoutObjectiveClosedStatus = new Set<Id>();
        Set<Id> setClosedAcctPlanIds = new Set<Id>();
        List<Objective__c> lstAcctPlanObjectives =new List<Objective__c>();
        Map<Id,Id> mapObjectiveIdAcctPlanId=new Map<Id,Id>();
        Map<Id,List<Objective__c>> mapAcctPlanIdToObjectives=new Map<Id,List<Objective__c>>();
        List<Task> lstTasks=new List<Task>();
       
        //Iterating Closed Account Plans.
        for(Account_Plan__c objAcctPlan:lstAccountPlan) {
            if(objAcctPlan.Plan_Status__c==PLAN_STATUS_CLOSED && mapIdToOldAccountPlan.get(objAcctPlan.Id).Plan_Status__c != PLAN_STATUS_CLOSED) {
                setClosedAcctPlanIds.add(objAcctPlan.Id);
            }
        }
    
        //Fetching Related Plan Objectives.
        if(!setClosedAcctPlanIds.isEmpty()) {
          lstAcctPlanObjectives=new ObjectivesSelector().getObjectiveBySetAccountPlanIds(setClosedAcctPlanIds);
        }

        ilib_LogEvent.info('Objective Fetched : '+lstAcctPlanObjectives);
        
        //Iterating Plan Objectives.
        for(Objective__c objAcctPlanObjective:lstAcctPlanObjectives) {
            if(objAcctPlanObjective.Closed_Status__c==null) {
                setAcctPlanIdsWithoutObjectiveClosedStatus.add(objAcctPlanObjective.Account_Plan__c);
            }
            mapObjectiveIdAcctPlanId.put(objAcctPlanObjective.Id,objAcctPlanObjective.Account_Plan__c);
            if(!mapAcctPlanIdToObjectives.containsKey(objAcctPlanObjective.Account_Plan__c)) {
                mapAcctPlanIdToObjectives.put(objAcctPlanObjective.Account_Plan__c,new List<Objective__c>());
            }
            mapAcctPlanIdToObjectives.get(objAcctPlanObjective.Account_Plan__c).add(objAcctPlanObjective);
        }
        
        //Fecthing Related Tasks.
        if(!mapObjectiveIdAcctPlanId.isEmpty()) {
            lstTasks = new TaskSelector().getAllTaskByWhoId((List<String>)new List<Id>(mapObjectiveIdAcctPlanId.keySet()));
        }
        ilib_LogEvent.info('Task Fetched : '+lstTasks);
        ilib_LogEvent.info('Account Plan Having Error for Objective : '+setAcctPlanIdsWithoutObjectiveClosedStatus);

        //Splitting for Code Scan Issue.
        performCloseObjectivesAndAction(lstTasks,lstAccountPlan,mapObjectiveIdAcctPlanId,mapAcctPlanIdToObjectives,setAcctPlanIdsWithoutObjectiveClosedStatus);
        ilib_LogEvent.pop(); 
    }


    /*
    *  @author       : Nishan Shetty
    *  @description  : Method to close Account Plan Objectives and Account Plan Objectives Action when Account Plan is closed[DCP-50978]
    *  @param        : lstTasks -List of Tasks.
    *  @param        : lstAccountPlan - List of Account Plans.
    *  @param        : mapObjectiveIdAcctPlanId - Map of Objective Id To Account Plan Id.
    *  @param        : mapAcctPlanIdToObjectives - Map of Account Plan Id to List of Objectives.
    *  @param        : setAcctPlanIdsWithoutObjectiveClosedStatus - Set of Account PlanIds without Objective Closed Status.
    *  @return       : void
    */
    public static void performCloseObjectivesAndAction(List<Task> lstTasks,List<Account_Plan__c> lstAccountPlan,Map<Id,Id> mapObjectiveIdAcctPlanId,Map<Id,List<Objective__c>> mapAcctPlanIdToObjectives,Set<Id> setAcctPlanIdsWithoutObjectiveClosedStatus) {
        ilib_LogEvent.push(LOG_TITLE + '.performCloseObjectivesAndAction()');
        Map<Id,List<Task>> mapAcctPlanIdToTask =new Map<Id,List<Task>>();
        Set<Id> setAcctPlanWithError=new Set<Id>();
        List<Task> lstTasksToUpdate = new List<Task>();
        List<Objective__c> lstAcctPlanObjectivesToUpdate =new List<Objective__c>();

         //Iterating over Tasks.
         for(Task task: lstTasks) {
            ilib_LogEvent.message('Task in loop : '+task);
            String strSubject=task.Subject;
            if(task.Status!=TASK_STATUS_COMPLETED && strSubject!=null && strSubject.containsIgnoreCase(TASK_SUBJECT_CALL) && task.RecordType.DeveloperName==TASK_SALES_RECORDTYPE_NAME && mapObjectiveIdAcctPlanId.containsKey(task.WhatId) && (task.WhoId==null||task.Call_Result__c==null)) {
                setAcctPlanWithError.add(mapObjectiveIdAcctPlanId.get(task.WhatId));
            } 
            if(!mapAcctPlanIdToTask.containsKey(mapObjectiveIdAcctPlanId.get(task.WhatId))) {
                mapAcctPlanIdToTask.put(mapObjectiveIdAcctPlanId.get(task.WhatId),new List<Task>());
            }
            mapAcctPlanIdToTask.get(mapObjectiveIdAcctPlanId.get(task.WhatId)).add(task);
        }
        ilib_LogEvent.info('mapAcctPlanIdToTask : '+mapAcctPlanIdToTask);

        for(Account_Plan__c objAcctPlan:lstAccountPlan) {
            if(setAcctPlanIdsWithoutObjectiveClosedStatus.contains(objAcctPlan.Id)) {
                objAcctPlan.addError(Label.AddClosedStatusPlanObjectiveError);
            } else if(mapAcctPlanIdToObjectives.containsKey(objAcctPlan.Id)) {
                lstAcctPlanObjectivesToUpdate.addAll(mapAcctPlanIdToObjectives.get(objAcctPlan.Id));
            }

            if(setAcctPlanWithError.contains(objAcctPlan.Id)) {
                objAcctPlan.addError(Label.AddClosedActionError);
            } else if(mapAcctPlanIdToTask.containsKey(objAcctPlan.Id)) {
                    lstTasksToUpdate.addAll(mapAcctPlanIdToTask.get(objAcctPlan.Id));
            }
        } 
        
        ilib_LogEvent.info('Task To Update : '+lstTasksToUpdate);
        ilib_LogEvent.info('AccountPlan Objectives To Update : '+lstAcctPlanObjectivesToUpdate);

        //Splitting for Code Scan Issue.
        callFutureUpdateForObjectiveAndActions(lstTasksToUpdate,lstAcctPlanObjectivesToUpdate);
        ilib_LogEvent.pop();
    }

    /*
    *  @author       : Nishan Shetty
    *  @description  : Method to update Objective and Actions in Future DCP-50978
    *  @param        : lstTasksToUpdate -List of Task Records To Update.
    *  @param        : lstPlanObjectivesToUpdate- List of Plan Objectives To Update.
    */
    public static void callFutureUpdateForObjectiveAndActions( List<Task> lstTasksToUpdate, List<Objective__c> lstAcctPlanObjectivesToUpdate) {
        ilib_LogEvent.push(LOG_TITLE + '.callFutureUpdateForObjectiveAndActions()');
        if(!lstTasksToUpdate.isEmpty()||!lstAcctPlanObjectivesToUpdate.isEmpty()) {
            CloseRelatedObjectives.performClosureForAcctPlanObjectiveAndTask(JSON.serialize(lstTasksToUpdate),JSON.serialize(lstAcctPlanObjectivesToUpdate));
        }
        ilib_LogEvent.pop();
    }

}