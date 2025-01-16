/**
 *    @author KD
 *    @date   30-March-2021
 *    @description  Scheduled batch to send MS teams notification
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------------------
 *     Developer                      Date                Description
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
 */
global with sharing class ScheduleBatchSendCaseTeamsNotification extends ilib_ScheduleAndBatch implements Database.Stateful, Database.AllowsCallouts{
    public List<MS_Team_Notification__c> lstMSTeamsNotificationToUpdate = new List<MS_Team_Notification__c>();
    public Map<Id,List<String>> mapOfNotificationIdtoCaseNumber = new Map<Id,List<String>>();
    public Map<Id,List<MS_Team_Notification__c>> mapOfNotificationIdToMSTeamNotification = new Map<Id,List<MS_Team_Notification__c>>();
    public static final Integer HTTP_SUCCESS_CODE = 200;
    public static ilib_LogInterface.LogDetails log;
    public DateTime dtTimeNow;
    public Set<String> setRegionGroupHoliday = new Set<String>();
    public static final String CODEPARAMTER_FREQUENCY = 'Case_Notification_Batch_Frequency';
    /*
    Constructor
    */
    public ScheduleBatchSendCaseTeamsNotification(){
        dtTimeNow = Datetime.now();
        setRegionGroupHoliday = CaseChangeEventsService.getHolidaysAndWorkingHours(dtTimeNow);
    }
    /* execute method */
    global override void execute(SchedulableContext sc)
    {   
        Datetime dtTimeNowScheduled = Datetime.now();
        Database.executeBatch(new ScheduleBatchSendCaseTeamsNotification(),100);
        String strHour =new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set<String>{CODEPARAMTER_FREQUENCY})[0].Value__c;
        Integer offset = UserInfo.getTimezone().getOffset(dtTimeNowScheduled);
        Datetime dtlocal = dtTimeNowScheduled.addSeconds(offset/1000);
        Datetime dtdueDateTime = dtlocal.addHours(Integer.valueOf(strHour));
        String strCron = '0 0 '+String.valueOf(dtlocal.hourGMT()+Integer.valueOf(strHour))+' '+dtdueDateTime.dayGMT()+' '+dtdueDateTime.monthGmt()+' ? '+dtdueDateTime.yearGmt();
        System.debug(strCron);
        if(dtlocal.dayGMT() == dtdueDateTime.dayGMT() && !Test.isRunningTest()){
            system.schedule('ScheduleBatchSendCaseTeamsNotification'+String.valueOf(dtdueDateTime),strCron,new ScheduleBatchSendCaseTeamsNotification());
        }

    }
    /* start method to query records */
    global override Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'Select id,IsActive__c,Last_NotificationTime__c,Notification_Detail__c,Notification_Detail__r.Send_Only_During_Office_Hours__c,Notification_Detail__r.Send_Only_After_Hours__c,Notification_Detail__r.User_Group__c,Re_Trigger_Count__c,Case__c,Case__r.CaseNumber,Notification_Eligible__c,Case__r.Region__c,Case__r.Origin,Case__r.Owner.Type,Case__r.Owner.Name from MS_Team_Notification__c where IsActive__c = TRUE and Notification_Eligible__c = TRUE AND Notification_Detail__r.Is_Active__c = true';
        return Database.getQueryLocator(query);
    }
    /* method to execute logic for each chunk of records*/
    global override void execute(Database.BatchableContext bc, List<sobject> lstMSTeamsNotification){
        for(MS_Team_Notification__c objMSTeamNotification : (List<MS_Team_Notification__c>)lstMSTeamsNotification){
            //Check for holiday by checking region and user group
            if(objMSTeamNotification.Notification_Detail__r.Send_Only_During_Office_Hours__c && !setRegionGroupHoliday.isEmpty() && objMSTeamNotification.Case__r.Region__c != null && objMSTeamNotification.Case__r.Owner.Type == 'Queue' && String.isNotBlank(objMSTeamNotification.Notification_Detail__r.User_Group__c))
                if(setRegionGroupHoliday.contains(objMSTeamNotification.Case__r.Region__c+'-'+CaseChangeEventsService.getCaseUserGroup(objMSTeamNotification.Case__r.Owner.Name)) && objMSTeamNotification.Notification_Detail__r.User_Group__c == CaseChangeEventsService.getCaseUserGroup(objMSTeamNotification.Case__r.Owner.Name))
                    continue;
            if(objMSTeamNotification.Notification_Detail__r.Send_Only_After_Hours__c && objMSTeamNotification.Case__r.Region__c != null && objMSTeamNotification.Case__r.Owner.Type == 'Queue' && String.isNotBlank(objMSTeamNotification.Notification_Detail__r.User_Group__c)){
                if(setRegionGroupHoliday.isEmpty() || !setRegionGroupHoliday.contains(objMSTeamNotification.Case__r.Region__c+'-'+CaseChangeEventsService.getCaseUserGroup(objMSTeamNotification.Case__r.Owner.Name)) && objMSTeamNotification.Notification_Detail__r.User_Group__c == CaseChangeEventsService.getCaseUserGroup(objMSTeamNotification.Case__r.Owner.Name))
                    continue;
            }
            if(!mapOfNotificationIdtoCaseNumber.containsKey(objMSTeamNotification.Notification_Detail__c))
                mapOfNotificationIdtoCaseNumber.put(objMSTeamNotification.Notification_Detail__c,new List<String>());
            mapOfNotificationIdtoCaseNumber.get(objMSTeamNotification.Notification_Detail__c).add(objMSTeamNotification.Case__r.CaseNumber);
            if(!mapOfNotificationIdToMSTeamNotification.containsKey(objMSTeamNotification.Notification_Detail__c))
                mapOfNotificationIdToMSTeamNotification.put(objMSTeamNotification.Notification_Detail__c,new List<MS_Team_Notification__c>());
            mapOfNotificationIdToMSTeamNotification.get(objMSTeamNotification.Notification_Detail__c).add(objMSTeamNotification);
        }
    }
    /* Final method */
    global override void finish(Database.BatchableContext bc){
        try{
            MSTeamsNotificationSender instantiated = new MSTeamsNotificationSender();
            ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
            List<Interface_Log__c> lstInterfaceLog = new List<Interface_Log__c>();
            List<Notification_Detail__c> lstAllNotificationDetails = [Select id,Is_Instant_Notification__c,MS_Teams_Recipient__c,Trigger_Notification_After_in_HRS__c,Notification_Template__c,Recipient_Name__c,Region__c,Send_Only_During_Office_Hours__c,Rule_Syntax__c,User_Group__c from Notification_Detail__c];
            for(Notification_Detail__c objNotification : lstAllNotificationDetails){
                if(!mapOfNotificationIdtoCaseNumber.containsKey(objNotification.id))
                    continue;
             
                MSTeamsNotificationSender.EmailResult  emailResult = MSTeamsNotificationSender.sendTeamsNotificationForCase(objNotification.MS_Teams_Recipient__c,objNotification.Notification_Template__c,objNotification.Recipient_Name__c,mapOfNotificationIdtoCaseNumber.get(objNotification.Id));
                log = ilib_LogInterface.initiateLog(interfaceDetails,'EndPoint : '+objNotification.MS_Teams_Recipient__c+' Body: '+emailResult.sendEmailBody);
                lstInterfaceLog.add(ilib_LogInterface.returnLogRecord(log,emailResult.sendEmailResultObject.isSuccess() ? ilib_LogInterface.RESULT_SUCCESS :ilib_LogInterface.RESULT_FAIL,emailResult.sendEmailBody,null,null));

                for(MS_Team_Notification__c objMSTeamNotification : mapOfNotificationIdToMSTeamNotification.get(objNotification.id)){
                    
                    if(emailResult.sendEmailResultObject.isSuccess()==false && Test.isRunningTest()==false)
                        objMSTeamNotification.Re_Trigger_Count__c = objMSTeamNotification.Re_Trigger_Count__c + 1;
                    else
                        objMSTeamNotification.Last_NotificationTime__c = dtTimeNow;
                    lstMSTeamsNotificationToUpdate.add(objMSTeamNotification);
                }

            }
            if(!lstMSTeamsNotificationToUpdate.isEmpty())
                update lstMSTeamsNotificationToUpdate;
            if(!lstInterfaceLog.isEmpty())
                upsert lstInterfaceLog;
        }catch(Exception e){
            
            ApexExceptions.emit('ScheduleBatchSendCaseTeamsNotification',e);
        }
    }
}