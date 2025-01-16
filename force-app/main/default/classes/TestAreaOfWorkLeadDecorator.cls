/**
 *   @author: Deep Diwakar
*    @date:   Nov-27-2023
*    @description: Test class for AreaOfWorkLeadDecorator class
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Nov-27-2023        CMCM-4510: Initial version
*    --------------------------------------------------------------------------------------------------
 */

@IsTest
private class TestAreaOfWorkLeadDecorator {

    @IsTest
    static void testAoWAutoSetInsert() {
        Lead lead = TestDataMarketing.createLeadForMarketable('Aow', 'Testaow', 'aow_test@testing.com', 'USA', 'Aow Test Inc');
        lead.Area_Of_Interest__c = 'Animal Testing';

        Test.startTest();
        insert lead;
        Test.stopTest();

        Lead resultLead = [SELECT Id, Area_Of_Work__c, Area_Of_Interest__c FROM Lead WHERE Id =: lead.Id];

        Assert.areEqual('Agrigenomics', resultLead.Area_Of_Work__c, 'Area of work field did not set correctly');

    }

    @IsTest
    static void testAoWForUserInputInsert() {
        Lead lead = TestDataMarketing.createLeadForMarketable('Aow', 'Testaow', 'aow_test@testing.com', 'USA', 'Aow Test Inc');
        lead.Area_Of_Interest__c = 'Animal Testing';
        lead.Area_Of_Work__c = 'Cancer Research';

        Test.startTest();
        insert lead;
        Test.stopTest();

        Lead resultLead = [SELECT Id, Area_Of_Work__c, Area_Of_Interest__c FROM Lead WHERE Id =: lead.Id];

        Assert.areEqual('Cancer Research', resultLead.Area_Of_Work__c, 'Area of work field did not set correctly');

    }

    @IsTest
    static void testAoWForMultipleAoI() {
        Lead lead = TestDataMarketing.createLeadForMarketable('Aow', 'Testaow', 'aow_test@testing.com', 'USA', 'Aow Test Inc');
        lead.Area_Of_Interest__c = 'Animal Testing;Cancer Research';

        Test.startTest();
        insert lead;
        Test.stopTest();

        Lead resultLead = [SELECT Id, Area_Of_Work__c, Area_Of_Interest__c FROM Lead WHERE Id =: lead.Id];

        Assert.isTrue(String.isBlank(resultLead.Area_Of_Work__c), 'Area of work field set incorrectly');

    }

    @IsTest
    static void testAoWForUpdate() {
        Lead lead = TestDataMarketing.createLeadForMarketable('Aow', 'Testaow', 'aow_test@testing.com', 'USA', 'Aow Test Inc');
        lead.Area_Of_Interest__c = 'Animal Testing';
        insert lead;

        lead.Area_Of_Interest__c = 'Genetic Health';

        Test.startTest();
        update lead;
        Test.stopTest();

        Lead resultLead = [SELECT Id, Area_Of_Work__c, Area_Of_Interest__c FROM Lead WHERE Id =: lead.Id];

        Assert.areEqual('Genetic Health', resultLead.Area_Of_Interest__c, 'Area of interest field did not set correctly');
        Assert.areEqual('Agrigenomics', resultLead.Area_Of_Work__c, 'Area of work field did not set correctly');

    }

}