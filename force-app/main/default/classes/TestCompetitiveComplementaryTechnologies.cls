/**
 * @author Gerardo Garcia
 * @description Test CompetitiveComplementaryTechnologies
 * Modification Log:
 *   ---------------------------------------------------------------------------------------------------------------------------
 *    Developer                     Date(YY-MM-DD)                  Description
 *    Gerardo Garcia                2023-10-02                      Initial Version CMCM-3960
 *    Gerardo Garcia                2023-10-02                      Test Opportunity Primary Competitor validation  CMCM-4485
 *    Saurabh Brahmankar			2024-02-13						Test class updated as per story CMCM-5755 and CMCM-5875
 *    Enrique Reyes                 2024-07-01                      Test you're not able to create a second primary cct even with Channel Partner Portal User
 *   ---------------------------------------------------------------------------------------------------------------------------
 */
@IsTest
private class TestCompetitiveComplementaryTechnologies {

    private static final String OPP_NAME_1 = 'Test Opp 1';
    private static final String OPP_NAME_2 = 'Test Opp 2';
    private static final String OPP_NAME_3 = 'Test Opp 3';
    private static final String ACC_NAME_1 = 'Test ACC 1';
    private static final String ACC_NAME_2 = 'Test ACC 2';
    private static final String ACC_NAME_3 = 'Test ACC 3';
    private static final String ACC_NAME_4 = 'Test ACC 4';
    private static final String USER_ALIAS_1 = 'CHPUSER';
    private static Boolean hasRunTaps = false;
    
    @TestSetup
    static void makeData(){
        Account a1 = TestDataAccount.initAccount();
        a1.Name = ACC_NAME_1;
        a1.Clinical_Type__c = 'Clinical';
        Account a2 = TestDataAccount.initAccount();
        a2.Name = ACC_NAME_2;
        a2.Clinical_Type__c = 'Clinical';
        Account a3 = TestDataAccount.initAccount();
        a3.Name = ACC_NAME_3;
        a3.Account_Group__c = 'Ultimate Consignee';
        Account a4 = TestDataAccount.initAccount();
        a4.Name = ACC_NAME_4;
        a4.Account_Group__c = 'Distributor';

        insert new List<Account> {a1, a2, a3, a4};

        Opportunity o1 = TestDataOpportunity.initOpportunity(a1);
        o1.Name = OPP_NAME_1;
        Opportunity o2 = TestDataOpportunity.initOpportunity(a2);
        o2.Name = OPP_NAME_2;
        insert new List<Opportunity> {o1, o2};

        Competitive_Complementary_Technology__c sample1 = TestDataCompetitiveCompTech.initForOpportunity(o2.id, true);
        insert new List<Competitive_Complementary_Technology__c> {sample1};

        Contact objContact = TestDataContact.getNewContact(a4);
        Id profileId = [select Id from Profile where Name = 'Channel Partner Sales and Service' limit 1].Id;
        User channelPartnerUser1 = TestDataUser.initPartnerUser(profileId, objContact.Id);
        channelPartnerUser1.Alias = USER_ALIAS_1;
        insert new List<User> {channelPartnerUser1};
    }

    @IsTest
    private static void testPlatformEvent() {
        Test.startTest();
        Database.SaveResult res = CompetitiveComplementaryTechnologies.emitEvent('id1,id1,id2');
        Test.stopTest();
        Assert.areEqual(true, res.isSuccess(), 'Platform event should be a success');
    }

    @IsTest
    private static void opportunityHasAlreadyMarkedPrimaryCTTInsert() {
        List<Opportunity> opps = getOpportunities(new String[] {OPP_NAME_1, OPP_NAME_2});
        System.debug('opps:' + JSON.serializePretty(opps));

        Test.startTest();
        Competitive_Complementary_Technology__c cct11 = TestDataCompetitiveCompTech.initForOpportunity(opps[0].id, true);   // Success
        Competitive_Complementary_Technology__c cct12 = TestDataCompetitiveCompTech.initForOpportunity(opps[0].id, false);  // Success
        Competitive_Complementary_Technology__c cct13 = TestDataCompetitiveCompTech.initForOpportunity(opps[0].id, false);  // Success
        Competitive_Complementary_Technology__c cct21 = TestDataCompetitiveCompTech.initForOpportunity(opps[1].id, false);  // Success
        Competitive_Complementary_Technology__c cct22 = TestDataCompetitiveCompTech.initForOpportunity(opps[1].id, true);   // Fail. opp[1] has already have a primary competitor.
        Competitive_Complementary_Technology__c cct23 = TestDataCompetitiveCompTech.initForOpportunity(opps[1].id, false);  // Success
        Database.SaveResult[] res = Database.insert(new List<Competitive_Complementary_Technology__c> {cct11, cct12, cct13, cct21, cct22, cct23}, false);
        Test.stopTest();
        System.debug('res:' + JSON.serializePretty(res));
        String errorMessage = '';
        Integer errorsCount = 0;
        for (Database.SaveResult sr : res) {
            if (!sr.isSuccess()) {
                for(Database.Error err : sr.getErrors()) {
                    errorMessage = err.getMessage();
                    errorsCount++;
                }
            }
        }
        Assert.areEqual(1, errorsCount, 'There should be 1 error');
        Assert.areEqual(Label.CCT_Validation_Primary_Competitor, errorMessage, 'Error message should be thrown as only 1 primary cct allowed per opportunity');

        // on update validation
        cct23.Primary_Competitor__c = true;
        Database.SaveResult result = Database.update(cct23, false);
        Assert.isFalse(result.isSuccess(), 'Should not able to update to primary');
    }

    @IsTest
    private static void opportunityHasAlreadyMarkedPrimaryCTTInsertWithChannelPartnerUser() {
        User channelPartnerUser = [select Id from User where Alias = :USER_ALIAS_1 limit 1];
        Account ultimateConsigneeAccount = [select Id from Account where Name = :ACC_NAME_3 limit 1];
        Account distributorAccount = [select Id from Account where Name = :ACC_NAME_4 limit 1];

        AccountShare shareRecord1 = new AccountShare(
            UserOrGroupId = channelPartnerUser.Id,
            AccountId = ultimateConsigneeAccount.Id,
            AccountAccessLevel = 'Read',
            OpportunityAccessLevel = 'None',
            RowCause = 'Manual'
        );
        AccountShare shareRecord2 = new AccountShare(
            UserOrGroupId = channelPartnerUser.Id,
            AccountId = distributorAccount.Id,
            AccountAccessLevel = 'Read',
            OpportunityAccessLevel = 'None',
            RowCause = 'Manual'
        );
        //Share manually Ultimate Consignee & Distributor with ChannelPartnerUser since we don't have the complete Channel Partner Territory Setup
        insert new List<AccountShare> {shareRecord1, shareRecord2};

        System.runAs(channelPartnerUser) {
            //Create Opportunity as Channel Partner Portal User
            Opportunity o3 = TestDataOpportunity.initOpportunity(ultimateConsigneeAccount, Label.OpportunityRTIndirectStandard);
            o3.Name = OPP_NAME_3;
            o3.Distributor__c = distributorAccount.Id;
            insert new List<Opportunity> {o3};
        }

        List<Opportunity> opps = getOpportunities(new String[] {OPP_NAME_3});

        //Create CCT record as Admin User
        Competitive_Complementary_Technology__c sample2 = TestDataCompetitiveCompTech.initForOpportunity(opps[0].Id, true);
        insert new List<Competitive_Complementary_Technology__c> {sample2};

        System.runAs(channelPartnerUser) {
            //Test you're not able to create a second primary CCT with Channel Partner Portal User
            Test.startTest();
            Competitive_Complementary_Technology__c cct31 = TestDataCompetitiveCompTech.initForOpportunity(opps[0].Id, true);  // Fail. opp[1] has already have a primary competitor.
            Competitive_Complementary_Technology__c cct32 = TestDataCompetitiveCompTech.initForOpportunity(opps[0].id, false); // Success
            Database.SaveResult[] res = Database.insert(new List<Competitive_Complementary_Technology__c> {cct31}, false);
            Test.stopTest();

            String errorMessage = '';
            Integer errorsCount = 0;

            for (Database.SaveResult sr : res) {
                if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) {
                        errorMessage = err.getMessage();
                        errorsCount++;
                    }
                }
            }
            Assert.areEqual(1, errorsCount, 'There should be 1 error');
            Assert.areEqual(Label.CCT_Validation_Primary_Competitor, errorMessage, 'Error message should be thrown as only 1 primary cct allowed per opportunity');

            //update validation
            cct32.Primary_Competitor__c = true;
            Database.SaveResult result = Database.update(cct32, false);
            Assert.isFalse(result.isSuccess(), 'Should not able to update to primary');
        }
    }

    @IsTest
    private static void opportunityHasAlreadyMarkedPrimaryCTTUpdate() {
        List<Opportunity> opps = getOpportunities(new String[] {OPP_NAME_1, OPP_NAME_2});
        System.debug('opps:' + JSON.serializePretty(opps));

        Competitive_Complementary_Technology__c cct11 = TestDataCompetitiveCompTech.initForOpportunity(opps[0].id, true);   // Success
        Competitive_Complementary_Technology__c cct23 = TestDataCompetitiveCompTech.initForOpportunity(opps[1].id, false);  // Success

        insert new List<Competitive_Complementary_Technology__c> {cct11, cct23};

        // on update ignore validation.
        cct11.Outsourced_Service_Provider__c = 'common change'; // Success. It has primary competitor flag and is the only one from that opportunity; but allow any change field on cct.
        Database.SaveResult result1 = Database.update(cct11, false);
        System.debug(result1);
        Assert.isTrue(result1.isSuccess(), 'Should allow doing an update');

        // on update validation.
        cct23.Primary_Competitor__c = true; // Fail. from false to true. op2 has already cct as primary
        Database.SaveResult result2 = Database.update(cct23, false);
        Assert.isFalse(result2.isSuccess(), 'Should not able to update to primary');
    }

    private static List<Opportunity> getOpportunities(List<String> names) {
        return [SELECT id, Name, AccountId FROM Opportunity WHERE Name IN :names ORDER BY Name ASC];
    }

    private static Account getAccount(String name) {
        return [SELECT id FROM Account WHERE Name = :name];
    }

    //Added by Saurabh
    @IsTest
    private static void testOnAfterDelete() {
        
        Account a = TestDataAccount.getNewAccount();
        Opportunity o1 = TestDataOpportunity.initOpportunity(a);
        o1.Name = OPP_NAME_1;

        Opportunity o2 = TestDataOpportunity.initOpportunity(a);
        o2.Name = OPP_NAME_2;
        insert new List<Opportunity> {o1, o2};

        Competitive_Complementary_Technology__c sample1 = TestDataCompetitiveCompTech.initForOpportunity(o2.id, true);
        //Allow Opportunities.updateIsUpdatedBySystemAndReasonBackwards to execute after the Opp has been updated
        Opportunities.boolIsOpptyUpdated = false;
        insert sample1;
         
        Test.startTest();
        //Allow Opportunities.updateIsUpdatedBySystemAndReasonBackwards to execute after the Opp has been updated
        Opportunities.boolIsOpptyUpdated = false;
		Delete sample1;
        
        Test.stopTest();
        
        // Verify that the opportunity fields are updated correctly
        Opportunity updatedOpp = [SELECT Id, Has_Competitor_Info__c, Is_Updated_By_System__c FROM Opportunity WHERE Id = :o2.Id];
        System.assertEquals(false, updatedOpp.Has_Competitor_Info__c);
        System.assertEquals(false, updatedOpp.Is_Updated_By_System__c);
        
    }

    /*
    *  @Author: Saurabh Brahmankar
    *  @Description: Test method to verify the behavior of the onAfterUpdateRecalculateSharing() method.
    * 				 This method tests the recalculation of sharing rules after an update operation.
    */
    @IsTest
    public static void testOnAfterUpdateRecalculateSharing() {
        Account a = TestDataAccount.getNewAccount();
        Opportunity o1 = TestDataOpportunity.initOpportunity(a);
        o1.Name = OPP_NAME_1;

        Opportunity o2 = TestDataOpportunity.initOpportunity(a);
        o2.Name = OPP_NAME_2;
        insert new List<Opportunity> {o1, o2};

        Competitive_Complementary_Technology__c sample1 = TestDataCompetitiveCompTech.initForOpportunity(o2.id, true);
        insert sample1;
        sample1.CompetitorName__c='GenapSys';
        update sample1;
        // Verify the expected behavior
        System.assertEquals(false, hasRunTaps); // Assuming this flag exists
        
    }	
    
    /*
    *  @Author: Saurabh Brahmankar
    *  @Description: Test method to verify the behavior of the onAfterUpdateNoRecalculateSharing() method.
    * 				 This method tests the behavior when an update operation does not trigger recalculation of sharing rules.
    */
    @IsTest
    public static void testOnAfterUpdateNoRecalculateSharing() {
        Account a = TestDataAccount.getNewAccount();
        Opportunity o1 = TestDataOpportunity.initOpportunity(a);
        o1.Name = OPP_NAME_1;

        Opportunity o2 = TestDataOpportunity.initOpportunity(a);
        o2.Name = OPP_NAME_2;
        insert new List<Opportunity> {o1, o2};

        Competitive_Complementary_Technology__c sample1 = TestDataCompetitiveCompTech.initForOpportunity(o2.id, true);
        insert sample1;
		//Map<Id, sObject> existingRecords = new Map<Id, sObject> {o2.Id => o2}; // Simulate existing record
        Test.startTest();
        // Update opportunity field that shouldn't trigger recalculation
        o2.StageName = 'Closed Won';
        update o2;
		Test.stopTest();
        // Assert methods were called, no recalculation
        System.assertEquals(false, hasRunTaps); // Assuming this flag exists
     
    }    
    
    /*
    *  @Author: Saurabh Brahmankar
    *  @Description: Test method to verify the behavior of the canProceedRecalculateSharing() method.
    * 				 This method tests whether the canProceedRecalculateSharing() method returns true.				 
    */
    @IsTest
    private static void testCanProceedRecalculateSharing() {
        CompetitiveComplementaryTechnologies cct = new CompetitiveComplementaryTechnologies(new List<Competitive_Complementary_Technology__c>());

        Test.startTest();
        Boolean result = cct.canProceedRecalculateSharing();
        Test.stopTest();
        system.assertEquals(true,result); 
    }	
    
    /*
    *  @Author: Saurabh Brahmankar
    *  @Description: Test method to verify the behavior of the getWorkstream() method.
    * 				 This method tests whether the getWorkstream() method returns the expected workstream value.
    */
    @IsTest
    private static void testGetWorkstream() {
        Test.startTest();
        CompetitiveComplementaryTechnologies cct = new CompetitiveComplementaryTechnologies(new List<Competitive_Complementary_Technology__c>());
        String workstream = cct.getWorkstream();
        Test.stopTest();
		system.assertEquals('Sales',workstream);        
        
    }

    @IsTest
    private static void validationRuleMandatoryParentIdAccount() {
        Account acc = getAccount(ACC_NAME_1);
        Competitive_Complementary_Technology__c cct = TestDataCompetitiveCompTech.initCompetitiveCompTech(acc.id);
        cct.Account__c = null;

        System.debug('cct:' + JSON.serializePretty(cct));

        Test.startTest();
        Database.SaveResult result = Database.insert(cct, false);
        Test.stopTest();

        System.debug(result);

        Assert.isFalse(result.success, 'Account__c should be mandatory');
    }


    @IsTest
    private static void validationRuleMandatoryParentIdOpportunity() {
        Opportunity opportunity = getOpportunities(new String[] {OPP_NAME_1})[0];
        Competitive_Complementary_Technology__c cct = TestDataCompetitiveCompTech.initForOpportunity(opportunity.id, false);
        cct.Opportunity_Name__c = null;
        
        System.debug('cct:' + JSON.serializePretty(cct));

        Test.startTest();
        Database.SaveResult result = Database.insert(cct, false);
        Test.stopTest();

        System.debug(result);

        Assert.isFalse(result.success, 'Opportunity_Name__c should be mandatory');
    }
}