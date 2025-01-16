/**
*    @author: Deep Diwakar
*    @date:   Feb-13-2024
*    @description: Test class for BatchLeadAOWUpdates class
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Feb-13-2024        CMCM-4508: Test class for BatchLeadAOWUpdates class
*    --------------------------------------------------------------------------------------------------
*/

@isTest
private class TestBatchLeadAOWUpdates {

    @isTest
    static void testBatchMultipleUpdates() {
        Lead leadSingleAOW = TestDataMarketing.createLeadForMarketable('AowS', 'TestaowS', 'aow_s_test@testing.com', 'USA', 'Aow Single Test Inc');
        leadSingleAOW.Area_Of_Interest__c = 'Animal Testing';

        Lead leadMultipleAOW = TestDataMarketing.createLeadForMarketable('AowM', 'TestaowM', 'aow_m_test@testing.com', 'USA', 'Aow Multiple Test Inc');
        leadMultipleAOW.Area_Of_Interest__c = 'Animal Testing;Cancer Research';

        Lead leadNoneAOW = TestDataMarketing.createLeadForMarketable('AowNone', 'TestaowNone', 'aow_none_test@testing.com', 'USA', 'Aow None Test Inc');

        // Bypass trigger so we don't set AOW values through trigger
        cs_Apex_Settings__c objApexSettings=cs_Apex_Settings__c.getInstance();
        objApexSettings.Bypass_All_Triggers__c=true;
        upsert objApexSettings cs_Apex_Settings__c.Id;

        insert new List<Lead>{leadSingleAOW, leadMultipleAOW, leadNoneAOW};

        // Revert bypass
        objApexSettings.Bypass_All_Triggers__c=false;
        upsert objApexSettings cs_Apex_Settings__c.Id;

        // start test
        Test.startTest();

        Database.executeBatch(new BatchLeadAOWUpdates());

        Test.stopTest();

        List<Lead> lstResultLead = [SELECT Id, Area_Of_Work__c, Email FROM Lead WHERE Email IN ('aow_s_test@testing.com', 'aow_m_test@testing.com', 'aow_none_test@testing.com')];

        Lead resultSingle, resultMultiple, resultNone;

        for (Lead lead : lstResultLead) {
            if ('aow_s_test@testing.com'.equals(lead.Email)) {
                resultSingle = lead;
            } else if ('aow_m_test@testing.com'.equals(lead.Email)) {
                resultMultiple = lead;
            } else {
                resultNone = lead;
            }
        }

        Assert.areEqual('Agrigenomics', resultSingle.Area_Of_Work__c, 'Batch update did not set single AOW correctly');
        Assert.isNull( resultMultiple.Area_Of_Work__c, 'Batch update did not set multiple AOW correctly');
        Assert.isNull(resultNone.Area_Of_Work__c, 'Batch update did not set none AOW correctly');
        
    }

    @isTest
    static void testBatchWithoutAOI() {
        Lead leadNoAOI = TestDataMarketing.createLeadForMarketable('AowNone', 'TestaowNone', 'aow_none_test@testing.com', 'USA', 'Aow None Test Inc');
        insert leadNoAOI;

        // start test
        Test.startTest();

        Database.executeBatch(new BatchLeadAOWUpdates());

        Test.stopTest();
        Lead resultLead = [SELECT Id, Area_Of_Work__c, Area_Of_Interest__c FROM Lead WHERE Id =: leadNoAOI.Id];

        Assert.isNull(resultLead.Area_Of_Work__c, 'Batch update did not work correctly for no AOI scenario');

    }

    @isTest
    static void testBatchWithAOINoAOW() {
        Lead leadWithAOI = TestDataMarketing.createLeadForMarketable('AowNone', 'TestaowNone', 'aow_none_test@testing.com', 'USA', 'Aow None Test Inc');
        
        // in case of multiple AOI values, we skip setting AOW
        leadWithAOI.Area_Of_Interest__c = 'Animal Testing;Cancer Research';
        insert leadWithAOI;

        // start test
        Test.startTest();

        Database.executeBatch(new BatchLeadAOWUpdates());

        Test.stopTest();
        Lead resultLead = [SELECT Id, Area_Of_Work__c, Area_Of_Interest__c FROM Lead WHERE Id =: leadWithAOI.Id];

        Assert.isNull(resultLead.Area_Of_Work__c, 'Batch update did not work correctly for with AOI scenario');

    }

}