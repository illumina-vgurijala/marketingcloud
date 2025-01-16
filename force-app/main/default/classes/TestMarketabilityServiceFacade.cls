/**
*    @author: Deep Diwakar
*    @date:   Mar-07-2024
*    @description: Test class for testing Marketability logic
     @Test Class:  It is a Test class for MarketabilityServiceFacade and GlobalMarketabilityStrategyV1 
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Mar-07-2024        CMCM-5551: Test class for MarketabilityServiceFacade and GlobalMarketabilityStrategyV1 
*         Deep Diwakar       Mar-23-2024        CMCM-5552: Added few more test methods
*         Deep Diwakar       May-22-2024        CMCM-7994: Added test methods for Cvent Marketability logic
*         Deep Diwakar       May-30-2024        CMCM-7770: Added test methods for Captello Marketability logic
* --------------------------------------------------------------------------------------------------
*/

@isTest
private class TestMarketabilityServiceFacade {

    @isTest
    static void testOptInCountrySingle() {
        Lead testLead = TestDataMarketing.createLeadForMarketable('Marketability', 'Testing', 'marketability@testing.com', 'Japan', 'Marketability Test Inc');
        testLead.explicit_opt_in__c = 'Yes';
        
        Test.startTest();
        insert testLead;
        Test.stopTest();

        Lead resultLead = [SELECT Id, Marketable__c, Marketable_Date__c FROM Lead WHERE Id =: testLead.Id];

        Assert.areEqual('Yes', resultLead.Marketable__c, 'Marketability logic did not work correctly for opt in country single');
        Assert.isNotNull(resultLead.Marketable_Date__c, 'Marketability logic did not set marketable date correctly for opt in country single');

    }

    @isTest
    static void testOptInCountrySingleNoOptIn() {
        Lead testLead = TestDataMarketing.createLeadForMarketable('Marketability', 'Testing', 'marketability@testing.com', 'Japan', 'Marketability Test Inc');
        testLead.explicit_opt_in__c = 'No';
        
        Test.startTest();
        insert testLead;
        Test.stopTest();

        Lead resultLead = [SELECT Id, Marketable__c, Marketable_Date__c FROM Lead WHERE Id =: testLead.Id];

        Assert.areEqual('No', resultLead.Marketable__c, 'Marketability logic did not work correctly for opt in country single with explicit No');
        Assert.isNull(resultLead.Marketable_Date__c, 'Marketability logic did not set marketable date correctly for opt in country single with explicit No');

    }

    @isTest
    static void testOptOutCountrySingle() {
        Lead testLead = TestDataMarketing.createLeadForMarketable('Marketability', 'Testing', 'marketability@testing.com', 'USA', 'Marketability Test Inc');
        testLead.implicit_opt_in__c = 'Yes';
        
        Test.startTest();
        insert testLead;
        Test.stopTest();

        Lead resultLead = [SELECT Id, Marketable__c, Marketable_Date__c FROM Lead WHERE Id =: testLead.Id];
        Assert.areEqual('Yes', resultLead.Marketable__c, 'Marketability logic did not work correctly for opt out country single');
        Assert.isNotNull(resultLead.Marketable_Date__c, 'Marketability logic did not set marketable date correctly for opt out country single');

    }

    @isTest
    static void testOptOutCountrySingleNoOptIn() {
        Lead testLead = TestDataMarketing.createLeadForMarketable('Marketability', 'Testing', 'marketability@testing.com', 'USA', 'Marketability Test Inc');
        testLead.implicit_opt_in__c = 'No';
        
        Test.startTest();
        insert testLead;
        Test.stopTest();

        Lead resultLead = [SELECT Id, Marketable__c, Marketable_Date__c FROM Lead WHERE Id =: testLead.Id];
        Assert.areEqual('No', resultLead.Marketable__c, 'Marketability logic did not work correctly for opt out country single with no opt in');
        Assert.isNull(resultLead.Marketable_Date__c, 'Marketability logic did not set marketable date correctly for opt out country single with no opt in');

    }

    @isTest
    static void testOptOutCountryDouble() {
        // Country - Germany, CountryCode - DE
        Contact testContact = TestDataMarketing.createContactForMarketable('Marketability', 'Testing', 'marketability@testing.com', 'DE');
        testContact.explicit_opt_in__c = 'Yes';
        
        Test.startTest();
        insert testContact;
        Test.stopTest();

        Contact resultContact = [SELECT Id, Double_Opt_In_Email_Sent_Date__c FROM Contact WHERE Id =: testContact.Id];
        Assert.isNotNull(resultContact.Double_Opt_In_Email_Sent_Date__c, 'Marketability logic did not set double opt in email send date correctly for opt out country double');

    }

    @isTest
    static void testOptOutCountryDoubleUpdate() {
        // Country - Germany, CountryCode - DE
        Contact testContact = TestDataMarketing.createContactForMarketable('Marketability', 'Testing', 'marketability@testing.com', 'DE');
        testContact.explicit_opt_in__c = 'Yes';
        insert testContact;

        testContact.double_opt_in__c = 'Yes';
        
        Test.startTest();
        update testContact;
        Test.stopTest();

        Contact resultContact = [SELECT Id, Marketable__c, Marketable_Date__c FROM Contact WHERE Id =: testContact.Id];
        Assert.areEqual('Yes', resultContact.Marketable__c, 'Marketability logic did not work correctly for opt out country double');
        Assert.isNotNull(resultContact.Marketable_Date__c, 'Marketability logic did not set marketable date correctly for opt out country double');

    }

    @isTest
    static void testOptInCountryDouble() {
        Lead testLead = TestDataMarketing.createLeadForMarketable('Marketability', 'Testing', 'marketability@testing.com', 'Japan', 'Marketability Test Inc');
        testLead.explicit_opt_in__c = 'Yes';
        insert testLead;
        
        Test.startTest();
        // Since there is not opt in country double, directly calling opt in country double method
        GlobalMarketabilityStrategyV1 mktgOptInDouble = new GlobalMarketabilityStrategyV1();
        mktgOptInDouble.setMarketableForOptInCountryDouble(testLead);
        Test.stopTest();

        Assert.isNotNull(testLead.Double_Opt_In_Email_Sent_Date__c, 'Marketability logic did not set double opt in email send date correctly for opt out country double');

    }

    @isTest
    static void testOptInCountryDoubleOptedYes() {
        Lead testLead = TestDataMarketing.createLeadForMarketable('Marketability', 'Testing', 'marketability@testing.com', 'Japan', 'Marketability Test Inc');
        testLead.explicit_opt_in__c = 'Yes';
        testLead.double_opt_in__c = 'Yes';

        insert testLead;
        
        Test.startTest();
        // Since there is not opt in country double, directly calling opt in country double method
        GlobalMarketabilityStrategyV1 mktgOptInDouble = new GlobalMarketabilityStrategyV1();
        mktgOptInDouble.setMarketableForOptInCountryDouble(testLead);
        Test.stopTest();

        Assert.areEqual('Yes', testLead.Marketable__c, 'Marketability logic did not set marketability correctly for opt out country double');

    }

    @isTest
    static void testOptOutScenario() {
        Lead testLead = TestDataMarketing.createLeadForMarketable('Marketability', 'Testing', 'marketability@testing.com', 'Japan', 'Marketability Test Inc');
        testLead.explicit_opt_in__c = 'Yes';
        insert testLead;

        testLead.Pardot_Opted_Out__c = true;
        
        Test.startTest();
        update testLead;
        Test.stopTest();

        Lead resultLead = [SELECT Id, Marketable__c, Marketable_Date__c FROM Lead WHERE Id =: testLead.Id];

        Assert.areEqual('No', resultLead.Marketable__c, 'Marketability logic did not work correctly for opt out scenario');
        Assert.isNull(resultLead.Marketable_Date__c, 'Marketability logic did not clear marketable date correctly for opt out scenario');

    }

    @isTest
    static void testLeadCountryCode() {
        Lead testLead = TestDataMarketing.createLeadForMarketable('Marketability', 'Testing', 'marketability@testing.com', 'Japan', 'Marketability Test Inc');
        testLead.explicit_opt_in__c = 'Yes';
        testLead.Country = '';
        testLead.CountryCode = 'JP';
        
        Test.startTest();
        insert testLead;
        Test.stopTest();

        Lead resultLead = [SELECT Id, Marketable__c, Marketable_Date__c FROM Lead WHERE Id =: testLead.Id];

        Assert.areEqual('Yes', resultLead.Marketable__c, 'Marketability logic did not work correctly for opt in country single');
        Assert.isNotNull(resultLead.Marketable_Date__c, 'Marketability logic did not set marketable date correctly for opt in country single');

    }

    @isTest
    static void testSkipScenrario() {
        Lead testLead = TestDataMarketing.createLeadForMarketable('Marketability', 'Testing', 'marketability@testing.com', 'USA', 'Marketability Test Inc');
        testLead.implicit_opt_in__c = 'Yes';

        MarketabilityServiceFacade.testContextSkipRun = true;
        
        Test.startTest();
        insert testLead;
        Test.stopTest();

        Lead resultLead = [SELECT Id, Marketable__c, Marketable_Date__c FROM Lead WHERE Id =: testLead.Id];
        Assert.isNull(resultLead.Marketable__c, 'Marketability logic did not work correctly for skip test scenario');
        Assert.isNull(resultLead.Marketable_Date__c, 'Marketability logic did not set marketable date correctly for skip test scenario');

    }

    @isTest
    static void testOptInRuleUnknown() {
        Contact testContact = TestDataMarketing.createContactForMarketable('Marketability', 'Testing', 'marketability@testing.com', 'US');
        testContact.MailingCountryCode = '';
        testContact.explicit_opt_in__c = 'Yes';
        
        Test.startTest();
        insert testContact;
        Test.stopTest();

        Contact resultContact = [SELECT Id, Opt_in_Rule__c, Marketable__c, Marketable_Date__c FROM Contact WHERE Id =: testContact.Id];

        Assert.areEqual('Unknown', resultContact.Opt_in_Rule__c, 'Marketability logic did not work correctly for opt in rule unknown');
       
    }

    @isTest
    static void testCventOptInInsert() {
        User cventUser = [SELECT Id FROM User WHERE Name = 'Integration Cvent' AND IsActive = true];

        Lead testLead = new Lead();

        Test.startTest();
        System.runAs(cventUser) {
            testLead = TestDataMarketing.createLeadForMarketable('Marketability', 'Testing', 'marketability@testing.com', 'USA', 'Marketability Test Inc');
            testLead.cvent_opt_in__c = 'Yes';
            testLead.cvent_contact_me__c = 'Yes';
            insert testLead;
        }
        Test.stopTest();

        Lead resultLead = [SELECT Id, cvent_opt_in__c, cvent_opt_in_change_date__c, cvent_contact_me_date__c
                             FROM Lead WHERE Id =: testLead.Id LIMIT 1];
        Assert.areEqual(resultLead.cvent_opt_in_change_date__c, Date.today(), 'Cvent opt in change date did not set correctly in insert scenario');
        Assert.areEqual(resultLead.cvent_contact_me_date__c, Date.today(), 'Cvent contact me date did not set correctly in insert scenario');
    
    }

    @isTest
    static void testCventOptInUpdate() {
        User cventUser = [SELECT Id FROM User WHERE Name = 'Integration Cvent' AND IsActive = true];

        Contact testContact = new Contact();
        Test.startTest();
        System.runAs(cventUser) {
            testContact = TestDataMarketing.createContactForMarketable('Marketability', 'Testing', 'marketability@testing.com', 'US');
            testContact.cvent_opt_in__c = 'No';
            insert testContact;

            testContact.cvent_opt_in__c = 'Yes';
            testContact.cvent_contact_me__c = 'Yes';
            update testContact;

        }
        Test.stopTest();

        Contact resultContact = [SELECT Id, cvent_opt_in__c, cvent_opt_in_change_date__c, cvent_contact_me_date__c
                                  FROM Contact WHERE Id =: testContact.Id LIMIT 1];

        Assert.areEqual(resultContact.cvent_opt_in_change_date__c, Date.today(), 'Cvent opt in change date did not set correctly in update scenario');
        Assert.areEqual(resultContact.cvent_contact_me_date__c, Date.today(), 'Cvent contact me date did not set correctly in update scenario');

    }

    @isTest
    static void testCaptelloOptInInsert() {
        User captelloUser = [SELECT Id FROM User WHERE Name = 'Integration Captello' AND IsActive = true];

        Lead testLead = new Lead();

        Test.startTest();
        System.runAs(captelloUser) {
            testLead = TestDataMarketing.createLeadForMarketable('Marketability', 'Testing', 'marketability@testing.com', 'USA', 'Marketability Test Inc');
            testLead.captello_opt_in__c = 'Yes';
            testLead.captello_contact_me__c = 'Yes';
            insert testLead;
        }
        Test.stopTest();

        Lead resultLead = [SELECT Id, captello_opt_in__c, captello_opt_in_change_date__c, captello_contact_me_date__c
                             FROM Lead WHERE Id =: testLead.Id LIMIT 1];
        Assert.areEqual(Date.today(), resultLead.captello_opt_in_change_date__c, 'Captello opt in change date did not set correctly in insert scenario');
        Assert.areEqual(Date.today(), resultLead.captello_contact_me_date__c, 'Captello contact me date did not set correctly in insert scenario');
    
    }

    @isTest
    static void testCaptelloOptInUpdate() {
        User captelloUser = [SELECT Id FROM User WHERE Name = 'Integration Captello' AND IsActive = true];

        Contact testContact = new Contact();
        Test.startTest();
        System.runAs(captelloUser) {
            testContact = TestDataMarketing.createContactForMarketable('Marketability', 'Testing', 'marketability@testing.com', 'US');
            testContact.captello_opt_in__c = 'No';
            insert testContact;

            testContact.captello_opt_in__c = 'Yes';
            testContact.captello_contact_me__c = 'Yes';
            update testContact;

        }
        Test.stopTest();

        Contact resultContact = [SELECT Id, captello_opt_in__c, captello_opt_in_change_date__c, captello_contact_me_date__c
                                  FROM Contact WHERE Id =: testContact.Id LIMIT 1];

        Assert.areEqual(Date.today(), resultContact.captello_opt_in_change_date__c, 'Captello opt in change date did not set correctly in update scenario');
        Assert.areEqual(Date.today(), resultContact.captello_contact_me_date__c, 'Captello contact me date did not set correctly in update scenario');

    }

}