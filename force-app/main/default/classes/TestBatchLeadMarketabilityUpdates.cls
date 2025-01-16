/**
*    @author: Deep Diwakar
*    @date:   Mar-23-2024
*    @description: Test class for BatchLeadMarketabilityUpdates class
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Mar-23-2024        CMCM-5552: Test class for BatchLeadMarketabilityUpdates class
*    --------------------------------------------------------------------------------------------------
*/

@isTest
private class TestBatchLeadMarketabilityUpdates {

    @TestSetup
    static void makeData(){
        Lead testLeadOptInSingle = TestDataMarketing.createLeadForMarketable('Optin', 'Single', 'testoptin@testing.com', 'Japan', 'Test Optin Single Inc');
        testLeadOptInSingle.explicit_opt_in__c = 'Yes';

        Lead testLeadOptOutSingle = TestDataMarketing.createLeadForMarketable('Optout', 'Single', 'testoptout@testing.com', 'USA', 'Test Optout Single Inc');
        testLeadOptOutSingle.implicit_opt_in__c = 'Yes';

        Lead testLeadOptOutDouble = TestDataMarketing.createLeadForMarketable('Optout', 'Double', 'testoptoutdouble@testing.com', 'Germany', 'Test Optout Double Inc');
        testLeadOptOutDouble.explicit_opt_in__c = 'Yes';
        
        // making sure marketability logic don't run while creating leads
        MarketabilityServiceFacade.testContextSkipRun = true;

        insert new List<Lead> {testLeadOptInSingle, testLeadOptOutSingle, testLeadOptOutDouble};

        // reverting maketability logic bypass
        MarketabilityServiceFacade.testContextSkipRun = false;

    }

    @isTest
    static void testLeadMarketabilityBatch() {

        Test.startTest();
        Database.executeBatch(new BatchLeadMarketabilityUpdates());
        Test.stopTest();

        List<Lead> lstLeads = [SELECT Id, Email, Marketable__c, Marketable_Date__c, Double_Opt_In_Email_Sent_Date__c
                                 FROM Lead LIMIT 1000];

        Lead resultOptInSingle = new Lead();
        Lead resultOptOutSingle = new Lead();
        Lead resultOptOutDouble = new Lead();

        for (Lead lead : lstLeads) {
            if ('testoptin@testing.com'.equals(lead.email)) {
                resultOptInSingle = lead;
                continue;
            }

            if ('testoptout@testing.com'.equals(lead.email)) {
                resultOptOutSingle = lead;
                continue;
            }

            if ('testoptoutdouble@testing.com'.equals(lead.email)) {
                resultOptOutDouble = lead;
            }
        }

        Assert.areEqual('Yes', resultOptInSingle.Marketable__c, 'Marketability logic did not work correctly for opt in country single');
        Assert.isNotNull(resultOptInSingle.Marketable_Date__c, 'Marketability logic did not set marketable date correctly for opt in country single');

        Assert.areEqual('Yes', resultOptOutSingle.Marketable__c, 'Marketability logic did not work correctly for opt out country single');
        Assert.isNotNull(resultOptOutSingle.Marketable_Date__c, 'Marketability logic did not set marketable date correctly for opt out country single');

        Assert.isNotNull(resultOptOutDouble.Double_Opt_In_Email_Sent_Date__c, 'Marketability logic did not set double opt in email send date correctly for opt out country double');

    }
}