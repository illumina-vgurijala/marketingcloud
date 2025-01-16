/**
 *   @author: Deep Diwakar
*    @date:   Jul-30-2024
*    @description: Test class for MktgTaskDecorator class
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                  Description
*         Deep Diwakar       Jul-30-2024            CMCM-7519: Added test methods for MktgTaskDecorator class
*         Deep Diwakar       Oct-14-2024            CMCM-9424: Added test method to test Non-MQ task updates
*         Deep Diwakar       Dec-03-2024            CMCM-12470: Updated to adjust Task subject change
*    --------------------------------------------------------------------------------------------------
*/

@isTest
private class TestMktgTaskDecorator {

    @isTest
    static void testLeadMQTask() {
        Lead testLead = TestDataMarketing.createLeadForMarketable('Marketing', 'Testing', 'marketing_task@testing.com', 'USA', 'Marketing Task Testing Inc');
        testLead.Form_Type__c = 'Gated Files';
        testLead.Product_Interest__c = 'Consumables';
        testLead.Questions_For_Rep__c = 'Please refer to the Questions for Rep field for more information about this Lead inquiry';
        testLead.Last_Form_Submission_URL__c = 'www.test.com';

        insert testLead;

        Task mktgTestTask = new Task();
        mktgTestTask.Subject = 'A new Lead has submitted a Contact Me request! Please review!';
        mktgTestTask.WhoId = testLead.Id;
        mktgTestTask.Priority = 'Normal';
        mktgTestTask.Status = 'Open';

        //query for pardot user
        User pardotUser = [Select Id From User Where Name = 'Integration Pardot' Limit 1];

        Test.startTest();
        System.runAs(pardotUser) {
            insert mktgTestTask;
        }
        Test.stopTest();

        Task resultTask = [Select Id, Subject From Task Where Id =: mktgTestTask.Id];

        Assert.isTrue(resultTask.Subject.contains('Product Interest'), 'Marketing Task updates did not work');

    }

    @isTest
    static void testContactMQTask() {
        Contact testContact = TestDataMarketing.createContactForMarketable('Marketing', 'Testing', 'marketing_task@testing.com', 'US');
        testContact.Form_Type__c = 'Questions';
        testContact.Product_Interest__c = 'Consumables;Services';
        testContact.Questions_For_Rep__c = 'Please refer to the Questions for Rep field for more information about this Contact inquiry';
        testContact.Last_Form_Submission_URL__c = 'www.test.com';

        insert testContact;

        Task mktgTestTask = new Task();
        mktgTestTask.Subject = 'A Contact has filled out a Contact Me request! Please review!';
        mktgTestTask.WhoId = testContact.Id;
        mktgTestTask.Priority = 'Normal';
        mktgTestTask.Status = 'Open';

        //query for pardot user
        User pardotUser = [Select Id From User Where Name = 'Integration Pardot' Limit 1];

        Test.startTest();
        System.runAs(pardotUser) {
            insert mktgTestTask;
        }
        Test.stopTest();

        Task resultTask = [Select Id, Subject From Task Where Id =: mktgTestTask.Id];

        Assert.isTrue(resultTask.Subject.contains('Services'), 'Marketing Task updates did not work');

    }

    @isTest
    static void testOtherMktgTask() {
        Lead testLead = TestDataMarketing.createLeadForMarketable('Marketing', 'Testing', 'marketing_task@testing.com', 'USA', 'Marketing Task Testing Inc');
        testLead.Form_Type__c = 'Gated Files';
        testLead.Product_Interest__c = 'Consumables';
        testLead.Questions_For_Rep__c = 'Please refer to the Questions for Rep field for more information about this Lead inquiry';
        testLead.Last_Form_Submission_URL__c = 'www.test.com';

        insert testLead;

        Task nonMQTestTask = new Task();
        nonMQTestTask.Subject = 'Other Marketing task for testing!';
        nonMQTestTask.WhoId = testLead.Id;
        nonMQTestTask.Priority = 'Normal';
        nonMQTestTask.Status = 'Open';

        //query for pardot user
        User pardotUser = [Select Id From User Where Name = 'Integration Pardot' Limit 1];

        Test.startTest();
        System.runAs(pardotUser) {
            insert nonMQTestTask;
        }
        Test.stopTest();

        Task resultTask = [Select Id, Subject From Task Where Id =: nonMQTestTask.Id];

        Assert.isFalse(resultTask.Subject.contains('Product Interest'), 'Marketing Task updates did not work');

    }

    @isTest
    static void testNonMQTask() {
        Lead testLead = TestDataMarketing.createLeadForMarketable('Marketing', 'Testing', 'marketing_task@testing.com', 'USA', 'Marketing Task Testing Inc');
        testLead.Form_Type__c = 'Gated Files';
        testLead.Product_Interest__c = 'Consumables';
        testLead.Questions_For_Rep__c = 'Please refer to the Questions for Rep field for more information about this Lead inquiry';
        testLead.Last_Form_Submission_URL__c = 'www.test.com';

        insert testLead;

        Task nonMQTestTask = new Task();
        nonMQTestTask.Subject = 'Follow up information requested! Please review!';
        nonMQTestTask.WhoId = testLead.Id;
        nonMQTestTask.Priority = 'Normal';
        nonMQTestTask.Status = 'Open';

        //query for pardot user
        User pardotUser = [Select Id From User Where Name = 'Integration Pardot' Limit 1];

        Test.startTest();
        System.runAs(pardotUser) {
            insert nonMQTestTask;
        }
        Test.stopTest();

        Task resultTask = [Select Id, Subject From Task Where Id =: nonMQTestTask.Id];

        Assert.isTrue(resultTask.Subject.contains('Product Interest'), 'Marketing Task updates for Non MQ task did not work');

    }

}