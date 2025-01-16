/**
 *    @author KD
 *    @date   30-March-2021
 *    @description  Service class for CaseChangeEvents
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------------------
 *     Developer                      Date                Description
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
 */
public with sharing class CaseChangeEventsService extends ilib_RestReceiver{
    public static final Integer HTTP_SUCCESS_CODE = 200;
    public static ilib_LogInterface.LogDetails log;
    public static Map<Id,List<Case>> mapInsantNotificationIdToCase = new Map<Id,List<Case>>();
    public static Set<Notification_Detail__c> setNotificationDetailsInUse = new Set<Notification_Detail__c>();
    public static Map<String,List<String>> mapOfQueueKeyWordToUserRegion = new Map<String,List<String>>{
        'CS' => new List<String>{'Customer Service','CS -'},
        'TS' => new List<String>{'Technical Support','TS -'},
        'CP' => new List<String>{'CP:'}
    };
    /**
     *  @author       : KD
     *  @description  : Fetch all MS team notification records for Upsert
     *  @return       : List<MS_Team_Notification__c>
     */
    public static List<MS_Team_Notification__c> fetchMSTeamNotificationRecords(List<Case> lstCase,Set<String> setNewCaseId,Map<Id,List<MS_Team_Notification__c>> mapExistingCaseidToMSNotification,List<Notification_Detail__c> lstNotificationDetails,Map<String,Set<String>> mapCaseIdToFieldUpdate){
        List<MS_Team_Notification__c> lstMSTeamNotificationToUpsert = new List<MS_Team_Notification__c>();
        for(Case objCase : lstCase){
            for(Notification_Detail__c objNotificationDetails : lstNotificationDetails){
                if(objCase.Region__c != objNotificationDetails.Region__c)
                    continue;
                MS_Team_Notification__c objMSTeamNotification = getMSTeamNotificationRecord(
                    objCase,
                    objNotificationDetails,
                    setNewCaseId.contains((String)objCase.Id),
                    mapExistingCaseidToMSNotification.containsKey(objCase.Id)?mapExistingCaseidToMSNotification.get(objCase.Id):new List<MS_Team_Notification__c>(),
                    mapCaseIdToFieldUpdate
                );
                if(objMSTeamNotification != null)
                    lstMSTeamNotificationToUpsert.add(objMSTeamNotification);
            }
        }
        if(!mapInsantNotificationIdToCase.isEmpty()){
            instantCaseMSTeamNotification(JSON.serialize(mapInsantNotificationIdToCase),JSON.serialize(setNotificationDetailsInUse));
        }
        return lstMSTeamNotificationToUpsert;
    }
    /**
     *  @author       : KD
     *  @description  : create MS team notification record based on criteria check against notification details
     *  @return       : MS_Team_Notification__c
     */
    public static MS_Team_Notification__c getMSTeamNotificationRecord(Case objCase,Notification_Detail__c objNotificationDetails,Boolean boolIsNew,List<MS_Team_Notification__c> lstExistingMSNotification,Map<String,Set<String>> mapCaseIdToFieldUpdate){
        Map<Id,Id> mapNotificationDetailIdtoMSTeamNotificationId = new Map<Id,Id>();
        if(!lstExistingMSNotification.isEmpty())
            mapNotificationDetailIdtoMSTeamNotificationId = UtilsCollection.getMapOfIdToId(lstExistingMSNotification,'Notification_Detail__c','Id');
        Boolean isConditionSatisfied = MSNotificationRuleEngine.checkCondition(objCase,objNotificationDetails.Rule_Syntax__c,null);
        if(isConditionSatisfied != null && isConditionSatisfied){
            if(objNotificationDetails != null && objNotificationDetails.Is_Instant_Notification__c){
                Boolean boolCheckFieldUpdate = false;
                if(!mapCaseIdToFieldUpdate.containsKey(objCase.Id))
                    boolCheckFieldUpdate = true;
                if(mapCaseIdToFieldUpdate.containsKey(objCase.Id)){
                    for(String strUpdatedField : mapCaseIdToFieldUpdate.get(objCase.Id)){
                        if(objNotificationDetails.Impacted_Fields__c.contains(strUpdatedField)){
                            boolCheckFieldUpdate = true;
                            break;
                        }
                    }
                }
                if(boolCheckFieldUpdate){
                    if(!CaseChangeEventsService.mapInsantNotificationIdToCase.containsKey(objNotificationDetails.Id))
                        CaseChangeEventsService.mapInsantNotificationIdToCase.put(objNotificationDetails.id,new List<Case>());
                    CaseChangeEventsService.mapInsantNotificationIdToCase.get(objNotificationDetails.id).add(objCase);
                    setNotificationDetailsInUse.add(objNotificationDetails);
                }
                return null;
            }
            else if(boolIsNew){
                return new MS_Team_Notification__c(Case__c = objCase.Id,Notification_Detail__c = objNotificationDetails.id);
            }
            else if(!boolIsNew && !mapNotificationDetailIdtoMSTeamNotificationId.containsKey(objNotificationDetails.id)){
                // Create new juntion object for updated case satisfing criteria
                return new MS_Team_Notification__c(Case__c = objCase.Id,Notification_Detail__c = objNotificationDetails.id);
            }
        }
        else{
            if(mapNotificationDetailIdtoMSTeamNotificationId.containsKey(objNotificationDetails.id)){
                // Mark existing record as inactive
                return new MS_Team_Notification__c(Id=mapNotificationDetailIdtoMSTeamNotificationId.get(objNotificationDetails.id),IsActive__c = FALSE);
            }
        }
        return null;
    }
    /**
     *  @author       : KD
     *  @description  : Future method to send instand notification
     *  @return       : void
     */

    @future(callout = true)
    public static void instantCaseMSTeamNotification(String strInsantNotificationIdToCase,String strSetNotificationRecordInUse){
        try{
            Set<String> setRegionGroupHoliday = getHolidaysAndWorkingHours(Datetime.now());
            Map<Id,List<Case>> mapInsantNotificationIdToCase = (Map<Id,List<Case>>)JSON.deserialize(strInsantNotificationIdToCase,Map<Id,List<Case>>.class);
            Set<Notification_Detail__c> setNotificationRecordInUse = (Set<Notification_Detail__c>)JSON.deserialize(strSetNotificationRecordInUse,Set<Notification_Detail__c>.class);
            CaseChangeEventsService instantiated = new CaseChangeEventsService();
            ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
            List<Interface_Log__c> lstInterfaceLog = new List<Interface_Log__c>();
            for(Notification_Detail__c objNotificationDetails : setNotificationRecordInUse){
                for(Case objCase : mapInsantNotificationIdToCase.get(objNotificationDetails.Id)){
                    //Check for holiday by checking region and user group
                   
                    if(objNotificationDetails.Send_Only_During_Office_Hours__c && !setRegionGroupHoliday.isEmpty() && objCase.Region__c != null && objCase.Owner.Type == 'Queue' && String.isNotBlank(objNotificationDetails.User_Group__c)){
                        if(setRegionGroupHoliday.contains(objCase.Region__c+'-'+getCaseUserGroup(objCase.Owner.Name)) && objNotificationDetails.User_Group__c == getCaseUserGroup(objCase.Owner.Name))
                            continue;
                    }
                    if(objNotificationDetails.Send_Only_After_Hours__c && objCase.Region__c != null && objCase.Owner.Type == 'Queue' && String.isNotBlank(objNotificationDetails.User_Group__c)){
                        if(setRegionGroupHoliday.isEmpty() || !setRegionGroupHoliday.contains(objCase.Region__c+'-'+getCaseUserGroup(objCase.Owner.Name)) && objNotificationDetails.User_Group__c == getCaseUserGroup(objCase.Owner.Name))
                            continue;
                    }
                    MSTeamsNotificationSender.sendTeamsNotificationForCase(objNotificationDetails.MS_Teams_Recipient__c,objNotificationDetails.Notification_Template__c,objNotificationDetails.Recipient_Name__c,new List<String>{objCase.CaseNumber});
                 
                    /*HttpRequest objReq = MSTeamsNotificationSender.sendTeamsNotificationForCase(objNotificationDetails.MS_Teams_Recipient__c,objNotificationDetails.Notification_Template__c,objNotificationDetails.Recipient_Name__c,new List<String>{objCase.CaseNumber});
                    log = ilib_LogInterface.initiateLog(interfaceDetails,'EndPoint : '+objNotificationDetails.MS_Teams_Recipient__c+' Body: '+objReq.getBody());
                    HttpResponse response = Test.isRunningTest() ? MockHTTPCalloutMSTNotifications.respondMock('Auth') : new Http().send(objReq);
                    lstInterfaceLog.add(ilib_LogInterface.returnLogRecord(log,response.getStatusCode() == HTTP_SUCCESS_CODE ? ilib_LogInterface.RESULT_SUCCESS :ilib_LogInterface.RESULT_FAIL,response.getBody(),null,null));*/
                }
            }
            if(!lstInterfaceLog.isEmpty())
                upsert lstInterfaceLog;
        }catch(Exception e){
           
            ApexExceptions.emit('CaseChangeEventsService',e);
        }
    }
    /**
     *  @author       : KD
     *  @description  :  method to list of region having holiday
     *  @return       : void
     */
    public static Set<String> getHolidaysAndWorkingHours(DateTime dtTimeNow){
        Date dtToday = date.newinstance(dtTimeNow.year(), dtTimeNow.month(), dtTimeNow.day());
        Set<String> setRegionGroupHoliday = new Set<String>();
        setRegionGroupHoliday = getWorkingHoursHoliday(dtTimeNow);
        String strCalenderNameRegex = 'MSTeam-%';
        List<Calendar> lstPublicCalendar = new CalendarsSelector().getActivePublicCalandarByTypeAndName(strCalenderNameRegex);
        Set<Id> setPublicCalendarId = new Set<Id>();
        if(lstPublicCalendar.isEmpty())
            return setRegionGroupHoliday;
        for(Calendar objCalendar : lstPublicCalendar){
            setPublicCalendarId.add(objCalendar.Id);
        }
        List<Event> lstEvent = [Select id,IsAllDayEvent,ActivityDate,ActivityDateTime,EndDateTime,Type,Subject,Owner.Name from Event where OwnerId IN: setPublicCalendarId AND Type = 'Holiday' AND ((IsAllDayEvent = true AND ActivityDate <=: dtToday AND EndDateTime>=: dtTimeNow) OR (IsAllDayEvent = false AND ActivityDateTime <=: dtTimeNow AND EndDateTime>=: dtTimeNow))];
        for(Event objEvt : lstEvent){
            String strRegionGouppKey = objEvt.Owner.Name.split('-')[1]+'-'+objEvt.Owner.Name.split('-')[2];
            setRegionGroupHoliday.add(strRegionGouppKey);
        }
        return setRegionGroupHoliday;
    }
    /**
     *  @author       : KD
     *  @description  :  method to list of region in off working hour
     *  @return       : void
     */
    public static Set<String> getWorkingHoursHoliday(DateTime dtTimeNow){
        Set<String> setRegionGroupWorkingHour = new Set<String>();
        new BusinessHoursSelector().selectActiveByName('CaseBH-%');
        List<BusinessHours> lstBusinessHours = new BusinessHoursSelector().selectActiveByName('CaseBH-%');
        if(lstBusinessHours.isEmpty())
            return setRegionGroupWorkingHour;
        for(BusinessHours objBusinessHour : lstBusinessHours){
            if(!BusinessHours.isWithin(objBusinessHour.Id,dtTimeNow)){
                String strRegionGouppKey = objBusinessHour.Name.split('-')[1]+'-'+objBusinessHour.Name.split('-')[2];
                setRegionGroupWorkingHour.add(strRegionGouppKey);
            }
        }
        return setRegionGroupWorkingHour;
    }
    /**
     *  @author       : KD
     *  @description  :  method to get User group of Case
     *  @return       : void
     */
    public static string getCaseUserGroup(String strCaseOwnerName){
        for(String strUserGroup : mapOfQueueKeyWordToUserRegion.keySet()){
            for(String strKeyWord : mapOfQueueKeyWordToUserRegion.get(strUserGroup)){
                if(strCaseOwnerName.contains(strKeyWord))
                    return strUserGroup;
            }
        }
        return '';
    }
}