/**
* @author Shivani Jain
* @date 8th April 2022
*
* @description DCP-49914 Test class for PerformAdminActions_CommentManager
*/ 
@IsTest
private class TestPerformAdminActions_CommentManager {

    static final string TYPE_WECHAT = 'WeChat Comment';

    @TestSetup
    static void setupData(){
        Account objAcc = TestDataAccount.getNewAccount();

        Contact con = new Contact(FirstName = 'first', LastName = 'last', Is_Active__c = true, AccountID = objAcc.Id ,Email='testid@gmail.com.invalid' , Phone = '1234567890');
        insert con;

        Case caseRec = TestDataCase.initServiceRequestCase(con);
        insert caseRec;
    }

    static testmethod void triggerChatterPostOnCommentTest() {
        Case cs = [SELECT id FROM Case LIMIT 1];

        Test.startTest();
        Comment__c comment = new Comment__c();
        comment.recordTypeId = Schema.SObjectType.Comment__c.getRecordTypeInfosByName().get('Case - WeChat').getRecordTypeId();
        comment.Name = 'Sent by User';
        comment.Case__c = cs.Id;
        comment.Comment__c = 'Test Comment';
        comment.Type__c = TYPE_WECHAT;
        insert comment;
        Test.stopTest();

        Comment__c updatedComment = [SELECT id, Perform_Actions_as_Admin__c from Comment__c LIMIT 1];
        System.Assert(updatedComment.Perform_Actions_as_Admin__c, 'Perform_Actions_as_Admin__c checkbox on Comment Update failed');
    }
}