/*@ author       : Saurabh Brahmankar
* @ date         : 03-05-2024
* @ Description  : Batch class to update fields Primary Field Service Engineer and Primary Field Application Scientis from Account 
				   if the related Account to Field Support records have a Primary Field Service Engineer field or Primary Field Application Scientist user role
*
* 100% Code Coverage: TestBatchToUpdateAccountPFASandPFSE
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Saurabh Brahmankar       03-05-2024             Initial version
*
*/

global class BatchToUpdateAccountFieldsPFASandPFSE implements Database.Batchable<sObject> {

	private static final String LOG_TITLE = 'BatchAccountFieldsUpdatePFASandPFSE';
    private static final String PRIMARY_FIELD_APPLICATION_SCIENTIST = 'Primary Field Application Scientist';
    private static final String PRIMARY_FIELD_SERVICE_ENGINEER = 'Primary Field Service Engineer';

    // Map to store User Ids and their corresponding names
    Map<Id, String> userIdToNameMap;
    
    /*
    *  @Author: Saurabh Brahmankar
    *  @Description: constructor to pass the user name value to parent constructor
    */    
    global BatchToUpdateAccountFieldsPFASandPFSE() {
    userIdToNameMap = new Map<Id, String>();
    }
    /**
     * @author: Saurabh Brahmankar
     * @date: 03-05-2024
     * @description: Required start method for batch
     * @param: bc - batch context
     * @return: query
     */
    /*Query for updating fields through batch*/
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, User_Role__c, User__c, Account__c, User__r.Name
            FROM Account_to_Field_Support__c
            WHERE User_Role__c IN ('Primary Field Application Scientist', 'Primary Field Service Engineer')
        ]);
    }    
    

    /**
     * @author: Saurabh Brahmankar
     * @date: 03-05-2024
     * @description: Required execute method for batch
     * @param: bc - batch context
     * @return: void
     */    
    /*Execute method of Batch Class*/    
    global void execute(Database.BatchableContext bc, List<Account_to_Field_Support__c> scope) {
        Map<Id, Account> accMap = new Map<Id, Account>();

        // Fetch User Ids and corresponding names and store them in userIdToNameMap
        for (Account_to_Field_Support__c supportRecord : scope) {
            userIdToNameMap.put(supportRecord.User__c, supportRecord.User__r.Name);
        }
        
        // Iterate through the child records
        for (Account_to_Field_Support__c supportRecord : scope) {
            Id accountId = supportRecord.Account__c;

            // Check if the account is already in the map
            if (!accMap.containsKey(accountId)) { 
                accMap.put(accountId, new Account(Id = accountId));
            }

            // Update the relevant custom fields based on User Role
            //Account accToUpdate = accMap.get(accountId);
            if (supportRecord.User_Role__c == PRIMARY_FIELD_APPLICATION_SCIENTIST) {
                accMap.get(accountId).Primary_Field_Application_Scientist__c = userIdToNameMap.get(supportRecord.User__c);
            } else if (supportRecord.User_Role__c == PRIMARY_FIELD_SERVICE_ENGINEER) {
                accMap.get(accountId).Primary_Field_Service_Engineer__c = userIdToNameMap.get(supportRecord.User__c);
            }
        }

        // Update the account records
        if (!accMap.isEmpty()) {
        //update accMap.values();
        Database.SaveResult[] updateResults = Database.update(accMap.values(), false);
            for (Integer i = 0; i < updateResults.size(); i++) {
    		if (updateResults[i].isSuccess()) {
        		System.debug('updateResults ==>'+updateResults[i]);
    		} else {
        	// Handle error for failed update
        	Database.Error error = updateResults[i].getErrors()[0];
        	String errorMessage = error.getMessage();
        	// Handle the error as needed
        	System.debug('errorMessage ==>'+errorMessage);
    		}
			}
        }
    }            
    
    /**
     * @author: Saurabh Brahmankar
     * @date: 03-05-2024
     * @description: Required final method for batch
     * @param: bc - batch context
     * @return: void
     */
    global void finish(Database.BatchableContext bc) {
        ilib_LogEvent.push(LOG_TITLE + '.finish()');
		system.debug('Batch Job Completed.');
        ilib_LogEvent.info('No work for finish method.');
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();

    }    
    
}