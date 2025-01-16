/**
*    Description - Batch Class to do a one time data load to delete the Entity Subscription records whose parent opportunities are
*    closed.
*    Test Class Coverage For 100% coverage: testEntitySubscriptionRecordDeletionBatch
*    Modification Log:
*   ------------------------------------------------------------------------------------------------
*    Developer                      Date                		Description
*    Priya Mukherjee              29 Aug 2023                   CMCM-790
*    -----------------------------------------------------------------------------------------------
**/
global class EntitySubscriptionRecordDeletionBatch implements Database.Batchable<sObject>{
	/**Start Method- Query for Entity Subscription records with closed 
     * parent Opportunities
     **/
    public Database.QueryLocator start(Database.BatchableContext bc){        
        String query = 'SELECT Id, ParentId FROM EntitySubscription WHERE ParentId IN (SELECT Id FROM Opportunity WHERE StageName like \'%Closed%\')';
        return Database.getQueryLocator(query);
    }
    /**Execute Method- Add subscriptions to the list for deletion for records with closed 
     * parent Opportunities
     **/
    public void execute(Database.BatchableContext bc, List<SObject> scope){
		List<EntitySubscription> subscriptionsToDelete = new List<EntitySubscription>();
        
        for (SObject record : scope) {
            EntitySubscription subscription = (EntitySubscription)record;
            subscriptionsToDelete.add(subscription);
        }
        
        // Delete the subscriptions in bulk
        if (!subscriptionsToDelete.isEmpty()) {
            delete subscriptionsToDelete;
        }
	}
    /**Finish Method- No action required
     * Logging msg after completion
     **/
	public void finish(Database.BatchableContext bc){
        ilib_LogEvent.info('EntitySubscriptionRecordDeletionBatch execution complete');
        
    }
	
}