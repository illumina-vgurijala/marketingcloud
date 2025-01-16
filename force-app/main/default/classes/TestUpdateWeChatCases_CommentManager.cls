/**
* @author Shivani Jain
* @date 4 April 2022
*
* @description DCP-49914 Test class for UpdateWeChatCases_CommentManager
*/ 
@IsTest
private class TestUpdateWeChatCases_CommentManager {

    static final string TYPE_WECHAT = 'WeChat Comment';

    @TestSetup
    static void setupData(){
        Account objAcc = TestDataAccount.getNewAccount();

        Contact con = new Contact(FirstName = 'firstname', LastName = 'lastname', Is_Active__c = true, AccountID = objAcc.Id ,Email='testid@gmail.com.invalid' , Phone = '1234567890');
        insert con;

        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
    }

    static testmethod void updateUnreadEmailsCheckboxOnCaseTest() {
        Case caseRecord = [SELECT id FROM Case LIMIT 1];

        Test.startTest();
        Comment__c cRec = new Comment__c();
        cRec.recordTypeId = Schema.SObjectType.Comment__c.getRecordTypeInfosByName().get('Case - WeChat').getRecordTypeId();
        cRec.Name = 'Sent by User';
        cRec.Case__c = caseRecord.Id;
        cRec.Comment__c = 'Test Comment';
        cRec.Type__c = TYPE_WECHAT;
        insert cRec;
        Test.stopTest();

        Case updatedCaseRec = [SELECT id, Unread_Emails__c from Case LIMIT 1];
        System.Assert(updatedCaseRec.Unread_Emails__c, 'Unread Emails checkbox on Case Update failed');
    }
}