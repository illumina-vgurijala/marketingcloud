/**
 *  @author Charket
 *  @date   01-April-2024
 *  @description Test class for CharketCustomerCareOutOfOfficeController
 **/
@isTest
public class TestCharketCustomerCareOutOfOffice {
    /** @DESCRIPTION - setupTestData **/
    @TestSetup
    static void initTestData() {
        Charket__WeChatAccount__c wechatAccount = new Charket__WeChatAccount__c(
                Name = 'Test Account', Charket__SalesforceEndpoint__c = 'www.salesforcecom', Charket__Type__c = 'Service Account',
                Charket__WeChatOriginId__c = 'gh_e8c4857297b0', UsedFor__c = 'Customer Care'
            );
        insert wechatAccount;
        Profile p = [select Id from Profile where Name = 'System Administrator'];
        User user1 = new User(
                Alias = 'test001', Email = 'teststatus@test001.com',
                EmailEncodingKey = 'UTF-8', LastName = 'test001', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = p.Id,
                TimeZoneSidKey = 'America/Los_Angeles',  UserName = 'teststatus@test001.com'
            );
        insert user1;
        
        User user2 = new User(
                Alias = 'test002', Email = 'teststatus@test002.com',
                EmailEncodingKey = 'UTF-8', LastName = 'test002', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = p.Id,
                TimeZoneSidKey = 'America/Los_Angeles',  UserName = 'teststatus@test002.com'
            );
        insert user2;

        Charket__WeChatAgentStatus__c agentStatus1 = new Charket__WeChatAgentStatus__c(
                Name = 'Online', Charket__IsAcceptsChats__c = true, 
                Charket__IsActive__c = true, Charket__Priority__c = 1
            );
        Charket__WeChatAgentStatus__c agentStatus2 = new Charket__WeChatAgentStatus__c(
            Name = 'Out of Office', Charket__IsAcceptsChats__c = false, 
            Charket__IsActive__c = true, Charket__Priority__c = 1
        );
        insert new List<Charket__WeChatAgentStatus__c> {agentStatus1, agentStatus2};

        Charket__WeChatAgent__c agent1 = new Charket__WeChatAgent__c(
                Name = 'agent1', Charket__WeChatAgentStatus__c = agentStatus1.Id, 
                Charket__User__c = user1.Id, Charket__WeChatAccount__c = wechatAccount.Id, 
                Charket__IsActive__c = true, 
                Charket__LastDesktopActiveTime__c = Datetime.now(),
                Charket__Status__c = 'Online'
            );
        Charket__WeChatAgent__c agent2 = new Charket__WeChatAgent__c(
            Name = 'agent2', Charket__WeChatAgentStatus__c = agentStatus1.Id, 
            Charket__User__c = user2.Id, Charket__WeChatAccount__c = wechatAccount.Id, 
            Charket__IsActive__c = true, 
            Charket__LastDesktopActiveTime__c = Datetime.now(),
            Charket__Status__c = 'Online'
        );
        insert new List<Charket__WeChatAgent__c>{agent1, agent2};
    }

    /** @DESCRIPTION - test update agents **/
    @isTest
    static void testUpdateAgents(){
        List<Charket__WeChatAgent__c> agentList = [SELECT Id FROM Charket__WeChatAgent__c LIMIT 20];
        ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(agentList);
        setCon.setSelected(agentList);
        CharketCustomerCareOutOfOfficeController con = new CharketCustomerCareOutOfOfficeController(setCon);
        PageReference result = con.init();
        System.assert(result != null);
    }
}