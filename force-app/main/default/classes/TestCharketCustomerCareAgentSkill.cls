/**
 *  @author Charket
 *  @date   29-Mar-2024
 *  @description Test class for CharketCustomerCareAgentSkill
 **/
@isTest
public class TestCharketCustomerCareAgentSkill
{
    public static String agentId;
    public static String followerId;
    
    /** @DESCRIPTION - setupTestData **/
    @TestSetup
    static void initTestData() {
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
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId()
        );
        insert testAccount;
        Contact testContact = new Contact(
            FirstName = 'test', 
            LastName = 'test', 
            Email = 'test@test.com', 
            Alternate_Email__c = 'test@test.com', 
            AccountId = testAccount.Id
        );
        insert testContact;
        
        Charket__WeChatFollower__c follower = new Charket__WeChatFollower__c(
            Charket__OpenId__c = 'abcdefg12345111', 
            IsContactVerified__c = true, 
            Charket__Contact__c = testContact.Id, 
            Charket__WeChatAccount__c = wechatAccount.Id
        );
        Charket__WeChatFollower__c follower2 = new Charket__WeChatFollower__c(
            Charket__OpenId__c = 'abcdefg12345222', 
            Charket__WeChatAccount__c = wechatAccount.Id
        );
        Charket__WeChatFollower__c follower3 = new Charket__WeChatFollower__c(
            Charket__OpenId__c = 'abcdefg12345333', 
            Charket__IndexedUnionId__c = 'unionabcdefg12345333',
            Charket__WeChatAccount__c = wechatAccount.Id
        );
        Charket__WeChatFollower__c follower4 = new Charket__WeChatFollower__c(
            Charket__OpenId__c = 'abcdefg12345444', 
            Charket__Contact__c = testContact.Id,
            IsContactVerified__c = true,
            IsEmailVerified__c = true,
            Charket__IndexedUnionId__c = 'unionabcdefg12345333'
        );
        insert new List<Charket__WeChatFollower__c>{follower, follower2, follower3, follower4};

        Profile p = [select Id from Profile where Name = 'System Administrator'];
        User user = new User(
                Alias = 'david007', Email = 'testuseragent@test003.com',
                EmailEncodingKey = 'UTF-8', LastName = 'david009', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = p.Id,
                TimeZoneSidKey = 'America/Los_Angeles',  UserName = 'testuseragent@test003.com'
            );
        insert user;
        
        Charket__WeChatAgentStatus__c agentStatus = new Charket__WeChatAgentStatus__c(
                Name = 'online', Charket__IsAcceptsChats__c = true, 
                Charket__IsActive__c = true, Charket__Priority__c = 1
            );
        insert agentStatus;

        Charket__WeChatAgent__c agent = new Charket__WeChatAgent__c(
            Name = 'test agent', 
            Charket__WeChatAgentStatus__c = agentStatus.Id, 
            Charket__User__c = user.Id, 
            Charket__WeChatAccount__c = wechatAccount.Id, 
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
    }
    
    /** @DESCRIPTION - test assign chat when transfer **/
    @isTest
    static void testVerfieidContactScanEvent(){
        Test.startTest();
        Charket.SkillContext context = new Charket.SkillContext();
        Charket.WeChatApiEvent.Scan scanEvent = new Charket.WeChatApiEvent.Scan();
        scanEvent.FromUserId = 'abcdefg12345111';
        scanEvent.ToUserId = 'gh_e8c4857297b0';
        scanEvent.Ticket = 'testqrcodeticket';
        context.WeChatEvent = scanEvent;

        Charket.SkillSession session = new Charket.SkillSession();

        CharketCustomerCareAgentSkill agentSkill = new CharketCustomerCareAgentSkill();
        Charket.SkillResponse skillResponse = agentSkill.execute(context, session);
        Test.stopTest();

        System.assert(skillResponse != null);
    }

    /** @DESCRIPTION - test assign chat when transfer **/
    @isTest
    static void testUnverfieidContactScanEvent(){
        Test.startTest();
        Charket.SkillContext context = new Charket.SkillContext();
        Charket.WeChatApiEvent.Scan scanEvent = new Charket.WeChatApiEvent.Scan();
        scanEvent.FromUserId = 'abcdefg12345222';
        scanEvent.ToUserId = 'gh_e8c4857297b0';
        scanEvent.Ticket = 'testqrcodeticket';
        context.WeChatEvent = scanEvent;

        Charket.SkillSession session = new Charket.SkillSession();

        CharketCustomerCareAgentSkill agentSkill = new CharketCustomerCareAgentSkill();
        Charket.SkillResponse skillResponse = agentSkill.execute(context, session);
        Test.stopTest();

        System.assert(skillResponse != null);
    }

    /** @DESCRIPTION - test assign chat when transfer **/
    @isTest
    static void testUnionId(){
        Test.startTest();
        Charket.SkillContext context = new Charket.SkillContext();
        Charket.WeChatApiEvent.Scan scanEvent = new Charket.WeChatApiEvent.Scan();
        scanEvent.FromUserId = 'abcdefg12345333';
        scanEvent.ToUserId = 'gh_e8c4857297b0';
        scanEvent.Ticket = 'testqrcodeticket';
        context.WeChatEvent = scanEvent;

        Charket.SkillSession session = new Charket.SkillSession();

        CharketCustomerCareAgentSkill agentSkill = new CharketCustomerCareAgentSkill();
        Charket.SkillResponse skillResponse = agentSkill.execute(context, session);
        Test.stopTest();

        System.assert(skillResponse != null);
    }

    /** @DESCRIPTION - test assign chat when transfer **/
    @isTest
    static void testSubscribeEvent(){
        Test.startTest();
        Charket.SkillContext context = new Charket.SkillContext();
        Charket.WeChatApiEvent.Scan scanEvent = new Charket.WeChatApiEvent.Scan();
        scanEvent.FromUserId = 'abcdefg12345555';
        scanEvent.ToUserId = 'gh_e8c4857297b0';
        scanEvent.Ticket = 'testqrcodeticket';
        context.WeChatEvent = scanEvent;

        Charket.SkillSession session = new Charket.SkillSession();

        CharketCustomerCareAgentSkill agentSkill = new CharketCustomerCareAgentSkill();
        Charket.SkillResponse skillResponse = agentSkill.execute(context, session);
        Test.stopTest();

        System.assert(skillResponse != null);
    }
}