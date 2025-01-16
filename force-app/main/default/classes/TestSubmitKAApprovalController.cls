/******************************************************************************************************************************
* NAME         : TestSubmitKAApprovalController
* DESCRIPTION  : Test class for SubmitKAApprovalController
*                    
* @AUTHOR : Anisha Bharti
* @DATE   : 12-Dec-2020   
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/ 

@isTest(SeeAllData = false)  
public with sharing class TestSubmitKAApprovalController {
	
    /*
    *@author: Anisha Bharti
    *@Desc: Test method 
    */
    public static String newId;
    @testSetup
    static  void setupData(){
        
        Knowledge__kav know = new Knowledge__kav();
        know.Article_Body__c = 'I am the Article body';
        know.Title = 'New "Article"';
        know.Summary = 'Test Article Summary';
        know.UrlName = 'New--Article-Demo-A';
        know.Primary_Workflow__c = 'Instrumentation';
		know.Secondary_Workflow__c = 'Software';
        know.Article_Version_Author__c = userinfo.getuserid();
		know.RecordtypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByDeveloperName().get('FAQ').getRecordTypeId();
		
        insert know;
        Custom_Approval_Matrix__c am = new Custom_Approval_Matrix__c();
        am.Name = 'Instrumentation';
        am.Email_Queue__c = 'KB_Instrumentation';
        am.RecordtypeId = Schema.SObjectType.Custom_Approval_Matrix__c.getRecordTypeInfosByDeveloperName().get(label.Knowledge_Approval_Matrix_Recordtype).getRecordTypeId();
        insert am;
        
    }

    
    /**
    *    @author Anisha Bharti
    *    @date   12-Dec-2020
    *    @test Method of fetchKnowledgeArticles
    */
    static testmethod void testfetchKnowledgeArticles(){
        Knowledge__kav know = [select id, Title, Summary, Article_Body__c, UrlName, Primary_Workflow__c,Secondary_Workflow__c from Knowledge__kav LIMIT 1];
        Test.startTest();
        SubmitKAApprovalController.submitApproval(know.id, 'Comment');
        Test.stopTest();
		System.assertEquals('Instrumentation', know.Primary_Workflow__c);
        System.assertEquals('Software', know.Secondary_Workflow__c);
    }
}