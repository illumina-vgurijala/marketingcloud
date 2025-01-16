@isTest(isParallel=true)
/***************************************************************************************************************************************
* NAME   : TestCaseUnreadEmailsToggleController 
* --------------------------------------------------------------------------------------------------------------------------------------
*/	
public with sharing class TestCaseUnreadEmailsToggleController {
		
    static Case cs;
	@testSetup
    static void initializeTestData(){
    	cs = TestDataCase.initNewCase('Business Issue', 'Initiated', 'Phone - Field');
        cs.Date_of_Issue_Awareness__c = Date.Today();
        insert cs;
    }

    @isTest
    static void testToggleUnreadEmail(){
        initializeTestData();
    	Case objCase = [Select id,Unread_Emails__c From Case LIMIT 1];

        Test.startTest();
        
        Test.setCurrentPageReference(new PageReference('Page.CaseUnreadEmailsToggle')); 
        System.currentPageReference().getParameters().put('id', objCase.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(objCase);
        CaseUnreadEmailsToggleController pageController = new CaseUnreadEmailsToggleController(sc);
        pageController.toggleUnreadEmail();
        Case objCase1 = [Select id,Unread_Emails__c From Case where id =:objCase.Id];
        Test.stopTest();
        System.assertEquals(objCase.Unread_Emails__c,!objCase1.Unread_Emails__c);
    }
}