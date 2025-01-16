/***************************************************************************************************************************************
 * NAME   : TestTechnicians
 * DESCRIPTION  : TestClass for Technicians Trigger
 *          
 *    
 * @AUTHOR : Akash Kumar.
 * @DATE   : 30-September-2018  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                          DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Akash Kumar           30-September-2018               Initial Version
 ****************************************************************************************************************************************/
@isTest(SeeAllData = false)
public with sharing class TestTechnicians
{
	@testSetup
		/*Test Data*/
	public static void initializeTestData()
	{

		List < User > lstUsers = [SELECT Id
			FROM User
			WHERE Profile.Name =: System.label.Field_Service
			LIMIT 1
		];
		SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam('Test', 'country');
		insert serviceTeam;
	}
	/**
	 *    @author Akash Kumar
	 *    @date   2018-09-28
	 *    @description Update Scenarios for Populate field service fields
	 */
	static testMethod void updateFieldServicesFieldOnOpportunityOnUpdate()
	{

		SVMXC__Service_Group__c serviceTeam = [Select id from SVMXC__Service_Group__c];
		System.debug('serviceTeam' + serviceTeam);
		List < User > lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service LIMIT 1];
		SVMXC__Service_Group_Members__c technicianFAS = TestDataFieldService.createTechnician(lstUsers[0].id, 'Test Technician', serviceTeam.id);
		technicianFAS.SVMXC__Active__c = true;
		insert technicianFAS;

		List < Opportunity > lstOpportunity = new List < Opportunity > ();

		Account acc1 = TestDataAccount.getNewAccount();
		acc1.Account_Group__c = 'Distributor';

		Account acc2 = TestDataAccount.getNewAccount();
		acc2.Account_Group__c = 'Distributor';

		List < Account > lstAccount = new List < Account > ();
		lstAccount.add(acc1);
		lstAccount.add(acc2);

		update lstAccount;

        Opportunity opp1 = TestDataOpportunity.initOpportunity(acc1, Label.OpportunityRTDirectStandard);
        opp1.Name = 'opp1';
        opp1.Ultimate_Consignee__c = acc1.Id;
        Opportunity opp2 = TestDataOpportunity.initOpportunity(acc1, Label.OpportunityRTIndirectStandard);
        opp2.Name = 'opp2';
        opp2.Distributor__c = acc1.Id;
        opp2.Ultimate_Consignee__c = acc1.Id;
        opp2.Direct_Sale_to_Ultimate_Consignee__c = false;
        lstOpportunity.add(opp1);
        lstOpportunity.add(opp2);

		insert lstOpportunity;

		Account_to_Field_Support__c afs1 = new Account_to_Field_Support__c(User__c = technicianFAS.Id,
			Account__c = acc1.Id, User_Role__c = 'Primary Field Application Scientist');

		Account_to_Field_Support__c afs2 = new Account_to_Field_Support__c(User__c = technicianFAS.Id,
			Account__c = acc1.Id, User_Role__c = 'Field Application Manager');

		Account_to_Field_Support__c afs3 = new Account_to_Field_Support__c(User__c = technicianFAS.Id,
			Account__c = acc1.Id, User_Role__c = 'Primary Field Service Engineer');

		Account_to_Field_Support__c afs4 = new Account_to_Field_Support__c(User__c = technicianFAS.Id,
			Account__c = acc1.Id, User_Role__c = 'Field Service Manager');

		list < Account_to_Field_Support__c > lstAccFS = new list < Account_to_Field_Support__c > ();
		lstAccFS.add(afs1);
		lstAccFS.add(afs2);
		lstAccFS.add(afs3);
		lstAccFS.add(afs4);
		insert lstAccFS;

		test.startTest();

		technicianFAS.SVMXC__Active__c = false;
		update technicianFAS;

		test.stopTest();
		Opportunity opp = [Select id, Primary_Field_Service_Engineer__c from Opportunity where Name =: 'opp1'];
		System.assert(true, opp.Primary_Field_Service_Engineer__c = null);
	}
}