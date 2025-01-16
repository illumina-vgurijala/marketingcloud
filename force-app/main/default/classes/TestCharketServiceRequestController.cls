/**
 *    @author Fonsey
 *    @date   2 May 2021
 *    @description   DCP-46141 - Test Class for CharketServiceRequestController
 *    Modification Log:
 *    ------------------------------------------------------------------------------------
 *    Developer                         Date                     Description
 *    Fonsey (Charket)                 2 May 2021              Initial Version - DCP-46141 : Qualtrics Integration.
 *    Sheikh Shahnawaz                 28-sep-2022             Code Coverage Enhancement
 * ---------------------------------------------------------------------------------------
 */
@isTest
public class TestCharketServiceRequestController {
    /** @DESCRIPTION - setupTestData **/
    @testSetup
    static void setupTestData() {
        // Setup test data
        Charket__WeChatAccount__c wechatAccount = new Charket__WeChatAccount__c(
            Name = 'Test Account',
            Charket__SalesforceEndpoint__c = 'www.salesforcecom',
            Charket__Type__c = 'Service Account',
            Charket__WeChatOriginId__c = 'gh_e8c4857297b0'
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
            IsEmailVerified__c = true,
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
    }

    /** @DESCRIPTION - test Save Case For Veried Follower **/
    @isTest
    static void testSaveCaseForVeriiedFollower() {
            Charket__WeChatAccount__c wechatAccount = [
                SELECT Id, Charket__SalesforceEndpoint__c
                FROM Charket__WeChatAccount__c
                LIMIT 1
            ];
            PageReference testPage = new PageReference(
                '/apex/CharketServiceRequest?wechatAccountId=' + wechatAccount.Id
            );
            testPage.getHeaders().put('User-Agent', 'MicroMessenger');
            test.setCurrentPage(testPage);
            CharketServiceRequestController thisController = new CharketServiceRequestController();
            thisController.init();
            PageReference testPage2 = new PageReference(
                '/apex/CharketServiceRequest?wechatAccountId=' +
                wechatAccount.Id +
                '&code=1234567'
            );
            testPage2.getHeaders().put('User-Agent', 'MicroMessenger');
            test.setCurrentPage(testPage2);
            CharketServiceRequestController thisController2 = new CharketServiceRequestController();
            thisController2.openId = 'abcdefg123456';
            thisController2.init();
            system.assert(thisController2.CurrentFollower != null);
            system.assert(
                CharketServiceRequestController.createNewCase(
                    'sub',
                    '电话',
                    'case des',
                    '',
                    'abcdefg123456'
                ) != null
            );
            System.assert(
                CharketServiceRequestController.createNewCase(
                    'sub',
                    '电话',
                    'case des',
                    '',
                    '123456'
                ) != null
            );
        }

    /** @DESCRIPTION - test Save Case For Non Veried Follower **/
    @isTest
    static void testSaveCaseForNonVeriiedFollower() {
            Charket__WeChatFollower__c follower = [
                SELECT Id
                FROM Charket__WeChatFollower__c
                LIMIT 1
            ];
            Charket__WeChatAccount__c wechatAccount = [
                SELECT Id, Charket__SalesforceEndpoint__c
                FROM Charket__WeChatAccount__c
                LIMIT 1
            ];
            PageReference testPage = new PageReference(
                '/apex/CharketServiceRequest?wechatAccountId=' + wechatAccount.Id
            );
            testPage.getHeaders().put('User-Agent', 'MicroMessenger');
            test.setCurrentPage(testPage);
            CharketServiceRequestController thisController = new CharketServiceRequestController();
            thisController.init();
            system.assert(thisController.ContentVersion1 != null);
            system.assert(thisController.ContentVersion2 != null);
            system.assert(thisController.ContentVersion3 != null);
            thisController.ContentVersion1.Title = '1.jpg';
            thisController.ContentVersion1.VersionData = blob.valueof('cdbdcdndcj1111');
            thisController.ContentVersion2.Title = '2.jpg';
            thisController.ContentVersion2.VersionData = blob.valueof('cdbdcdndcj1111');
            thisController.ContentVersion3.Title = '3.jpg';
            thisController.ContentVersion3.VersionData = blob.valueof('cdbdcdndcj1111');
            Account testAccount = new Account(
                Name = 'Acme',
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
                    .get('Customer')
                    .getRecordTypeId()
            );
            insert testAccount;
            Contact testContact = new Contact(
                firstname = 'test',
                Lastname = 'test2',
                Email = 'test@test2.com',
                Alternate_Email__c = 'test@test2.com'
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
            testCase = [SELECT Id, CaseNumber FROM Case LIMIT 1];
            thisController.CaseNumber = testCase.CaseNumber;
            thisController.uploadImages();
            PageReference testPage2 = new PageReference(
                '/apex/CharketServiceRequest?wechatAccountId=' +
                wechatAccount.Id +
                '&code=1234567'
            );
            testPage2.getHeaders().put('User-Agent', 'MicroMessenger');
            test.setCurrentPage(testPage2);
            CharketServiceRequestController thisController2 = new CharketServiceRequestController();
            thisController2.openId = 'abcdefg123456';
            CharketServiceRequestController.updateFollowerDataPrivacyPolicyConsentDate(
                'abcdefg123456'
            );
            CharketServiceRequestController.updateFollowerDataPrivacyPolicyConsentDate('');
            thisController2.init();
            CharketServiceRequestController.getOpenId();
            system.assert(thisController2.CurrentFollower != null);
            thisController2.openId = 'abcdefg1234';
            thisController2.init();
            CharketCustomUtil.sendEmailVerificationCode(
                '123456',
                'david.lee@charket.com',
                'norely@test.com',
                'acme'
            );
            CharketCustomUtil.generateVerificationCode(4);
            CharketCustomUtil.getFollower(thisController2.openId);
            system.assert(
                CharketServiceRequestController.verifiyEmailCode(
                    '123456',
                    'david',
                    'lee',
                    'test@test2.com',
                    '18611999444',
                    'Acme',
                    '电话',
                    '123456tetwt',
                    'sub',
                    'abc',
                    'abcdefg123456'
                ) != null
            );
            system.assert(
                CharketServiceRequestController.verifiyEmailCode(
                    '123456',
                    'david',
                    'lee',
                    'test@test2.com',
                    '18611999444',
                    'Acme',
                    '电话',
                    '123456tetwt',
                    'sub',
                    'abc',
                    ''
                ) != null
            );
            CharketServiceRequestController.sendVerificationCode(
                'test@test2.com',
                'noreply@test.com',
                'acme',
                follower.Id
            );
            CharketServiceRequestController.sendVerificationCode(
                'test@test2.com',
                'noreply@test.com',
                'acme',
                null
            );
            CharketServiceRequestController.HistoryCaseItem followerHistoryCase = new CharketServiceRequestController.HistoryCaseItem(
                testCase.Id,
                '00123',
                'case dec',
                '12345',
                '2021-05-30',
                'abcd',
                'abchdcudu'
            );
        }
   
    /** @DESCRIPTION - test Controller **/
    @isTest
    static void testController() {
        String encryptedOpenId = 'DRjd/GnduI3Efzen9V9BvbNUfc/VKgXltV7Kbk9sMkY=';
        Charket__WeChatAccount__c wechatAccount = [
            SELECT Id, Charket__SalesforceEndpoint__c,OpenIdAesKey__c
            FROM Charket__WeChatAccount__c
            LIMIT 1
        ];
        Charket__WeChatFollower__c currentFollower = [select id,Firstname__c,Lastname__c from Charket__WeChatFollower__c limit 1];
        case caseObj = [select id from case limit 1];
        String caseId = caseObj.Id;
        CharketSettings__mdt charketSetting = new CharketSettings__mdt();
        Test.startTest();
            CharketCustomUtil.decryptOpenId( encryptedOpenId, wechatAccount, charketSetting);
            CharketCustomUtil.encryptOpenId( encryptedOpenId, wechatAccount, charketSetting);
            charketSetting.AesKeySize__c = 128;
            CharketCustomUtil.decryptOpenId( encryptedOpenId, wechatAccount, charketSetting);
            CharketCustomUtil.encryptOpenId( encryptedOpenId, wechatAccount, charketSetting);
            CharketCustomUtil.addCharketLog('TestCode123', 'Test Message charket', 'Test data test data,test data');
            CharketCustomUtil.getCommentCallbackUrl(wechatAccount, caseId);
            currentFollower.Firstname__c = 'TestFirstName';
            currentFollower.Lastname__c = 'TestLastName';
            CharketCustomUtil.getFollowerFullName(currentFollower);
        Test.stopTest();
        system.assert(wechatAccount.id != null,'We chat account is null');


    }

     /** @DESCRIPTION - test Complaint and Feedback **/
     @isTest
     static void testComplaintAndFeedback() {
         Charket__WeChatAccount__c wechatAccount = [
             SELECT Id, Charket__SalesforceEndpoint__c
             FROM Charket__WeChatAccount__c
             LIMIT 1
         ];
         PageReference testPage = new PageReference(
             '/apex/CharketServiceRequest?wechatAccountId=' + wechatAccount.Id + '&type=complaint_and_feedback'
         );
         testPage.getHeaders().put('User-Agent', 'MicroMessenger');
         test.setCurrentPage(testPage);
         CharketServiceRequestController thisController = new CharketServiceRequestController();
         thisController.init();
         System.assert(thisController.IsComplaintAndFeedback);
     }
 }
