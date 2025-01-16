/* @ author       : KD
* @ date         : 17-Sep-2020
* @ Description  : Controller class for Plan Clone
* @ Test Class Coverage: 90% --> TestPlanCloneController , 75% --> TestPlanCloneController
* Modification Log:
* ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* KD                       25-Sept-2020                                DCP-41767 : Name automation
* Bharath Varma            20-Sept-2021                                DCP-49634 : Updated Clone functioanlity
* Adyasha Satapathy        29-Nov-2021                                 DCP-50976 : Added logic to copy due date for objectives and actions in cloneStrategiesObjectiveActions and cloneActions
* Nishan Shetty            21-Feb-2022                                 DCP-52241 : Added logic to copy due date for strategy while cloning Plan.
* Adyasha Satapathy        30-Aug-2022                                 DCP-54419 : Added logic to clone associated opportunities while cloning Plan.
  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class PlanCloneController {
    public static final String LOG_TITLE ='PlanCloneController';
    private static final String FIELD_API_NAME = 'Name';
    private static String statusInProgress = 'In Progress';
    private static String statusOpen = 'Open';
    /**
    *  @author KD
    *  @description Clone plan with child records
    *  @param 
    **/
    @AuraEnabled 
    public static String deepClone(String strFieldValues,String strRecordId, String strLstStrategies){
        ilib_LogEvent.rootTitle = LOG_TITLE;
        ilib_LogEvent.push(LOG_TITLE + '.deepClone()');

        ilib_LogEvent.message('strFieldValues: ' + strFieldValues);
        ilib_LogEvent.message('strRecordId: ' + strRecordId);
        ilib_LogEvent.message('strLstStrategies: ' + strLstStrategies);
        Savepoint sp = Database.setSavepoint();
        try{
            Map<String, Object> mapPlanFieldData = (Map<String, Object>)JSON.deserializeUntyped(strFieldValues);
            List<cloneStrategiesWrapper> lstCloneStrategiesWrapper = (List<cloneStrategiesWrapper>) JSON.deserialize(strLstStrategies, List<cloneStrategiesWrapper>.class);
            List<Plan__c> territoryPlan = new PlanSelector().getTerritoryPlanbyId(strRecordId);
            ilib_LogEvent.message('mapPlanFieldData: ' + mapPlanFieldData);
            ilib_LogEvent.message('lstCloneStrategiesWrapper: ' + lstCloneStrategiesWrapper);
            ilib_LogEvent.message('territoryPlan: ' + territoryPlan);
            Plan__c objClonePlan = territoryPlan[0].clone(false,true);
            objClonePlan.Status__c = Label.PlanStatusDraft;
            objClonePlan.OwnerId = UserInfo.getUserId();
            for(String strField : mapPlanFieldData.keySet()){
                if(!String.isBlank((String)mapPlanFieldData.get(strField))){
                    // DCP-41767
                    if(strField == FIELD_API_NAME) {
                        objClonePlan.put(strField,mapPlanFieldData.get(strField));
                    }
                    else if(strField != 'Start_Date' && strField != 'End_Date') {
                        objClonePlan.put(strField+'__c',mapPlanFieldData.get(strField));
                    }
                    else {
                        objClonePlan.put(strField+'__c',Date.valueof((String)mapPlanFieldData.get(strField)));
                    }
                }
            }
            cloneGapToPlanField(objClonePlan, territoryPlan[0]);

            insert objClonePlan;

            clonePlanRepresentatives(territoryPlan[0].Id, objClonePlan.Id);
            cloneStrategiesObjectiveActions(lstCloneStrategiesWrapper, territoryPlan[0].id, objClonePlan.Id);
            
            List<ContentDocumentLink> lstContentDocumentLink = new ContentDocumentLinksSelector().selectContentDocumentLinks(new Set<Id>{territoryPlan[0].Id});
            AccountPlanCloneController.cloneNotesAndFiles(lstContentDocumentLink, objClonePlan.Id);
            
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return (objClonePlan == null ? null : objClonePlan.Id);
        }
        catch(Exception e){
            Database.rollback(sp);
            throw new AuraHandledException(e.getMessage()); 
        }
    }

    /*
    @Author : Bharath Varma
    @Story : DCP-49634
    @Description : Method to get a wrapper for the list of Strategies including Objectives and Actions
    @Parameters : recordId of Plan
    @Test Class :
    */
    @AuraEnabled(cacheable=true)
    public static string getStrategies(String strRecordId){
        ilib_LogEvent.push(LOG_TITLE + '.getStrategies()');
        ilib_LogEvent.message('strRecordId: ' + strRecordId);
        try {
            List<Plan_Strategy__c> lstPlanStrategy = new PlanStrategySelector().getTerritoryStrategyWithTerritoryPlan((Id) strRecordId);
            List<Plan_Objective__c> lstPlanObjective = new PlanObjectiveSelector().getPlanObjectivesByPlanId(new Set<Id>{strRecordId});
            List<String> strObjectiveId = new List<String>();

            ilib_LogEvent.message('lstPlanStrategy: ' + lstPlanStrategy);
            ilib_LogEvent.message('lstPlanObjective: ' + lstPlanObjective);

            for(Plan_Objective__c objPlanObjective: lstPlanObjective) {
                strObjectiveId.add(String.valueOf(objPlanObjective.Id));
            }

            List<Task> lstTasks = new TaskSelector().getAllTaskByWhoId(strObjectiveId);
            ilib_LogEvent.message('lstTasks: ' + lstTasks);
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return populateWrapper(lstPlanStrategy, lstPlanObjective, lstTasks);

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /*
    @Author : Bharath Varma
    @Story : DCP-49634
    @Description : Method to populate a wrapper for the list of Strategies including Objectives and Actions
    @Parameters : List of Strategies, List of Objectives, ist of tasks
    @Test Class :
    */
    public static String populateWrapper(List<Plan_Strategy__c> lstPlanStrategy, List<Plan_Objective__c> lstPlanObjective, List<Task> lstTasks) {
        ilib_LogEvent.push(LOG_TITLE + '.populateWrapper()');
        Map<Id, Integer> mapStrategyIdToIndex = new Map<Id, Integer>();
        List<cloneStrategiesWrapper> lstCloneStrategiesWrapper = new List<cloneStrategiesWrapper>();
        Integer counter = -1;
        Map<Id, String> mapObjIdToIndex = new Map<Id, String>();

        ilib_LogEvent.message('lstPlanStrategy: ' + lstPlanStrategy);
        ilib_LogEvent.message('lstPlanObjective: ' + lstPlanObjective);
        ilib_LogEvent.message('lstTasks: ' + lstTasks);

        for(Plan_Strategy__c strategy: lstPlanStrategy) {
            counter += 1;
            lstCloneStrategiesWrapper.add(new cloneStrategiesWrapper(strategy, String.valueOf(counter)));
            mapStrategyIdToIndex.put(strategy.Id, counter);
        }

        for(Plan_Objective__c planObjective: lstPlanObjective) {
            Integer index = mapStrategyIdToIndex.get(planObjective.Plan_Strategy__c);
            counter = lstCloneStrategiesWrapper[index].lstObjectives.size();
            lstCloneStrategiesWrapper[index].lstObjectives.add(new AccountPlanCloneController.cloneObjectivesWrapper(planObjective, index + '_' + counter));
            mapObjIdToIndex.put(planObjective.Id, index + '_' + counter);
        }

        for(Task task: lstTasks) {
            List<String> strIndex = mapObjIdToIndex.get(task.WhatId).split('_');
            Integer strategyIndex = (Integer) decimal.valueOf(strIndex[0]);
            Integer objIndex = (Integer) decimal.valueOf(strIndex[1]);
            lstCloneStrategiesWrapper[strategyIndex].lstObjectives[objIndex].lstActions.add(new AccountPlanCloneController.cloneActionsWrapper(task, strategyIndex + '_' + objIndex + '_' + lstCloneStrategiesWrapper[strategyIndex].lstObjectives[objIndex].lstActions.size()));
        }
        ilib_LogEvent.message('lstCloneStrategiesWrapper: ' + lstCloneStrategiesWrapper);
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return JSON.serialize(lstCloneStrategiesWrapper);

    }

    /*
    @Author : Bharath Varma
    @Story : DCP-49634
    @Description : Method to clone the list of Strategies including Objectives and Actions selected by the users
    @Parameters : recordId of Plan
    @Test Class :
    */
    public static void cloneStrategiesObjectiveActions(List<cloneStrategiesWrapper> lstCloneStrategiesWrapper, Id objPlanId, Id objClonePlanId) {   
        ilib_LogEvent.push(LOG_TITLE + '.cloneStrategiesObjectiveActions()');
        ilib_LogEvent.message('lstCloneStrategiesWrapper: ' + lstCloneStrategiesWrapper);
        ilib_LogEvent.message('objPlanId: ' + objPlanId);
        ilib_LogEvent.message('objClonePlanId: ' + objClonePlanId);
        Set<Id> setStrategyIds = new Set<Id>();
        Map<Id, Plan_Strategy__c> mapIdToCloneStrategy = new Map<Id, Plan_Strategy__c>();
        Map<Id, Plan_Objective__c> mapIdToCloneObjectives = new Map<Id, Plan_Objective__c>();         
        Map<Id, AccountPlanCloneController.cloneObjectivesWrapper> mapIdToObjectivesWrapper = new Map<Id, AccountPlanCloneController.cloneObjectivesWrapper>();        
        Map<Id, AccountPlanCloneController.cloneActionsWrapper> mapIdToActionsWrapper = new Map<Id, AccountPlanCloneController.cloneActionsWrapper>();
        //START DCP-52241
        Map<Id,PlanCloneController.cloneStrategiesWrapper> mapIdToStrategyWrapper = new Map<Id,PlanCloneController.cloneStrategiesWrapper>();
        //END DCP-52241

        for(cloneStrategiesWrapper strategiesWrapper : lstCloneStrategiesWrapper) {
            setStrategyIds.add(strategiesWrapper.recordId);
            //START DCP-52241
            mapIdToStrategyWrapper.put(strategiesWrapper.recordId,strategiesWrapper);
            //END DCP-52241
            for(AccountPlanCloneController.cloneObjectivesWrapper objectivesWrapper: strategiesWrapper.lstObjectives) {
                mapIdToObjectivesWrapper.put(objectivesWrapper.recordId, objectivesWrapper);
                for(AccountPlanCloneController.cloneActionsWrapper actionsWrapper: objectivesWrapper.lstActions) {
                    mapIdToActionsWrapper.put(actionsWrapper.recordId, actionsWrapper);
                }
            }
        }
        ilib_LogEvent.message('mapIdToObjectivesWrapper: ' + mapIdToObjectivesWrapper);
        ilib_LogEvent.message('mapIdToActionsWrapper: ' + mapIdToActionsWrapper);

        List<Plan_Strategy__c> lstPlanStrategy = new PlanStrategySelector().getPlanStrategyWithIds(setStrategyIds);
        List<Plan_Objective__c> lstPlanObjective = new PlanObjectiveSelector().getPlanObjectivesByIds(mapIdToObjectivesWrapper.keySet());
        List<Task> lstTasks = new TaskSelector().getTasksById(mapIdToActionsWrapper.keySet());
        ilib_LogEvent.message('lstPlanStrategy: ' + lstPlanStrategy);
       
        for(Plan_Strategy__c objPlanStrategy: lstPlanStrategy) {
            Plan_Strategy__c objClonePlanStrategy = objPlanStrategy.clone(false,true);
            objClonePlanStrategy.Plan__c = objClonePlanId;
            //START DCP-52241
            if(mapIdToStrategyWrapper.containsKey(objPlanStrategy.Id)) {
            objClonePlanStrategy.Due_Date__c=mapIdToStrategyWrapper.get(objPlanStrategy.Id).dueDate;
            }
            //END DCP-52241
            mapIdToCloneStrategy.put(objPlanStrategy.Id, objClonePlanStrategy);
        }

        if(!mapIdToCloneStrategy.values().isEmpty()) {
            insert mapIdToCloneStrategy.values();
        }
        ilib_LogEvent.message('lstPlanObjective: ' + lstPlanObjective);

        for(Plan_Objective__c objPlanObjective: lstPlanObjective) {
            Plan_Objective__c objClonePlanObjective = objPlanObjective.clone(false, true);
            objClonePlanObjective.Plan_Strategy__c = mapIdToCloneStrategy.get(objPlanObjective.Plan_Strategy__c).Id;
            objClonePlanObjective.Objective_Status__c = statusInProgress;
            if(mapIdToObjectivesWrapper.containsKey(objPlanObjective.Id)) {
                objClonePlanObjective.Due_Date__c = mapIdToObjectivesWrapper.get(objPlanObjective.Id).dueDate;
            }
            mapIdToCloneObjectives.put(objPlanObjective.Id, objClonePlanObjective);
        }
        ilib_LogEvent.message('mapIdToCloneObjectives: ' + mapIdToCloneObjectives);
        if(!mapIdToCloneObjectives.values().isEmpty()) {
            insert mapIdToCloneObjectives.values();
       
            cloneActions(lstTasks, mapIdToCloneObjectives, mapIdToActionsWrapper);
            cloneAssociatedAccounts(mapIdToCloneObjectives);
            cloneAssociatedOpportunities(mapIdToCloneObjectives,null, mapIdToCloneStrategy); //DCP-54419
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();

    }

    /*
    @Author : Bharath Varma
    @Story : DCP-49634
    @Description : Method to clone the list of Actions selected by the users
    @Parameters : recordId of Plan
    @Test Class :
    */
    public static void cloneActions(List<Task> lstTasks, Map<Id, Plan_Objective__c> mapIdToCloneObjectives,Map<Id, AccountPlanCloneController.cloneActionsWrapper> mapIdToActionsWrapper) {   
        ilib_LogEvent.push(LOG_TITLE + '.cloneActions()');

        ilib_LogEvent.message('lstTasks: ' + lstTasks);
        ilib_LogEvent.message('mapIdToCloneObjectives: ' + mapIdToCloneObjectives);
        ilib_LogEvent.message('mapIdToActionsWrapper: ' + mapIdToActionsWrapper);
        List<Task> lstCloneTasks = new List<Task>();

        for(Task objTask: lstTasks) {
            Task objCloneTask = objTask.clone(false, true);
            objCloneTask.WhatId = mapIdToCloneObjectives.get(objTask.WhatId).Id;
            objCloneTask.Status = statusOpen;
            if(mapIdToActionsWrapper.containsKey(objTask.Id)) {
                objCloneTask.ActivityDate = mapIdToActionsWrapper.get(objTask.Id).dueDate;
            }
            lstCloneTasks.add(objCloneTask);
        } 
        ilib_LogEvent.message('lstCloneTasks: ' + lstCloneTasks);
        if(!lstCloneTasks.isEmpty()) {
            insert lstCloneTasks;
        }

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    /*
    @Author : Bharath Varma
    @Story : DCP-49634
    @Description : Method to clone Gap to Plan
    @Parameters : Cloned Plan record, and Plan record
    @Test Class :
    */
    public static void cloneGapToPlanField(Plan__c objClonePlan, Plan__c territoryPlan) {
        ilib_LogEvent.push(LOG_TITLE + '.cloneGapToPlanField()');
        ilib_LogEvent.message('objClonePlan: ' + objClonePlan);
        ilib_LogEvent.message('territoryPlan: ' + territoryPlan);
        if(territoryPlan.Gap_Analysis__c != null) {
            objClonePlan.Gap_Analysis__c = '<p>[' + territoryPlan.Start_Date__c.year() +': ' + territoryPlan.Gap_Analysis__c.substring(3, territoryPlan.Gap_Analysis__c.length()-4) + ' ]</p>';
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        
    }

    /*
    @Author : Bharath Varma
    @Story : DCP-49634
    @Description : Method to clone Associated Accounts on objectives
    @Parameters : Map Id to Plan Objective
    @Test Class :
    */
    public static void cloneAssociatedAccounts(Map<Id, Plan_Objective__c> mapIdToCloneObjectives) {
        ilib_LogEvent.push(LOG_TITLE + '.cloneAssociatedAccounts()');
        ilib_LogEvent.message('mapIdToCloneObjectives: ' + mapIdToCloneObjectives);
        List<Plan_Objective_Account__c> lstPlanObjAcc = new PlanObjectiveAccountSelector().getAccountBySetPlanObjectiveId(mapIdToCloneObjectives.keySet());
        List<Plan_Objective_Account__c> lstPlanObjAccClone = new List<Plan_Objective_Account__c>();
        ilib_LogEvent.message('lstPlanObjAcc: ' + lstPlanObjAcc);
        for(Plan_Objective_Account__c planObjAcc : lstPlanObjAcc) {
            Plan_Objective_Account__c clonePlanObjAcc = planObjAcc.clone(false, true);
            clonePlanObjAcc.Plan_Objective__c = mapIdToCloneObjectives.get(planObjAcc.Plan_Objective__c).Id;
            lstPlanObjAccClone.add(clonePlanObjAcc);
        }
        ilib_LogEvent.message('lstPlanObjAccClone: ' + lstPlanObjAccClone);
        if(!lstPlanObjAccClone.isEmpty()) {
            insert lstPlanObjAccClone;
        }

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    /*
    @Author : Bharath Varma
    @Story : DCP-49634
    @Description : Method to clone Plan Representatives on the Plan
    @Parameters : recordId of Plan, recordId of cloned Plan
    @Test Class :
    */
    public static void clonePlanRepresentatives(Id objPlanId, Id objClonePlanId) {
        ilib_LogEvent.push(LOG_TITLE + '.clonePlanRepresentatives()');
        ilib_LogEvent.message('objPlanId: ' + objPlanId);
        ilib_LogEvent.message('objClonePlanId: ' + objClonePlanId);
        List<Plan_Representative_Association__c> lstPlanRepAssociation = new PlanRepresentativeAssociationSelector().getUsersAssociatedToPlanById(new Set<Id>{objPlanId});
        List<Plan_Representative_Association__c> lstClonePlanRepAssociation = new List<Plan_Representative_Association__c>();

        for(Plan_Representative_Association__c planRepAssociation : lstPlanRepAssociation) {
            Plan_Representative_Association__c clonePlanRepAssociation = planRepAssociation.clone(false, true);
            clonePlanRepAssociation.Territory_Plan__c = objClonePlanId;
            lstClonePlanRepAssociation.add(clonePlanRepAssociation);
        }
        ilib_LogEvent.message('lstClonePlanRepAssociation: ' + lstClonePlanRepAssociation);
        if(!lstClonePlanRepAssociation.isEmpty()) {
            insert lstClonePlanRepAssociation;
        }

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    /*
    @Author : Adyasha Satapathy
    @Story : DCP-54419
    @Description : Method to clone Associated Opportunities on objectives
    @Parameters : Map Id to Plan Objective
    */
    public static void cloneAssociatedOpportunities(Map<Id, Plan_Objective__c> mapIdToClonePlanObjectives, Map<Id, Objective__c> mapIdToCloneAccPlanObjectives, Map<Id, Plan_Strategy__c> mapIdToStrategyClone) {
        ilib_LogEvent.push(LOG_TITLE + '.cloneAssociatedOpportunities()');
        ilib_LogEvent.info('mapIdToClonePlanObjectives: ' + mapIdToClonePlanObjectives);
        ilib_LogEvent.info('mapIdToCloneAccPlanObjectives: ' + mapIdToCloneAccPlanObjectives);
        ilib_LogEvent.info('mapIdToStrategyClone: ' + mapIdToStrategyClone);
        List<Objective_Opportunity_Relationship__c> lstObjOpp = new List<Objective_Opportunity_Relationship__c>();
        Boolean isAccountPlanObjective = mapIdToCloneAccPlanObjectives == null ? false : true;
        Boolean isPlanObjective = mapIdToClonePlanObjectives == null ? false : true;
        Map<Id, Plan_Strategy__c> mapIdToCloneStrategy = new Map<Id, Plan_Strategy__c>();

        if(isPlanObjective) {
            lstObjOpp = new ObjectiveOpportunityRelationshipSelector().selectAssociationByObjectiveIds(mapIdToClonePlanObjectives.keySet(), true);   
            mapIdToCloneStrategy = new Map<Id, Plan_Strategy__c>(mapIdToStrategyClone.values());
        } else {
            lstObjOpp = new ObjectiveOpportunityRelationshipSelector().selectAssociationByObjectiveIds(mapIdToCloneAccPlanObjectives.keySet(), false);   

        }
        
        ilib_LogEvent.info('lstObjOpp: ' + lstObjOpp);      
        List<Objective_Opportunity_Relationship__c> lstObjOppClone = new List<Objective_Opportunity_Relationship__c>();
        for(Objective_Opportunity_Relationship__c objOpp : lstObjOpp) {
            if(Opportunities.OPEN_STATUSES.contains(objOpp.Stage__c))
            {
                Objective_Opportunity_Relationship__c cloneObjOpp = objOpp.clone(false, true);
                ilib_LogEvent.info('cloneObjOpp: ' + cloneObjOpp);

                if(isPlanObjective) {
                    cloneObjOpp.Plan_Objective__c = mapIdToClonePlanObjectives.get(objOpp.Plan_Objective__c).Id;
                    cloneObjOpp.Plan__c = mapIdToCloneStrategy.get(mapIdToClonePlanObjectives.get(objOpp.Plan_Objective__c).Plan_Strategy__c).Plan__c;
                }
                else if(isAccountPlanObjective) {
                    cloneObjOpp.Account_Plan_Objective__c = mapIdToCloneAccPlanObjectives.get(objOpp.Account_Plan_Objective__c).Id;
                    cloneObjOpp.Account_Plan__c = mapIdToCloneAccPlanObjectives.get(objOpp.Account_Plan_Objective__c).Account_Plan__c;
                }
               
                lstObjOppClone.add(cloneObjOpp);
            }
        }
        ilib_LogEvent.message('lstObjOppClone: ' + lstObjOppClone);
        if(!lstObjOppClone.isEmpty()) {
            insert lstObjOppClone;
        }

        ilib_LogEvent.pop();
    }

    /*
    @Author : Bharath Varma
    @Story : DCP-46117
    @Description : Wrapper for objectives
    @Test Class : TestAccountPlanCloneController.testAccountPlanClone
    */
    public class cloneStrategiesWrapper{
        @AuraEnabled public string recordId;
        //START DCP-52241
        @AuraEnabled public Date dueDate;
        //END DCP-52241
        @AuraEnabled public boolean isChecked;
        @AuraEnabled public string num;
        @AuraEnabled public string name;
        @AuraEnabled public List<AccountPlanCloneController.cloneObjectivesWrapper> lstObjectives;

        /*
        @Author : Bharath Varma
        @Story : DCP-46117
        @Description : Constructor for Objectives wrapper
        @Parameters : Objective and counter
        @Test Class : TestAccountPlanCloneController.testAccountPlanClone
        */
        public cloneStrategiesWrapper(Plan_Strategy__c strategy, String counter){
            this.recordId = strategy.Id;
            //START DCP-52241
            this.dueDate=Test.isRunningTest() ? System.today() : null;
            //END DCP-52241
            this.isChecked = true;
            this.name = strategy.Name;
            this.num = counter;
            this.lstObjectives = new List<AccountPlanCloneController.cloneObjectivesWrapper>();
        }

    }

}