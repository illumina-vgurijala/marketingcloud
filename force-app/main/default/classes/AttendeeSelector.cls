/**
*    @author: Pankaj Singla
*    @date:   12-Aug-2020
*    @description:  Selector class for Attendee Object
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla		        12-Aug-2020		       Initial Build
*             Rishab Wali               07-June-2022           [DCP-53883] Adding Query Instrumentation		
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class AttendeeSelector extends ilib_SObjectSelector{
	
    public static final string LOG_TITLE = 'AttendeeSelector';
    public static final String MARKETING_QUERY_LOGS = 'MarketingQueryLogs';
    string stringSortOrder = 'openq__Interaction__r.LastModifieddate DESC';

    /*
    * Method - Return sObject Type
    */
    public Schema.SObjectType getSObjectType()
    {
        return openq__Attendee__c.sObjectType;
    }
  	
	/*
    *  @author  Pankaj singla
    *  @description return the orderby field 
    *  @String Sort Order
    */
	
	public override String getOrderBy(){
        return stringSortOrder;
    }
    
	/*
    *  @author  Pankaj singla
    *  @description Retrieve list of fields for Attendee Object 
    *  @return sObjectFieldList list of Schema.SObjectField
    */
	
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField>{
            openq__Attendee__c.Id,
            openq__Attendee__c.Name,
            openq__Attendee__c.openq__Contact__c,
            openq__Attendee__c.openq__Interaction__c                
         };
    }
	
	/*
    *  @author Pankaj singla
    *  @description Fetch the Attendee
    *  @param lst of Attendees
    *  @return List of Attendees  
    */
    public List<openq__Attendee__c> selectAttendeesFromTrigger(List<openq__Attendee__c> lstnewAttendees) {
        ilib_LogQuery logger = null;

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            Set<Id> setAttendeeIds = UtilsCollection.getSetOfIds(lstnewAttendees);
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAttendeesFromTrigger',UtilsCollection.serializeIds(setAttendeeIds));
        }

        stringSortOrder = 'openq__Interaction__r.LastModifieddate DESC';
        List<openq__Attendee__c> res = (List<openq__Attendee__c>) Database.query(
                                        newQueryFactory().selectField('openq__Interaction__r.name')
                                       .selectField('openq__Interaction__r.openq__Date__c')
                                       .selectField('openq__Interaction__r.LastModifieddate')
                                       .selectField('openq__Interaction__r.openq__Interaction_Name__c')
                                       .selectField('openq__Interaction__r.openq__Interaction_Type__c')
                                       .selectField('openq__Contact__r.ownerId')            
                                       .setCondition('id in:lstnewAttendees').toSOQL()    
                                       );

        if (Feature.isOn(MARKETING_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }
	
	/*
    *  @author Pankaj singla
    *  @description Fetch the Attendee based on ContactId
    *  @param set of ContactIds
    *  @return List of Attendees  
    */
    public List<openq__Attendee__c> selectAttendeesByContactIds(Set<Id> setContactIds){
        ilib_LogQuery logger = null;

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAttendeesByContactIds',UtilsCollection.serializeIds(setContactIds));
        }

        stringSortOrder = 'openq__Interaction__r.LastModifieddate DESC';
        List<openq__Attendee__c> res = (List<openq__Attendee__c>) Database.query(
                                        newQueryFactory().selectField('openq__Interaction__r.name')
                                        .selectField('openq__Interaction__r.openq__Date__c')
                                        .selectField('openq__Interaction__r.LastModifieddate')
                                        .selectField('openq__Interaction__r.openq__Interaction_Name__c')
                                        .selectField('openq__Interaction__r.openq__Interaction_Type__c')
                                        .selectField('openq__Contact__r.ownerId')            
                                        .setCondition('openq__Contact__c in:setContactIds').toSOQL()    
                                        );

        if (Feature.isOn(MARKETING_QUERY_LOGS)) {
            logger.stop(res.size());
        }
                                
        return res;
    }
}