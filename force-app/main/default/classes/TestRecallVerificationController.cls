/**************************************************************************************************************************************
* NAME   : TestRecallVerificationController
* DESCRIPTION  : Test class for RecallVerificationController to validate the functionality of its methods.
*  
* @AUTHOR : Abhishek Yadav
* @DATE   : 30-Jul-2024  
*  
* MODIFICATION LOG: 
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Abhishek Yadav         30-Jul-2024         Initial Version. Added unit tests for account lookup operations.
****************************************************************************************************************************************/
@isTest
public with sharing class TestRecallVerificationController {
    /* create data */
    @TestSetup
    static void makeData() {
        Account objAccount = TestDataAccount.getAccount('Test Account 1', 'USD');
        objAccount.Account_Group__c = 'Distributor';
        objAccount.Clinical_Type__c = 'Clinical';
        insert objAccount;

        Contact con = TestDataContact.getNewContact(objAccount);

        Case objCase = TestDataCase.initServiceRequestCase(con);
        objCase.Recall__c = true;
        objCase.Status = 'Initiated';
        insert objCase;
        // To create a fAN record of record type "Notification"
        Field_Action_Notification__c fAN =TestDataFieldService.createFAN('Notification');
        insert fAN;
        // To create a new fAI record With fAN record type "Notification"
        Field_Action_Item__c fAI =TestDataFieldService.createFAI(objCase.Id,fAN.Id);
        insert fAI;
    }
    /**
    * Unit test for RecallVerificationController method getCaseRecord
    * @description This test method inserts test Case records and validates the getCaseRecord method.
    **/
    @isTest
    public static void testgetCaseRecord() {
        Test.startTest();
        Id caseId = [SELECT Id FROM Case LIMIT 1].Id;
        List<RecallVerificationController.CaseWrapper> cw = RecallVerificationController.getCaseRecord(caseId);
        Assert.isTrue(cw != null , 'CaseWrapper is null');
        Test.stopTest();
    }
    /**
    * Unit test for RecallVerificationController method fetchAccountData & linkFileWithCases 
    * @description This test method inserts File on case records and validates the fetchAccountData & linkFileWithCases method.
    **/
    @isTest
    public static void testFileOnCases() {
        Test.startTest();
        Case objCase = [SELECT Id FROM Case LIMIT 1];
        Contact con = [SELECT Id , AccountId FROM Contact LIMIT 1];
        ContentVersion contentVersion = new ContentVersion(
        Title = 'Penguins',
        PathOnClient = 'Penguins.jpg',
        VersionData = Blob.valueOf('Test Content'),
        IsMajorVersion = true,
        FirstPublishLocationId = objCase.Id
        );
        insert contentVersion;    
        List<ContentDocument> documents = [
            SELECT Id, Title, LatestPublishedVersionId 
            FROM ContentDocument LIMIT 1
        ];
        Case cseObj = TestDataCase.initServiceRequestCase(con);
        cseObj.Recall__c = true;
        cseObj.Status = 'Initiated';
        insert cseObj;
        Test.stopTest();
        List<RecallVerificationController.CaseWrapper> caseWrapperList = RecallVerificationController.fetchFileWithCase(objCase.Id);
        Assert.isTrue(caseWrapperList != null , 'CaseWrapper is null');
        RecallVerificationController.linkFileWithCases(documents[0].Id, new List<String>{cseObj.Id});
        List<ContentDocumentLink> cdlList = [SELECT Id FROM ContentDocumentLink WHERE ContentDocumentId =:documents[0].Id];
        Assert.areEqual(3, cdlList.size() , 'cdlList list does not have 3 record');
        List<RecallVerificationController.CaseWrapper> csWrapperList = RecallVerificationController.fetchCaseWithAccountId(con.AccountId);
        Assert.areEqual(2, csWrapperList.size() , 'csWrapperList list does not have 2 record');
    }
}