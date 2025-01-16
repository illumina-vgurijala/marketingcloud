/**
 *  @author  Charket 
 *  @date   29-Mar-2024
 *  @description Test class for CharketCustomerCareController.
 **/
@isTest
public class TestCharketCustomerCareController
{
    public static String agentId;
    public static String followerId;

    /** @DESCRIPTION - setupTestData **/
    @TestSetup
    static void initTestData() {
        Charket__WeChatAccount__c wechatAccount = new Charket__WeChatAccount__c(
                Name = 'Test Account', Charket__SalesforceEndpoint__c = 'www.salesforcecom', Charket__Type__c = 'Service Account',
                Charket__WeChatOriginId__c = 'gh_e8c4857297b0', UsedFor__c = 'Customer Care', AESKeySize__c = 256, OpenIdAesKey__c = 'lKU1nWWjuQExIymhuvBNkm/wS8u9UiUpI67LzIy0EBI='
            );
        insert wechatAccount;
        Account testAccount = new Account(Name = 'Acme', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId());
        insert testAccount;
        Contact testContact = new Contact(firstname = 'test', Lastname = 'test', Email = 'test1@test.com', Alternate_Email__c = 'test1@test.com', AccountId = testAccount.Id);
        insert testContact;
 
        Profile p = [select Id from Profile where Name = 'System Administrator'];
        User user = new User(
                Alias = 'david007', Email = 'testuseragent@test003.com',
                EmailEncodingKey = 'UTF-8', LastName = 'david009', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = p.Id,
                TimeZoneSidKey = 'America/Los_Angeles',  UserName = 'testuseragent@test003.com'
            );
        insert user;
        
        User user2 = new User(
                Alias = 'dav037', Email = 'testuseragent@test003.com',
                EmailEncodingKey = 'UTF-8', LastName = 'david009', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = p.Id,
                TimeZoneSidKey = 'America/Los_Angeles',  UserName = 'testuseragent@test073.com'
            );
        insert user2;

        User backupUser = new User(
                Alias = 'davi008', Email = 'testuseragent@test004.com',
                EmailEncodingKey = 'UTF-8', LastName = 'david0010', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = p.Id,
                TimeZoneSidKey = 'America/Los_Angeles',  UserName = 'testuseragent@test004.com'
            );
        insert backupUser;
        
        Charket__WeChatAgentStatus__c agentStatus = new Charket__WeChatAgentStatus__c(
                Name = 'online', Charket__IsAcceptsChats__c = true, 
                Charket__IsActive__c = true, Charket__Priority__c = 1
            );
        Charket__WeChatAgentStatus__c agentStatus2 = new Charket__WeChatAgentStatus__c(
            Name = 'Out of Office', Charket__IsAcceptsChats__c = false, 
            Charket__IsActive__c = true, Charket__Priority__c = 1
        );
        insert new List<Charket__WeChatAgentStatus__c> {agentStatus, agentStatus2};
        Charket__WeChatFollower__c follower = new Charket__WeChatFollower__c(
            Charket__OpenId__c = 'abcdefg123456', 
            Charket__WeChatAccount__c = wechatAccount.Id);
        insert follower;        

        Charket__WeChatAgent__c agent = new Charket__WeChatAgent__c(
                Name = 'agent1', Charket__WeChatAgentStatus__c = agentStatus.Id, 
                Charket__User__c = user.Id, Charket__WeChatAccount__c = wechatAccount.Id, 
                Charket__IsActive__c = true, 
                BackupAgent__c = backupUser.Id, 
                Charket__LastDesktopActiveTime__c = Datetime.now(),
                Charket__Status__c = 'Online'
            );
        Charket__WeChatAgent__c agent2 = new Charket__WeChatAgent__c(
            Name = 'agent2', Charket__WeChatAgentStatus__c = agentStatus2.Id, 
            Charket__User__c = user2.Id, Charket__WeChatAccount__c = wechatAccount.Id, 
            Charket__IsActive__c = true, 
            BackupAgent__c = backupUser.Id, 
            Charket__LastDesktopActiveTime__c = Datetime.now(),
            Charket__Status__c = 'Out of Office'
        );
        Charket__WeChatAgent__c backupAgent = new Charket__WeChatAgent__c(
                Name = 'backup agent', Charket__WeChatAgentStatus__c = agentStatus.Id, 
                Charket__User__c = backupUser.Id, Charket__WeChatAccount__c = wechatAccount.Id, 
                Charket__IsActive__c = true,  
                Charket__LastDesktopActiveTime__c = Datetime.now(),
                Charket__Status__c = 'Online'
            );
        insert new List<Charket__WeChatAgent__c>{agent, agent2, backupAgent};
        Charket__WeChatTranscript__c tran = new Charket__WeChatTranscript__c(
                Charket__WeChatFollower__c = follower.Id, 
                Charket__WeChatAgent__c = agent.Id,
                Charket__IsActive__c = true
            );
        insert tran;
    }
    
    /** @DESCRIPTION - test customer care controller **/
    @isTest
    static void testInit(){              
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=uniqueUserName); 
        System.runAs(u){
            Charket__WeChatAccount__c wechatAccount = [
                SELECT Id, AesKeySize__c, OpenIdAesKey__c 
                FROM Charket__WeChatAccount__c
                WHERE Charket__WeChatOriginId__c = 'gh_e8c4857297b0' LIMIT 1
            ];
            PageReference testPage = new PageReference('/apex/CharketCustomerCare?wid=' + wechatAccount.Id);
            testPage.getHeaders().put('User-Agent', 'MicroMessenger');
            test.setCurrentPage(testPage);

            CharketCustomerCareController controller = new CharketCustomerCareController();
            controller.init();

            String cookieName = 'OPENID' + String.valueOf(wechatAccount.Id).right(15);
            String encryptedOpenId = controller.encryptOpenId('abcdefg123456', wechatAccount);
            Cookie openIdCookie = new Cookie(cookieName, encryptedOpenId, null, 14400, true);
            testPage.setCookies(new List<Cookie>{ openIdCookie });

            controller.init();
            controller.getOpenId();
            CharketCustomerCareController.createCharketLog('test', 'test', 'test');
            String decryptedOpenId = controller.decryptOpenId(encryptedOpenId, wechatAccount);
            System.assert(decryptedOpenId != null);
        }
    }

    /** @DESCRIPTION - test customer care controller **/
    @isTest
    static void testInitCode(){              
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=uniqueUserName); 
        System.runAs(u){
            Charket__WeChatAccount__c wechatAccount = [
                SELECT Id, AesKeySize__c, OpenIdAesKey__c 
                FROM Charket__WeChatAccount__c
                WHERE Charket__WeChatOriginId__c = 'gh_e8c4857297b0' LIMIT 1
            ];
            PageReference testPage = new PageReference('/apex/CharketCustomerCare?wid=' + wechatAccount.Id);
            testPage.getHeaders().put('User-Agent', 'MicroMessenger');
            testPage.getParameters().put('code', 'testcode');
            test.setCurrentPage(testPage);

            CharketCustomerCareController controller = new CharketCustomerCareController();
            controller.init();
            String openId = controller.getOpenId();
            System.assertEquals(null, openId);
        }
    }

    /** @DESCRIPTION - test customer care controller **/
    @isTest
    static void testInitWithoutFollower(){              
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=uniqueUserName); 
        System.runAs(u){
            Charket__WeChatAccount__c wechatAccount = [
                SELECT Id, AesKeySize__c, OpenIdAesKey__c 
                FROM Charket__WeChatAccount__c
                WHERE Charket__WeChatOriginId__c = 'gh_e8c4857297b0' LIMIT 1
            ];
            PageReference testPage = new PageReference('/apex/CharketCustomerCare?wid=' + wechatAccount.Id);
            testPage.getHeaders().put('User-Agent', 'MicroMessenger');
            test.setCurrentPage(testPage);

            CharketCustomerCareController controller = new CharketCustomerCareController();
            controller.init();

            String cookieName = 'OPENID' + String.valueOf(wechatAccount.Id).right(15);
            String encryptedOpenId = controller.encryptOpenId('abcdefg123', wechatAccount);
            Cookie openIdCookie = new Cookie(cookieName, encryptedOpenId, null, 14400, true);
            testPage.setCookies(new List<Cookie>{ openIdCookie });

            controller.init();
            String decryptedOpenId = controller.decryptOpenId(encryptedOpenId, wechatAccount);
            System.assert(decryptedOpenId != null);
        }
    }

    /** @DESCRIPTION - test customer care controller **/
    @isTest
    static void testSendEmailVerificationCode(){              
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=uniqueUserName); 
        System.runAs(u){
            Charket__WeChatFollower__c wechatFollower = [
                SELECT Id FROM Charket__WeChatFollower__c 
                WHERE Charket__OpenId__c = 'abcdefg123456' LIMIT 1];
            CharketCustomerCareController.Follower follower = new CharketCustomerCareController.Follower();
            follower.email = 'test@test.com';
            follower.firstName = 'firstname';
            follower.lastName = 'lastname';
            follower.mobile = '13512341234';
            follower.companyName = 'testcompany';
            follower.followerId = wechatFollower.Id;
            String result = CharketCustomerCareController.sendVerificationCode(JSON.serialize(follower));
            System.assert(result != null);
        }
    }

    /** @DESCRIPTION - test customer care controller **/
    @isTest
    static void testAcceptPrivacyDate(){              
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=uniqueUserName); 
        System.runAs(u){
            Charket__WeChatFollower__c follower = [
                SELECT Id FROM Charket__WeChatFollower__c 
                WHERE Charket__OpenId__c = 'abcdefg123456' LIMIT 1];
            String result = CharketCustomerCareController.acceptPrivacyDate(follower.Id);
            System.assert(result != null);
        }
    }

    /** @DESCRIPTION - test customer care controller **/
    @isTest
    static void testSubmitSuccess(){              
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=uniqueUserName); 
        System.runAs(u){
            Charket__WeChatFollower__c wechatFollower = [
                SELECT Id FROM Charket__WeChatFollower__c 
                WHERE Charket__OpenId__c = 'abcdefg123456' LIMIT 1];
            wechatFollower.EmailVerificationCode__c = '123456';
            wechatFollower.Email__c = 'test@test.com';
            update wechatFollower;
            
            CharketCustomerCareController.Follower follower = new CharketCustomerCareController.Follower();
                follower.email = 'test@test.com';
                follower.firstName = 'firstname';
                follower.lastName = 'lastname';
                follower.emailVerificationCode = '123456';
                follower.mobile = '13512341234';
                follower.companyName = 'testcompany';
                follower.followerId = wechatFollower.Id;
            String result = CharketCustomerCareController.submit(JSON.serialize(follower));
            System.assert(result != null);
        }
    }

    /** @DESCRIPTION - test customer care controller **/
    @isTest
    static void testSubmitFailed(){              
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=uniqueUserName); 
        System.runAs(u){
            Charket__WeChatFollower__c wechatFollower = [
                SELECT Id FROM Charket__WeChatFollower__c 
                WHERE Charket__OpenId__c = 'abcdefg123456' LIMIT 1];
            CharketCustomerCareController.Follower follower = new CharketCustomerCareController.Follower();
            follower.email = 'test@test.com';
            follower.firstName = 'firstname';
            follower.lastName = 'lastname';
            follower.mobile = '13512341234';
            follower.companyName = 'testcompany';
            follower.followerId = wechatFollower.Id;
            String result = CharketCustomerCareController.submit(JSON.serialize(follower));
            
            System.assert(result != null);
        }
    }
}