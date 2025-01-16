/**
 *   @author: Deep Diwakar
*    @date:   June-10-2023
*    @description: Platform event subscriber trigger handler class for ProcessContactOnOpportunityClose__e event
*    @Test Class: TestProcessContactsOnOpportunityClose
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       June-27-2023        DCP-60098: Platform event subscriber trigger handler class for ProcessContactOnOpportunityClose__e event
*    --------------------------------------------------------------------------------------------------
 */

 public with sharing class ProcessContactsOnOpportunityClose extends ilib_SObjectDomain {

    private static final String STRING_OPPORTUNITY_STAGE_CLOSED_WON = 'Closed Won';
    private static final String STRING_OPPORTUNITY_STAGE_CLOSED_LOST = 'Closed Lost';
    private static final String STRING_OPPORTUNITY_STAGE_CLOSED_ABANDONED = 'Closed Abandoned';


    /**
     * @author: Deep Diwakar
     * @date: June-27-2023
     * @description: Constructor
     * @param: list of platform event records
     * @return: NA
     */
    public ProcessContactsOnOpportunityClose(List<ProcessContactOnOpportunityClose__e> sObjectList) {
        super(sObjectList);   
        // setting workstream
        ilib_LogEvent.setWorkstream(ilib_LogEvent.MARKETING);  
    }
	
	/*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable {
        /*Method Param - List<sObject> */
        public ilib_SObjectDomain construct(List<SObject> sObjectList) {
          return new ProcessContactsOnOpportunityClose(sObjectList);
        }
    }

    /**
     * @author: Deep Diwakar
     * @date: June-27-2023
     * @description: after insert method of trigger handler
     * @return: void
     */
    public override void onAfterInsert(){

        ilib_LogEvent.info('received platform event');
        
        List<ProcessContactOnOpportunityClose__e> totalEvents = (List<ProcessContactOnOpportunityClose__e>) records;
        ilib_LogEvent.info('total events received: ' + totalEvents.size());

        Set<Id> setOpptyId = new Set<Id>();
        Map<Id, String> mapContactIdToOpptyStage = new Map<Id, String>();
        Set<String> setClosedOpportunityStatusString = new Set<String>{STRING_OPPORTUNITY_STAGE_CLOSED_WON, STRING_OPPORTUNITY_STAGE_CLOSED_LOST, STRING_OPPORTUNITY_STAGE_CLOSED_ABANDONED};
        Map<Id, Contact> mapFinalUpdates = new Map<Id, Contact>();
        Set<OpportunityContactRole> closedWonOpptyContactRole = new Set<OpportunityContactRole>();
        Set<OpportunityContactRole> closedOpptyContactRole = new Set<OpportunityContactRole>();

        // collect all oppty ids
        for (ProcessContactOnOpportunityClose__e event : totalEvents) {
            setOpptyId.add(event.OpportunityId__c);
        }

        ilib_LogEvent.info('setOpptyId: ' + setOpptyId);

        // get all OCR tied to these Opportunities
        List<OpportunityContactRole> lstOcr = new OpportunityContactRoleSelector().selectAllOppContactIds(setOpptyId, 'Open Opportunity');

       // loop through all contacts to store contact id and oppty stage for recycling logic
       // if multiple closing opportunities tied to same contact then choosing closing stage that is there for 
       // last opportunity in that transaction
       for (OpportunityContactRole ocr : lstOcr) {
            mapContactIdToOpptyStage.put(ocr.Contact.Id, ocr.Opportunity.StageName);
       }

       ilib_LogEvent.info('mapContactIdToOpptyStage size: ' + mapContactIdToOpptyStage.size());

       // find MQ ocr
       Set<OpportunityContactRole> mktgQualifiedOcr = MktgWaterfallServiceHelper.findWaterfallQualifiedContactRoles(lstOcr);
       
       ilib_LogEvent.info('mktgQualifiedOcr size: ' + mktgQualifiedOcr.size());

       // find closed won and closed lost/abandon ocr from MQ ocr
       for (OpportunityContactRole ocr : mktgQualifiedOcr) {

            if (String.isNotBlank(ocr.Opportunity.StageName) && STRING_OPPORTUNITY_STAGE_CLOSED_WON.equals(ocr.Opportunity.StageName)) {
                // store ocr for closed won oppty for waterfall logic
                closedWonOpptyContactRole.add(ocr);
            } else {
                // store closed lost and abandoned oppty
                closedOpptyContactRole.add(ocr);
            }

       }

       ilib_LogEvent.info('closedWonOpptyContactRole size: ' + closedWonOpptyContactRole.size());
       ilib_LogEvent.info('closedOpptyContactRole size: ' + closedOpptyContactRole.size());

       Set<OpportunityContactRole> setFilteredOcr = new Set<OpportunityContactRole>();
       setFilteredOcr.addAll(setWaterfallFields(closedWonOpptyContactRole));

       ilib_LogEvent.info('setFilteredOcr size: ' + setFilteredOcr.size());


       // add waterfall updated contact roles to final map
       for (OpportunityContactRole ocr : setFilteredOcr) {
            mapFinalUpdates.put(ocr.Contact.Id, ocr.Contact);
       }

       // check if any reset is needed for closed lost/abandoned oppty
       List<Contact> lstResetWaterfallContacts = new List<Contact>();
       if (!closedOpptyContactRole.isEmpty()) {
           Set<Id> setContactIds = UtilsCollection.getSetOfIds(new List<OpportunityContactRole>(closedOpptyContactRole), 'ContactId');
           lstResetWaterfallContacts.addAll(MktgWaterfallServiceHelper.revaluateWaterfallStage(setContactIds));
       }

       ilib_LogEvent.info('lstResetWaterfallContacts size: ' + lstResetWaterfallContacts.size());

       // combine set and reset waterfall field updates
       for (Contact cont : lstResetWaterfallContacts) {
           if (!mapFinalUpdates.containsKey(cont.Id)) {
               mapFinalUpdates.put(cont.Id, cont);
           }
       }

        // remove any open contacts from recyle contact map
        for (OpportunityContactRole ocrOpen : new OpportunityContactRoleSelector().selectInvalidOppContactIds(mapContactIdToOpptyStage.keySet(), setClosedOpportunityStatusString, 'Open Opportunity')) {
            mapContactIdToOpptyStage.remove(ocrOpen.Contact.Id);
        }

        ilib_LogEvent.info('mapContactIdToOpptyStage size: ' + mapContactIdToOpptyStage.size());

        // recycle contacts and update final map - mapFinalUpdates
        recycleContacts(mapContactIdToOpptyStage, mapFinalUpdates);

        ilib_LogEvent.info('mapFinalUpdates: ' + mapFinalUpdates);

        // update contacts
        if (!mapFinalUpdates.isEmpty()) {
            MktgWaterfallServiceHelper.processDML(mapFinalUpdates.values());
        }

    }


    /**
     * @author: Deep Diwakar
     * @date: June-27-2023
     * @description: this method sets waterfall fields
     * @param: Set of opportunity contat role records for which we have to set waterfall fields
     * @return: Set of updatd opportunity contat role records
     */
    private Set<OpportunityContactRole> setWaterfallFields(Set<OpportunityContactRole> setOcr) {

        Set<OpportunityContactRole> updateOcr = new Set<OpportunityContactRole>();

        for (OpportunityContactRole ocr: setOcr) {
            ocr.Contact.Waterfall_Stage__c = STRING_OPPORTUNITY_STAGE_CLOSED_WON;

            if (ocr.Contact.Waterfall_Closed_Won_Date__c == null) {
                ocr.Contact.Waterfall_Closed_Won_Date__c = Datetime.Now();
            }
            if (ocr.Contact.Waterfall_Engaged_Date__c == null) {
                ocr.Contact.Waterfall_Engaged_Date__c = Datetime.Now();
            }
            if (ocr.Contact.Waterfall_Qualified_Date__c == null) {
                ocr.Contact.Waterfall_Qualified_Date__c = Datetime.Now();
            }
            if (ocr.Contact.Waterfall_Sales_Accepted_Date__c == null) {
                ocr.Contact.Waterfall_Sales_Accepted_Date__c = Datetime.Now();
            }
            if (ocr.Contact.Waterfall_Opportunity_Date__c == null) {
                ocr.Contact.Waterfall_Opportunity_Date__c = Datetime.Now();
            }

            updateOcr.add(ocr);

        }

        return updateOcr;

    }

    /**
     * @author: Deep Diwakar
     * @date: June-27-2023
     * @description: this method recycles contacts
     * @param: Map of contact id and corresponding oppty stage, final Map to collect udpated contact records
     * @return: Updated map of contact id and records
     */
    private Map<Id, Contact> recycleContacts(Map<Id, String> mapContactIdToOpptyStage, Map<Id, Contact> resultMap) {

        // recycle contact
        for (Id contId : mapContactIdToOpptyStage.keySet()) {
            Contact recycleContact;

            // check if this contact has waterfall fields updates as well. if so, then pick waterfall updated instance to combine recycle updates with it
            if (resultMap.containsKey(contId)) {
                // this contact has waterfall updates
                recycleContact = resultMap.get(contId);
            } else {
                // no waterfall updates, only recycling
                recycleContact = new Contact(Id = contId);
            }

            recycleContact.Marketing_Contact_Status__c = 'Recycled';
            recycleContact.Is_Recycled__c = true;
            recycleContact.Disposition_Code__c = mapContactIdToOpptyStage.get(contId);
            resultMap.put(contId, recycleContact);

        }

        return resultMap;

    }

}