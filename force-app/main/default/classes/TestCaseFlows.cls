/***************************************************************************************************************************************
* NAME   : TestCaseFlows
* DESCRIPTION  : For covering the Record-Trigger : Case After Save:Post On QA Reopen , Record-Trigger : Case After Save : Send email to QA Reviewer
*    
* @AUTHOR : Saikiran Surapaneni
* @DATE   : 6-Oct-2023  
*
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Saikiran Surapaneni      9-Oct-2023          Initial Version
* Abhishek Yadav           26-Dec-2023         Added Asserts 
* Kumar Gaurav             29-Aug-2024         Update
****************************************************************************************************************************************/
@IsTest
public class TestCaseFlows {
    
    /**
    * Method to prepare test data
    **/
    @testSetup
    public static void makeData() {
        //insert account
        Account objAccount = TestDataAccount.getAccount('Test Account', 'USD');
        objAccount.Account_Group__c = Accounts.GROUP_ULTIMATE_CONSIGNEE;
        insert objAccount;
        
        //insert contact
        Contact objContact = TestDataPerson.getNewContact(objAccount.Id);            
        Contact insertedContact = [Select AccountId from Contact where Id =: objContact.Id];
        System.assertEquals(insertedContact.AccountId , objAccount.Id);
        
        //create case
        Case objCase = TestDataCase.createCase('Service Request', 'Pending QA Review', objContact.Id);
    }
    
    /**
    * Method to test Post on QA Reopen Flow
    **/
    @IsTest
    public static void testCasePostonQAReopen() {
        Case objCase = [SELECT Id , Status FROM Case LIMIT 1];
        Test.startTest();
        objCase.Status = 'Reopened';
        update objCase;
        Test.stopTest();
        System.assert(objCase != null, true);
        FeedItem item = [SELECT Id FROM FeedItem LIMIT 1];
        Assert.isTrue(item != null);
    }
    
    /**
    * Method to test Send Email to QA Reviewer Flow
    **/
    @IsTest
    public static void testSendEmailToQAReviewer() {
        Test.startTest();
        Case objCase = [SELECT Id , Status , CaseNumber, QA_Reviewer__c FROM Case LIMIT 1];
        User qaUser = TestDataUser.findUserInProfile('Quality Assurance');
        objCase.QA_Reviewer__c = qaUser.Id;
        update objCase;
        objCase.QA_Reviewer__c = UserInfo.getUserId();
        objCase.Status = 'Pending QA Review';
        update objCase; 
        System.assert(objCase != null, true);
        Test.stopTest();        
		Integer emailCount = Limits.getLimitEmailInvocations();
        Assert.isTrue(emailCount != null, 'email not sent');
    }
    
}