/**
 *    @author           Akash Kumar
 *    @date             2018-05-15
 *    @description      Domain class for Technicians
 *    Modification Log:
 *    -------------------------------------------------------------------------------------------------
 *             Developer                      Date                      Description
 *             Akash Kumar                28th September 2018           Populate Field Service field 
 *																			on Opportunity
 *             Todd Newman                1st November 2019             INC0234515 utilize platform event
 *																			to update Opportunities
 *    ------------------------------------------------------------------------------------------------- 
 *                    
 */
public with sharing class Technicians extends ilib_SObjectDomain
{

		/*
         * Constructor
         */

	public Technicians(List < SVMXC__Service_Group_Members__c > sObjectList)
	{
		super(sObjectList);
	}
	/*
	 * Boilerplate which is required for base class instantiation logic
	 */
	public class Constructor implements ilib_SObjectDomain.IConstructable
	{
	    /*Param - sobjectList  */
		public ilib_SObjectDomain construct(List < SObject > sObjectList)
		{
			return new Technicians(sObjectList);
		}
	}

		/*
         * description - onAfterUpdate method
		 * return - void
         */ 
	public override void onAfterUpdate(Map<Id, SObject> existingRecords)
	{
		populateFieldServiceFieldsOnOpportunity(
            (List<SVMXC__Service_Group_Members__c>)records,
            (Map<Id, SVMXC__Service_Group_Members__c>)existingRecords
        );
	}

	/*
	 * @author          Akash Kumar
	 * @date            2018-09-28
	 * @description     Stamp FS user IDs on related opportunities
	 */
	private void populateFieldServiceFieldsOnOpportunity(List<SVMXC__Service_Group_Members__c> lstTechnicians, Map<Id, SVMXC__Service_Group_Members__c> idToOldTechician)
	{
        // filter for technicians where user Id or active flag was modified
		Set<Id> setModifiedTechnicianIds = new Set<Id>();
		for (SVMXC__Service_Group_Members__c technician : lstTechnicians)
			if (technician.SVMXC__Salesforce_User__c != idToOldTechician.get(technician.Id).SVMXC__Salesforce_User__c || technician.SVMXC__Active__c != idToOldTechician.get(technician.Id).SVMXC__Active__c)
				setModifiedTechnicianIds.add(technician.Id);

        System.debug('setModifiedTechnicianIds ' + setModifiedTechnicianIds);
        if (setModifiedTechnicianIds.isEmpty()) return;

        // find the accounts related to these technicians (via the account to field service table)
		List <Account_to_Field_Support__c> lstA2FS = new AccountTechniciansSelector().selectAccountTechnicians(setModifiedTechnicianIds);
		Set<Id> setAccountIds = UtilsCollection.getSetOfIds(lstA2FS, 'Account__c');
        System.debug('setAccountIds ' + setAccountIds);
        if (setAccountIds.isEmpty()) return;

        // INC0234515: publish event to set field service user names on opportunities
        OpportunityServiceUserRecalcs.publish(setAccountIds);
	}

}