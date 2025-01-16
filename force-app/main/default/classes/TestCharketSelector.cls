/**
*   @author Charket
*   @date 12-Oct-2023
*
*   @description Test class for CharketSelector class
* *  Modification Log:
 *  -------------------------------------------------------------------------------------------------------------------
 *      Developer                      Date                Description
 *      Charket                       29-Mar-2024          Added new method testSelectWeChatRecords
 *  -------------------------------------------------------------------------------------------------------------------
 */
@isTest
public class TestCharketSelector {
    private static final String WECHAT_RECORD_TYPE_NAME = 'Case - WeChat';
    private static final String COMMENT_TYPE = 'Illumina Comment';
    private static final String EMAIL_TEMPLATE_NAME = 'Charket_Verification_Code_Email';
    private static final String CHINA_QUEUE_NAME =  'China Technical Support';

    /** @DESCRIPTION - test charket selector **/
    @isTest
    static void testSelectors() {
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

        String recordTypeId = Schema.SObjectType.Comment__c.getRecordTypeInfosByName().get(WECHAT_RECORD_TYPE_NAME).getRecordTypeId();
        
        Test.startTest();
        new CharketSelector().selectWeChatAccountsById(wechatAccount.Id);
        new CharketSelector().selectOpenCasesWithWeChatComments(follower.Id);
        new CharketSelector().selectCaseByCaseNumber('03451899');
        new CharketSelector().selectInstalledProduct('123');
        new CharketSelector().selectInstalledProductBySerialLotNumber('123');
        new CharketSelector().selectAccountContactRelationByEmail(testAccount.Id, 'test@test.com');
        new CharketSelector().selectAccountContactRelationByAlternateEmail(testAccount.Id, 'test@test.com');
        new CharketSelector().selectContactByEmail('test@test.com');
        new CharketSelector().selectContactByAlternateEmail('test@test.com');
        new CharketSelector().selectContactById(testContact.Id);
        new CharketSelector().selectContentVersionById(contentVersion.Id);
        new CharketSelector().selectContentDocumentLinks(new Set<Id>{testCase.Id});
        new CharketSelector().selectContentVersionByCDIds(new Set<ID>{contentDocumentLink.ContentDocumentId});
        new CharketSelector().selectContentDistributionByCVs(new List<ContentVersion>{contentVersion});
        new CharketSelector().selectCasesByCaseId(testCase.Id);
        new CharketSelector().selectWeChatCommentByCaseId(testCase.Id, recordTypeId);
        new CharketSelector().selectUnreadWeChatCommentByCaseId(new List<Id>{testCase.Id}, COMMENT_TYPE, recordTypeId);
        new CharketSelector().selectCommentById(testComment.Id);
        new CharketSelector().selectEmailTemplateByName(EMAIL_TEMPLATE_NAME);
        new CharketSelector().selectOrgWideEmailAddress('test@test.com');
        new CharketSelector().selectGroupByName('CHINA_QUEUE_NAME');
        
        ilib_LogEvent.emit();
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Charket__WeChatAccount__c> wechatAccounts = new CharketSelector().selectWeChatAccountsById(wechatAccount.Id);
        System.assert(wechatAccounts.size() > 0);
    }

    /** @DESCRIPTION - test select wechat records **/
    @isTest
    static void testSelectWeChatRecords(){
        Account testAccount = new Account(
            Name = 'Acme',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
                .get('Customer')
                .getRecordTypeId()
        );
        insert testAccount;
        Charket__WeChatAccount__c wechatAccount = new Charket__WeChatAccount__c(
            Name = 'Test Account',
            Charket__SalesforceEndpoint__c = 'www.salesforcecom',
            Charket__Type__c = 'Service Account',
            Charket__WeChatOriginId__c = 'gh_e8c4857297b0',
            UsedFor__c = 'Customer Care'
        );
        insert wechatAccount;
        Charket__WeChatFollower__c follower = new Charket__WeChatFollower__c(
            Charket__OpenId__c = 'abcdefg123456',
            Charket__IndexedUnionId__c = 'unionidabcdefg123456',
            IsEmailVerified__c = true,
            Charket__WeChatAccount__c = wechatAccount.Id
        );
        insert follower;
        Profile p = [select Id from Profile where Name = 'System Administrator'];
        User user = new User(
            Alias = 'test007', Email = 'testuseragent@test003.com',
            EmailEncodingKey = 'UTF-8', LastName = 'david009', LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US', ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',  UserName = 'testuseragent@test003.com'
        );
        insert user;
        Charket__WeChatAgentStatus__c agentStatus = new Charket__WeChatAgentStatus__c(
            Name = 'Online', Charket__IsAcceptsChats__c = true, 
            Charket__IsActive__c = true, Charket__Priority__c = 1
        );
        insert agentStatus;
        Charket__WeChatAgent__c agent = new Charket__WeChatAgent__c(
            Name = 'agent1', Charket__WeChatAgentStatus__c = agentStatus.Id, 
            Charket__User__c = user.Id, Charket__WeChatAccount__c = wechatAccount.Id, 
            Charket__IsActive__c = true, 
            Charket__LastDesktopActiveTime__c = Datetime.now(),
            Charket__Status__c = 'Online'
        );
        insert agent;
        Charket__WeChatTranscript__c tran = new Charket__WeChatTranscript__c(
                Charket__WeChatFollower__c = follower.Id, 
                Charket__WeChatAgent__c = agent.Id,
                Charket__Status__c = 'In Progress',
                Charket__IsActive__c = true
            );
        insert tran;

        Charket__WeChatAccount__c wechatAccount2 = new CharketSelector().selectWeChatAccountByOriginId('gh_e8c4857297b0');
        System.assert(wechatAccount2 != null);

        Charket__WeChatFollower__c wechatFollower = new CharketSelector().selectWeChatFollowerByOpenId('abcdefg123456');
        System.assert(wechatFollower != null);
        

        Charket__WeChatFollower__c wechatFollower1 = new CharketSelector().selectWeChatFollowerById(follower.Id);
        System.assert(wechatFollower1 != null);

        Charket__WeChatFollower__c wechatFollower2 = new CharketSelector().selectVerifiedFollowerByUnionId('unionidabcdefg123456');
        System.assert(wechatFollower2 != null);
        new CharketSelector().selectAccountSpecialistById(testAccount.Id);
        new CharketSelector().selectAgentStatusByName('Out of Office');
        Charket__WeChatTranscript__c wechatTranscript = new CharketSelector().selectOpenTranscriptByFollowerId(follower.Id);
        System.assert(wechatTranscript != null);
        List<Charket__WeChatTranscript__c> wechatTranscripts = new CharketSelector().selectOpenTranscriptsByAgentId(agent.Id);
        System.assert(wechatTranscripts.size() > 0);

        Charket__WeChatAgent__c wechatAgent = new CharketSelector().selectActiveCustomerCareAgentByUserId(user.Id, wechatAccount.Id);
        System.assert(wechatAgent != null);
        Charket__WeChatAgent__c wechatAgent2 = new CharketSelector().selectRandomCustomerCareOnlineAgent(wechatAccount.Id);
        System.assert(wechatAgent2 != null);
    }
}