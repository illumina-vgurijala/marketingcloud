/**
 *  @author  Charket 
 *  @date   29-Mar-2024
 *  @description Test class for WeChatAgentTrigger.
 **/
@isTest
public class TestWeChatAgentTrigger {
    public static String agentId;
    public static String followerId;

    /** @DESCRIPTION - setupTestData **/
    @TestSetup
    static void initTestData() {
        // Setup test data
         Charket__WeChatAccount__c wechatAccount = new Charket__WeChatAccount__c(
                Name = 'Test Account', Charket__SalesforceEndpoint__c = 'www.salesforcecom', Charket__Type__c = 'Service Account',
                Charket__WeChatOriginId__c = 'gh_e8c4857297b0', UsedFor__c = 'Customer Care'
            );
        insert wechatAccount;
        Account testAccount = new Account(Name = 'Acme', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId());
        insert testAccount;
        Contact testContact = new Contact(firstname = 'test', Lastname = 'test', Email = 'test@test.com', Alternate_Email__c = 'test@test.com', AccountId = testAccount.Id);
        insert testContact;

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User user1 = new User(
            LastName = 'testuser001', 
            Email = 'testuser001@test.com',
            Alias = 'test001', 
            EmailEncodingKey = 'UTF-8', 
            LanguageLocaleKey = 'en_US', 
            LocaleSidKey = 'en_US', 
            ProfileId = profile.Id,
            UserName = 'testagenttrigger@test001.com',
            TimeZoneSidKey = 'America/Los_Angeles'
        );

        User user2 = new User(
            LastName = 'testuser002', 
            Email = 'testuser002@test.com',
            Alias = 'test002', 
            EmailEncodingKey = 'UTF-8', 
            LanguageLocaleKey = 'en_US', 
            LocaleSidKey = 'en_US', 
            ProfileId = profile.Id,
            UserName = 'testagenttrigger@test002.com',
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert new List<User>{user1, user2};
        
        Charket__WeChatAgentStatus__c agentStatus1 = new Charket__WeChatAgentStatus__c(
                Name = 'Online', Charket__IsAcceptsChats__c = true, 
                Charket__IsActive__c = true, Charket__Priority__c = 1
            );
        Charket__WeChatAgentStatus__c agentStatus2 = new Charket__WeChatAgentStatus__c(
            Name = 'Out of Office', Charket__IsAcceptsChats__c = false, 
            Charket__IsActive__c = true, Charket__Priority__c = 2
        );
        insert new List<Charket__WeChatAgentStatus__c> {agentStatus1, agentStatus2};

        Charket__WeChatAgent__c agent1 = new Charket__WeChatAgent__c(
            Name = 'test_agent1', Charket__WeChatAgentStatus__c = agentStatus1.Id, 
            Charket__User__c = user1.Id, Charket__WeChatAccount__c = wechatAccount.Id, 
            Charket__IsActive__c = true, 
            BackupAgent__c = user2.Id, 
            Charket__LastDesktopActiveTime__c = Datetime.now()
        );
        Charket__WeChatAgent__c agent2 = new Charket__WeChatAgent__c(
            Name = 'test_agent2', Charket__WeChatAgentStatus__c = agentStatus1.Id, 
            Charket__User__c = user2.Id, Charket__WeChatAccount__c = wechatAccount.Id, 
            Charket__IsActive__c = true, 
            Charket__LastDesktopActiveTime__c = Datetime.now()
        );
        insert new List<Charket__WeChatAgent__c>{agent1, agent2};

        List<Charket__WeChatFollower__c> followers = new List<Charket__WeChatFollower__c>();
        for(Integer i=0;i < 50;i++) {
            Charket__WeChatFollower__c follower = new Charket__WeChatFollower__c(
                Charket__OpenId__c = 'abcdefg123456' + i, 
                Charket__WeChatAccount__c = wechatAccount.Id);
            followers.add(follower);
        }
        insert followers;
        List<Charket__WeChatTranscript__c> transcripts = new List<Charket__WeChatTranscript__c>();
        for(Charket__WeChatFollower__c follower : followers){
            Charket__WeChatTranscript__c transcript = new Charket__WeChatTranscript__c(
                Charket__WeChatFollower__c = follower.Id, 
                Charket__Status__c = 'New',
                Charket__IsActive__c = true,
                Charket__WeChatAgent__c = agent1.Id
            );
            transcripts.add(transcript);
        }
        insert transcripts;
    }
    
    /** @DESCRIPTION - test transfer chat when agent status is updated **/
    @isTest
    static void testCharketCustomerCareAgentTrigger(){
        Charket__WeChatAgentStatus__c outOfOfficeStatus = [
            SELECT Id FROM Charket__WeChatAgentStatus__c
            WHERE Name = 'Out of Office' LIMIT 1];
        Charket__WeChatAgent__c agent = [
            SELECT Id, Charket__WeChatAgentStatus__c
            FROM Charket__WeChatAgent__c 
            WHERE Name = 'test_agent1' limit 1];
        agent.Charket__WeChatAgentStatus__c = outOfOfficeStatus.Id;
        update agent;

        Charket__WeChatTranscript__c transcript = [
            SELECT Id, Charket__WeChatAgent__c
            FROM Charket__WeChatTranscript__c
            WHERE Charket__WeChatFollower__r.Charket__OpenId__c = 'abcdefg1234561'
            AND Charket__IsClosed__c = false
            LIMIT 1];
        System.assert(transcript.Charket__WeChatAgent__c != null);
    } 
}