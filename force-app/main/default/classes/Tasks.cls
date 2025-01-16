/* @ author       : KD
* @ date         : 5-Sept-2019
* @ Description  : Task Trigger helper class contains all Business logic implementation
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* KD                       3-Aug-2020                                   Added total task calculation logic for Plan Objection
* KD                       19-oct-2020                                  Moved task calculation logic for Plan Objection to Admin operation to overcome task access issue for portal user.                    
*Prem Ranjan			   19-May-2021				DCP-46309			Territory Planning: Desired Notification from self-created action/task
* Rishab Wali              5-Jan-2021               DCP-49756           Update Most Recent Activity Date on Lead 
* Deep Diwakar             Jul-30-2024              CMCM-7519/7968      Updated to add before save method and decorator call for Marketing task updates
*---------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class Tasks extends ilib_SObjectDomain{
    public static Boolean boolIsTestRunning = false;
	public static String emailTemplateName = 'Plan_Self_Task_Notify';//DCP-46309
    public static final String EXCEPTION_LOG_TITLE = 'Task.selfCreatedTaskNotification';//DCP-46309
    public static final String STR_OBJECTIVEAPI = 'Objective__c';
    public static final String STR_PLANOBJAPI = 'Plan_Objective__c';

    private static final String STRING_PARDOT_INTEGRATION_USER ='Integration Pardot';

    /*
    * Description : Constructor
    */
    public Tasks(List<Task> sObjectList)
    {
        super(sObjectList);
    }
    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /*
        * Boilerplate for construct
        */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new Tasks(sObjectList);
        }
    }

     /**
     * @author: Deep Diwakar
     * @date: Jul-30-2024
     * @description: Added before save method for Marketing task updates
     * @param: none
     * @return: void
     */
    public override void onBeforeInsert() {

        String curretUser = UserInfo.getname();

        ilib_LogEvent.info('curretUser: ' + curretUser);

        if (STRING_PARDOT_INTEGRATION_USER.equalsIgnoreCase(curretUser)) {
            ilib_LogEvent.setWorkstream(ilib_LogEvent.MARKETING);
            ilib_LogEvent.info('calling marketing task decorator');
            //CMCM-7519: Instantiating decorator object to add marketing task updates
            ilib_SObjectDecorator mktgTaskDecorator = new MktgTaskDecorator(records);
            mktgTaskDecorator.decorate();
        }
        

    }
    /**
     *  @author       : Kushagra Desai
     *  @description  : 
     *  @return       : void
     */
    public override void onAfterDelete(){
        List<Task> lstTempTask = (List<Task>) records;
        
        Set<Id>setObjectiveIds=new Set<Id>();
        Set<Id>setPlanObjectiveIds=new Set<Id>();
        for(Task tsk : lstTempTask){
            if(tsk.WhatId != null){
                if(tsk.WhatId.getSObjectType().getDescribe().getName() == STR_OBJECTIVEAPI){
                
                    setObjectiveIds.add(tsk.WhatId);
                }
                if(tsk.WhatId.getSObjectType().getDescribe().getName() == STR_PLANOBJAPI){
                    setPlanObjectiveIds.add(tsk.WhatId);
                }
            }
        }
        if(!setObjectiveIds.isEmpty()) {
            updateObjectiveRecords(setObjectiveIds);
        }
        if(!setPlanObjectiveIds.isEmpty()) {
            checkLoggedInUserType(setPlanObjectiveIds);
        }
    }
    /**
     *  @author       : Kushagra Desai
     *  @description  : 
     *  @return       : void
     */
    public override void onAfterInsert(){
        List<Task> lstTempTask = (List<Task>) records;
        Set<Id>setObjectiveIds=new Set<Id>();
        Set<Id>setPlanObjectiveIds=new Set<Id>();
        LIst<Task> lstTask = new List<Task>();
        Set<Id> setLeadId = new Set<Id>();
        Map<Id,Date> mapLeadIdToTaskCloseDate = new Map<Id,Date>();
        for(Task tsk : lstTempTask){
            if(tsk.WhatId != null){
                if(tsk.WhatId.getSObjectType().getDescribe().getName() == STR_OBJECTIVEAPI){
                    setObjectiveIds.add(tsk.WhatId);
                    lstTask.add(tsk);
                }
                if(tsk.WhatId.getSObjectType().getDescribe().getName() == STR_PLANOBJAPI){
                    setPlanObjectiveIds.add(tsk.WhatId);
                    lstTask.add(tsk);
                }
            }
            if(tsk.WhoId != null) //DCP-49756
            {
                if(tsk.WhoId.getSObjectType().getDescribe().getName() == 'Lead' && tsk.Status == 'Completed')
                {
                    setLeadId.add(tsk.WhoId);
                    mapLeadIdToTaskCloseDate.put(tsk.WhoId,tsk.ActivityDate);
                }
            }
        }
        if(!setObjectiveIds.isEmpty()) {
            updateObjectiveRecords(setObjectiveIds);
        }
        if(!setPlanObjectiveIds.isEmpty()) {
            checkLoggedInUserType(setPlanObjectiveIds);
        }
        //DCP-46309
		if(!lstTask.isEmpty())
        {
            selfCreatedTaskNotification(lstTask);
        }
        if(!setLeadId.isEmpty())
        {
            updateMostRecentActivityDateLead(setLeadId,mapLeadIdToTaskCloseDate); //DCP-49756
        }
		
    }
	
    /**
     *  @author       : Kushagra Desai
     *  @description  : 
     *  @return       : void
     */
    public override void onAfterUpdate(Map<Id, SObject> oldRecords){
        List<Task> lstChangedStatusTask = UtilsObject.filterForFieldChanges(records, oldRecords, new List<String> {'Status'});
        system.debug('Updated records --> '+ lstChangedStatusTask);
        
        Set<Id>setObjectiveIds=new Set<Id>();
        Set<Id>setPlanObjectiveIds=new Set<Id>();
        Set<Id> setLeadId = new Set<Id>();
        Map<Id,Date> mapLeadIdToTaskCloseDate = new Map<Id,Date>();
        for(Task tsk : lstChangedStatusTask){
            if(tsk.WhatId != null){
                if(tsk.WhatId.getSObjectType().getDescribe().getName() == STR_OBJECTIVEAPI){
                    setObjectiveIds.add(tsk.WhatId);
                }
                if(tsk.WhatId.getSObjectType().getDescribe().getName() == STR_PLANOBJAPI){
                    setPlanObjectiveIds.add(tsk.WhatId);
                }
            }
            if(tsk.WhoId != null) //DCP-49756
            {
                if(tsk.WhoId.getSObjectType().getDescribe().getName() == 'Lead' && tsk.Status == 'Completed')
                {
                    setLeadId.add(tsk.WhoId);
                    mapLeadIdToTaskCloseDate.put(tsk.WhoId,tsk.ActivityDate);
                }
            }
        }
        if(!setObjectiveIds.isEmpty()) {
            updateObjectiveRecords(setObjectiveIds);
        }
        if(!setPlanObjectiveIds.isEmpty()) {
            checkLoggedInUserType(setPlanObjectiveIds);
        }
        if(!setLeadId.isEmpty())
        {
            updateMostRecentActivityDateLead(setLeadId,mapLeadIdToTaskCloseDate); //DCP-49756
        }
        
    }
    /**
     *  @author       : Kushagra Desai
     *  @description  : update total task count and total closed task count in objective
     *  @return       : void
     */
    public Static void updateObjectiveRecords(Set<id> setObjectIds){
       
        List<Objective__c> listObjective=new List<Objective__c>();
       
        for(Objective__c objObjective : new ObjectivesSelector().getObjectivesWithTasks(setObjectIds)){
            integer totalTask=objObjective.Tasks.size();
            integer closedTask=0;
            for(Task objTask : objObjective.Tasks) {
                If(objTask.Status==Label.Completed) {
                    closedTask++;
                }
                
            }
            objObjective.Total_Task__c= totalTask;
            objObjective.Total_Closed_Task__c=closedTask;
            listObjective.add(objObjective);
        }

        update listObjective;
    }
    /**
     *  @author       : Kushagra Desai
     *  @description  : update total task count and total closed task count in plan objective
     *  @return       : void
     */
    public Static void updatePlanObjectiveRecords(Set<id> setObjectIds){
       
        List<Plan_Objective__c> listObjective=new List<Plan_Objective__c>();
       
        for(Plan_Objective__c objObjective : new PlanObjectiveSelector().getPlanObjectivesWithTasks(setObjectIds)){
            integer totalTask=objObjective.Tasks.size();
            integer closedTask=0;
            for(Task objTask : objObjective.Tasks) {
                If(objTask.Status==Label.Completed) {
                    closedTask++;
                }
                
            }
            objObjective.No_of_Actions__c= totalTask;
            objObjective.No_of_Completed_Actions__c=closedTask;
            listObjective.add(objObjective);
        }

        update listObjective;
    }
    /*
    * Description : Method to check if logged in user is external
    */
    public static void checkLoggedInUserType(Set<id> setPlanObjectiveIds){
        if(userinfo.getUserType() == 'Standard' && !boolIsTestRunning) {
            updatePlanObjectiveRecords(setPlanObjectiveIds);
        }
        else{
            String strPlanObectiveId = '';
            for(String strId : setPlanObjectiveIds) {
                strPlanObectiveId += strId + ',';
            }
            strPlanObectiveId = strPlanObectiveId.removeEnd(',');
            Admin_Operation__e ao = new Admin_Operation__e(Name__c = 'UpdatePlanObjectiveRecords', Related_Record__c = strPlanObectiveId);
            // Emit the log data via Platform Events
            EventBus.publish(ao);
        }
    }
	 /*
    * Description : Method sent email notification for self created task for DCP-46309
    */
    public static void selfCreatedTaskNotification(List<Task> lstTaskRecord){
        EmailTemplatesSelector emailTemplateSlctr = new EmailTemplatesSelector();
        List<EmailTemplate> lstEmailTemplate = emailTemplateSlctr.selectByNameOrDeveloperName(new List<String> {emailTemplateName});
        Map<Id,Id> mapTaskUserIds = new Map<Id,Id>();
        try
        {
        for(Task tsk : lstTaskRecord)
        {
            if(tsk.WhatId != null && tsk.OwnerId == tsk.CreatedById)
            {
                mapTaskUserIds.put(tsk.Id,tsk.OwnerId);
            }
        }
            sendEmailNotification(lstEmailTemplate[0].Id, mapTaskUserIds);
        }
        catch (Exception e) {
            ApexExceptions.emit(EXCEPTION_LOG_TITLE, e);
    }
    }

	 /*
    * Description : Method to sent email notification for DCP-46309
    */
    public static void sendEmailNotification(Id tempId, Map<Id,Id> mapTaskOwnerIds){
    List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
    try 
    {
        for(Id tsk : mapTaskOwnerIds.keySet())
        {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTemplateId(tempId);
        mail.setTargetObjectId(mapTaskOwnerIds.get(tsk));
        mail.setWhatId(tsk);
        mail.setSaveAsActivity(false);
        mail.setUseSignature(false);
        allmsg.add(mail);
        }
        if(!test.isRunningTest()) {
            Messaging.sendEmail(allmsg,false); }
        }catch (Exception e) {
            ApexExceptions.emit(EXCEPTION_LOG_TITLE, e);
        }
	}

    /**
     * Description - [DCP-49756] Update Most Recent Activity Date on Lead
     */
    private void updateMostRecentActivityDateLead(Set<Id> setLeadIds,Map<Id,Date> mapLeadIdToTaskCloseDate)
    {
        ilib_LogEvent.push('Tasks.updateMostRecentActivityDateLead()');
        ilib_LogEvent.info('set Lead Ids  : '+ setLeadIds);
        List<lead> updatedLeads = new List<lead>();
        for(Lead objLead : [SELECT Id,Most_Recent_Activity_Date__c FROM Lead WHERE Id =: setLeadIds])
        {
            if(mapLeadIdToTaskCloseDate.get(objLead.Id) > Date.valueOf(objLead.Most_Recent_Activity_Date__c))
            {
                objLead.Most_Recent_Activity_Date__c =  mapLeadIdToTaskCloseDate.get(objLead.Id);
                updatedLeads.add(objLead);
            }
        }
        if(!updatedLeads.isEmpty())
        {
            ilib_LogEvent.info('Updated Leads Id  : '+ UtilsCollection.getSetOfIds(updatedLeads));
            Database.update(updatedLeads,false);
        }
        ilib_LogEvent.pop();
    }
}