/**
*    @author Sai Pasumarthy
*    @date   2024-09-26
*    @description   CMCM-6757 : C&CT: [OPP] Create 'Close Reason - Other' field
*    Test classes for 75%: TestBatchToUpdateOpportunityCloseReason
* 
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Sai Pasumarthy              2024-09-26            Initial Version
*    -----------------------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class BatchToUpdateOpportunityCloseReason implements Database.Batchable < sObject >, Database.Stateful {
    public List <Database.SaveResult> saveResults = new List <Database.SaveResult>();
    private final static String LOG_TITLE = 'BatchToUpdateOpportunityCloseReason';
    
    /*
    * @author: Sai Pasumarthy
    * @date: 2024-09-26
    * @description: Required start method for batch
    * @param: bc - batch context 
    * @return: query
    */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Close_Reason_Other__c FROM Opportunity WHERE Abandon_Reason__c = \'Other\'';
        return Database.getQueryLocator(query);
    }

    /*
    * @author: Sai Pasumarthy
    * @date: 2024-09-26
    * @description: Required execute method for batch
    * @param: bc - batch context 
    * @return: void
    */
    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        for(Opportunity opportunity : scope) {            
            opportunity.Close_Reason_Other__c = 'Pre-CCT';
            opportunitiesToUpdate.add(opportunity);
        }
        try {
            if (!opportunitiesToUpdate.isEmpty()) {
                saveResults.addAll(Database.update(opportunitiesToUpdate, false));
                handleSaveResults(saveResults, 'Opportunity');
            }
        } 
        catch (DmlException e) {
            // Log any exceptions that occurred during the update operation
            System.debug('Error in updating Opportunity: ' + e.getMessage());
        }
    }
  
     /**
    * @author Sai Pasumarthy
    * @description method to handle save results
    **/  
    public void handleSaveResults(List < Database.SaveResult > saveResults, String objectType) {
        ilib_LogEvent.push(LOG_TITLE + '.execute()');
        for (Database.SaveResult saveResult: saveResults) {
            if (!saveResult.isSuccess()) {
                for (Database.Error e: saveResult.getErrors()) {
                    ilib_LogEvent.info(objectType + ' Error: ' + e.getStatusCode() + ' - ' + e.getMessage());
                    ilib_LogEvent.info(objectType + ' fields that affected this error: ' + e.getFields());
                    ilib_LogEvent.info(objectType + ' record that affected this id: ' + saveResult.getId());
                }
            }
            if (saveResult.isSuccess()) {
                System.debug('Success Status for Opportunity records   ' + saveResult);
                ilib_LogEvent.info('Success Status for Opportunity records  ' + saveResult);
            }
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit(); 
    }

    /**
    * @author Sai Pasumarthy
    * @description finish method of Batch
    **/
    public void finish(Database.BatchableContext bc)
    {
    }
}