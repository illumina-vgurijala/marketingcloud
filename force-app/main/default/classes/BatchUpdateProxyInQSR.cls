/**
*    @author: Vignesh 
*    @date:   04-Jun-2020
*    @description:  Batch class to Update Proxy Owner field In QSR based on Owner Out of office.
*    Modification Log:
*    ------------------------------------------------------------------------------------
*    Developer                      Date             Description
*    Vignesh                     04-Jun-2020        Initial Version - DCP-37395
*    ------------------------------------------------------------------------------------ 
*                    
*/
global without sharing class BatchUpdateProxyInQSR extends ilib_ScheduleAndBatch implements Database.Batchable<sObject>{
    
    Map<Id,Id> mapOOOEnabledUser = new Map<Id,Id>();
    List<Id> lstOOODisabledUser = new List<Id>();
    list<string> lstOpenStatuses = new list<string> { System.Label.QSRStatusInitiated,System.Label.QSRStatusInProgress,System.Label.QSRStatusAwaitingResponse};
       
		
	 /*
      * Constructor
      */	
    global BatchUpdateProxyInQSR(Map<Id,Id> mapOOOEnabledUser , List<Id> lstOOODisabledUser ){
        this.mapOOOEnabledUser = mapOOOEnabledUser;
        this.lstOOODisabledUser = lstOOODisabledUser;
    }
	
   /*
    * method: start method
    * Params: Database.BatchableContext
    */
    global override Database.QueryLocator start(Database.BatchableContext bc){
        
        list<Id> lstOwnerId = new list<Id>();
        lstOwnerId.addall(mapOOOEnabledUser.Keyset());
        lstOwnerId.addall(lstOOODisabledUser);
        
        string strQuery = 'Select id,OwnerId,Proxy_Owner__c,Status__c from Qualtrics_Survey_Response__c WHERE ownerId IN: lstOwnerId';
        return Database.getQueryLocator(strQuery);
    }
    
   /*
    * method: execute method
    * Params: Database.BatchableContext , List<sObject> lstRecords
    * return: void
    */
    global void execute(Database.BatchableContext bc, List<Qualtrics_Survey_Response__c> lstScope){
        list<Qualtrics_Survey_Response__c> lstQSRToUpdate = new list<Qualtrics_Survey_Response__c>();
        
        for(Qualtrics_Survey_Response__c objQSR : lstScope){
            if(mapOOOEnabledUser.containsKey(objQSR.ownerId) &&  lstOpenStatuses.contains(objQSR.Status__c) && objQSR.Proxy_Owner__c != mapOOOEnabledUser.get(objQSR.ownerId) ){
                objQSR.Proxy_Owner__c = mapOOOEnabledUser.get(objQSR.ownerId);
                lstQSRToUpdate.add(objQSR);
            }
            
            if(lstOOODisabledUser.contains(objQSR.ownerId) && objQSR.Proxy_Owner__c != Null ){
                objQSR.Proxy_Owner__c = Null;
                lstQSRToUpdate.add(objQSR);
            }
        }
        
        update lstQSRToUpdate;
    }
    
   /*
    * Method: finish
    * Params: Database.BatchableContext
    * return: void
    */
    global override void finish(Database.BatchableContext bc){
        //No Action Needed.
    }
}