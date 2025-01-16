/***************************************************************************************************************************************
* @Author:  Nidhi Hegde
* @Date:    06-Oct-2023 
* @Name :   TestCommentActionInsert
* @Description: For Covering Comment_Actions_on_Insert Flow
* ------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* ------------------------------------------------------------------------------------
* Nidhi Hegde             06-Oct-2023        Initial Version (CMCM-3826)
******************************************************************************************************************************************************************/

@isTest
public class TestCommentActionInsert {
    static final String TYPE_WE_CHAT = 'WeChat Comment';
    static final String TYPE_ILLUMINA = 'Illumina Comment';
    public final static Id WECHAT_RECORD_TYPE_ID = Schema.SObjectType.Comment__c.getRecordTypeInfosByName().get('Case - WeChat').getRecordTypeId();
    
      /**
       *   @author Nidhi Hegde
      * Initialize data for test method 
     */
    
    @TestSetup
    static void setupData() {
        Charket__WeChatAccount__c wechatAccount = new Charket__WeChatAccount__c(
            Name = 'Test Account',
            Charket__SalesforceEndpoint__c = 'www.salesforce.com',
            Charket__Type__c = 'Service Account',
            Charket__WeChatOriginId__c = 'gh_e8c4857297b0',
            DataPrivacyPolicy__c='<p>Test</p>'
        );
        insert wechatAccount;
        
        Contact testContact = new Contact(
            firstname = 'test',
            Lastname = 'test',
            Email = 'testemail@test.com',
            Alternate_Email__c = 'testemail@test.com'
        );
        insert testContact;
        Account objAcc = TestDataAccount.getCustomerAccount();
        insert objAcc;
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname', Is_Active__c = true, AccountID = objAcc.Id ,Email='test@gmail.com.invalid' , Phone = '1234567890');
        insert con;
        Charket__WeChatFollower__c follower = new Charket__WeChatFollower__c(
            Charket__OpenId__c = 'abcdefg123456',
            EmailVerificationCode__c = '123456',
            Charket__Contact__c = testContact.Id,
            Charket__WeChatAccount__c = wechatAccount.Id
        );
        insert follower;
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.WeChatFollower__c = follower.id;
        insert cs;
    }
     
    /**
     * @author Nidhi Hegde
    * This test method is responsible for testing the notification functionality. 
   */
    
    
    @isTest
    public static void testNotification() {
        Case caseRec = [SELECT id FROM Case LIMIT 1];
        
        Test.startTest();
        Comment__c cRecord = new Comment__c();
        cRecord.Name = 'Sent by TS User';
        cRecord.recordTypeId = WECHAT_RECORD_TYPE_ID;
        cRecord.Case__c = caseRec.Id;
        cRecord.Comment__c = 'Test Comment';
        cRecord.Type__c = TYPE_IllUMINA;
        insert cRecord;
        System.assert(cRecord.Id != NULL, 'Created Record');
        List<FeedItem> feedList = [SELECT Id FROM FeedItem LIMIT 1];
        Assert.isTrue(feedList != null);
        Test.stopTest();
    }
    
    /**
     *@author Nidhi Hegde
    * This test method is responsible for testing the posting of a Chatter feed item when a Comment__c record is updated. 
   */ 
    
    @isTest
    public static void testPostToChatter() {
        Id pId = [SELECT Id FROM Profile WHERE Name = 'WeChat Charket Profile'].Id;
        String firstName = TestData.getRandom(4);
        String lastName = TestData.getRandom();
        User u = new User(
            Alias = firstName,
            Email = firstName + '@test.org',
            EmailEncodingKey = 'UTF-8',
            LastName = lastName,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = PId,
            IsActive = true,
            FederationIdentifier = '0000000',
            TimezoneSidKey = 'America/Los_Angeles',
            Username = firstName + '@test.' + lastName
        );
        insert u;
        System.runAs(u) {
            Comment__c commentRec = new Comment__c();
            commentRec.Name = 'Sent by Test User';
            commentRec.recordTypeId = WECHAT_RECORD_TYPE_ID;
            commentRec.Comment__c = 'Test Comment';
            commentRec.Type__c = TYPE_WE_CHAT;
            commentRec.Perform_Actions_as_Admin__c = false;
            insert commentRec;
            System.assert(commentRec.Id != NULL, 'Created Record');
        }
        Test.startTest();
        Case caseRec = [SELECT id FROM Case LIMIT 1];
        Comment__c commentRec = [SELECT Id, Perform_Actions_as_Admin__c FROM Comment__c LIMIT 1];
        commentRec.Perform_Actions_as_Admin__c = true;
        commentRec.case__c = caseRec.Id;
        update commentRec;
        Test.stopTest();
        List<FeedItem> feedList = [SELECT Id FROM FeedItem LIMIT 1];
        Assert.isTrue(feedList != null);
    }
}