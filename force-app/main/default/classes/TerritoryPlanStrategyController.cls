/**
 *    @author KD
 *    @date   25-July-2020
 *    @description : Controller class for Strategy Tab
 *    @Test Class Coverage: 90% --> TerritoryPlanStrategyController, TestAccountPlanObjectivesController & 75% --> TerritoryPlanStrategyController
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    KD                            19-Aug-2020          DCP-39127 : Added additional Labels
 *    KD                            31-Aug-2020          DCP-40334 : Automation of Objective creation from associated account
 *    KD                            21-Sept-2020         DCP-41752 : Account visibility for Channel partner
 *    Adyasha                       23-November-2021     DCP-50392 : Added labels for plan associated opportunities functionality
 *    Adyasha                       24-March-2022        DCP-52442 : Added labels for adding accounts and opportunities to Objectives
 *    Rucha Dalvi            31-May-2022                DCP-52588 : Violation Reduction Sales(Q3) Codescan Fix
 *    Nishan Shetty                  03-Jun-2022         DCP-50962 : Batch Manager Implementation DCP-50962.
 *    Pravallika Gundreddy           05-Sep-2022         DCP-52623 : Added Comments Field to Plan Objective Wrapper
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class TerritoryPlanStrategyController {

    private static final String LOG_TITLE = 'TerritoryPlanStrategyController';
    public static Map<string,Plan_Strategy__c> mapAllTerritoryStrategies = new Map<string,Plan_Strategy__c>();
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION: Fetch Strategy and labels
    *  @PARAM :  String Plan Id
    *  @RETURN:  JSON String
    */
    @AuraEnabled(cacheable = true)
    public static string initRecord(String recordId){
        ilib_LogEvent.setTitle(LOG_TITLE); 
        try{
            List<PlanStrategyWrapper> lstPlanWrapper = new List<PlanStrategyWrapper>();
            for(Plan_Strategy__c objTS : new PlanStrategySelector().getTerritoryStrategyWithTerritoryPlan(recordId) ){
                lstPlanWrapper.add(new PlanStrategyWrapper(objTS));
            }
            Map<String,String> mapLabels = new Map<String,string>{
                'UI_Message_No_Account_Plan_Objective' => Label.UI_Message_No_Account_Plan_Objective,
                'UI_Message_Delete_Confirmation' => Label.UI_Message_Delete_Confirmation,
                'UI_Message_Deactivate_Confirmation' => Label.UI_Message_Deactivate_Confirmation,
                'UI_Message_Task_Delete' => Label.UI_Message_Task_Delete,
                'UI_Message_Objective_Deactivated' => Label.UI_Message_Objective_Deactivated,
                'UI_Message_Strategy_Deactivated' => Label.UI_Message_Strategy_Deactivated,
                'UI_Message_APO_Delete' => Label.UI_Message_APO_Delete,
                'UI_Message_APO_Create' => Label.UI_Message_APO_Create,
                'UI_Message_Task_Create' => Label.UI_Message_Task_Create,
                'UI_Message_Objective_Create' => Label.UI_Message_Objective_Create,
                'UI_Message_Strategy_Create' => Label.UI_Message_Strategy_Create,
                'UI_Modal_Header_New_Strategy' => Label.UI_Modal_Header_New_Strategy,
                'UI_Modal_Header_New_Objective' => Label.UI_Modal_Header_New_Objective,
                'UI_Modal_Header_New_Task' => Label.UI_Modal_Header_New_Task,
                'UI_Modal_Header_Edit_Strategy' => Label.UI_Modal_Header_Edit_Strategy,
                'UI_Modal_Header_Edit_Objective' => Label.UI_Modal_Header_Edit_Objective,
                'UI_Modal_Header_Edit_Task' => Label.UI_Modal_Header_Edit_Task,
                'UI_Label_Strategy_API' => Label.UI_Label_Strategy_API,
                'UI_Label_Objective_API' => Label.UI_Label_Objective_API,
                'UI_Label_Task_API' => Label.UI_Label_Task_API,
                'UI_Message_Task_Edit' => Label.UI_Message_Task_Edit,
                'UI_Message_Objective_Edit' => Label.UI_Message_Objective_Edit,
                'UI_Message_Strategy_Edit' => Label.UI_Message_Strategy_Edit,
                // DCP-39127
                'UI_Label_No_Account'  => Label.UI_Label_No_Account,
                'UI_Label_No_Search_Result'  => Label.UI_Label_No_Search_Result,
                'UI_Label_No_Row_Selected' => Label.UI_Label_No_Row_Selected,
                'UI_Label_List_Account' => Label.UI_Label_List_Account,
                //Adding below labels for DCP-50392
                'UI_Message_No_Objective_Opportunities' => Label.UI_Message_No_Objective_Opportunities,
                'UI_Label_No_Search_Result_Objective_Opportunity' => Label.UI_Label_No_Search_Result_Objective_Opportunity,
                'UI_Label_List_Objective_Opportunity' => Label.UI_Label_List_Objective_Opportunity,
                'UI_Label_No_Opportunity' => Label.UI_Label_No_Opportunity,
                'UI_Label_Create_Objective' => Label.UI_Label_Create_Objective,
                'UI_Label_No_Account_For_Adding_Opportunity' => Label.UI_Label_No_Account_For_Adding_Opportunity,
                // End of DCP-50392
                // Added for DCP-52242
                'PlanOverlay' => Label.PlanOverlay,
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
            ilib_LogEvent.emit();
            return '{"lstStrategyWrap": '+JSON.serialize(lstPlanWrapper )+','
                    +' "mapLabels": '+JSON.serialize(mapLabels)+'}';
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());  
        }
    }
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION: Fetch Strategy
    *  @PARAM :  String Strategy Id
    *  @RETURN:  JSON String
    */
    @AuraEnabled(cacheable = true)
    public static string fetchStrategy(String strRecordid){
        ilib_LogEvent.setTitle(LOG_TITLE); 
        try{
            List<PlanStrategyWrapper> lstPlanWrapper = new List<PlanStrategyWrapper>();
            List<PlanObjectiveWrapper> lstPlanObjectiveWrapper = new List<PlanObjectiveWrapper>();
            list<Plan_Strategy__c> lstTS = new PlanStrategySelector().getPlanStrategyWithObjective(strRecordid);
            if(!lstTS.isEmpty()){
                lstPlanWrapper.add(new PlanStrategyWrapper(lstTS[0]));
                for(Plan_Objective__c objTO : lstTS[0].Plan_Objectives__r ){
                    lstPlanObjectiveWrapper.add(new PlanObjectiveWrapper(objTO));
                }
                ilib_LogEvent.emit();
                return '{"objPlanWrapper": '+JSON.serialize(lstPlanWrapper[0] )+','
                    +'"planRecordType": '+JSON.serialize(lstTS[0].Plan__r.RecordType.DeveloperName)+','
                    +'"objPlanObjectiveWrapper": '+JSON.serialize(lstPlanObjectiveWrapper)+'}';
            }
            ilib_LogEvent.emit();
            return null;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());  
        }   
    }
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION: Fetch Objective
    *  @PARAM :  String Objective Id
    *  @RETURN:  JSON String
    */
    @AuraEnabled(cacheable = true)
    public static String fetchObjective(String strRecordid){
        ilib_LogEvent.setTitle(LOG_TITLE); 
        try{
            Plan_Objective__c objTO = new PlanObjectiveSelector().getTerritoryObjectiveWithId(strRecordid);
            ilib_LogEvent.emit();
            return JSON.serialize(new PlanObjectiveWrapper(objTO));
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());  
        }
    }
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION: Fetch task related to objective
    *  @PARAM :  String Objective Id
    *  @RETURN:  JSON String
    */
    @AuraEnabled(cacheable = true)
    public static string fetchTaskList(String strRecordid){
        ilib_LogEvent.setTitle(LOG_TITLE); 
        try{
            list<ActionWrapper> lstActionWrapper = new list<ActionWrapper>();
            for(Task objTask :  new TaskSelector().getAllTaskByWhoId(new List<String>{strRecordid})){
                lstActionWrapper.add(new ActionWrapper(objTask));
            }
            ilib_LogEvent.emit();
            return '{"lstActionWrapper": '+JSON.serialize(lstActionWrapper)+'}';
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());  
        }
    }

    /*
    *  @AUTHOR:  Adyasha
    *  @DESCRIPTION: DCP-52242 - wired method for Fetch Accounts for Display
    *  @PARAM :  String strRecordId Objective Id
    *  @RETURN:  JSON String
    */
    @AuraEnabled(cacheable = true)
    public static string fetchAssociatedAccount(String strRecordId) {
        ilib_LogEvent.setTitle(LOG_TITLE); 
        try {
            ilib_LogEvent.emit();
            return getAssociatedAccountsData(strRecordId);
        }
        catch(Exception e) {
            throw new AuraHandledException(e.getMessage());  
        }
    }

    /*
    *  @AUTHOR:  Adyasha
    *  @DESCRIPTION: DCP-52242 - Fetch Opportunities for Display
    *  @PARAM :  String strRecordId Objective Id
    *  @RETURN:  JSON String
    */
    @AuraEnabled
    public static String getAssociatedAccountsForObjectives(String strRecordId) {
        ilib_LogEvent.setTitle(LOG_TITLE); 
        try {
            ilib_LogEvent.emit();
           return getAssociatedAccountsData(strRecordId);
        }
        catch(Exception e) {
            throw new AuraHandledException(e.getMessage());  
        }
    }
    
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION: Fetch Account associated to objective
    *  @PARAM :  String Objective Id
    *  @RETURN:  JSON String
    // Modified as part of DCP-39127
    // Modified as part of DCP-40334
    */
    public static String getAssociatedAccountsData(String strRecordId) {
        ilib_LogEvent.push(LOG_TITLE + '.getAssociatedAccountsData()');
        Schema.DescribeFieldResult fieldResult = Account.Customer_Type__c.getDescribe();
        List<Schema.PicklistEntry> lstPickList = fieldResult.getPicklistValues();
        Set<Id> setAccountId = new Set<Id>();
        List<AccountPlanObjectiveWrapper> lstAccountPlanObjectiveWrapper = new list<AccountPlanObjectiveWrapper>();
        ilib_LogEvent.message('strRecordId='+strRecordId);
        for(Plan_Objective_Account__c obATO : new PlanObjectiveAccountSelector().getAccountByPlanObjectiveId(strRecordId)) {
            lstAccountPlanObjectiveWrapper.add(new AccountPlanObjectiveWrapper(obATO));
            setAccountId.add(obATO.Account__c);
        }
        Set<String> setTerritoryCode = new Set<String>();
        // DCP-40334
        Plan_Objective__c objPlanObjective = new PlanObjectiveSelector().getPlanObjectiveById(strRecordId)[0];
        // DCP-41752 : Account visibility for Channel partner
        if(userinfo.getUserType() == Label.UserTypeStandard && String.isNotBlank(objPlanObjective.Plan_Strategy__r.Plan__r.Territory_Code__c)) {
            setTerritoryCode.add(objPlanObjective.Plan_Strategy__r.Plan__r.Territory_Code__c);
        }            
        set<Id> setRelatedAccount = new set<Id>();
        if(objPlanObjective.Plan_Strategy__r.Plan__r.RecordType.DeveloperName == Label.Plan_Indirect) {
            setTerritoryCode.add(objPlanObjective.Plan_Strategy__r.Plan__r.Channel_Partner_Territory_Code__c);
        }
        if(objPlanObjective.Plan_Strategy__r.Plan__r.RecordType.DeveloperName == Label.PlanOverlay) {
            setTerritoryCode.addAll(getChildTerritoryCode(objPlanObjective.Plan_Strategy__r.Plan__r.OwnerId));
        }
        for(ObjectTerritory2Association objObjectTerritory2Association : new ObjectTerritory2AssociationsSelector().getByTerritoryCode(setTerritoryCode)) {
            if(!setAccountId.contains(objObjectTerritory2Association.objectId)) {
                setRelatedAccount.add(objObjectTerritory2Association.objectId);
            }
        }
        List<AccountWrapper> lstAccountWrap = new List<AccountWrapper>();
        for(Account objAcc : new AccountsSelector().selectAccounts(setRelatedAccount)) {
            lstAccountWrap.add(new AccountWrapper(objAcc));
        }
        ilib_LogEvent.pop();
        return '{"lstAccountPlanObjectiveWrapper": '+JSON.serialize(lstAccountPlanObjectiveWrapper)+','
            +'"customerTypeValues": '+JSON.serialize(lstPickList)+','
            +'"planObjective": '+JSON.serialize(new PlanObjectiveWrapper(objPlanObjective))+','
            +'"lstAccountWrap": '+JSON.serialize(lstAccountWrap)+'}';
    }
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION: Fetch child territory code for owner
    *  @PARAM :  Owner Id
    *  @RETURN:  Set<String>
    */
    public static Set<String> getChildTerritoryCode(Id idOwnerId){
        ilib_LogEvent.setTitle(LOG_TITLE); 
        Set<Id> setTerritoryId = new Set<Id>();
        Set<String> setTerritoryCode = new Set<String>();
        for(UserTerritory2Association objUTA : new UserTerritory2AssociationSelector().selectByUserIds(new Set<Id>{idOwnerId})){
            setTerritoryId.add(objUTA.Territory2Id);
            setTerritoryCode.add(objUTA.Territory2.Territory_Code__c);
        }
        if(!setTerritoryId.isEmpty()){
            for(Territory2 objTr : new TerritoriesSelector().selectChildrenByTerritoryId(setTerritoryId)) {
                setTerritoryCode.add(objTr.Territory_Code__c);
            }
        }
        ilib_LogEvent.emit();
        return setTerritoryCode;
    }
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION: Wrapper class for Strategy
    */
    public class PlanStrategyWrapper{
        public String name,dueDate,description, strObjectId;
        /*
        *  @AUTHOR:  KD
        *  @DESCRIPTION: Wrapper class for Constructor
        */
        public PlanStrategyWrapper(Plan_Strategy__c objTS){
            this.strObjectId = objTS.id;
            this.name = objTS.Name;
            this.description = objTS.Description__c;
            this.dueDate = string.valueof(objTS.Due_Date__c);
        }
    }
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION: Wrapper class for Objective
    */
    public class PlanObjectiveWrapper{
        // Variable used to display column data [CodeScan flag marked false positive]
        public String strObjectId;
        public String closedStatus;
        public String dueDate;
        public String marketSegment;
        public String objectiveStatus;
        public String name;
        public String priority;
        public String productType;
        public String ownerName;
        public String actionCompleted;
        public String strategyName;
        public String planName;
        public String objectiveName;
        public String comments; //DCP-52623

        /*
        *  @AUTHOR:  KD
        *  @DESCRIPTION: Wrapper class for Constructor
        */
        public PlanObjectiveWrapper(Plan_Objective__c objTS){
            this.strObjectId = objTS.id;
            this.dueDate = string.valueof(objTS.Due_Date__c);
            this.closedStatus = objTS.Closed_Status__c;
            this.marketSegment = objTS.Market_Segment__c;
            this.objectiveStatus = objTS.Objective_Status__c;
            this.name = 'Plan Objective: '+objTS.Name;
            this.priority = objTS.Priority__c;
            this.productType = objTS.Product_Type__c;
            this.ownerName = objTS.Owner_Name__c;
            this.actionCompleted = String.valueof(objTS.Percent_Action_Completed__c) + ' %'; //DCP-52588 Mark as false positive since its percent data type
            // DCP-40334
            this.strategyName = objTS.Plan_Strategy__r.Name;
            this.planName = objTS.Plan_Strategy__r.Plan__r.Name;
            this.objectiveName = objTS.Name;
            this.comments = objTS.comments__c; //DCP-52623

        }
    }
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION: Wrapper class for Task
    */
    public class ActionWrapper{
        public String whatId;
        public String subject;
        public String status;
        public String strrecordid;
        public String priority;
        public String dueDate;
        public String comments;
        public String assignedTo;
        public String assignedId;
        /*
        *  @AUTHOR:  KD
        *  @DESCRIPTION: Wrapper class for Constructor
        */
        public ActionWrapper(Task objTask){
            this.whatId = objTask.WhatId;
            this.subject = objTask.Subject;
            this.status = objTask.Status;
            this.strrecordid = objTask.Id;
            this.priority = objTask.Priority;
            this.dueDate = String.valueof(objTask.ActivityDate);
            this.comments = objTask.Description;
            this.assignedTo = objTask.Owner_Full_Name__c;
            this.assignedId = objTask.OwnerId;
        }
    }
    // Modified as part of DCP-39127
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION: Wrapper class for Account
    */
    public class AccountWrapper{
        public string strAccountId;
        public string accountName;
        public string ownerName;
        public string erpNumber;
        public string customerType;
        public string city;
        /*
        *  @AUTHOR:  KD
        *  @DESCRIPTION: Wrapper class for Constructor
        */
        public AccountWrapper(Account acc){
            this.strAccountId = acc.Id;
            this.accountName = acc.Name;
            this.ownerName = acc.Owner.Name;
            this.erpNumber  = acc.ERP_Customer_Id__c;
            // DCP-39127
            this.customerType = acc.Customer_Type__c;
            this.city = acc.BillingCity;

        }
    }
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION: Wrapper class for Account plan Objective
    */
    public class AccountPlanObjectiveWrapper{
        public string strAccountId; 
        public string accountURL;
        public string accountName;
        public string ownerName;
        public string erpNumber;
        public string strRecordID;
        public string planName;
        public string objectiveName;
        public string objectiveStatus;
        public string priority;
        public string planStrategyName;
        public string planOwnerName;
        public string objectiveId;
        public string closedStatus;
        public Date dueDate;
        
        /*
        *  @AUTHOR:  KD
        *  @DESCRIPTION: Wrapper class for Constructor
        */
        public AccountPlanObjectiveWrapper(Plan_Objective_Account__c objATO ){
            this.strAccountId = '/'+objATO.Account__c;
            this.accountName = objATO.Account__r.Name;
            this.ownerName = objATO.Account__r.Owner.Name;
            this.erpNumber = objATO.Account__r.ERP_Customer_Id__c;
            this.strRecordID = objATO.Id;
            this.accountURL = (Userinfo.getUserType() == 'Standard' ?  '/' : '/ICPP/s/account/') + objATO.Account__c;
            this.planName = objATO.Plan_Objective__r.Plan_Strategy__r.Plan__r.Name;
            this.objectiveName = objATO.Plan_Objective__r.Name;
            this.objectiveStatus = objATO.Plan_Objective__r.Objective_Status__c;
            this.priority = objATO.Plan_Objective__r.Priority__c;
            this.planStrategyName = objATO.Plan_Objective__r.Plan_Strategy__r.Name;
            this.planOwnerName = objATO.Plan_Objective__r.Plan_Strategy__r.Plan__r.Owner.Name;
            this.objectiveId = objATO.Plan_Objective__r.Id;
            this.closedStatus = objATO.Plan_Objective__r.Closed_Status__c;
            this.dueDate = objATO.Plan_Objective__r.Due_Date__c;
           
        }
        
    }
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION: Delete account association
    *  @PARAM :  list of account association id
    *  @RETURN: String
    */
    @AuraEnabled
    public static string deleteAssociatedAccount(list<string> lstRecordId){
        ilib_LogEvent.setTitle(LOG_TITLE); 
        try{
            list<Plan_Objective_Account__c> lstATOToDel = new list<Plan_Objective_Account__c>();
            for(string objATOID :lstRecordId){
                lstATOToDel.add(new Plan_Objective_Account__c(id = objATOID )); 
            }
            delete lstATOToDel;
            ilib_LogEvent.emit();
            return  Label.UI_Message_APO_Delete.replace('{0}',String.valueOf(lstATOToDel.size()));
        }
        catch(Exception e) {
            //DCP-52588 Added to fix error handling codescan issue
            throw new AuraHandledException(e.getMessage()); 
        }
    }
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION: Add account association
    *  @PARAM :  String Objective Id and list of account id
    *  @RETURN: String
    // Modified as part of DCP-40334
    */
    @AuraEnabled
    public static string addAssociatedAccount(list<string> lstAccountId, string objectiveId,String strObjectiveJSON){
        ilib_LogEvent.setTitle(LOG_TITLE); 
        try{
            list<Plan_Objective_Account__c> lstATOToCreate = new list<Plan_Objective_Account__c>();
            for(string strAccountId : lstAccountId ){
                lstATOToCreate.add(new Plan_Objective_Account__c(Account__c = strAccountId,Plan_Objective__c = objectiveId ));
            }
            insert lstATOToCreate;
            // DCP-40334
            
            //DCP-50962 - implementation of batch manager
            ilib_BatchManager.executeBatch(new BatchClonePlanObjectiveToObjective(lstAccountId, strObjectiveJSON),100);
            
            ilib_LogEvent.emit();
            return   Label.UI_Message_APO_Create.replace('{0}',String.valueOf(lstATOToCreate.size()));
        }
        catch(Exception e){
            //DCP-52588 Added to fix error handling codescan issue
            throw new AuraHandledException(e.getMessage()); 
        }
    }
    
}