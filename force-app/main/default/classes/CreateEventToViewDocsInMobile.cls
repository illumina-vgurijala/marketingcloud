/***************************************************************************************************************************************
    * NAME   : CreateEventToViewDocsInMobile
    * DESCRIPTION  : Logic for creating event on WO to view attachments on mobile
    *                    
    * @AUTHOR : Adyasha Satapathy
    * @DATE   : 11-Jun-2021  
    * 
    * MODIFICATION LOG: 
    * -----------------------------------------------------------------------------------------------------------------------------------------------------------
    * DEVELOPER                DATE                DESCRIPTION 
    * ------------------------------------------------------------------------------------------------------------------------------------------------------------
    * Adyasha Satapathy        11-Jun-2021         DCP-47185: Create Event to view WO Attached Docs in mobile
******************************************************************************************************************************************************************/
public with sharing class CreateEventToViewDocsInMobile {
    private static final String LOG_TITLE = 'CreateEventToViewDocsInMobile';
    private static final String EVENT_SUBJECT = 'Quote Created';

    /**
     *  @author       : Adyasha Satapathy
     *  @description  : Create Event to enable viewing Documents on mobile app
     *  @return       : void
     */
    public static void createEventToViewWODocument(Set<Id> setWorkOrderIds)
    {
        ilib_LogEvent.push(LOG_TITLE + '.createEventToViewWODocument()');
        List<Event> lstEvents = new List<Event>();
        Map<Id,Set<Id>> mapWorkOrderToEventOwnerIds = new Map<Id,Set<Id>>();
        //Set<Id> setWorkOrderIds = UtilsCollection.getSetOfIds(lstWorkOrders);
        
        List<SVMXC__Service_Order__c> lstUpdatedWO = new WorkOrdersSelector().selectWorkOrderId(setWorkOrderIds);
        List<Event> lstExistingEvents = new EventsSelector().selectEventsForWhatId(setWorkOrderIds);
        
        for(Event objEvent : lstExistingEvents)
        {
            if(!mapWorkOrderToEventOwnerIds.containsKey(objEvent.WhatId))
            {
                mapWorkOrderToEventOwnerIds.put(objEvent.WhatId, new Set<Id>());
            }
            mapWorkOrderToEventOwnerIds.get(objEvent.WhatId).add(objEvent.OwnerId);
        }
        for(SVMXC__Service_Order__c objWO : lstUpdatedWO)
        {
            // check if set contains current Work Order OwnerId
            if(mapWorkOrderToEventOwnerIds.isEmpty() 
            ||(mapWorkOrderToEventOwnerIds.containsKey(objWO.Id)
            && !mapWorkOrderToEventOwnerIds.get(objWO.Id).contains(objWO.OwnerId)))
            {
                Event objEvent = new Event();
                objEvent.OwnerId = objWO.OwnerId; //user id
                objEvent.WhatId = objWO.id; //record id
                objEvent.StartDateTime = System.now();
                objEvent.EndDateTime = System.now().addMinutes(15);
                objEvent.Subject = EVENT_SUBJECT;            
                lstEvents.add(objEvent);
            }
        }
        if(!lstEvents.isEmpty())
        {
            insert lstEvents;
        }
        ilib_LogEvent.pop();
    }
}