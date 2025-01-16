/**
*    @author: Kushagra Desai
*    @date:   19-Sept-2019
*    @description:  Controller class for AccountPlanObjectives LWC.
*    @Test Class Coverage: 90% --> TestAccountPlanObjectivesController , 75% --> TestAccountPlanObjectivesController
*    Modification Log:
*    -----------------------------------------------------------------------------------
*     Developer                       Date                 Description
        KD                            6-Aug-2020           DCP-39561 added method to support cloning of Plan objectives
        KD                            31-Aug-2020          DCP-40334 : Automation of Objective creation from associated account
        Bharath Varma                 22-Feb-2021          DCP-43570 : Added logic for passing Product_Type__c
        Bharath Varma                 09-Jun-2021          DCP-46115 : Added logic to create multiple tasks at once
        Ashwin Kumar                  24-Aug-2021          TASK0587523 : Updated ObjectTerritory2AssociationsSelector.selectOnlyDirectByAccountId method to accept List param
        Adyasha                       02-Dec-2021          DCP-50392 : Added labels for plan associated opportunities functionality
        Adyasha                       24-Mar-2022          DCP-52242 : Added labels for adding accounts and opportunities to Objectives
        Prem Ranjan                   04 May 2022          CodeScan Fix (APEX) Unused Local Variable
        Aman Tyagi                    31-Mar-2022          Codescan fixes
        Rucha Dalvi                   30-May-2022          DCP-52588 : Violation Reduction Sales(Q3)
        Pravallika                    05-Sep-2022          DCP-52623 : Added Comments Field to Objectives Wrapper
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class AccountPlanObjectivesController {

    private static final String LOG_TITLE = 'TerritoryPlanStrategyController';

    public static final String DUE_DATE = 'DueDate';
    /**
     * @author KD
     * @date   19-Sept-2019
     * @description   Initial data load
     */
    @AuraEnabled(cacheable = true)
    public static string initRecord(String recordId){
        ilib_LogEvent.push(LOG_TITLE + '.initRecord()');
        try{
            InitDataWrapper initdata = new InitDataWrapper();
            Account_Plan__c objAccountPlanInstance = new AccountPlanSelector().getAccountPlanByAccountPlanRecordId(recordId);
            List<Objective__c> lstobjective = new ObjectivesSelector().getObjectiveByAccountPlanIds(recordId);
            List<ObjectiveWrapper> lstObjWrapper = new List<ObjectiveWrapper>();
            for(Objective__c obj : lstobjective){
                ObjectiveWrapper objwrap = new ObjectiveWrapper(obj,objAccountPlanInstance);
                lstObjWrapper.add(objwrap);
            }
            initdata.strategy = objAccountPlanInstance.Illumina_Strategy__c;
            initdata.lstobjectiveWrap  = lstObjWrapper;
            ilib_LogEvent.message('----->List>'+initdata);
            Map<String,String> mapoflabels = new Map<String,string>{
                'UI_Objective_EditObjective' => Label.UI_Objective_EditObjective,
                'UI_Objective_Delete' => Label.UI_Objective_Delete,
                'UI_Objective_EditStrategy' => Label.UI_Objective_EditStrategy,
                'UI_Objective_NewObjective' => Label.UI_Objective_NewObjective,
                'UI_Objective_DeactivateObjective' => Label.UI_Objective_DeactivateObjective,
                'UI_Objective_Message' => Label.UI_Objective_Message,
                'UI_Task_Delete' => Label.UI_Task_Delete,
                'UI_Objective_Updated' => Label.UI_Objective_Updated,
                'UI_Error_Message_No_Territory_Plan' => Label.UI_Error_Message_No_Territory_Plan,
                'UI_Message_Available_Territory_Plan' => Label.UI_Message_Available_Territory_Plan,
                'UI_Label_Task_API' => Label.UI_Label_Task_API,
                'UI_Message_Task_Edit' => Label.UI_Message_Task_Edit,
                'UI_Modal_Header_Edit_Task' => Label.UI_Modal_Header_Edit_Task,
                'UI_Modal_Header_New_Task' => Label.UI_Modal_Header_New_Task,
                'UI_Message_Task_Create' => Label.UI_Message_Task_Create,
                'UI_Message_Task_Delete' => Label.UI_Message_Task_Delete,
                'UI_Message_Delete_Confirmation' => Label.UI_Message_Delete_Confirmation,
                'UI_Error_Message_System_Error' => Label.UI_Error_Message_System_Error,
                //Adding below labels for DCP-50392
                'UI_Message_No_Objective_Opportunities' => Label.UI_Message_No_Objective_Opportunities,
                'UI_Label_No_Search_Result_Objective_Opportunity' => Label.UI_Label_No_Search_Result_Objective_Opportunity,
                'UI_Label_List_Objective_Opportunity' => Label.UI_Label_List_Objective_Opportunity,
                'UI_Label_No_Opportunity' => Label.UI_Label_No_Opportunity,
                'UI_Label_Create_Objective' => Label.UI_Label_Create_Objective,
                'UI_Label_No_Account_For_Adding_Opportunity' => Label.UI_Label_No_Account_For_Adding_Opportunity,
                'UI_Label_No_Row_Selected' => Label.UI_Label_No_Row_Selected,
                // End of DCP-50392
                // Added for DCP-52242                
                'UI_Label_Add_Account' => Label.UI_Label_Add_Account,
                'UI_Label_Add_Opportunity' => Label.UI_Label_Add_Opportunity,
                'UI_Label_Segmentation_Selection_Field_Customer_Type' => Label.UI_Label_Segmentation_Selection_Field_Customer_Type,
                'UI_Label_City' => Label.UI_Label_City,
                'UI_Search' => Label.UI_Search,
                'UI_Label_Customer_ERP_Number' => Label.UI_Label_Customer_ERP_Number,
                'UI_Label_Account_Name' => Label.UI_Label_Account_Name,
                'UI_Reset' => Label.UI_Reset
                // End of DCP-52242
            };
            initdata.mapLabel = mapoflabels;
            String jsonInitdata = JSON.serialize(initdata);
            ilib_LogEvent.pop();
            return jsonInitdata;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage()); 
        }
    }
    /*
    * @author KD
     * @date   19-Sept-2019
    * Description : Delete Task
    */
    @AuraEnabled
    public static boolean deleteTask(String recordId){
        ilib_LogEvent.setTitle(LOG_TITLE);
        try{
            if(String.isnotblank(recordId)){
                List<Task> lstTask = new TaskSelector().getAllTask(recordId);
                Delete lstTask;
                ilib_LogEvent.emit();
                return true;
            }
            ilib_LogEvent.emit();
            return null;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage()); 
        }
    }
    /*
    * @author KD
     * @date   19-Sept-2019
    * Description : Create Task
    */
    @AuraEnabled
    public static boolean createTask(String taskData,String objectiveId, String selectedRec){
        ilib_LogEvent.push(LOG_TITLE + '.createTask()');
        try{
            String strObjectiveid = objectiveId;
            ilib_LogEvent.message('Objective id -->'+strObjectiveid);
            ilib_LogEvent.message('JSON--->'+taskData);
            Map<String, Object> mapTaskFieldData = (Map<String, Object>)JSON.deserializeUntyped(taskData);
            ilib_LogEvent.message('map map map-->'+mapTaskFieldData);
            ilib_LogEvent.message('Task id -->'+mapTaskFieldData.get('TaskId'));
            List<Id> lstUsersSelected = (List<Id>) JSON.deserialize(selectedRec, List<Id>.class); //DCP-46115
            List<Task> lstTasks = new List<Task>(); //DCP-46115

            if((Id)mapTaskFieldData.get('TaskId') != null){
                // Update task action
                ilib_LogEvent.message('JSON Update--->'+taskData);
                Task tsk = new Task(
                    id = (Id)mapTaskFieldData.get('TaskId'),
                    Subject = (String)mapTaskFieldData.get('Subject'),
                    Description = (String)mapTaskFieldData.get('Descrition'),
                    Status = (String)mapTaskFieldData.get('Status'),
                    Priority = (String)mapTaskFieldData.get('Priority'),
                    RecordTypeid = Schema.SObjectType.Task.getRecordTypeInfosByName().get(Label.TaskRecordTypeMarketing).getRecordTypeId()
                );
                tsk.ActivityDate = mapTaskFieldData.get(DUE_DATE) != null ? Date.valueof((String)mapTaskFieldData.get(DUE_DATE)) : null;
                if(mapTaskFieldData.containsKey('OwnerId'))
                    tsk.OwnerId = (Id)mapTaskFieldData.get('OwnerId');
                strObjectiveid = tsk.WhatId;
                upsert tsk;
            }
            else{
                // Create new Task
                for(Id userId: lstUsersSelected) { //DCP-46115
                    Task objNewTask = new Task();
                    objNewTask.WhatId = objectiveId;
                    objNewTask.Subject = (String)mapTaskFieldData.get('Subject');
                    objNewTask.ActivityDate = mapTaskFieldData.get(DUE_DATE) != null ? Date.valueof((String)mapTaskFieldData.get(DUE_DATE)) : null;
                    objNewTask.Description = (String)mapTaskFieldData.get('Descrition');
                    objNewTask.Status = (String)mapTaskFieldData.get('Status');
                    objNewTask.Priority = (String)mapTaskFieldData.get('Priority');
                    objNewTask.OwnerId = userId; //DCP-46115

                    lstTasks.add(objNewTask);
                }
                insert lstTasks;
            }
            ilib_LogEvent.pop();
            return true;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }

    }
    /**
     * @author KD
     * @date   19-Sept-2019
     * @description   Wrapper class to return initial page load value.
     */
    public class InitDataWrapper{
        @AuraEnabled public string strategy;
        @AuraEnabled public List<ObjectiveWrapper> lstobjectiveWrap;
        @auraEnabled public Map<String,String> mapLabel;
    }
    /**
     * @author KD
     * @date   19-Sept-2019
     * @description   Wrapper to store objective data
     */
    public class ObjectiveWrapper{
        @AuraEnabled public string recordid;
        @AuraEnabled public string name;
        @AuraEnabled public string owner;
        @AuraEnabled public Date dueDate;
        @AuraEnabled public string closedStatus ;
        @AuraEnabled public string objectiveStatus;
        @AuraEnabled public string priority;
        @AuraEnabled public string statusColor;
        @AuraEnabled public String actionCompleted;
        @AuraEnabled public String productType;
        @AuraEnabled public String comments; //DCP-52623
        
        /*
        * @Author: KD
        * @Description : parameterized constructor of class ObjectiveWrapper and instantiating Objective__c ,Account_Plan__c
        * @param : Objective__c obj,Account_Plan__c accPlan
        */
        public ObjectiveWrapper(Objective__c obj,Account_Plan__c accPlan){
            this.recordid = obj.id;
            this.name = 'Objective : '+obj.Name;
            this.owner = accPlan.Owner.Name;
            this.dueDate = obj.Due_Date__c;
            this.closedStatus = obj.Closed_Status__c;
            this.objectiveStatus = obj.Objective_Status__c;
            this.priority = obj.Priority__c;
            //DCP-52588 Fixing UselessStringValueOf Codescan Issue
            this.actionCompleted = obj.Action_Completed__c + ' %';
            //DCP-52588 Removing parentheses to fix Codescan Issue
            this.statusColor = obj.Objective_Status__c == 'At Risk' ? 'Red' : obj.Objective_Status__c == 'In Progress' ? 'Green' : 'Grey';
            this.productType = obj.Product_Type__c;
            this.comments = obj.Comments__c; //DCP-52623

        }
    }
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION:DCP-39561 Fetch all Plan Objective associated with account plan for association
    *  @PARAM :  Account Id and Account Plan id
    *  @RETURN: String
    // Updated as part of DCP-40334
    */
    @AuraEnabled
    public static string getAssociatedObjective(String strAccountId,String strAccountPlanId){
        ilib_LogEvent.setTitle(LOG_TITLE);
        try{
            List<TerritoryPlanStrategyController.PlanObjectiveWrapper> lstPlanObjectiveWrapper= new List<TerritoryPlanStrategyController.PlanObjectiveWrapper>();
            List<ObjectTerritory2Association> lstObjectTerritory2Association = new ObjectTerritory2AssociationsSelector().selectOnlyDirectByAccountId(new List<String> {strAccountId} );    //TASK0587523
            if(lstObjectTerritory2Association.isEmpty())
                throw new AuraHandledException(Label.UI_Error_Message_No_Territory_Account);
            List<Plan__c> lstPlan = new List<Plan__c>();
            String strTerritoryCode = lstObjectTerritory2Association[0].Territory2.Territory_Code__c;
            // DCP-40334
            lstPlan = new PlanSelector().getPlanbyTerritoryCodeStatus(strTerritoryCode,Label.AccountPlanStatusActive);
            if(lstPlan.isEmpty()){
                lstPlan = new PlanSelector().getPlanbyTerritoryCodeStatus(strTerritoryCode,Label.AccountPlanStatusDraft);
                if(lstPlan.isEmpty()) {
                    ilib_LogEvent.emit();
                    return JSON.serialize(lstPlanObjectiveWrapper); 
                }       
            }
            Set<Id> setPlanId = new Set<Id>();
            for(Plan__c objPlan : lstPlan) {
                setPlanId.add(objPlan.Id);
            }
            List<Plan_Objective__c> lstPlanObjective = new PlanObjectiveSelector().getPlanObjectivesByPlanId(setPlanId);
            List<Objective__c> lstObjective = new ObjectivesSelector().getObjectiveByAccountPlanWithAssociation(strAccountPlanId);
            Set<Id> setAssociatedPlanObjectiveIds = new Set<Id>();
            for(Objective__c objOb : lstObjective) {
                setAssociatedPlanObjectiveIds.add(objOb.Plan_Objective__c);
            }
            for(Plan_Objective__c objPlanObjective : lstPlanObjective) {
                if(!setAssociatedPlanObjectiveIds.contains(objPlanObjective.Id)) {
                    lstPlanObjectiveWrapper.add(new TerritoryPlanStrategyController.PlanObjectiveWrapper(objPlanObjective));
                }
            }
            ilib_LogEvent.emit();
            return JSON.serialize(lstPlanObjectiveWrapper);
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION: DCP-39561 Created Objective based onuser selection
    *  @PARAM :  List of AccountPlan Wrapper and Plan id
    *  @RETURN: String
     // Updated as part of DCP-40334
    */
    @AuraEnabled
    public static string createAccountObjective(String lstAccountPlanWrapper, String strPlanId){
        ilib_LogEvent.setTitle(LOG_TITLE);
        try{
            List<TerritoryPlanStrategyController.PlanObjectiveWrapper> lstlstAccountPlanObjectiveWrap = (List<TerritoryPlanStrategyController.PlanObjectiveWrapper>)JSON.deserialize(lstAccountPlanWrapper,List<TerritoryPlanStrategyController.PlanObjectiveWrapper>.class);
            List<Objective__c> lstObjective = new List<Objective__c>();
            for(TerritoryPlanStrategyController.PlanObjectiveWrapper objAPO : lstlstAccountPlanObjectiveWrap){
                Objective__c objObjective = new Objective__c();
                objObjective.Account_Plan__c = strPlanId;
                objObjective.Name = objAPO.objectiveName;
                objObjective.Priority__c = objAPO.priority;
                objObjective.Objective_Status__c = objAPO.objectiveStatus;
                objObjective.Due_Date__c = Date.valueof(objAPO.dueDate);
                objObjective.Plan_Objective__c = objAPO.strObjectId;
                objObjective.Closed_Status__c = objAPO.closedStatus;
                lstObjective.add(objObjective);
            }
            insert lstObjective;
            ilib_LogEvent.emit();
            return  Label.UI_Message_Objective_From_Plan_Create.replace('{0}',String.valueOf(lstObjective.size()));
        }
        catch(Exception e) {
           
            ApexExceptions.emit('AccountPlanObjectivesController',e);
            ilib_LogEvent.emit();
            //DCP-52588 Added to fix AuraEnabledWithoutCatchBlock Codescan Issue
            throw new AuraHandledException(e.getMessage());
        }
    }
}