/**
*    @author Adyasha Satapathy
*    @date   2021-05-20
*    @description    Selector Class For Events, DCP-39601
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                  Date                   Description
*    Adyasha Satapathy        20 May 2021            Initial Version
*    Venkatesh Prabhu         3rd December 2024      CMCM-12168 Too many SOQL queries: 101
*    ------------------------------------------------------------------------------------                   
*/
public with sharing class EventsSelector extends ilib_SObjectSelector
{
    private static final String LOG_TITLE = 'EventsSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    /**
     *  @author  Adyasha
     *  @description Retrieve sObjectType
     *  @return Schema.SObjectType
     **/
    public Schema.SObjectType getSObjectType()
    {
        return Event.sObjectType;
    }
    /**
     *  @author  Adyasha
     *  @description Retrieve list of fields for Event sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Event.Id,
            Event.OwnerId,
            Event.WhatId,
            Event.StartDateTime,
            Event.EndDateTime,
            Event.Subject,
            Event.IsAllDayEvent
        };      
    }
    /**
     *  @author Adyasha
     *  @description Fetch the List of Events based on WhatId
     *  @param Set of WhatIds
     *  @return List<Event>
     **/
    public List<Event> selectEventsForWhatId(Set<Id> setWhatIds)
    {
        return (List<Event>) Database.query(
            newQueryFactory()
            .setCondition('WhatId IN :setWhatIds')
            .toSOQL()
        );
    }

     /**
     * @author Venkatesh Prabhu
     * @description Fetches a list of Events based on specified criteria including start and end date, owner IDs, and event subject
     * @param startDateTime 
     * @param endDateTime 
     * @param ownerIds 
     * @param eventSubject 
     * @return  `List<Event>`
     */
    public List<Event > getTechnicianCalender(DateTime startDateTime, DateTime endDateTime, Set<Id> ownerIds, String eventSubject) {
        ilib_LogQuery logger = null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.ownerIds', UtilsCollection.serializeIds(ownerIds));
        }
        
        List<Event> res = (List<Event>) Database.query(
            newQueryFactory()
            .setCondition('StartDateTime <= : startDateTime AND EndDateTime >= : endDateTime AND OwnerId IN : ownerIds AND Subject LIKE : eventSubject').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        
        return res;
    }   
}