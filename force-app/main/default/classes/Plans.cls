/**
 *    @author Anisha Bharti
 *    @date   07-Aug-2020
 *    @description : Handler class for PlanTrigger.
 * 
 *    90% Code Coverage : TestAccountPlanCloneController,TestAccountPlanMobileNavController,TestAccountPlanObjectivesController,
 *                        TestAccountPlans,TestAccountTerritoryUsersController,TestAccountsServiceSalesEmails,TestAssetExpirationReminderController,
 *                        TestBatchAccountPlanPopulateRegion,TestBatchCloseOpenActionsOnClosedPlans,TestBatchCreatePMPlans,TestBatchUpdateObjectives,
 *                        TestCloseRelatedObjectives,TestCompetitiveDataRollUpSummaryCtrl,TestContentDocumentLinks,TestCoveredProductsQueueable,
 *                        TestCreateQuoteAutomation,TestDataBillableFlowQueueable,TestInstalledProductsService,TestNewAccountPlanController,TestOpportunities,
 *                        TestPlanAssociatedOppsController,TestPlanCloneController,TestPlanCreationController,TestPlanRepresentativeController,
 *                        TestPlanShareService,TestPlans,TestPopulateLastPMDateOnIP,TestScheduledBatchPlanOverdueTaskEmail,TestSegmentationSelectionController,
 *                        TestServiceContractDataReceiver,TestServicePlanSelector,TestSharingConsole,TestStakeHolderController,TestTAPS_AccountPlans,
 *                        TestTAPS_ApttusDocumentVersion,TestTAPS_ApttusRelatedAgreement,TestTAPS_DeferredRun,TestTAPS_Locations,TestTAPS_ObjectiveOppRelationships,
 *                        TestTAPS_PartnerRequest,TestTAPS_SmaxWorkOrder,TestTasks,TestTerritoryPlanStrategyController,TestViewActivePlansController,
 *                        TestViewActivePlansTerritoryController,TestViewRelatedActiveTerritoryPlanCtrl,TestViewTerritoryPlansController,Test_batchToMarkIsFileAttached.
 *    75% Code Coverage : TestAccountPlanCloneController,TestAccountPlanMobileNavController,TestAccountPlanObjectivesController,
 *                        TestAccountPlans,TestAccountTerritoryUsersController,TestAccountsServiceSalesEmails,TestAssetExpirationReminderController,
 *                        TestBatchAccountPlanPopulateRegion,TestBatchCloseOpenActionsOnClosedPlans,TestBatchCreatePMPlans,TestBatchUpdateObjectives,
 *                        TestCloseRelatedObjectives,TestCompetitiveDataRollUpSummaryCtrl,TestContentDocumentLinks,TestCoveredProductsQueueable,
 *                        TestCreateQuoteAutomation,TestDataBillableFlowQueueable,TestInstalledProductsService,TestNewAccountPlanController,TestOpportunities,
 *                        TestPlanAssociatedOppsController,TestPlanCloneController,TestPlanCreationController,TestPlanRepresentativeController,
 *                        TestPlanShareService,TestPlans,TestPopulateLastPMDateOnIP,TestScheduledBatchPlanOverdueTaskEmail,TestSegmentationSelectionController,
 *                        TestServiceContractDataReceiver,TestServicePlanSelector,TestSharingConsole,TestStakeHolderController,TestTAPS_AccountPlans,
 *                        TestTAPS_ApttusDocumentVersion,TestTAPS_ApttusRelatedAgreement,TestTAPS_DeferredRun,TestTAPS_Locations,TestTAPS_ObjectiveOppRelationships,
 *                        TestTAPS_PartnerRequest,TestTAPS_SmaxWorkOrder,TestTasks,TestTerritoryPlanStrategyController,TestViewActivePlansController,
 *                        TestViewActivePlansTerritoryController,TestViewRelatedActiveTerritoryPlanCtrl,TestViewTerritoryPlansController,Test_batchToMarkIsFileAttached.
 * 
 *    Modification Log:
 *    -----------------------------------------------------------------------------------------------------------------
 *  Developer                          Date                  Description
 *  Anisha Bharti                   25-Aug-2020         Added method onAfterUpdate
 *  KD                              8-Sept-2020          Added method onAfterInsert  for Plan sharing 
 *  Bharath Varma                   24-Aug-2021         Method to close all tasks once the Plan is closed.
 *  Nishan Shetty                   06-Dec-2021        [DCP-50978] Method to close related Plan Objectives and Actions once Plan is closed.
 *  Nishan Shetty                   03-Jun-2022        [DCP-50962] Implementation of Ilib Batch Manager Framework.
 *  Sibin P Kuriakose               19-Sep-2022        [CMSI-213] Instrumentation of the class.
 *    ------------------------------------------------------------------------------------------------------------------
 *                    
 */
public with sharing class Plans extends ilib_SObjectDomain {

    private static final String TASK_STATUS_COMPLETED = 'Completed'; //DCP-49635
    private static final String PLAN_STATUS_CLOSED = 'Closed';//DCP-49635
    public static Boolean stopRecursiveForPlanObjectiveStatusClose = false;//DCP-50978
    private static final String TASK_SUBJECT_CALL='Call';//DCP-50978
    private static final String TASK_SALES_RECORDTYPE_NAME='Sales';//DCP-50978
    public static final String LOG_TITLE = 'Plans';//DCP-50978
    
    static id directRecordtypeId = Schema.SObjectType.Plan__c.getRecordTypeInfosByDeveloperName().get(Label.Plan_Direct).getRecordTypeId();
    static id indirectRecordtypeId = Schema.SObjectType.Plan__c.getRecordTypeInfosByDeveloperName().get(Label.Plan_Indirect).getRecordTypeId();
    static map<String, SObject> mapTerritorycodePlan= new Map<String, SObject>();
    /** 
     * @description  Constructor
     * @param List of plan
     */
    public Plans(List<Plan__c> sObjectList)
    {
        super(sObjectList);
    }
    /**
    *  @author Sibin P Kuriakose
    *  @description  CMSI-218,method will return the workstream
    *  @return string
    **/

    public override string getWorkstream(){

        return ilib_LogEvent.SALES;

    }
    /** 
     * @description  implements ilib_SObjectDomain.IConstructable
     */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /** 
         * @description  construct method
         */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new Plans(sObjectList);
        }
    }
    /** 
     * @description  onBeforeUpdate method
     */
    public override void onBeforeUpdate(Map<Id, SObject> idToOldRecords){
        checkForActivePlanExists(idToOldRecords);
    }
    /**
     * @author Anisha
     * @description method to check existing active plan
     * @param map id to old records.
     */
    public void checkForActivePlanExists (Map<Id,SObject> idToOldRecords){
        ilib_LogEvent.push(LOG_TITLE + 'checkForActivePlanExists'); //CMSI-213
        List<Plan__c> lstPlans = (List<Plan__c>) records;
        if (lstPlans == null || lstPlans.isEmpty()) return;
        
        Map<Id,Plan__c> idToOldPlan = (Map<Id,Plan__c>)idToOldRecords;
        List<Plan__c> lstIndirectPlan = new List<Plan__c>();
        List<Plan__c> lstDirectPlan = new List<Plan__c>();

        Set<String> setPlanTerritorycode = new set<String>();
        Set<Id> setPlanChannelPartner = new set<Id>();
        for(Plan__c plan : lstPlans)
        {
            Plan__c oldPlan = idToOldPlan.get(plan.Id);
            if(Label.PlanStatusActive.equals(plan.Status__c) && plan.Status__c != oldPlan.Status__c ){
                if(plan.RecordTypeId == directRecordtypeId)
                    mapTerritorycodePlan.put(plan.Territory_Code__c, plan);
                setPlanTerritorycode.add(plan.Territory_Code__c);  
                setPlanChannelPartner.add(plan.Channel_Partner__c);
            }
        }
        ilib_LogEvent.info('setPlanTerritorycode : ' + setPlanTerritorycode); //CMSI-213
        ilib_LogEvent.info('setPlanChannelPartner : ' + setPlanChannelPartner); //CMSI-213
        Map<String, Plan__c> mapIndirectPlans = new Map<String, Plan__c>();
        Map<String, Plan__c> mapDirectPlans = new Map<String, Plan__c>();
        if(!setPlanTerritorycode.isEmpty() && !setPlanChannelPartner.isEmpty()){
            lstIndirectPlan = new PlanSelector().getActiveIndirectPlanbyTerritoryCode(setPlanTerritorycode, setPlanChannelPartner, indirectRecordtypeId);
            for( Plan__c planIndirect : lstIndirectPlan)
                mapIndirectPlans.put(planIndirect.Territory_Code__c + planIndirect.Channel_Partner__c, planIndirect);
        }
        if(!setPlanTerritorycode.isEmpty()){
            lstDirectPlan = new PlanSelector().getActiveDirectPlanbyTerritoryCode(setPlanTerritorycode, directRecordtypeId);
            for( Plan__c planDirect : lstDirectPlan)
                mapDirectPlans.put(planDirect.Territory_Code__c, planDirect);
        }   
        ilib_LogEvent.info('mapIndirectPlans' + mapIndirectPlans.keySet()); //CMSI-213
        ilib_LogEvent.info('mapDirectPlans' + mapDirectPlans.keySet()); //CMSI-213     
        showActivePlanExistsError(mapIndirectPlans, mapDirectPlans, lstPlans);
        ilib_LogEvent.pop(); //CMSI-213
    }
    /**
    *    @author Anisha Bharti
    *    @date   25-Aug-2020
    *    @description Method to add error if active plan exists.
    */
    public static void showActivePlanExistsError(Map<String, Plan__c> mapIndirectPlans, Map<String, Plan__c> mapDirectPlans, List<Plan__c> lstPlans){
        ilib_LogEvent.push(LOG_TITLE + 'showActivePlanExistsError'); //CMSI-213
        for(Plan__c plan : lstPlans){
            if(mapIndirectPlans.containsKey(plan.Territory_Code__c + plan.Channel_Partner__c) && mapIndirectPlans.get(plan.Territory_Code__c + plan.Channel_Partner__c).id != plan.id && plan.RecordTypeId == indirectRecordtypeId )
                plan.addError(Label.Plan_Indirect_Restrict_Active_Error);
            else if(mapDirectPlans.containsKey(plan.Territory_Code__c) && mapDirectPlans.get(plan.Territory_Code__c).id != plan.id && plan.RecordTypeId == directRecordtypeId )
                plan.addError(Label.Plan_Direct_Restrict_Active_Error);
        }
        ilib_LogEvent.pop(); //CMSI-213
    }
    
    /**
    *    @author Anisha Bharti
    *    @date   25-Aug-2020
    *    @description Method onafterupdate of plan
    */
    public override void onAfterUpdate(Map<Id, SObject> idToOldRecords){
        if(!mapTerritorycodePlan.isEmpty())
            onPlanActivateUpdateAccountPlans();

        //START DCP-50978
        if(!stopRecursiveForPlanObjectiveStatusClose && !System.isBatch() && !System.isFuture()) {
            closePlanObjectivesAndActions((List<Plan__c>)records,(Map<Id,Plan__c>)idToOldRecords);
            stopRecursiveForPlanObjectiveStatusClose=true;
        }
        //END DCP-50978

    }
    
    /**
    *    @author Anisha Bharti
    *    @date   25-Aug-2020
    *    @description Method to call batch class and update Direct Territory Plan
    */
    public static void onPlanActivateUpdateAccountPlans() {
        ilib_LogEvent.push(LOG_TITLE + 'onPlanActivateUpdateAccountPlans'); //CMSI-213
        Set<Id> setTerritoriesId = new set<Id>();
        Map<Id, String> mapAccountTerritoryCode = new Map<Id, String> ();
        for(Territory2 lstTerritories : new TerritoriesSelector().getByTerritoryCode(mapTerritorycodePlan.keySet())){
            setTerritoriesId.add(lstTerritories.id);
        }
        for(ObjectTerritory2Association lstObj : new ObjectTerritory2AssociationsSelector().selectByTerritoryId(setTerritoriesId)){
            mapAccountTerritoryCode.put(lstObj.ObjectId, lstObj.Territory2.Territory_Code__c);
        }
        ilib_LogEvent.info('setTerritoriesId' + setTerritoriesId); //CMSI-213
        ilib_LogEvent.info('mapAccountTerritoryCode' + mapAccountTerritoryCode); //CMSI-213
         //DCP-50962 - implementation of batch manager
        ilib_BatchManager.executeBatch(new BatchUpdateAccountPlanWithActiveTP(mapTerritorycodePlan, mapAccountTerritoryCode),20);
        ilib_LogEvent.pop(); //CMSI-213
    }


    /**
     *  @author       : Kushagra Desai
     *  @description  : Add afterinsert handler sharing based on territory
     *  @return       : void
     */
    public override void onAfterInsert(){

        PlanShareService.sharePlanRecords((List<Plan__c>)records);
    }

   /*
    *  @author       : Nishan Shetty
    *  @description  : Method to close Plan Objectives and Plan Objectives Action when Plan is closed[DCP-50978]
    *  @param        : lstPlan -List of Plan Records
    *  @param        : mapIdToOldPlan - Old Map of Id to Plan
    *  @return       : void
    */
    public static void closePlanObjectivesAndActions(List<Plan__c> lstPlan,Map<Id,Plan__c> mapIdToOldPlan) {
        ilib_LogEvent.push(LOG_TITLE +'closePlanObjectivesAndActions'); //CMSI-213
        Set<Id> setPlanIdsWithoutObjectiveClosedStatus = new Set<Id>();
        Set<Id> setClosedPlanIds = new Set<Id>();
        List<Plan_Objective__c> lstPlanObjectives =new List<Plan_Objective__c>();
        Map<Id,Id> mapObjectiveIdPlanId=new Map<Id,Id>();
        Map<Id,List<Plan_Objective__c>> mapPlanIdToObjectives=new Map<Id,List<Plan_Objective__c>>();
        List<Task> lstTasks=new List<Task>();
       
        //Iterating Closed Plans.
        for(Plan__c objPlan:lstPlan) {
            if(objPlan.Status__c==PLAN_STATUS_CLOSED && mapIdToOldPlan.get(objPlan.Id).Status__c != PLAN_STATUS_CLOSED) {
               setClosedPlanIds.add(objPlan.Id);
            }
        }
        ilib_LogEvent.info('ClosedPlanIds' + setClosedPlanIds); //CMSI-213
        //Fetching Related Plan Objectives.
        if(!setClosedPlanIds.isEmpty()) {
         lstPlanObjectives=new PlanObjectiveSelector().getPlanObjectivesByPlanId(setClosedPlanIds);
        }

        ilib_LogEvent.info('Objective Fetched:'+UtilsCollection.getSetOfIds(lstPlanObjectives));
        
        //Iterating Plan Objectives.
        for(Plan_Objective__c objPlanObjective:lstPlanObjectives) {
            if(objPlanObjective.Closed_Status__c==null) {
                setPlanIdsWithoutObjectiveClosedStatus.add(objPlanObjective.Plan_Strategy__r.Plan__c);
            }
            mapObjectiveIdPlanId.put(objPlanObjective.Id,objPlanObjective.Plan_Strategy__r.Plan__c);
            if(!mapPlanIdToObjectives.containsKey(objPlanObjective.Plan_Strategy__r.Plan__c)) {
                mapPlanIdToObjectives.put(objPlanObjective.Plan_Strategy__r.Plan__c,new List<Plan_Objective__c>());
            }
            mapPlanIdToObjectives.get(objPlanObjective.Plan_Strategy__r.Plan__c).add(objPlanObjective);
        }
        
        //Fecthing Related Tasks.
        if(!mapObjectiveIdPlanId.isEmpty()) {
            lstTasks = new TaskSelector().getAllTaskByWhoId((List<String>)new List<Id>(mapObjectiveIdPlanId.keySet()));
        }
        ilib_LogEvent.info('Task Fetched:'+ UtilsCollection.getSetOfIds(lstTasks));
        ilib_LogEvent.info('Plan Having Error for Objective'+ setPlanIdsWithoutObjectiveClosedStatus);

        //Splitting for Code Scan Issue.
        performCloseObjectivesAndAction(lstTasks,lstPlan,mapObjectiveIdPlanId,mapPlanIdToObjectives,setPlanIdsWithoutObjectiveClosedStatus);
        ilib_LogEvent.pop(); 
    }


    /*
    *  @author       : Nishan Shetty
    *  @description  : Method to close Plan Objectives and Plan Objectives Action when Plan is closed[DCP-50978]
    *  @param        : lstTasks -List of Tasks.
    *  @param        : lstPlan - List of Plans.
    *  @param        : mapObjectiveIdPlanId - Map of Objective Id To Plan Id.
    *  @param        : mapPlanIdToObjectives - Map of Plan Id to List of Objectives.
    *  @param        : setPlanIdsWithoutObjectiveClosedStatus - Set of PlanIds without Objective Closed Status.
    *  @return       : void
    */
    public static void performCloseObjectivesAndAction(List<Task> lstTasks,List<Plan__c> lstPlan,Map<Id,Id> mapObjectiveIdPlanId,Map<Id,List<Plan_Objective__c>> mapPlanIdToObjectives,Set<Id> setPlanIdsWithoutObjectiveClosedStatus) {
        ilib_LogEvent.push(LOG_TITLE + 'performCloseObjectivesAndAction'); //CMSI-213
        Map<Id,List<Task>> mapPlanIdToTask =new Map<Id,List<Task>>();
        Set<Id> setPlanWithError=new Set<Id>();
        List<Task> lstTasksToUpdate = new List<Task>();
        List<Plan_Objective__c> lstPlanObjectivesToUpdate =new List<Plan_Objective__c>();

         //Iterating over Tasks.
         for(Task task: lstTasks) {
            String strSubject=task.Subject;
            if(task.Status!=TASK_STATUS_COMPLETED && strSubject!=null && strSubject.containsIgnoreCase(TASK_SUBJECT_CALL) && task.RecordType.DeveloperName==TASK_SALES_RECORDTYPE_NAME && mapObjectiveIdPlanId.containsKey(task.WhatId) && (task.WhoId==null||task.Call_Result__c==null)) {
                setPlanWithError.add(mapObjectiveIdPlanId.get(task.WhatId));
            } 
            if(!mapPlanIdToTask.containsKey(mapObjectiveIdPlanId.get(task.WhatId))) {
                mapPlanIdToTask.put(mapObjectiveIdPlanId.get(task.WhatId),new List<Task>());
            }
            mapPlanIdToTask.get(mapObjectiveIdPlanId.get(task.WhatId)).add(task);
        }


        for(Plan__c objPlan:lstPlan) {
            if(setPlanIdsWithoutObjectiveClosedStatus.contains(objPlan.Id)) {
                objPlan.addError(Label.AddClosedStatusPlanObjectiveError);
            } else if(mapPlanIdToObjectives.containsKey(objPlan.Id)) {
                lstPlanObjectivesToUpdate.addAll(mapPlanIdToObjectives.get(objPlan.Id));
            }

            if(setPlanWithError.contains(objPlan.Id)) {
                    objPlan.addError(Label.AddClosedActionError);
            } else if(mapPlanIdToTask.containsKey(objPlan.Id)) {
                    lstTasksToUpdate.addAll(mapPlanIdToTask.get(objPlan.Id));
            }
        } 
        Set<Id> taskownIds = UtilsCollection.getSetOfIds(lstTasksToUpdate, 'OwnerId'); //CMSI-213
        Set<Id> planname = UtilsCollection.getSetOfIds(lstPlanObjectivesToUpdate, 'Name'); //CMSI-213
        ilib_LogEvent.info('Task To Update:'+taskownIds + 'Plan Objectives To Update:'+planname); //CMSI-213

        //Splitting for Code Scan Issue.
        callFutureUpdateForObjectiveAndActions(lstTasksToUpdate,lstPlanObjectivesToUpdate);
        ilib_LogEvent.pop(); //CMSI-213
        
    }

    /*
    *  @author       : Nishan Shetty
    *  @description  : Method to update Objective and Actions in Future DCP-50978
    *  @param        : lstTasksToUpdate -List of Task Records To Update.
    *  @param        : lstPlanObjectivesToUpdate- List of Plan Objectives To Update.
    */
    public static void callFutureUpdateForObjectiveAndActions( List<Task> lstTasksToUpdate, List<Plan_Objective__c> lstPlanObjectivesToUpdate) {
        ilib_LogEvent.push(LOg_TITLE + 'callFutureUpdateForObjectiveAndActions'); //CMSI-213
        if(!lstTasksToUpdate.isEmpty()||!lstPlanObjectivesToUpdate.isEmpty()) {
            CloseRelatedObjectives.performClosureForPlanObjectiveAndTask(JSON.serialize(lstTasksToUpdate),JSON.serialize(lstPlanObjectivesToUpdate));
        }
        ilib_LogEvent.pop(); //CMSI-213
    }




}