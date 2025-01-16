/* @ author      : Adyasha Satapathy
* @ date         : 20-11-2020
* @ Description  : TestKAFeedbackController s is the test class for the Controller KAFeedbackController of feedbackComponent LWC.
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Adyasha Satapathy       20-11-2020                  DCP-43356          Initial version
* Adyasha Satapathy       03-12-2020                  DCP-43356          Test Class Update for File upload
* Adyasha Satapathy       29-01-2021                     NA              Codescan Issue Fixes
*/
@isTest
public with sharing class TestKAFeedbackController
{
    public static final String POSITIVE_VOTE_TYPE = '5';
    public static final String NEGATIVE_VOTE_TYPE = '1';
    public static final String EXCEPTION_MESSAGE = 'Script-thrown exception';
    public static final String KA_ARTICLE_BODY = 'testbody';
    public static final String KA_PRIMARY_WORKFLOW = 'Instrumentation';
    public static final String KA_SECONDARY_WORKFLOW = 'Software';

    /**
     *  @author      :Adyasha Satapathy
     *  @description :Setup method
     **/
    @TestSetup
    static void initializeTestData()
    {
        String newArticleKnowledgeId = createNewArticleAsADraft();
        publishArticle(newArticleKnowledgeId);
    }
    /**
     *  @author      :Adyasha Satapathy
     *  @description :test method to create Knowledge Article in draft version
     **/
    public static String createNewArticleAsADraft()
    {
        Knowledge__kav newArticle = TestDataKnowledgeArticle.getKnowledgeArticle(TestBatchKnowledgeArticleICESync.KA_TITLE,KA_PRIMARY_WORKFLOW,KA_SECONDARY_WORKFLOW);
        insert newArticle;
 
        return [SELECT KnowledgeArticleId FROM Knowledge__kav WHERE Id =: newArticle.Id].KnowledgeArticleId;
    }
    /**
     *  @author      :Adyasha Satapathy
     *  @description :test method to publish Knowledge Article
     **/
    public static void publishArticle(String recordId) 
    { 
        KbManagement.PublishingService.publishArticle(recordId, true);
    }
    /**
     *  @author      :Adyasha Satapathy
     *  @description :test method to create feedback record, file, upload file with feedback record save
     **/
    @isTest
    public static void testFeedbackController()
    {
        Knowledge__kav objKnowledge = [Select Id,Title,KnowledgeArticleId FROM Knowledge__kav LIMIT 1];
        
        Vote objVote = new Vote();
        objVote.ParentId = objKnowledge.KnowledgeArticleId;
        objVote.Type = NEGATIVE_VOTE_TYPE;
        insert objVote;

        //Create Feedback Record
        Feedback__c newFeed = new Feedback__c();
        newFeed.Feedback_Reason__c = 'Typo';
        newFeed.Feedback_Description__c = 'Test';
        newFeed.Feedback_Status__c = 'Open';
        newFeed.Feedback_Disposition__c = 'New';
        newFeed.Knowledge_Article_Link__c = objKnowledge.Id;
        insert newFeed;
       
        Test.startTest();
        KAFeedbackController.createVoteRecord(POSITIVE_VOTE_TYPE,objKnowledge.KnowledgeArticleId,objVote.Id);
        KAFeedbackController.fetchDetails(objKnowledge.Id);
       
        Test.stopTest();
        List<Vote> lstVote = [Select Id,ParentId,Type from Vote where ParentId =: objKnowledge.KnowledgeArticleId and CreatedBy.Id =:userinfo.getuserid()];
        System.assertEquals(1,lstVote.size());
        System.assertEquals(POSITIVE_VOTE_TYPE,lstVote.get(0).Type);
    }
    /**
     *  @author      :Adyasha Satapathy
     *  @description :test method to test exception for testCreateVoteFailure
     **/
    @isTest
    public static void testCreateVoteFailure(){
        String strExceptionMessage='';
        Knowledge__kav objKnowledge = [Select Id,Title,KnowledgeArticleId FROM Knowledge__kav LIMIT 1];
    
        Test.startTest();
        KAFeedbackController.createVoteRecord(POSITIVE_VOTE_TYPE,objKnowledge.KnowledgeArticleId,null);
        try{
            KAFeedbackController.createVoteRecord(POSITIVE_VOTE_TYPE,objKnowledge.KnowledgeArticleId,null);
        }catch(Exception e){
            strExceptionMessage = e.getMessage();
        }
        Test.stopTest();
        System.assertEquals(true, strExceptionMessage.contains(EXCEPTION_MESSAGE));
    }  
}