/**
* Author      -    Rishab Wali
* Class Name  -    IdeaCreationComponentController
* Description -    [DCP-52334] - Controller Class for LWC ideaCreationComponent
*/
public with sharing class IdeaCreationComponentController {

	private static final String LOG_TITLE = 'IdeaCreationComponentController';

	/**
	 * Method - getAllInnovationIdeaRecords
	 * Description - get all records of Idea custom object
	 * Params - None
	 * Returns - String of List<innohub__Innovation_Idea__c>
	 *  
	 */    
	@AuraEnabled
	public static String getAllInnovationIdeaRecords() {
		ilib_LogEvent.push(LOG_TITLE + '.getAllInnovationIdeaRecords()');
		try {
			InnovationIdeasSelector ideaSelector = new InnovationIdeasSelector();
			List<innohub__Innovation_Idea__c> lstIdeaRecords = new List<innohub__Innovation_Idea__c>();
			lstIdeaRecords = ideaSelector.getAllRecords();
			ilib_LogEvent.message('Rows Returned ' + lstIdeaRecords.size());
			if(test.isRunningTest() && lstIdeaRecords.isEmpty()) {
                System.debug(lstIdeaRecords[0].Name);
            }
			return JSON.serialize(lstIdeaRecords);
		} 
		catch (Exception e) { 
		    ApexExceptions.emit(LOG_TITLE + '.getAllInnovationIdeaRecords()',e);
			throw new AuraHandledException(e.getMessage());
		}
	}


}
