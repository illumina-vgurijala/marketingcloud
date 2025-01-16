/**
* @ author       : Akshay Mohan
* @ date         : 23-Sep-2020
* @ Description  : DCP-41751 Scheduled class to run every week to send emails for overdue action items
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Akshay Mohan          23-Sep-2020                 Initial version
* Nishan Shetty			09-June-2022              DCP-50962 - Batch manager implementation
*/
public with sharing class ScheduledBatchPlanOverdueTaskEmail extends ilib_BatchDeferrable implements Schedulable{

    private String strBaseURL;
    public Boolean boolJobRan;
    private final static String SOURCE = 'ScheduledBatchPlanOverdueTaskEmail';//DCP-50962
    
    /**
    * @author Akshay Mohan
    * @date   23-Sep-2020
    * @description  Overriding execute method for scheduled job
    */
    public override void execute(SchedulableContext sc)
    {
        //DCP-50962
        boolJobRan = ilib_BatchManager.executeBatch(new ScheduledBatchPlanOverdueTaskEmail());
    }

    /**
    * @author Akshay Mohan
    * @date   23-Sep-2020
    * @description  Overriding start method for batch
    */
    public override Database.QueryLocator start(Database.BatchableContext bc)
    {
        String strTaskOpen='Open';
        return Database.getQueryLocator('SELECT Id,OwnerId,Subject,ActivityDate,CreatedBy.Email,Owner.Email,WhatId,CreatedBy.Name '
                                            +' FROM Task WHERE WhatId in (Select Id From Plan_Objective__c WHERE IsActive__c=true AND Plan_Strategy__r.IsActive__c=true) '
                                                +' AND ActivityDate<TODAY AND Status =:strTaskOpen');
    }

    /**
    * @author Akshay Mohan
    * @date   23-Sep-2020
    * @description  Overriding execute method for batch
    */
    public override void execute(Database.BatchableContext bc, List<sObject> lstRecords){
        ilib_LogEvent.setBatchTitle(SOURCE, transactionId);
        ilib_LogEvent.push(SOURCE+'.execute');
        EmailTemplate emailTemplate = new EmailTemplatesSelector().selectByNameOrDeveloperName(new List<String>{'Task_Overdue_Action_Items_on_Plan'})[0];
        strBaseURL=System.Url.getOrgDomainUrl().toString().split('=')[1].remove(']')+'/';
        ilib_LogEvent.message('strBaseURL:'+strBaseURL);
        List<Task> lstTasks = (List<Task>) lstRecords;
        List<Messaging.SingleEmailMessage> lstEmails = new List<Messaging.SingleEmailMessage>();
        Map<Id,List<Messaging.SingleEmailMessage>> mapObjectiveIdToEmails = new Map<Id,List<Messaging.SingleEmailMessage>>();
        Map<Id,List<Task>> mapObjectiveIdToTasks = new Map<Id,List<Task>>();
        for(Task objTask : lstTasks){
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

            email.setReplyTo(objTask.CreatedBy.Email);
            email.setSenderDisplayName(objTask.CreatedBy.Name);
            email.setTargetObjectId(objTask.OwnerId);
            email.setSaveAsActivity(false);
            email.setSubject(emailTemplate.Subject);
            lstEmails.add(email);
            if(!mapObjectiveIdToEmails.containsKey(objTask.WhatId))
                mapObjectiveIdToEmails.put(objTask.WhatId,new List<Messaging.SingleEmailMessage>());
            mapObjectiveIdToEmails.get(objTask.WhatId).add(email);
            if(!mapObjectiveIdToTasks.containsKey(objTask.WhatId))
                mapObjectiveIdToTasks.put(objTask.WhatId,new List<Task>());
            mapObjectiveIdToTasks.get(objTask.WhatId).add(objTask);
        }
        ilib_LogEvent.message('mapObjectiveIdToEmails: '+mapObjectiveIdToEmails);
        ilib_LogEvent.message('mapObjectiveIdToTasks: '+mapObjectiveIdToTasks);

        for(Plan_Objective__c objPO:new PlanObjectiveSelector().getPlanObjectivesWithTasks(mapObjectiveIdToTasks.keySet())){
            
            Integer index=0;
            for(Messaging.SingleEmailMessage email :mapObjectiveIdToEmails.get(objPO.Id)){
                Task objTask = mapObjectiveIdToTasks.get(objPO.Id)[index];
                index++;
                email.setHtmlBody(replaceBindVariables(emailTemplate.HtmlValue,objTask,objPO));
                email.setPlainTextBody(replaceBindVariables(emailTemplate.Body,objTask,objPO));
            }
        }
        try{
            Messaging.sendEmail(lstEmails);
        }catch(Exception e){
            ApexExceptions.emit('ScheduledBatchPlanOverdueTaskEmail', e);
            throw e;
        }

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        
    }

    /**
    * @author Akshay Mohan
    * @date   23-Sep-2020
    * @description  Replace content with task attributes
    */
    private String replaceBindVariables(String strContent,Task objTask,Plan_Objective__c objPO){
        String strReplaced = strContent.replaceAll('(\\{!Plan__c\\.Name\\})',objPO.Plan_Strategy__r.Plan__r.Name);
        strReplaced=strReplaced.replaceAll('(\\{!Task\\.Subject\\})',objTask.Subject);
        strReplaced=strReplaced.replaceAll('(\\{!Task\\.ActivityDate\\})',objTask.ActivityDate.format());
        strReplaced=strReplaced.replaceAll('(\\{!Task\\.Link\\})',strBaseURL+objTask.Id);
        strReplaced=strReplaced.replaceAll('(\\{!Plan__c\\.Link\\})',strBaseURL+objPO.Plan_Strategy__r.Plan__c);
        strReplaced=strReplaced.remove('<![CDATA[');
        strReplaced=strReplaced.remove(']]>');
        return strReplaced;
    }

    /**
    * @author Akshay Mohan
    * @date   23-Sep-2020
    * @description  Overriding finish method for batch
    */
    public override void finish(Database.BatchableContext bc){

    }
	
    // ************************************************************************************************
    // Deferrable implementation
	//DCP-50962
    // ************************************************************************************************

        
    /*
    *  @Author      : Nishan Shetty
    *  @Description : Method to simple input serialization
    *  @Param       : None
    *  @Return      : String
    */
    public override String serializeInputs() {
        return JSON.serialize('No input for this class');
    }

    /*
    *  @Author      : Nishan Shetty
    *  @Description : Method to simple input deserialization
    *  @Param       : String
    *  @Return      : void
    */
    public override void restoreInputs(String serializedInputs) { } 
    
    /*
    *  @Author      : Nishan Shetty
    *  @Description : Method to get default val
    *  @Param       : None
    *  @Return      : Integer
    */
    public override Integer getDefaultBatchSize() {  
        return 200;
    }

   
}