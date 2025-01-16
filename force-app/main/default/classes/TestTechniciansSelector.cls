/***************************************************************************************************************************************
 * NAME   : TestTechniciansSelector
 * DESCRIPTION  : TestClass for TechniciansSelector class.
 *    
 * @AUTHOR : Prashanth
 * @DATE   : 29-Aug-2021  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Prashanth             29-Aug-2021             Initial Version
***************************************************************************************************************************************
*/
@isTest(seeAllData = false)
public with sharing class TestTechniciansSelector {
    static final String LANGUAGE_LOCALE_KEY = 'en_US';
    static final String STRING_USER_EMAIL = 'puser000@amamama.com';
    static final String STRING_TIMEZONE = 'America/Los_Angeles';
    static final String STRING_SERVICE_TEAM_NAME = 'Test Team';
    static SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c();
    /**
      *  @author Prashanth
      *  @description - initialize test data
    **/
    @TestSetup
    public static void initializeTestData(){
        serviceTeam = new SVMXC__Service_Group__c(
            Name = STRING_SERVICE_TEAM_NAME,
            SVMXC__Country__c = 'India'
        );
        insert serviceTeam;
        System.assert(serviceTeam.Id != null);
    }
    /**
     * @author: Prashanth.
     * @description: This method is to test the techniciansSelector class.
     */
    @IsTest
    static void techniciansSelectorTest(){
        initializeTestData();
        List < User > lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service LIMIT 1];
        SVMXC__Service_Group_Members__c technicianFAS = TestDataFieldService.createTechnician(lstUsers[0].id, 'Test Technician', serviceTeam.id);
		technicianFAS.SVMXC__Active__c = true;
        technicianFAS.SVMXC__Salesforce_User__c = lstUsers[0].Id;
		insert technicianFAS;
        Test.startTest();
        TechniciansSelector selector = new TechniciansSelector();
        System.assertEquals(1,selector.selectTechniciansMatchingUsers(new Set<Id>{lstUsers[0].Id}).size(),'Assertion Failed.');
        System.assertEquals(1,selector.selectTechnicians(new Set<Id>{technicianFAS.Id}).size(),'Assertion Failed.');
        selector.selectTechniciansrecords(new Set<Id>{technicianFAS.Id}, new Set<Id>{lstUsers[0].Id});
        Test.stopTest();
    }
}