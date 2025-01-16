/***************************************************************************************************************************************
* @author Dhairya Shah
* @date 25-09-2024
*
* @description Process Builder to Flow class called WorkOrders
* MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Dhairya                 25 Sept 24           Initial Version
*
****************************************************************************************************************************************/ 
public with sharing class CreateScheduleEventHelper {
    public static List<SVMXC__Service_Group_Members__c> lstServiceGroupMembers=new List<SVMXC__Service_Group_Members__c>();
    public static DateTime endDateTime;// DS
    public static DateTime scheduledDateTime;// DS
    public static Decimal scheduledDurationInDays;//DS
    public static Integer durationInMinutes;//DS

    /*
    *  @AUTHOR: Dhairya Shah
    *  @DESCRIPTION: Requirement to convert process builder to code (Work Order : Schedule Events)
    *  @RETURN:  void
    */ 
    public static void createScheduleEvent(List<SVMXC__Service_Order__c> records, Map<Id, SObject> oldRecords) {
        if (records == null || records.isEmpty()) return;
    
        Set<String> eventId = new Set<String>();
        Set<Id> groupMemberId = new Set<Id>();
        Map<Id, Id> groupMemberIdWithUserId = getGroupMemberWithUserId(records, eventId, groupMemberId);
    
        List<Event> listEvent = new List<Event>();
    
        for (SVMXC__Service_Order__c objWorkOrder : records) { 
            SVMXC__Service_Order__c objOldWorkOrder = (SVMXC__Service_Order__c)(oldRecords.get(objWorkOrder.Id));
    
            if (shouldUpsertEvent(objWorkOrder, objOldWorkOrder, groupMemberIdWithUserId)) {
                listEvent.addAll(upsertEventRecords(objWorkOrder, objOldWorkOrder, groupMemberIdWithUserId));
            }
        }
    
        if (listEvent != null && !listEvent.isEmpty()) {
            WorkOrders.skipWOTrigger = true;
            UPSERT listEvent;
        }
    }
    
    private static Map<Id, Id> getGroupMemberWithUserId(List<SVMXC__Service_Order__c> records, Set<String> eventId, Set<Id> groupMemberId) {
        for (SVMXC__Service_Order__c takeEventId : records) {
            eventId.add(takeEventId.Scheduled_Event_ID__c);
            groupMemberId.add(takeEventId.SVMXC__Group_Member__c);
        }
    
        if (groupMemberId == null || groupMemberId.isEmpty()) return new Map<Id, Id>();
    
        if (lstServiceGroupMembers.isEmpty()) {
            lstServiceGroupMembers = new TechniciansSelector().selectTechnicians(groupMemberId);
        }
    
        Map<Id, Id> groupMemberIdWithUserId = new Map<Id, Id>();
    
        if (lstServiceGroupMembers != null && !lstServiceGroupMembers.isEmpty()) {
            for (SVMXC__Service_Group_Members__c dd : lstServiceGroupMembers) {
                groupMemberIdWithUserId.put(dd.Id, dd.SVMXC__Salesforce_User__c);
            }
        }
    
        return groupMemberIdWithUserId;
    }
    
    private static Boolean shouldUpsertEvent(SVMXC__Service_Order__c newWorkOrder, SVMXC__Service_Order__c oldWorkOrder, Map<Id, Id> groupMemberIdWithUserId) {
        Boolean returnValue = false;
        if(groupMemberIdWithUserId!=null && newWorkOrder.SVMXC__Group_Member__c!=null && newWorkOrder.SVMXC__Scheduled_Date_Time__c != null && newWorkOrder.SVMXC__SM_Scheduled_Duration__c != null
           && (newWorkOrder.SVMXC__Group_Member__c != oldWorkOrder.SVMXC__Group_Member__c || newWorkOrder.SVMXC__Scheduled_Date_Time__c != oldWorkOrder.SVMXC__Scheduled_Date_Time__c || newWorkOrder.SVMXC__SM_Scheduled_Duration__c != oldWorkOrder.SVMXC__SM_Scheduled_Duration__c)){
               returnValue = true;
           }
        return returnValue;
    }
    

    /*
    *  @AUTHOR: Dhairya Shah
    *  @DESCRIPTION: Upsert events
    *  @RETURN:  List<Event>
    */ 
    public static List<Event> upsertEventRecords(SVMXC__Service_Order__c objWorkOrder, SVMXC__Service_Order__c objOldWorkOrder, Map<Id, Id> groupMemberIdWithUserId) {
        DateTime scheduledDateTime = objWorkOrder.SVMXC__Scheduled_Date_Time__c;
        Integer scheduledDurationInHours = Integer.valueOf(objWorkOrder.SVMXC__SM_Scheduled_Duration__c);
        
        // Calculate end time by adding the scheduled duration to the start time
        DateTime endDateTime = scheduledDateTime.addHours(scheduledDurationInHours);
        
        // List to store Event records
        List<Event> listEvent = new List<Event>();
    
        // Create new event if no Scheduled_Event_ID__c exists
        if (objWorkOrder.Scheduled_Event_ID__c == null && objWorkOrder.Dispatcher__c == null && groupMemberIdWithUserId.get(objWorkOrder.SVMXC__Group_Member__c) != null) {
            Event evRecord = new Event();
            evRecord.EndDateTime = endDateTime;  // Set EndDateTime, Salesforce will auto-calculate DurationInMinutes
            evRecord.Is_Work_Order_Scheduled_by_FSE__c = true;
            evRecord.OwnerId = groupMemberIdWithUserId.get(objWorkOrder.SVMXC__Group_Member__c);
            evRecord.StartDateTime = scheduledDateTime;
            evRecord.Subject = objWorkOrder.Name;
            evRecord.WhatId = objWorkOrder.Id;
            listEvent.add(evRecord);
        } 
        // Update existing event if Scheduled_Event_ID__c is present
        else if (objWorkOrder.Scheduled_Event_ID__c != null && groupMemberIdWithUserId.get(objWorkOrder.SVMXC__Group_Member__c) != null) {
            Event objEvent = new Event(Id = objWorkOrder.Scheduled_Event_ID__c);
            objEvent.EndDateTime = endDateTime;  // Set EndDateTime, Salesforce will auto-calculate DurationInMinutes
            objEvent.OwnerId = groupMemberIdWithUserId.get(objWorkOrder.SVMXC__Group_Member__c);
            objEvent.StartDateTime = scheduledDateTime;
            objEvent.Subject = objWorkOrder.Name;
            listEvent.add(objEvent);
        }
    
        return listEvent;
    }    
    

    /*
    *  @AUTHOR: Dhairya Shah
    *  @DESCRIPTION: Requirement to convert process builder to code (Work Order : Update Installed Product Operation Status)
    *  @RETURN:  void
    */ 
    public static void updateInstalledProductOperationStatus(List<SVMXC__Service_Order__c> records,Map<Id, SObject> oldRecords) {
        
        // INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY for CS & CPUser
        if(!String.isBlank(WorkOrders.loggedInUserProfileName) &&  WorkOrders.loggedInUserProfileName != label.ProfileName_CustomerService){
            List<SVMXC__Installed_Product__c> listIP = new List<SVMXC__Installed_Product__c>();
            for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>) records){ 
                SVMXC__Service_Order__c objOldWorkOrder = (SVMXC__Service_Order__c)(oldRecords.get(objWorkOrder.Id));
                if(objWorkOrder.SVMXC__Component__c!=null){
                    listIP = installedProductOperationStatus(objWorkOrder, objOldWorkOrder);
                }
            }

            if(listIP!=null && !listIP.isEmpty()){
                dmlInstalledProductOperationStatus(listIP);
            }
        }
    }

    /*
    *  @AUTHOR: Dhairya Shah
    *  @DESCRIPTION: Requirement to convert process builder to code (Work Order : Update Installed Product Operation Status)
    *  @RETURN:  void
    */
    public static List<SVMXC__Installed_Product__c> installedProductOperationStatus(SVMXC__Service_Order__c objWorkOrder, SVMXC__Service_Order__c objOldWorkOrder) {
        List<SVMXC__Installed_Product__c> listIP = new List<SVMXC__Installed_Product__c>();
        SVMXC__Installed_Product__c updateIP = new SVMXC__Installed_Product__c(Id=objWorkOrder.SVMXC__Component__c);
        if((objWorkOrder.SVMXC__Component__r.Operation_Status__c == 'On'|| objWorkOrder.SVMXC__Component__r.Operation_Status__c =='' || objWorkOrder.SVMXC__Component__r.Operation_Status__c == null) && 
        objWorkOrder.SVMXC__Customer_Down__c == true && objOldWorkOrder.SVMXC__Customer_Down__c != objWorkOrder.SVMXC__Customer_Down__c){
            updateIP.Operation_Status__c = 'Off';
            listIP.add(updateIP);
        }else if((objWorkOrder.SVMXC__Component__r.Operation_Status__c == 'Off'|| objWorkOrder.SVMXC__Component__r.Operation_Status__c =='' || objWorkOrder.SVMXC__Component__r.Operation_Status__c == null) && 
            objWorkOrder.SVMXC__Customer_Down__c == false && objOldWorkOrder.SVMXC__Customer_Down__c != objWorkOrder.SVMXC__Customer_Down__c){
            updateIP.Operation_Status__c = 'On';
            listIP.add(updateIP);
        }
        return listIP;
    }

    /*
    *  @AUTHOR: Dhairya Shah
    *  @DESCRIPTION: Requirement to convert process builder to code (Work Order : Update Installed Product Operation Status)
    *  @RETURN:  void
    */
    public static void dmlInstalledProductOperationStatus(List<SVMXC__Installed_Product__c> listIP){
        WorkOrders.skipWOTrigger = true;
        UPDATE listIP;
    }
}