/* @ author       : Rishab Wali
* @ date         :  06-Jan-2022
* @ Description  : Event Trigger helper class contains all Business logic implementation
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
*---------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class Events extends ilib_SObjectDomain{
    
    /*
    * Description : Constructor
    */
    public Events(List<Event> sObjectList)
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
            return new Events(sObjectList);
        }
    }

    /**
     *  @author       : Rishab Wali
     *  @description  : 
     *  @return       : void
     */
    public override void onAfterInsert()
    {
        List<Event> lstEvent = (List<Event>)trigger.new;
        Set<Id> setLeadIds = new Set<Id>();
        Map<Id,DateTime> mapLeadIdToEventStartDate = new Map<Id,DateTime>();

        for(Event objEvent : lstEvent)
        {
            if(objEvent.whoId != null && objEvent.WhoId.getSObjectType().getDescribe().getName() == 'Lead')
            {
                setLeadIds.add(objEvent.whoId);
                mapLeadIdToEventStartDate.put(objEvent.whoId,objEvent.StartDateTime);
            }
        }

        if(!setLeadIds.isEmpty())
        {
            updateMostRecentActivityDateLead(setLeadIds,mapLeadIdToEventStartDate);
        }
    }

     /**
     *  @author       : Rishab Wali
     *  @description  : 
     *  @return       : void
     */
    public override void onAfterUpdate(Map<Id, SObject> oldRecords)
    {
        List<Event> lstEvent = (List<Event>)trigger.new;
        Map<Id,Event> oldMap = (Map<Id,Event>)trigger.oldMap;
        Set<Id> setLeadIds = new Set<Id>();
        Map<Id,DateTime> mapLeadIdToEventStartDate = new Map<Id,DateTime>();

        for(Event objEvent : lstEvent)
        {
            if(objEvent.whoId != null && objEvent.WhoId.getSObjectType().getDescribe().getName() == 'Lead'
               && oldMap.get(objEvent.Id).StartDateTime != objEvent.StartDateTime)
            {
                setLeadIds.add(objEvent.whoId);
                mapLeadIdToEventStartDate.put(objEvent.whoId,objEvent.StartDateTime);
            }
        }

        if(!setLeadIds.isEmpty())
        {
            updateMostRecentActivityDateLead(setLeadIds,mapLeadIdToEventStartDate);
        }

    }

    /**
     *  @author       : Rishab Wali
     *  @description  : [DCP-49756] Update Most Recent Activity Date
     *  @return       : void
     */
    public void updateMostRecentActivityDateLead(Set<Id> leadIds , Map<Id,DateTime> mapLeadIdToEventStartDate)
    {
        List<lead> updatedLeads = new List<lead>();
        Lead newLead = new Lead();
        for(Lead objLead : [SELECT Id,Most_Recent_Activity_Date__c FROM Lead WHERE Id =: leadIds])
        {
            newLead.Id = objLead.Id;
            if(mapLeadIdToEventStartDate.get(objLead.Id) > objLead.Most_Recent_Activity_Date__c)
            {
                newLead.Most_Recent_Activity_Date__c =  mapLeadIdToEventStartDate.get(objLead.Id);
            }
            updatedLeads.add(newLead);
            newLead = null;
        }
        Database.update(updatedLeads,false);
    }

}
