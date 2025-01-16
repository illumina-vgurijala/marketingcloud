/**
 *    @author David
 *    @date   20 Dec 2021
 *    @description  Test Class for CharketDataPrivacyConsentController
 *    Modification Log:
 *    ------------------------------------------------------------------------------------
 *    Developer                         Date                     Description
 *    David (Charket)                   20 Dec 2021               Test class of CharketDataPrivacyConsentController.
 * ---------------------------------------------------------------------------------------
 */
@isTest
public class TestCharketDataPrivacyConsentController {
    /** @DESCRIPTION - setupTestData **/
    @testSetup
    static void setupTestData() {
        // Setup test data
        Charket__WeChatAccount__c wechatAccount = new Charket__WeChatAccount__c(
            Name = 'Test Account',
            Charket__SalesforceEndpoint__c = 'www.salesforcecom',
            Charket__Type__c = 'Service Account',
            Charket__WeChatOriginId__c = 'gh_e8c4857297b0',
            DataPrivacyPolicy__c='<p> Test </p>'
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
            Email = 'test@test.com',
            Alternate_Email__c = 'test@test.com'
        );
        insert testContact;
        Case testCase = new Case(
            ContactId = testContact.Id,
            AccountId = testAccount.Id,
            Subject = '服务申请',
            Status = 'Initiated',
            Origin = 'Wechat',
            Region__c = 'China',
            Description = 'sxsxsx',
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName()
                .get('Inquiry')
                .getRecordTypeId()
        );
        insert testCase;
        Charket__WeChatFollower__c follower = new Charket__WeChatFollower__c(
            Charket__OpenId__c = 'abcdefg123456',
            EmailVerificationCode__c = '123456',
            Charket__Contact__c = testContact.Id,
            Charket__WeChatAccount__c = wechatAccount.Id
        );
        insert follower;
    }

    /** @DESCRIPTION - test Controller **/
    @isTest
    static void testController() {
        Charket__WeChatAccount__c wechatAccount = [
            SELECT Id, Charket__SalesforceEndpoint__c
            FROM Charket__WeChatAccount__c
            LIMIT 1
        ];
         system.assert(wechatAccount.id != null);
        PageReference testPage = new PageReference(
            '/apex/CharketDataPrivacyConsent?wechatAccountId=' + wechatAccount.Id
        );
        testPage.getHeaders().put('User-Agent', 'MicroMessenger');
        test.setCurrentPage(testPage);
        CharketDataPrivacyConsentController thisController = new CharketDataPrivacyConsentController();
        system.assert(thisController.dataPrivacyPolicy!= null);
    }
}