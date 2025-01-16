/**
 *    @author Bharath Varma
 *    @date   07-Sep-2021
 *    @description : Account Plan Clone Controller to handle clone functionality
 *    @Test Class Coverage: 90% --> TestAccountPlanCloneController , 75% --> TestAccountPlanCloneController
 *    Modification Log:
 *   ---------------------------------------------------------------------------------------------------------------------------------------------
 *       Developer                        Date               Description
 *     Bharath Varma                   07-Sep-2021          Initial Version
 *     Adyasha Satapathy               26-Nov-2021          Added logic to copy due date for objectives and actions in cloneObjectivesAndActions
 *     Adyasha Satapathy               30-Aug-2022          DCP-54419 : Added logic to clone associated opportunities while cloning Account Plan.
 *     Atit Kar                        09-Dec-2022          INC0442456 - Populate Territory_Region__c field on Account Plan Object on cloning
 *    --------------------------------------------------------------------------------------------------------------------------------------------
 */

public with sharing class AccountPlanCloneController {
    private static String accountPlanAPI = 'Account_Plan__c';
    private static String fileType = 'SNOTE';
    private static String typeCurrency = 'CURRENCY';
    private static String typeDate = 'DATE';
    private static String typeString = 'STRING';
    private static String statusInProgress = 'In Progress';
    private static String statusOpen = 'Open';

    
    
    /*
    @Author : Bharath Varma
    @Story : DCP-46117
    @Description : Method to get the list of Objectives and Actions
    @Parameters : recordId and objectApiName
    @Test Class : TestAccountPlanCloneController.testAccountPlanClone
    */
    @AuraEnabled(cacheable=true)
    public static String getObjectivesAndActions(String strRecordId, String objectApiName) {
        try{
            Set<Id> setRecordId = new Set<Id>{(Id) strRecordId};
            List<String> strWhatId = new List<String>();
            List<Objective__c> lstObjective = new List<Objective__c>();

            if(objectApiName == accountPlanAPI) {
                lstObjective = new ObjectivesSelector().getObjectiveBySetAccountPlanIds(setRecordId);
                for(Objective__c objective: lstObjective) {
                    strWhatId.add(objective.Id);
                }
            }

            List<Task> lstTasks = new TaskSelector().getAllTaskByWhoId(strWhatId);

            return populateWrapper(lstObjective, lstTasks);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage()); 
        }
        
    }

    /*
    @Author : Bharath Varma
    @Story : DCP-46117
    @Description : Method to clone the child objects
    @Parameters : List of selected objectives and Actions, recordId, objectApiName
    @Test Class : TestAccountPlanCloneController.testAccountPlanClone
    */
    @AuraEnabled
    public static string cloneAccountPlan(String strPlanDetails) {
        Savepoint sp = Database.setSavepoint();
        try {
            Map<String, String> planDetails = (Map<String, String>) JSON.deserialize(strPlanDetails, Map<String, String>.class);
            System.debug('@@@ From js --> ' + planDetails.get('strLstObjectivesActions'));
            List<cloneObjectivesWrapper> lstCloneObjectivesWrapper = (List<cloneObjectivesWrapper>) JSON.deserialize(planDetails.get('strLstObjectivesActions'), List<cloneObjectivesWrapper>.class);
            Map<String, String> mapClonePlanDetails = (Map<String, String>) JSON.deserialize(planDetails.get('strClonePlanDetails'), Map<String, String>.class);
            System.debug('@@@ lstCloneObjectivesWrapper --> ' + lstCloneObjectivesWrapper);
            if(planDetails.get('objectApiName') == accountPlanAPI) {
                Account_Plan__c accountPlan = new AccountPlanSelector().getAccountPlanByAccountPlanRecordId(planDetails.get('strRecordId'));
                Account_Plan__c accountPlanClone = accountPlan.clone(false,true);
                accountPlanClone.Plan_Status__c = 'Draft';
                accountPlanClone.Account_Region__c = accountPlan.Account_Name__r.Territory_Region__c; //INC0442456
                Map<String, Schema.SObjectField> fieldMap = ((SObject)Type.forName('Schema',planDetails.get('objectApiName')).newInstance()).getSObjectType().getDescribe().fields.getMap();
                for(String fieldName: mapClonePlanDetails.keySet()){
                    String fielddataType = String.valueOf(fieldMap.get(fieldName).getDescribe().getType());
                    if(fielddataType == typeCurrency){
                        accountPlanClone.put(fieldName, mapClonePlanDetails.get(fieldName)==null? null : decimal.valueOf(mapClonePlanDetails.get(fieldName)));
                    }
                    else if(fielddataType == typeDate){
                        accountPlanClone.put(fieldName, mapClonePlanDetails.get(fieldName)==null? null : date.valueOf(mapClonePlanDetails.get(fieldName)));
                    }
                    else if(fielddataType == typeString) {
                        accountPlanClone.put(fieldName, mapClonePlanDetails.get(fieldName)==null? null : mapClonePlanDetails.get(fieldName));
                    }
                }
                
                accountPlanClone.OwnerId = UserInfo.getUserId();
                cloneGapToPlanField(accountPlanClone, accountPlan);

                insert accountPlanClone;

                cloneObjectivesAndActions(lstCloneObjectivesWrapper, accountPlanClone);
                cloneStakeholders(accountPlanClone, accountPlan.Id);
                
                List<ContentDocumentLink> lstContentDocumentLink = new ContentDocumentLinksSelector().selectContentDocumentLinks(new Set<Id>{accountPlan.Id});
                cloneNotesAndFiles(lstContentDocumentLink, accountPlanClone.Id);

                return String.valueOf(accountPlanClone.Id);
            }
            else{
                // Placeholder for plan
                return '';
            }
            
        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException(e.getMessage()); 
        }
            
    }

    /*
    @Author : Bharath Varma
    @Story : DCP-46117
    @Description : Method to clone GapToPlan
    @Parameters : account plan object
    @Test Class : TestAccountPlanCloneController.testAccountPlanClone
    */
    public static void cloneGapToPlanField(Account_Plan__c objClonePlan, Account_Plan__c accountPlan) {
        if(accountPlan.Gap_Analysis__c != null) {
            objClonePlan.Gap_Analysis__c = '<p>[' + accountPlan.Start_Date__c.year() +': ' + accountPlan.Gap_Analysis__c.substring(3, accountPlan.Gap_Analysis__c.length()-4) + ' ]</p>';
        }
        
    }

    /*
    @Author : Bharath Varma
    @Story : DCP-46117
    @Description : Method to clone stake holders
    @Parameters : cloned account plan object, frmer account plan Id
    @Test Class : TestAccountPlanCloneController.testAccountPlanClone
    */
    public static void cloneStakeholders(Account_Plan__c accountPlanClone, String accountPlanId) {
        List<Key_Stakeholder_Analysis__c> lstStakeholders = new StakeholdersSelector().selectStakeholders(accountPlanId);
        List<Key_Stakeholder_Analysis__c> lstStakeholdersClone = new List<Key_Stakeholder_Analysis__c>();

        for(Key_Stakeholder_Analysis__c stakeHolder: lstStakeholders){
            Key_Stakeholder_Analysis__c stakeHolderClone = stakeHolder.clone(false, true);
            stakeHolderClone.Account_Plan__c = accountPlanClone.Id;
            lstStakeholdersClone.add(stakeHolderClone);
        }

        if(!lstStakeholdersClone.isEmpty()){
            insert lstStakeholdersClone;
        }
    }

    /*
    @Author : Bharath Varma
    @Story : DCP-46117
    @Description : Method to clone the list of Objectives and Actions
    @Parameters : List of cloneObjectivesWrapper, newly cloned account plan object
    @Test Class : TestAccountPlanCloneController.testAccountPlanClone
    */
    public static void cloneObjectivesAndActions(List<cloneObjectivesWrapper> lstCloneObjectivesWrapper, Account_Plan__c accountPlanClone) {
        Map<Id, cloneObjectivesWrapper> mapIdToObjectivesWrapper = new Map<Id, cloneObjectivesWrapper>();        
        Map<Id, cloneActionsWrapper> mapIdToActionsWrapper = new Map<Id, cloneActionsWrapper>();        

        for(cloneObjectivesWrapper cloneObjWrapper: lstCloneObjectivesWrapper) {
            mapIdToObjectivesWrapper.put(cloneObjWrapper.recordId, cloneObjWrapper);
            for(cloneActionsWrapper action: cloneObjWrapper.lstActions) {
                mapIdToActionsWrapper.put(action.recordId,action);
            }
        }

        List<Objective__c> lstObjectivesToBeCloned = new ObjectivesSelector().getObjectivesBySetOfIds(mapIdToObjectivesWrapper.keySet());
        List<Task> lstTasksToBeCloned = new TaskSelector().getTasksById(mapIdToActionsWrapper.keySet());
        Map<Id, Objective__c> mapIdToCloneObjective = new Map<Id, Objective__c>();

        for(Objective__c objective: lstObjectivesToBeCloned) {
            Objective__c objectiveClone = objective.clone(false, true);
            objectiveClone.Account_Plan__c = accountPlanClone.Id;
            objectiveClone.Objective_Status__c = statusInProgress;
            objectiveClone.Due_Date__c = mapIdToObjectivesWrapper.get(objective.Id)?.dueDate;            
            mapIdToCloneObjective.put(objective.Id, objectiveClone);
        }
        if(!mapIdToCloneObjective.values().isEmpty()) {
            insert mapIdToCloneObjective.values();
            PlanCloneController.cloneAssociatedOpportunities(null,mapIdToCloneObjective,null); //DCP-54419
        }

        List<Task> lstCloneTasks = new List<Task>();
        for(Task task: lstTasksToBeCloned) {
            Task taskClone = task.clone(false, true);
            taskClone.WhatId = mapIdToCloneObjective.get(task.WhatId)?.Id;
            taskClone.Status = statusOpen;            
            taskClone.ActivityDate = mapIdToActionsWrapper.get(task.Id)?.dueDate;
            lstCloneTasks.add(taskClone);
        }

        if(!lstCloneTasks.isEmpty()){
            insert lstCloneTasks;
        }

    }

    /*
    @Author : Bharath Varma
    @Story : DCP-46117
    @Description : Method to create a wrapper for the list of Objectives and Actions
    @Parameters : List of Objectives and List of Tasks
    @Test Class : TestAccountPlanCloneController.testAccountPlanClone
    */
    public static string populateWrapper(List<Objective__c> lstObjective, List<Task> lstTasks) {
        Map<Id, Integer> mapObjIdToIndex = new Map<Id, Integer>();
        List<cloneObjectivesWrapper> lstCloneObjectivesWrapper = new List<cloneObjectivesWrapper>();
        Integer counter = -1;
        for(Objective__c objective: lstObjective) {
            counter += 1;
            lstCloneObjectivesWrapper.add(new cloneObjectivesWrapper(objective, String.valueOf(counter)));
            mapObjIdToIndex.put(objective.Id, counter);
        }
        counter = -1;
        for(Task task: lstTasks) {
            counter += 1;
            Integer index = mapObjIdToIndex.get(task.WhatId);
            lstCloneObjectivesWrapper[index].lstActions.add(new cloneActionsWrapper(task, index + '_' + lstCloneObjectivesWrapper[index].lstActions.size()));
        }

        return JSON.serialize(lstCloneObjectivesWrapper);


    }

    /*
    @Author : Bharath Varma
    @Story : DCP-46117
    @Description : Method to clone notes and files
    @Parameters : List of ContentDocumentLink, newly cloned plan id
    @Test Class : TestAccountPlanCloneController.testAccountPlanClone
    */
    public static void cloneNotesAndFiles(List<ContentDocumentLink> lstContentDocumentLink, Id objPlanCloneId) {
        Set<Id> setContentDocumentId = new Set<Id>();
        Map<id, ContentNote> mapContentNote = new Map<Id, ContentNote>();
        
        for(ContentDocumentLink contentDocumentLink : lstContentDocumentLink) {
            if(contentDocumentLink.ContentDocumentId != null && contentDocumentLink.ContentDocument.FileType == fileType) {
                setContentDocumentId.add(contentDocumentLink.ContentDocumentId);
            }
        }
        List<ContentNote> lstContentNote = new ContentNoteSelector().selectContentNotes(setContentDocumentId);

        List<ContentNote> lstContentNoteClone = new List<ContentNote>();

        for(ContentNote contentNote: lstContentNote) {
            ContentNote contentNoteClone = new ContentNote();
            contentNoteClone.Title = contentNote.Title;
            contentNoteClone.Content = contentNote.Content;
            lstContentNoteClone.add(contentNoteClone);
            mapContentNote.put(contentNote.Id, contentNoteClone);
        }
        if(!lstContentNoteClone.isEmpty()){
            insert lstContentNoteClone;
        }

        List<ContentDocumentLink> lstContentDocumentLinkClone = new List<ContentDocumentLink>();
        for(ContentDocumentLink contentDocumentLink : lstContentDocumentLink) {
            ContentDocumentLink contentDocumentLinkClone = contentDocumentLink.clone(false, true);
            if(contentDocumentLink.ContentDocument.FileType == fileType){
                contentDocumentLinkClone.ContentDocumentId = mapContentNote.get(contentDocumentLink.ContentDocumentId).Id;
            }
            contentDocumentLinkClone.LinkedEntityId = objPlanCloneId;
            lstContentDocumentLinkClone.add(contentDocumentLinkClone);
        }
        
        if(!lstContentDocumentLinkClone.isEmpty()){
            insert lstContentDocumentLinkClone;
        }

    }

    /*
    @Author : Bharath Varma
    @Story : DCP-46117
    @Description : Wrapper for objectives
    @Test Class : TestAccountPlanCloneController.testAccountPlanClone
    */
    public class cloneObjectivesWrapper{
        @AuraEnabled public string recordId;
        @AuraEnabled public boolean isChecked;
        @AuraEnabled public string num;
        @AuraEnabled public string name;
        @AuraEnabled public string objectiveStatus;
        @AuraEnabled public Date dueDate;
        @AuraEnabled public List<cloneActionsWrapper> lstActions;

        /*
        @Author : Bharath Varma
        @Story : DCP-46117
        @Description : Constructor for Objectives wrapper
        @Parameters : Objective and counter
        @Test Class : TestAccountPlanCloneController.testAccountPlanClone
        */
        public cloneObjectivesWrapper(Objective__c objective, String counter){
            this.recordId = objective.Id;
            this.isChecked = true;
            this.name = objective.Name;
            this.num = counter;
            this.lstActions = new List<cloneActionsWrapper>();
            this.objectiveStatus = objective.Objective_Status__c;
            this.dueDate = Test.isRunningTest() ? System.today() : null;

        }

        /*
        @Author : Bharath Varma
        @Story : DCP-49634
        @Description : Constructor for Plan Objectives wrapper
        @Parameters : PlanObjective and counter
        @Test Class : TestAccountPlanCloneController.testAccountPlanClone
        */
        public cloneObjectivesWrapper(Plan_Objective__c objective, String counter){
            this.recordId = objective.Id;
            this.isChecked = true;
            this.name = objective.Name;
            this.num = counter;
            this.lstActions = new List<cloneActionsWrapper>();
            this.objectiveStatus = objective.Objective_Status__c;
            this.dueDate = Test.isRunningTest() ? System.today() : null;

        }

    }

    /*
    @Author : Bharath Varma
    @Story : DCP-46117
    @Description : Wrapper for Actions
    @Test Class : TestAccountPlanCloneController.testAccountPlanClone
    */
    public class cloneActionsWrapper{
        @AuraEnabled public string recordId;
        @AuraEnabled public boolean isChecked;
        @AuraEnabled public string num;
        @AuraEnabled public string name;
        @AuraEnabled public string status;
        @AuraEnabled public Date dueDate;

        /*
        @Author : Bharath Varma
        @Story : DCP-46117
        @Description : Constructor for Actions Wrapper
        @Parameters : Task and counter
        @Test Class : TestAccountPlanCloneController.testAccountPlanClone
        */
        public cloneActionsWrapper(Task task, String counter){
            this.recordId = task.Id;
            this.isChecked = true;
            this.name = task.Subject;
            this.status = task.Status;
            this.num = counter;
        }
    }
}