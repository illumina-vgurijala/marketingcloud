/*@ author       : Shaik Moulali
* @ date         : 10-04-2018
* @ Description  : Test class for Partner Help Request Controller class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Shaik Moulali          10-04-2018                 US-4252             Initial version
* Gerardo Garcia         18-12-2024                                     CMCM-13201 OpportunityClosedStageModal component CommetD implementation.
*/
@IsTest(SeeAllData=false)
private class TestPartnerHelpRequestController {
    private static final String TEST_NAME = 'TestUser_2024';

    @TestSetup
    static void makeData(){
        Id profileId = [SELECT id FROM profile WHERE name='Channel Partner Sales and Service'].id;

        Account ac =TestDataAccount.initAccount();
        insert ac;

        Contact con =TestDataContact.getNewContact(ac);

        User user = TestDataUser.initPartnerUser(profileId, con.id);
        user.FirstName= TEST_NAME;
        insert user;
        System.debug('user:' + user);
    }

    /*
    * test method for PartnerHelpRequestForm aura component Controller & Helper
    */		
    @IsTest
    private static void testPartnerHelpRequest (){
        User user = [SELECT id FROM User WHERE FirstName = :TEST_NAME LIMIT 1];
        
        List<Partner_Request__c> lstPartnerRequest = TestDataPartnerPortal.getNewPartnerRequest(1);
        //perform the test
        Test.startTest();
        System.runAs (user){
            PartnerHelpRequestController.fetchUserDetails();
            PartnerHelpRequestController.saveHelpRequest(lstPartnerRequest.get(0),'Partner_request__c','Help Request');
        } 
        Test.stopTest(); 
        Partner_Request__c partnerRequest = [SELECT Id, RecordType.Name FROM Partner_Request__c LIMIT 1];
        System.debug(partnerRequest.recordType.Name);
        Assert.areEqual('Help Request', partnerRequest.recordType.Name);
    }
    @isTest
    private static void errorPartnerHelpRequest() {
        User user = [SELECT id FROM User WHERE FirstName = :TEST_NAME LIMIT 1];
        String error;
        //perform the test
        Test.startTest();
        System.runAs (user){
            PartnerHelpRequestController.fetchUserDetails();
            error = PartnerHelpRequestController.saveHelpRequest(null, 'invalid param','invalid param');
        } 
        Test.stopTest();
        Assert.isNotNull(error, 'error message should have content');
    }
    /**
     * @description: Test for slOpportunityClosedStagePlatformEventCatch
     * @return: NA
     */
    @isTest
    private static void fetchSessionId(){
        User user = [SELECT id FROM User WHERE FirstName = :TEST_NAME LIMIT 1];
        String sessionId;
        Test.startTest();
        System.runAs (user){
            sessionId = PartnerHelpRequestController.fetchSessionId();
            System.debug('sessionId:' + sessionId);
        } 
        Test.stopTest(); 
        Assert.isNotNull(sessionId, 'Session not found?');
    }
}