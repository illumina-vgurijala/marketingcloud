/**
 *    @author Charket Team
 *    @description   DCP-49914 - Test Class for CharketServiceRequestCommentController
 */
@isTest
public class TestCharketServiceCommentController {
    /** @DESCRIPTION - setupTestData **/
    @testSetup
    static void setupTestData() {
        // Setup test data
        Charket__WeChatAccount__c wechatAccount = new Charket__WeChatAccount__c(
            Name = 'Test Account',
            Charket__SalesforceEndpoint__c = 'www.salesforcecom',
            Charket__Type__c = 'Service Account',
            Charket__WeChatOriginId__c = 'gh_e8c4857297b0',
            OpenIdAesKey__c = 'lKU1nWWjuQExIymhuvBNkm/wS8u9UiUpI67LzIy0EBI='
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
            Origin = 'Wechat',
            Region__c = 'China',
            Description = 'sxsxsx',
            WeChatFollower__c = follower.Id,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName()
                .get('Inquiry')
                .getRecordTypeId()
        );
        insert testCase;

        Comment__c testComment = new Comment__c(
            Name = 'new comment',
            Case__c = testCase.Id,
            Comment__c = 'for testing',
            Type__c = 'Illumina Comment',
            RecordTypeId = Schema.SObjectType.Comment__c.getRecordTypeInfosByName()
                .get('Case - WeChat')
                .getRecordTypeId()
        );
        insert testComment;

        ContentVersion contentVersion = new ContentVersion();
        contentVersion.VersionData = blob.valueof('cdbdcdndcj1111');
        contentVersion.Title = 'abc.txt';
        contentVersion.PathOnClient = 'abc.txt';
        contentVersion.IsMajorVersion = true;
        insert contentVersion;

        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :contentVersion.Id
        ]
        .ContentDocumentId;
        contentDocumentLink.LinkedEntityId = testComment.Id;
        contentDocumentLink.ShareType = 'V';
        insert contentDocumentLink;

        ContentDistribution newContentDistribution = new ContentDistribution();
        newContentDistribution.Name = 'abc.txt';
        newContentDistribution.ContentVersionId = contentVersion.Id;
        newContentDistribution.PreferencesAllowViewInBrowser = true;
        newContentDistribution.PreferencesLinkLatestVersion = true;
        newContentDistribution.PreferencesNotifyOnVisit = false;
        newContentDistribution.PreferencesPasswordRequired = false;
        newContentDistribution.PreferencesAllowOriginalDownload = true;
        insert newContentDistribution;
    }

    @isTest
    static void testPage() {
        Charket__WeChatAccount__c wechatAccount = [
            SELECT Id, Charket__SalesforceEndpoint__c, OpenIdAesKey__c
            FROM Charket__WeChatAccount__c
            LIMIT 1
        ];
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Comment__c testComment = [SELECT Id FROM Comment__c LIMIT 1];
        String pagePathNoCode = generatePagePath(wechatAccount.Id, testCase.Id, '');
        PageReference testPage = new PageReference(pagePathNoCode);
        testPage.getHeaders().put('User-Agent', 'MicroMessenger');
        test.setCurrentPage(testPage);
        CharketServiceRequestCommentController thisController = new CharketServiceRequestCommentController();
        thisController.init();

        String pagePath = generatePagePath(wechatAccount.Id, testCase.Id, '1234567');
        PageReference testPage2 = new PageReference(pagePath);
        testPage2.getHeaders().put('User-Agent', 'MicroMessenger');

        CharketSettings__mdt testCharketSetting = new CharketSettings__mdt(
            AesKeySize__c = 256
        );
        String cookieName = 'OPENID' + String.valueOf(wechatAccount.Id).right(14);
        Cookie openIdCookie = new Cookie(
            cookieName,
            CharketCustomUtil.encryptOpenId('abcdefg123456', wechatAccount, testCharketSetting),
            null,
            14400,
            true
        );
        testPage2.setCookies(new List<Cookie>{ openIdCookie });
        test.setCurrentPage(testPage2);
        CharketServiceRequestCommentController thisController2 = new CharketServiceRequestCommentController();
        thisController2.openId = 'abcdefg123456';
        thisController2.init();
        system.assertEquals(1, thisController2.ThisCaseComments.size());
        thisController2.contentVersion.Title = 'new file.txt';
        thisController2.contentVersion.VersionData = blob.valueof('cdbdcdndcj1111');
        thisController2.CaseCommentId = testComment.Id;
        thisController2.uploadImages();
        system.assert(thisController2.HasUploadFiles);
        CharketServiceRequestCommentController.saveTheComment(
            'test',
            testCase.Id,
            'guest',
            testComment.Id
        );
        CharketServiceRequestCommentController.updateCommentCustomerReadDateTime(testCase.Id);
        CharketServiceUpdateLogic.doBusinessLogic(new List<Id>{ testCase.Id });
        CharketCustomUtil.encryptOpenId('abcdefg123456', wechatAccount, testCharketSetting);
        testComment = [SELECT Id, Customer_Read_Date_Time__c FROM Comment__c LIMIT 1];
        system.assert(testComment.Customer_Read_Date_Time__c != null);
        
        PageReference testPage3 = new PageReference(pagePath);
        testPage3.getHeaders().put('User-Agent', 'MicroMessenger');
        test.setCurrentPage(testPage3);
        CharketServiceRequestCommentController thisController3 = new CharketServiceRequestCommentController();
        thisController3.openId = 'abcdefg123456';
        thisController3.init();
    }

    /**
     *  @author  Charket Team
     *  @description generate current page's path
     **/
    private static String generatePagePath(String accId, String caseId, String code) {
        return '/apex/CharketServiceRequestComment?wid=' + accId + '&cid=' + caseId + '&code=' + code;
    }
}