/**
* @author Shivani Jain
* @date 4 April 2022
*
* @description DCP-49914 Test class for CommentsSelector
*/ 
@IsTest
private class TestCommentsSelector {

    static final string TYPE_WE_CHAT = 'WeChat Comment';

    /*******************************************************************************************************
    * @description initialize data for test class
    */
    @TestSetup
    static void setupData(){
        Account objAcc = TestDataAccount.getNewAccount();
        System.assert(objAcc.Id != NULL, 'Account insertion failed');

        Contact con = new Contact(FirstName = 'firstname', LastName = 'lastname', Is_Active__c = true, AccountID = objAcc.Id ,Email='testid@gmail.com.invalid' , Phone = '1234567890');
        insert con;
        System.assert(con.Id != NULL, 'Contact insertion failed');

        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
        System.assert(cs.Id != NULL, 'Case insertion failed');

        Comment__c cRecord = new Comment__c();
        cRecord.Name = 'Sent by TS User';
        cRecord.recordTypeId = Schema.SObjectType.Comment__c.getRecordTypeInfosByName().get('Case - WeChat').getRecordTypeId();
        cRecord.Case__c = cs.Id;
        cRecord.Comment__c = 'Test Comment';
        cRecord.Type__c = TYPE_WE_CHAT;
        insert cRecord;
        System.assert(cRecord.Id != NULL, 'Comment insertion failed');


    }

    /*******************************************************************************************************
    * @description test method for updateUnreadEmailsCheckboxOnCase
    */
    static testmethod void selectCommentsSpecificCaseIdsTypeUserTest() {
        Case caseRec = [SELECT id FROM Case LIMIT 1];
        Set<String> typeSet = new Set<String> {TYPE_WE_CHAT};

        Test.startTest();
        CommentsSelector selector = new CommentsSelector();
        List<Comment__c> commentList = selector.selectCommentsSpecificCaseIdsTypeUser(new Set<Id>{caseRec.Id}, typeSet, UserInfo.getName());
        Test.stopTest();
        
        System.assert(!commentList.isEmpty(), 'selectCommentsSpecificCaseIdsTypeUser didnt return any record');
    }

    /*******************************************************************************************************
    * @description test method for updateUnreadEmailsCheckboxOnCase
    */
    static testmethod void selectWeChatCommentsSpecificIdsTest() {
        Comment__c  commentRec = [SELECT id FROM Comment__c LIMIT 1];

        Test.startTest();
        CommentsSelector selector = new CommentsSelector();
        List<Comment__c> commentList = selector.selectWeChatCommentsSpecificIds(new Set<Id>{commentRec.Id});
        Test.stopTest();
        
        System.assert(!commentList.isEmpty(), 'selectWeChatCommentsSpecificIdsTest didnt return any record');
    }

}