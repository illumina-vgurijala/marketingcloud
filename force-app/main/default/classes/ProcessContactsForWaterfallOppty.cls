/**
 *   @author: Deep Diwakar
*    @date:   July-31-2023
*    @description: Platform event subscriber trigger handler class for ProcessContactOnOpportunityClose__e event
*    @Test Class: TestProcessContactsOnOpportunityClose
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       July-31-2023        DCP-60098: Platform event subscriber trigger handler class for ProcessContactOnOpportunityClose__e event
*    --------------------------------------------------------------------------------------------------
 */

public with sharing class ProcessContactsForWaterfallOppty extends ilib_SObjectDomain {

    /**
     * @author: Deep Diwakar
     * @date: June-27-2023
     * @description: Constructor
     * @param: list of platform event records
     * @return: NA
     */
    public ProcessContactsForWaterfallOppty(List<ProcessContactForWaterfallOppty__e> sObjectList) {
        super(sObjectList);    
    }
	
	/*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable {
        /*Method Param - List<sObject> */
        public ilib_SObjectDomain construct(List<SObject> sObjectList) {
          return new ProcessContactsForWaterfallOppty(sObjectList);
            
        }
    }

    /**
     * @author: Deep Diwakar
     * @date: June-27-2023
     * @description: after insert method of trigger handler
     * @return: void
     */
    public override void onAfterInsert() {

        // setting workstream
        ilib_LogEvent.setWorkstream(ilib_LogEvent.MARKETING); 

        ilib_LogEvent.info('received platform event');
        
        List<ProcessContactForWaterfallOppty__e> totalEvents = (List<ProcessContactForWaterfallOppty__e>) records;
        ilib_LogEvent.info('total events received: ' + totalEvents.size());
        ilib_LogEvent.info('totalEvents: ' + totalEvents);

        Set<Id> setContactIds = new Set<Id>();
        Set<Id> setOpptyIds = new Set<Id>();

        for (ProcessContactForWaterfallOppty__e pEvent : totalEvents) {
            if ('Contact'.equals(pEvent.Object_Type__c)) {
                setContactIds.add(pEvent.Object_Id__c);
            } else if ('Opportunity'.equals(pEvent.Object_Type__c)) {
                setOpptyIds.add(pEvent.Object_Id__c);
            }
        }

        if (!setOpptyIds.isEmpty()) {
            List<OpportunityContactRole> lstOcr = new OpportunityContactRoleSelector().selectRoles(setOpptyIds);
            setContactIds = UtilsCollection.getSetOfIds(lstOcr, 'ContactId');
        }


        ilib_LogEvent.info('setContactIds size:' + setContactIds.size());
        if (!setContactIds.isEmpty()) {
            IMktgWaterfallOpptySrvc mktgWaterfallOpptySrvc = (IMktgWaterfallOpptySrvc) MktgWaterfallOpptySrvcInjector.getWaterfallOpptyService('Default');
            mktgWaterfallOpptySrvc.executeWaterfallOpptyLogic(setContactIds);
        }   
        

    }

}