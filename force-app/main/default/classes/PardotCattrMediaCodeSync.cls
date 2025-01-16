/**
 *   @author: Deep Diwakar
*    @date:   June-10-2023
*    @description: Platform event subscriber trigger handler class for PardotCattrMediaCodeSync event
*    @Test Class: TestPardotCattrMediaCodeSync, TestCampaignMembers, TestPardotCattrMediaCodeQueueable
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       June-10-2023        CMCM-1164: Platform event subscriber trigger handler class for PardotCattrMediaCodeSync event
*    --------------------------------------------------------------------------------------------------
 */

public with sharing class PardotCattrMediaCodeSync extends ilib_SObjectDomain {

    /**
     * @author: Deep Diwakar
     * @date: June-10-2023
     * @description: Constructor
     * @param: list of platform event records
     * @return: NA
     */
    public PardotCattrMediaCodeSync(List<PardotCattrMediaCodeSync__e> sObjectList){
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
          return new PardotCattrMediaCodeSync(sObjectList);
            
        }
    }

    /**
     * @author: Deep Diwakar
     * @date: June-10-2023
     * @description: after insert method of trigger handler
     * @return: void
     */
    public override void onAfterInsert(){

        ilib_LogEvent.info('received platform event');
        
		List<PardotCattrMediaCodeSync__e> totalEvents = (List<PardotCattrMediaCodeSync__e>) records;
        ilib_LogEvent.info('total events received: ' + totalEvents.size());

        // map for storing campaign member email to Pardot sync fields
        Map<String, Map<String, Boolean>> emailToSyncFieldsMap = new Map<String, Map<String, Boolean>>();

        for (PardotCattrMediaCodeSync__e event : totalEvents){

            Map<String, Boolean> syncFieldMap = new Map<String, Boolean>();
            syncFieldMap.put('Cattr', event.Cattr__c);
            syncFieldMap.put('MediaCode', event.Media_Code__c);

            emailToSyncFieldsMap.put(event.Email__c, syncFieldMap);

        }

        ilib_LogEvent.info('Map created: ' + emailToSyncFieldsMap);
        System.enqueueJob(new PardotCattrMediaCodeQueueable(emailToSyncFieldsMap));


    }
}