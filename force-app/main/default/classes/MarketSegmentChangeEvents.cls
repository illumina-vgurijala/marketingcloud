/**
 *   @author: Deep Diwakar
*    @date:   Jan-02-2024
*    @description: Platform event subscriber class for MarketSegmentChangeEvent__e event
*    @Test Class: TestMarketSegmentChangeEvents
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Jan-02-2024        Platform event subscriber class for MarketSegmentChangeEvent__e event
*    --------------------------------------------------------------------------------------------------
 */

public with sharing class MarketSegmentChangeEvents extends ilib_SObjectDomain {

    private final static String ACCOUNT = 'Account';

    /**
     * @author: Deep Diwakar
     * @date: Jan-02-2024
     * @description: Constructor
     * @param: list of platform event records
     * @return: NA
     */
    public MarketSegmentChangeEvents(List<MarketSegmentChangeEvent__e> sObjectList) {
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
          return new MarketSegmentChangeEvents(sObjectList);
        }
    }

    /**
     * @author: Deep Diwakar
     * @date: Jan-02-2024
     * @description: after insert method of trigger handler
     * @return: void
     */
    public override void onAfterInsert() {
        
        List<MarketSegmentChangeEvent__e> totalEvents = (List<MarketSegmentChangeEvent__e>) records;
        ilib_LogEvent.info('total events received: ' + totalEvents.size());
        ilib_LogEvent.info('totalEvents: ' + totalEvents);

        // get set of account id
        Set<Id> setAccountId = new Set<Id>();

        for (MarketSegmentChangeEvent__e platEvent : totalEvents) {
            if (ACCOUNT.equals(platEvent.Object_Type__c)) {
                setAccountId.add(platEvent.Object_Id__c);
            } 
        } 

        ilib_LogEvent.info('setAccountId: ' + setAccountId);

        // no account id
        if (setAccountId.isEmpty()) {
            ilib_LogEvent.info('no account id found in events');
            return;
        }

        // get all the contact records (with current AoW) for those account id
        List<Contact> lstContact = new List<Contact>();
        lstContact = new ContactsSelector().selectContactWithAow(setAccountId);

        // no contacts
        if (lstContact.isEmpty()) {
            ilib_LogEvent.info('no contacts found for given account ids');
            return;
        }

        ilib_LogEvent.info('calling decorator for lstContact: ' + lstContact);

        // call decorator
        ilib_SObjectDecorator decorator = new AreaOfWorkContactDecorator(lstContact);
        decorator.decorate();

        // update contacts
        update lstContact;

    }

}