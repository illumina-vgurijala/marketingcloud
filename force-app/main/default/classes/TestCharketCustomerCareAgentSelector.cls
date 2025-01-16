/**
 *  @author Charket
 *  @date   29-Mar-2024
 *  @description Test class for CharketCustomerCareAgentSelector
 **/
@isTest
public class TestCharketCustomerCareAgentSelector
{
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
        Charket__WeChatAccount__c wechatAccount2 = new Charket__WeChatAccount__c(
                Name = 'Test Account2', Charket__SalesforceEndpoint__c = 'www.salesforcecom', Charket__Type__c = 'Service Account',
                Charket__WeChatOriginId__c = 'gh_e8c485729722b0'
            );
        insert wechatAccount2;
        Account testAccount = new Account(Name = 'Acme', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId());
        Account testAccount2 = new Account(Name = 'Acme2', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId());
        insert new List<Account> {testAccount, testAccount2};
        Contact testContact = new Contact(firstname = 'test', Lastname = 'test', Email = 'test@test.com', Alternate_Email__c = 'test@test.com', AccountId = testAccount.Id);
        Contact testContact2 = new Contact(firstname = 'test', Lastname = 'test', Email = 'test@test.com', Alternate_Email__c = 'test@test.com', AccountId = testAccount2.Id);
        insert new List<Contact> {testContact, testContact2};
 
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
        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;
        SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(user.Id,'Primary Field Application Scientists',serviceTeam.id);
        technician.SVMXC__Email__c='a@b.com';
        technician.Preferred_Service_Report_Language__c='Japanese';
        insert technician;
        Account_to_Field_Support__c accountFieldSupport = new Account_to_Field_Support__c(Account__c = testAccount.Id, User__c = technician.Id, User_Role__c = 'Customer Care Specialist');
        insert accountFieldSupport;

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
            Charket__OpenId__c = 'abcdefg12345111', 
            IsContactVerified__c = true, 
            Charket__Contact__c = testContact.Id, 
            Charket__WeChatAccount__c = wechatAccount.Id
        );
        Charket__WeChatFollower__c follower2 = new Charket__WeChatFollower__c(
            Charket__OpenId__c = 'abcdefg12345222', 
            IsContactVerified__c = true, 
            Charket__Contact__c = testContact2.Id, 
            Charket__WeChatAccount__c = wechatAccount.Id
        );
        Charket__WeChatFollower__c follower3 = new Charket__WeChatFollower__c(
            Charket__OpenId__c = 'abcdefg12345333', 
            IsEmailVerified__c = true, 
            Charket__WeChatAccount__c = wechatAccount.Id
        );
        Charket__WeChatFollower__c follower4 = new Charket__WeChatFollower__c(
            Charket__OpenId__c = 'abcdefg12345444',
            Charket__WeChatAccount__c = wechatAccount.Id
        );
        Charket__WeChatFollower__c follower5 = new Charket__WeChatFollower__c(
            Charket__OpenId__c = 'abcdefg12345555',
            Charket__WeChatAccount__c = wechatAccount.Id,
            Charket__IndexedUnionId__c = 'unionidabcdefg12345555'
        );
        Charket__WeChatFollower__c follower6 = new Charket__WeChatFollower__c(
            Charket__OpenId__c = 'abcdefg12346666',
            Charket__WeChatAccount__c = wechatAccount2.Id,
            Charket__IndexedUnionId__c = 'unionidabcdefg12345555',
            Charket__Contact__c = testContact.Id,
            IsEmailVerified__c = true
        );
        insert new List<Charket__WeChatFollower__c>{follower, follower2, follower3, follower4, follower5, follower6};
        Charket__WeChatTranscript__c tran = new Charket__WeChatTranscript__c(
                Charket__WeChatFollower__c = follower.Id, 
                Charket__IsActive__c = true
            );
        insert tran;

        Charket__WeChatAgent__c agent = new Charket__WeChatAgent__c(
                Name = 'agent1', Charket__WeChatAgentStatus__c = agentStatus2.Id, 
                Charket__User__c = user.Id, Charket__WeChatAccount__c = wechatAccount.Id, 
                Charket__IsActive__c = true, 
                BackupAgent__c = backupUser.Id, 
                Charket__LastDesktopActiveTime__c = Datetime.now(),
                Charket__Status__c = 'Out of Office'
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
    }
    
    /** @DESCRIPTION - test assign chat when transfer **/
    @isTest
    static void testVerifiedContactWithSpecialist(){
        Charket.WeChatAgentSelectorContext context = new Charket.WeChatAgentSelectorContext('TEXT', '1234', 'abcdefg12345111');        
        CharketCustomerCareAgentSelector handler = new CharketCustomerCareAgentSelector();
        Charket__WeChatTranscript__c trans = [SELECT Id FROM Charket__WeChatTranscript__c LIMIT 1];
        CharketCustomerCareAgentSelector.setBotItemFields(trans.Id, 'abcdefg12345111', '1234');
        String agentId = handler.getAgentId(context);
        system.assert(agentId != null);
    }

    /** @DESCRIPTION - test assign chat when transfer **/
    @isTest
    static void testVerifiedContactWithoutSpecialist(){
        Charket.WeChatAgentSelectorContext context = new Charket.WeChatAgentSelectorContext('TEXT', '1234', 'abcdefg12345222');        
        CharketCustomerCareAgentSelector handler = new CharketCustomerCareAgentSelector();

        CharketCustomerCareAgentSelector.sendWeChatMessage('', 'abcdefg12345222');
        String agentId = handler.getAgentId(context);
        system.assert(agentId != null);
    }

    /** @DESCRIPTION - test assign chat when transfer **/
    @isTest
    static void testVerifiedEmail(){
        Charket.WeChatAgentSelectorContext context = new Charket.WeChatAgentSelectorContext('TEXT', '1234', 'abcdefg12345333');        
        CharketCustomerCareAgentSelector handler = new CharketCustomerCareAgentSelector();
        String agentId = handler.getAgentId(context);
        system.assertEquals(null, agentId);
    }

    /** @DESCRIPTION - test assign chat when transfer **/
    @isTest
    static void testNewFollower(){
        Charket.WeChatAgentSelectorContext context = new Charket.WeChatAgentSelectorContext('TEXT', '1234', 'abcdefg12345444');        
        CharketCustomerCareAgentSelector handler = new CharketCustomerCareAgentSelector();
        String agentId = handler.getAgentId(context);
        system.assertEquals(null, agentId);
    }

    /** @DESCRIPTION - test assign chat when transfer **/
    @isTest
    static void testUnionIdFollower(){
        Charket.WeChatAgentSelectorContext context = new Charket.WeChatAgentSelectorContext('TEXT', '1234', 'abcdefg12345555');        
        CharketCustomerCareAgentSelector handler = new CharketCustomerCareAgentSelector();
        String agentId = handler.getAgentId(context);
        system.assert(agentId != null);
    }
    
    /** @DESCRIPTION - test assign chat when receiveing a text message **/
    @isTest
    static void testTransferChat(){
        Charket.WeChatAgentSelectorContext context = new Charket.WeChatAgentSelectorContext('TRANSFER', '1234', 'abcdefg12345111');        
        CharketCustomerCareAgentSelector handler = new CharketCustomerCareAgentSelector();
        String agentId = handler.getAgentId(context);
        system.assert(agentId != null);
    }
}