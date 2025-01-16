/**
*    @author: Deep Diwakar
*    @date:   Mar-23-2024
*    @description: Test class for BatchContactMarketabilityUpdates class
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Mar-23-2024        CMCM-5552: Test class for BatchContactMarketabilityUpdates class
*    --------------------------------------------------------------------------------------------------
*/

@isTest
private class TestBatchContactMarketabilityUpdates {

    @TestSetup
    static void makeData(){
        Contact testContactOptInSingle = TestDataMarketing.createContactForMarketable('Optin', 'Single', 'testoptin@testing.com', 'JP');
        testContactOptInSingle.explicit_opt_in__c = 'Yes';

        Contact testContactOptOutSingle = TestDataMarketing.createContactForMarketable('Optout', 'Single', 'testoptout@testing.com', 'US');
        testContactOptOutSingle.implicit_opt_in__c = 'Yes';

        Contact testContactOptOutDouble = TestDataMarketing.createContactForMarketable('Optout', 'Double', 'testoptoutdouble@testing.com', 'DE');
        testContactOptOutDouble.explicit_opt_in__c = 'Yes';
        
        // making sure marketability logic don't run while creating contacts
        MarketabilityServiceFacade.testContextSkipRun = true;

        insert new List<Contact> {testContactOptInSingle, testContactOptOutSingle, testContactOptOutDouble};

        // reverting maketability logic bypass
        MarketabilityServiceFacade.testContextSkipRun = false;
        
    }

    @isTest
    static void testContactMarketabilityBatch() {

        Test.startTest();
        Database.executeBatch(new BatchContactMarketabilityUpdates());
        Test.stopTest();

        List<Contact> lstContacts = [SELECT Id, Email, Marketable__c, Marketable_Date__c, Double_Opt_In_Email_Sent_Date__c
                                     FROM Contact LIMIT 1000];

        Contact resultOptInSingle = new Contact();
        Contact resultOptOutSingle = new Contact();
        Contact resultOptOutDouble = new Contact();

        for (Contact contact : lstContacts) {
            if ('testoptin@testing.com'.equals(contact.email)) {
                resultOptInSingle = contact;
                continue;
            }

            if ('testoptout@testing.com'.equals(contact.email)) {
                resultOptOutSingle = contact;
                continue;
            }

            if ('testoptoutdouble@testing.com'.equals(contact.email)) {
                resultOptOutDouble = contact;
            }
        }

        Assert.areEqual('Yes', resultOptInSingle.Marketable__c, 'Marketability logic did not work correctly for opt in country single');
        Assert.isNotNull(resultOptInSingle.Marketable_Date__c, 'Marketability logic did not set marketable date correctly for opt in country single');

        Assert.areEqual('Yes', resultOptOutSingle.Marketable__c, 'Marketability logic did not work correctly for opt out country single');
        Assert.isNotNull(resultOptOutSingle.Marketable_Date__c, 'Marketability logic did not set marketable date correctly for opt out country single');

        Assert.isNotNull(resultOptOutDouble.Double_Opt_In_Email_Sent_Date__c, 'Marketability logic did not set double opt in email send date correctly for opt out country double');

    }

}