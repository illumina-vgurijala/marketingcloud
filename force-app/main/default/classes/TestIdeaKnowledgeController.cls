/**
*    @author: Deep Diwakar
*    @date:   Oct-05-2024
*    @description: 
     @Test Class:  It is a Test class for IdeaKnowledgeController, IdeaArticlesSelector and InnovationIdeasSelector
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Oct-05-2024        CMCM-10147: Test class for IdeaKnowledgeController, IdeaArticlesSelector and InnovationIdeasSelector
* --------------------------------------------------------------------------------------------------
*/

@IsTest
private class TestIdeaKnowledgeController {

    @TestSetup
    static void testDataCreation() {
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

        Id kaId;

        List<Knowledge__kav> lstKnowledge = [Select Id,KnowledgeArticleId from Knowledge__kav where Id IN :setKAIds];
        for(Knowledge__kav objKA : lstKnowledge)
        {
            KbManagement.PublishingService.publishArticle(objKA.KnowledgeArticleId, true);
            kaId = objKA.KnowledgeArticleId;
        }
		

        // create ideaArticle object record
        IdeaArticle__c testIdeaArticle = new IdeaArticle__c(Idea_Innohub__c = idea1.Id, Knowledge__c = newArticle1.Id, Case__c = testCase1.Id);
        insert testIdeaArticle;

        // create casearticle record
        CaseArticle testCaseArticle = new CaseArticle(CaseId = testCase1.Id, KnowledgeArticleId = kaId);
        insert testCaseArticle;


    }

    @isTest
    static void testGetLinkedIdeas() {
        // get KAV id
        knowledge__kav testKAV = [Select Id From knowledge__kav Where Title = 'Test Article 1'];

        List<innohub__Innovation_Idea__c> resultList = new List<innohub__Innovation_Idea__c>();

        Test.startTest();

        resultList = IdeaKnowledgeController.getLinkedIdeas(testKAV.Id);

        Test.stopTest();

        Assert.areEqual(1, resultList.size(), 'Method did not return correctly linked ideas');

    }

    @isTest
    static void testAttachIdeaToKnowledge() {

        // get KAV id
        knowledge__kav testKAV = [Select Id From knowledge__kav Where Title = 'Test Article 1'];

        // get ideas
        List<innohub__Innovation_Idea__c> ideaList = [Select Id From innohub__Innovation_Idea__c LIMIT 1000];
        List<Id> lstIdeaIds = new List<Id>();
        for (innohub__Innovation_Idea__c idea : ideaList) {
            lstIdeaIds.add(idea.Id);
        }

        Boolean result = false;
        String kavId = testKAV.Id;

        Test.startTest();

        result = IdeaKnowledgeController.attachIdeaToKnowledge(kavId, lstIdeaIds);

        Test.stopTest();

        Assert.isTrue(result, 'Ideas did not correctly linked to KAV');

    }

    @isTest
    static void testAttachIdeaNoCase() {

        // get KAV id
        knowledge__kav testKAV = [Select Id From knowledge__kav Where Title = 'Test Article 2'];

        // get ideas
        List<innohub__Innovation_Idea__c> ideaList = [Select Id From innohub__Innovation_Idea__c LIMIT 1000];
        List<Id> lstIdeaIds = new List<Id>();
        for (innohub__Innovation_Idea__c idea : ideaList) {
            lstIdeaIds.add(idea.Id);
        }

        Boolean result = false;
        String kavId = testKAV.Id;

        Test.startTest();

        result = IdeaKnowledgeController.attachIdeaToKnowledge(kavId, lstIdeaIds);

        Test.stopTest();

        Assert.isTrue(result, 'Ideas did not correctly linked to KAV');

    }

    @isTest
    static void testFindIdeas() {

        innohub__Innovation_Idea__c idea2 = [Select Id From innohub__Innovation_Idea__c Where Name = 'Test Idea 2'];
        List<Id> fixedSearchResults = new List<Id>{idea2.Id};

        Test.setFixedSearchResults(fixedSearchResults);

        List<innohub__Innovation_Idea__c> resultList = new List<innohub__Innovation_Idea__c>();

        Test.startTest();

        resultList = IdeaKnowledgeController.findIdeas('Test Idea 2');

        Test.stopTest();

        Assert.areEqual(1, resultList.size(), 'Not able to find Idea');

    }

    @IsTest
    static void testCatchBlockAttachIdeaToKnowledge() {

        Boolean exceptionThrown = false;

        // get KAV id
        knowledge__kav testKAV = [Select Id From knowledge__kav Where Title = 'Test Article 1'];

        // get ideas
        List<innohub__Innovation_Idea__c> ideaList = [Select Id From innohub__Innovation_Idea__c LIMIT 1000];
        List<Id> lstIdeaIds = new List<Id>();
        for (innohub__Innovation_Idea__c idea : ideaList) {
            lstIdeaIds.add(idea.Id);
        }

        String kavId = testKAV.Id;


        try {

            Test.startTest();

            IdeaKnowledgeController.testCodeCoverage = true;
            IdeaKnowledgeController.attachIdeaToKnowledge(kavId, lstIdeaIds);
    
            Test.stopTest();

        } catch(Exception ex) {
            exceptionThrown = ex.getTypeName().contains('AuraHandledException');
        }

        Assert.isTrue(exceptionThrown, 'Catch block did not throw exception properly');

    }

    @IsTest
    static void testCatchBlockFindIdeas() {

        Boolean exceptionThrown = false;

        innohub__Innovation_Idea__c idea2 = [Select Id From innohub__Innovation_Idea__c Where Name = 'Test Idea 2'];
        List<Id> fixedSearchResults = new List<Id>{idea2.Id};

        Test.setFixedSearchResults(fixedSearchResults);


        try {

            Test.startTest();

            IdeaKnowledgeController.testCodeCoverage = true;
            IdeaKnowledgeController.findIdeas('Test Idea 2');
    
            Test.stopTest();

        } catch(Exception ex) {
            exceptionThrown = ex.getTypeName().contains('AuraHandledException');
        }

        Assert.isTrue(exceptionThrown, 'Catch block did not throw exception properly');

    }

    @IsTest
    static void testCatchBlockGetLinkedIdeas() {

        Boolean exceptionThrown = false;

        // get KAV id
        knowledge__kav testKAV = [Select Id From knowledge__kav Where Title = 'Test Article 1'];


        try {

            Test.startTest();

            IdeaKnowledgeController.testCodeCoverage = true;
            IdeaKnowledgeController.getLinkedIdeas(testKAV.Id);
    
            Test.stopTest();

        } catch(Exception ex) {
            exceptionThrown = ex.getTypeName().contains('AuraHandledException');
        }

        Assert.isTrue(exceptionThrown, 'Catch block did not throw exception properly');

    }

}