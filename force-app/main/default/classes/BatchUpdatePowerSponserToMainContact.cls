/**
*    Description - Batch Class to do a one time data load to update Existing contact role records to replace Power Sponsor with Main
*	 Contact.
*    Test Class Coverage For 100% coverage: TestBatchPowerSponserToMainContactUpdate
*    Modification Log:
*   ------------------------------------------------------------------------------------------------
*    Developer                      Date                		Description
*    Priya Mukherjee              13 Sept 2023                   CMCM-2875
*    -----------------------------------------------------------------------------------------------
**/
global class BatchUpdatePowerSponserToMainContact implements Database.Batchable<sObject>{
    /**Start Method- Query for records with Power Sponsper 
     * text value 
     **/
    public Database.QueryLocator start(Database.BatchableContext bc){        
       // Query the Contact Role records that need to be updated
        String query = 'SELECT Id, Role FROM OpportunityContactRole WHERE Role = \'Power Sponsor\'';
        return Database.getQueryLocator(query);
    }
    /**Execute Method- Add Logic to the update list of records with Power Sponser value to 
     * Main Contact
     **/
    public void execute(Database.BatchableContext bc, List<OpportunityContactRole> scope){
		List<OpportunityContactRole> rolesToUpdate = new List<OpportunityContactRole>();

        // Iterate through the Contact Roles and replace 'Power Sponsor' with 'Main Contact'
        for (OpportunityContactRole role : scope) {
            role.Role = 'Main Contact';
            rolesToUpdate.add(role);
        }

        // Update the Contact Role records
        if (!rolesToUpdate.isEmpty()) {
            update rolesToUpdate;
        }
	}
    /**Finish Method- No action required
     * Logging msg after completion
     **/
	public void finish(Database.BatchableContext bc){
        
    }

}