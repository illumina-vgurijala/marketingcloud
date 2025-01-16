/*
*  @Author:
*  @Date: 
*  @Description:
*
*  @Test Class for above 90% coverage.
*    -TestLocations
*  @Test Class for atleast 75% coverage.
      -TestLocations
*  Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                    Description
*  Nishan Shetty                 24-Aug-2022            DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
*    ------------------------------------------------------------------------------------                  
*/
public with sharing class Locations extends ilib_SObjectDomain {

    public static Boolean hasRunTaps = false;
    public static Boolean bypassTapsOnInsert = false; // for unit testing only

		/*
         * Constructor
         */ 
    public Locations(List<SVMXC__Site__c> sObjectList)
    {
        super(sObjectList);
    }
    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
	    /*Param - sobjectList  */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new Locations(sObjectList);
        }
    }
	
		/*
         * description - onBeforeInsert method
		 * return - void
         */	
    public override void onBeforeInsert(){
        setStockingLocationForPartnerStock(records);
    }

		/*
         * description - onBeforeUpdate method
		 * return - void
         */
    public override void onBeforeUpdate(Map<Id, SObject> oldRecords){
        setStockingLocationForPartnerStock(records);
    }
    
    //Set the Stocking location to true for partner locations
    private void setStockingLocationForPartnerStock(List<Sobject> oldRecords){
        for(SVMXC__Site__c objLocation : (List<SVMXC__Site__c>)records){
            if(objLocation.Type__c == 'Partner Stock'){
                objLocation.SVMXC__Stocking_Location__c = true;
            }
        }
    }

        /*
         * description - populateAccountOnLocation method
		 * return - void
         */
    public static void populateAccountOnLocation(List<Id>listLocationIds){
        Set<String> setERPCustomerIds= new Set<String>();
        List<SVMXC__Site__c> listLocation = new List<SVMXC__Site__c>();
        List<SVMXC__Site__c> listGetLocation = new List<SVMXC__Site__c>();
        if(listLocationIds.size() > 0){
            for(SVMXC__Site__c objLocation : new LocationsSelector().selectLocations(listLocationIds)){
                if((objLocation.SVMXC__Account__c == null)&&((objLocation.Type__c == 'Ultimate Consignee')||(objLocation.Type__c == 'Sold To')))
                    {
                        setERPCustomerIds.add(objLocation.ERP_Customer_Id__c); 
                        listGetLocation.add(objLocation);                       
                    }  
            }
            
            for(Account objAcc: new AccountsSelector().selectAccountsForERPCustomerIds(setERPCustomerIds)){
                for(SVMXC__Site__c objLocation1 : listGetLocation){
                    if(objAcc.ERP_Customer_Id__c == objLocation1.ERP_Customer_Id__c)
                    objLocation1.SVMXC__Account__c = objAcc.Id;
                    listLocation.add(objLocation1);
                }
            }
                
            update listLocation;
                
        }              
   }

        /*
         * description - onAfterInsert method
		 * return - void
         */
    public override void onAfterInsert()
    {
	    List <Id> listLocationIds = new List<Id> ();
        if (!bypassTapsOnInsert) {
        TAPS_OrchestratorInterface tapsOrchestrator = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
        tapsOrchestrator.recalculateRecordChanges(UtilsCollection.getSetOfIds(records,'Id'),getSObjectType());//DCP-44091
        }
        
        for(SVMXC__Site__c loc: (List<SVMXC__Site__c>)records){
            listLocationIds.add(loc.Id);
        } 
		
		 ilib_Queueablethread  queueableThread = new ilib_Queueablethread('LocationsAfterInsert');
         queueableThread.logandQueue(new LocationQueueable('populateAccountOnLocation', listLocationIds ),'LocationQueueable','populateAccountOnLocation');   
          if(queueableThread!=null)
          //CMSI-36 workstream passed
          ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SALES); 
    }

        /*
         * description - onAfterUpdate method
		 * return - void
         */
    public override void onAfterUpdate(Map<Id, sObject> existingRecords)
    {
        if (!hasRunTaps && !isInsertOperationForObject(getSObjectType()))
        {
            List<String> fieldsThatTriggerRecalculation = new List<String> { 'OwnerId', 'SVMXC__Account__c' };
            TAPS_OrchestratorInterface tapsOrchestratorInst = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
            Set<Id> idsThatNeedRecalculation = tapsOrchestratorInst.updateRequiresRecalculation(records, existingRecords, fieldsThatTriggerRecalculation);//DCP-44091
            if (idsThatNeedRecalculation.size() > 0)
            {
                tapsOrchestratorInst.recalculateRecordChanges(idsThatNeedRecalculation, getSObjectType());//DCP-44091
                hasRunTaps = true;
            }
        }
    }

}