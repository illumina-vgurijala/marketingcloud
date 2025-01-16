/*
*    @author: Rishab Wali
*    @date:   11-Nov-2020
*    @description:  Batch class to auto terminate agreements.
*    Modification Log:
*    ------------------------------------------------------------------------------------
*    Developer               Date                Description
*    Nishan Shetty         13-June-2022        Implementing Batch Manager Framework DCP-50962.
*    Rishi Sharma          19-Sept-2022        DCP-56529 - Agreements getting stuck with "Terminate In progress"
*    Test Class for 90% Coverage: TestBatchAutoTerminateAgreements
*    Test Class for 75% Coverage: TestBatchAutoTerminateAgreements (As of Sept 23, 2022 - 92%)
*    ------------------------------------------------------------------------------------ 
*                    
*/
global without sharing class BatchAutoTerminateAgreements extends ilib_BatchDeferrable implements Database.AllowsCallouts {

    /* Batch Start Method to query records */
    global override Database.QueryLocator start(Database.BatchableContext bc) {        
        String query = 'SELECT Id,Apttus__Termination_Date__c,Apttus__Status__c, Validation_Status__c from Apttus__APTS_Agreement__c WHERE Apttus__Status__c != \'Terminated\' AND Apttus__Termination_Date__c = today';
        return Database.getQueryLocator(query);
    }
    /* Batch Execute Method to process records */
    global override void execute(Database.BatchableContext bc, List<sobject> lstAgreement) {  
        
        for(Apttus__APTS_Agreement__c agg : (List<Apttus__APTS_Agreement__c>)lstAgreement) {
            try {
                //Since, batch size is 1, method called in for loop
                ApttusAgreementValidateController.sendTerminateRequest(agg.Id,'Terminate', agg.Validation_Status__c);  
            } Catch(Exception e) { ApexExceptions.emit('BatchAutoTerminateAgreements',agg.Id,e); }
        }    
        
    }
    
    /* Schedulable Execute Method to schedule Batch */    
    global override void execute(SchedulableContext sc) {
        
        Map<String, String> params = UtilsSettings.getCustomMetadataMap('Auto_Terminate_Agreements');
        Integer defaultBatchSize = 100;
        Integer batchSize = UtilsSettings.parseIntegerFromSettingsMap(params, 'TerminateBatchSize', defaultBatchSize);
        if (batchSize < 1 || batchSize > 100){
            batchSize = defaultBatchSize;
        }
            //DCP-50962
            ilib_BatchManager.executeBatch(new BatchAutoTerminateAgreements(),batchSize);
    }
    /* Batch Finish Method for post execute logic */    
    global override void finish(Database.BatchableContext bc) {
       //No Logic needed.
    }
	
// ************************************************************************************************
// Deferrable implementation
// ************************************************************************************************
  
  /*
  *  @Author      : Nishan Shetty
  *  @Description : Method to simple input serialization
  *  @Param       : None
  *  @Return      : String
  */
    public override String serializeInputs() {
        return JSON.serialize('No input for this class');
    }

  /*
  *  @Author      : Nishan Shetty
  *  @Description : Method to simple input deserialization
  *  @Param       : String
  *  @Return      : void
  */
  public override void restoreInputs(String serializedInputs) { }   
    
}