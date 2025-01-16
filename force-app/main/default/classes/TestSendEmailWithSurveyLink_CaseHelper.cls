/**
* @author Shivani Jain
* @date 19 May 2022
*
* @description DCP-49913 Test class for SendEmailWithSurveyLink_CaseHelper
*/ 
@IsTest
private class TestSendEmailWithSurveyLink_CaseHelper {
    @testSetup
    static void setupTestData() {
        Charket__WeChatAccount__c wechatAccount = new Charket__WeChatAccount__c(
            Name = 'Test Account',
            Charket__SalesforceEndpoint__c = 'www.salesforce.com',
            Charket__Type__c = 'Service Account',
            Charket__WeChatOriginId__c = 'gh_e8c4857297b0',
            DataPrivacyPolicy__c='<p>Test</p>'
        );
        insert wechatAccount;

        Account testAccount = new Account(
            Name = 'Acme',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
                .get('Customer')
                .getRecordTypeId()
        );
        insert testAccount;

        Contact testContact = new Contact(
            firstname = 'test',
            Lastname = 'test',
            Email = 'testemail@test.com',
            Alternate_Email__c = 'testemail@test.com'
        );
        insert testContact;

        Charket__WeChatFollower__c follower = new Charket__WeChatFollower__c(
            Charket__OpenId__c = 'abcdefg123456',
            EmailVerificationCode__c = '123456',
            Charket__Contact__c = testContact.Id,
            Charket__WeChatAccount__c = wechatAccount.Id
        );
        insert follower;

        Case testCase = new Case(
            ContactId = testContact.Id,
            AccountId = testAccount.Id,
            Subject = '服务申请',
            Status = 'Initiated',
            Origin = 'WeChat - TS',
            Region__c = 'China',
            Description = 'sxsxsx',
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName()
                .get('Inquiry')
                .getRecordTypeId(),
            Category__c = 'Analysis Software',
            Sub_Type__c = 'Technical',
            WeChatFollower__c = follower.Id
        );
        insert testCase;

    }

    static testmethod void testEmail() {
        Case caseRec = [SELECT id, WeChatFollower__c, WeChatFollower__r.Email__c FROM Case LIMIT 1];
        caseRec.status='Completed';
        caseRec.Record_Updated_from_SFM__c=true;
        caseRec.Has_Inquiry_Case_Subject_Code__c = true;
        caseRec.Qualtrics_Survey_Link__c = 'www.google.com';
        update caseRec;

        Test.startTest();
        SendEmailWithSurveyLink_CaseHelper.sendEmailWithSurveyLink(new List<Case>{caseRec});
        Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();
        
        System.assert(emailInvocations > 0, 'no email sent');
    }
}
