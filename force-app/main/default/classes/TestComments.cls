/**
* @author Shivani Jain
* @date 4 April 2022
*
* @description DCP-49914 Test class for Comments
*/ 
@IsTest
private class TestComments {

    static final string TYPE_WECHAT = 'WeChat Comment';
    
    /*******************************************************************************************************
    * @description initialize data for test class
    */
    @TestSetup
    static void setupData(){
        Account objAcc = TestDataAccount.getNewAccount();

        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname', Is_Active__c = true, AccountID = objAcc.Id ,Email='test@gmail.com.invalid' , Phone = '1234567890');
        insert con;

        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
    }

    /*******************************************************************************************************
    * @description test method for asynCallsOnCommentInsert
    */
    static testmethod void asynCallsOnCommentInsertTest() {
        Case caseRec = [SELECT id FROM Case LIMIT 1];

        Test.startTest();
        Comment__c commentRec = new Comment__c();
        commentRec.Name = 'Sent by Test User';
        commentRec.recordTypeId = Schema.SObjectType.Comment__c.getRecordTypeInfosByName().get('Case - WeChat').getRecordTypeId();
        commentRec.Case__c = caseRec.Id;
        commentRec.Comment__c = 'Test Comment';
        commentRec.Type__c = TYPE_WECHAT;
        insert commentRec;
        System.assert(commentRec.Id != NULL, 'Comment insertion failed');

        commentRec.Comment__c = 'Test Comment Update';
        update commentRec;
        Test.stopTest();

        Case updatedCase = [SELECT id, Unread_Emails__c from Case LIMIT 1];
        System.assert(updatedCase.Unread_Emails__c, 'Unread Emails checkbox on Case Update failed');
    }
}