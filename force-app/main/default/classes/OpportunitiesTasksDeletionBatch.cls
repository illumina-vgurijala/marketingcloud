/**
*    Description - Batch Class to Delete the Tasks for related Opprtunities.
*    Test Class Coverage For 100% coverage: TestOpportunitiesTasksDeletionBatch
*    Modification Log:
*   ------------------------------------------------------------------------------------------------
*    Developer                      Date                		Description
*    Balakrishna                    3rd August 2023              CMCM-1367  
*    -----------------------------------------------------------------------------------------------
**/
global class OpportunitiesTasksDeletionBatch implements Database.Batchable<sObject> {
    
    /* START METHOD */
    global Database.QueryLocator start(Database.BatchableContext bC) {
        return Database.getQueryLocator([SELECT Id FROM Task WHERE Subject LIKE'%Update Opportunity: Complete all other stage-related exit criteria%']);
    }
    
    /* EXECUTE METHOD */
    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        System.debug('## deleting Task records :: '+scope.size());   
 		ilib_LogEvent.info('Deleting Task reccords : '+ scope.size());
        //delete list of Tasks records
        if(!scope.isEmpty()){
            delete scope;   
            Database.emptyRecycleBin(scope);
        } 
    }
    
    /* FINISH METHOD */
    global void finish(Database.BatchableContext bc) { }

}