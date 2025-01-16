/**
 *   @author: Deep Diwakar
*    @date:   June-30-2023
*    @description: Platform event subscriber trigger handler class for PardotContactResignationSync__e event
*    @Test Class: TestPardotContactsResignationSync, TestContacts, TestPardotResignationNtfQueueable
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       June-30-2023        DCP-60096: Platform event subscriber trigger handler class for PardotContactResignationSync__e event
*    --------------------------------------------------------------------------------------------------
 */

 public with sharing class PardotContactsResignationSync extends ilib_SObjectDomain {


    /**
     * @author: Deep Diwakar
     * @date: June-30-2023
     * @description: Constructor
     * @param: list of platform event records
     * @return: NA
     */
    public PardotContactsResignationSync(List<PardotContactResignationSync__e> sObjectList){
        super(sObjectList);   
        // setting workstream
        ilib_LogEvent.setWorkstream(ilib_LogEvent.MARKETING);  
    }
	
	/*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /*Method Param - List<sObject> */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
          return new PardotContactsResignationSync(sObjectList);
            
        }
    }

    /**
     * @author: Deep Diwakar
     * @date: June-30-2023
     * @description: after insert method of trigger handler
     * @return: void
     */
    public override void onAfterInsert(){

        ilib_LogEvent.info('received platform event');
        
		    List<PardotContactResignationSync__e> totalEvents = (List<PardotContactResignationSync__e>) records;
        ilib_LogEvent.info('total events received: ' + totalEvents.size());
        Set<String> emailSet = new Set<String>();

        for (PardotContactResignationSync__e event : totalEvents) {
            ilib_LogEvent.message('event email: ' + event.Contact_Email__c);
            emailSet.add(event.Contact_Email__c);
        }

        ilib_LogEvent.info('emailSet size: ' + emailSet.size());
        if (!emailSet.isEmpty()) {
            ilib_LogEvent.info('calling queueable PardotResignationNotificationQueueable');
            // call queueable 
            System.enqueueJob(new PardotResignationNotificationQueueable(new List<String>(emailSet)));
        }

    }

}