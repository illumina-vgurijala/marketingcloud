/**
*    @author: Deep Diwakar
*    @date:   Oct-11-2024
*    @description: Test class for BatchIdeaArticleUpdate class
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Oct-11-2024        CMCM-8512: Test class for BatchIdeaArticleUpdate class
*    --------------------------------------------------------------------------------------------------
*/

@isTest
private class TestBatchIdeaArticleUpdate {

    @TestSetup
    static void testDataSetup() {
         // create ideas
         List<innohub__Innovation_Idea__c> ideaList = new List<innohub__Innovation_Idea__c>();
         innohub__Innovation_Idea__c idea1 = new innohub__Innovation_Idea__c(Name = 'Test Idea 1', Category__c = 'Sequencer: Hardware/Control SW/Reagents',
                                                                             Sub_Category__c = 'iSeq 100', innohub__Description__c = 'Test Idea 1');
         innohub__Innovation_Idea__c idea2 = new innohub__Innovation_Idea__c(Name = 'Test Idea 2', Category__c = 'Software: Non-instrument Control SW',
                                                                             Sub_Category__c = 'BaseSpace CLI', innohub__Description__c = 'Test Idea 2');
         innohub__Innovation_Idea__c idea3 = new innohub__Innovation_Idea__c(Name = 'Test Idea 3', Category__c = 'Library Prep',
                                                                             Sub_Category__c = 'DNA prep kits', innohub__Description__c = 'Test Idea 3');
         ideaList.add(idea1);
         ideaList.add(idea2);
         ideaList.add(idea3);
         insert ideaList;
 
         // create contact
         Contact testContact = TestDataMarketing.createContact('Marketability', 'Testing', 'marketability@testing.com', 'US');
 
         // create case
         List<Case> lstCases = new List<Case>();
         Case testCase1 = TestDataCase.initNewCase('Service Request', 'Initiated', testContact.Id);
         Case testCase2 = TestDataCase.initNewCase('Service Request', 'Initiated', testContact.Id);
         Case testCase3 = TestDataCase.initNewCase('Service Request', 'Initiated', testContact.Id);
         lstCases.add(testCase1);
         lstCases.add(testCase2);
         lstCases.add(testCase3);
 
         insert lstCases;
 
         // create knowledge article
         Id draftRecordTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByName().get('Evaluation Aid').getRecordTypeId();
      
         knowledge__kav newArticle1 = new knowledge__kav(Title='Test Article 1',Recordtypeid = draftRecordTypeId, summary='xyz',urlname=String.valueof(System.now()).replaceAll('[^a-zA-Z0-9\\-s+]', '-')+'Z1',Article_Body__c='test', Article_Version_Author__c = userinfo.getuserid(),Primary_Workflow__c='Software',Secondary_Workflow__c='Software');
         knowledge__kav newArticle2 = new knowledge__kav(Title='Test Article 2',Recordtypeid = draftRecordTypeId, summary='xyz',urlname='Demo',Article_Body__c='test', Article_Version_Author__c = userinfo.getuserid(),Primary_Workflow__c='Software',Secondary_Workflow__c='Software');
         knowledge__kav newArticle3 = new knowledge__kav(Title='Archived',Recordtypeid = draftRecordTypeId, summary='xyz',urlname='Archived',Article_Body__c='test', Article_Version_Author__c = userinfo.getuserid(),Primary_Workflow__c='Software',Secondary_Workflow__c='Software');
         
         insert new List<Knowledge__kav>{newArticle1, newArticle2,newArticle3};
         
         Set<Id> setKAIds = new Set<Id>{newArticle1.Id, newArticle2.Id};

 
         List<Knowledge__kav> lstKnowledge = [Select Id,KnowledgeArticleId from Knowledge__kav where Id IN :setKAIds];
         for(Knowledge__kav objKA : lstKnowledge)
         {
             KbManagement.PublishingService.publishArticle(objKA.KnowledgeArticleId, true);
         }
         
        // link idea to knowledge article
        IdeaArticle__c testIdeaArticle = new IdeaArticle__c(Idea_Innohub__c = idea1.Id, Knowledge__c = newArticle1.Id);
        insert testIdeaArticle;
 
        
    }

    @IsTest
    static void testIdeaArticleBatch() {

        // get existing contact
        Contact testCont = [Select Id From Contact Where Email = 'marketability@testing.com' Limit 1];

        // create new case
        Case testCase = TestDataCase.initNewCase('Service Request', 'Initiated', testCont.Id);
        insert testCase;

        // get Knowledge article version
        knowledge__kav testKAV = [Select Id, KnowledgeArticleId From knowledge__kav Where Title = 'Test Article 1'];

        // create casearticle record
        CaseArticle testCaseArticle = new CaseArticle(CaseId = testCase.Id, KnowledgeArticleId = testKAV.KnowledgeArticleId);
        insert testCaseArticle;

        Test.startTest();
        Database.executeBatch(new BatchIdeaArticleUpdate());
        Test.stopTest();

        List<IdeaArticle__c> lstResultList = [Select Id From IdeaArticle__c where Case__c =: testCase.Id];

        Assert.areEqual(1, lstResultList.size(), 'Batch Job Idea article did not create record correctly');


    }

    @IsTest
    static void testIdeaArticleBatchNoInsert() {

        // get existing contact
        Contact testCont = [Select Id From Contact Where Email = 'marketability@testing.com' Limit 1];

        // create new case
        Case testCase = TestDataCase.initNewCase('Service Request', 'Initiated', testCont.Id);
        insert testCase;

        // get Knowledge article version
        knowledge__kav testKAV = [Select Id, KnowledgeArticleId From knowledge__kav Where Title = 'Test Article 2'];

        // create casearticle record
        CaseArticle testCaseArticle = new CaseArticle(CaseId = testCase.Id, KnowledgeArticleId = testKAV.KnowledgeArticleId);
        insert testCaseArticle;

        Test.startTest();
        Database.executeBatch(new BatchIdeaArticleUpdate());
        Test.stopTest();

        List<IdeaArticle__c> lstResultList = [Select Id From IdeaArticle__c  where Case__c =: testCase.Id];

        Assert.areEqual(0, lstResultList.size(), 'Batch Job Idea article did not create record correctly');


    }

}