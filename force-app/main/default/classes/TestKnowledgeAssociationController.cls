/**
 *    @author Anisha Bharti
 *    @date   25-Nov-2020
 *    @description  Test class of KnowledgeAssociationComponentController
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------------------
 *     Developer                      Date                Description
 *  
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
 */
@isTest
public with sharing class TestKnowledgeAssociationController {
    
    /*
    *@author: Anisha Bharti
    *@Desc: Test method 
    */

    public static final string  KNOWLEDGE_WORKFLOW = 'Instrumentation';

    @testSetup 
    static void setupData(){
        Knowledge__kav know = TestDataKnowledgeArticle.getKnowledgeArticle('New "Article"',KNOWLEDGE_WORKFLOW,KNOWLEDGE_WORKFLOW);
        insert know;
        
        Knowledge__kav know1 = TestDataKnowledgeArticle.getKnowledgeArticle('New Sample "Article"',KNOWLEDGE_WORKFLOW,KNOWLEDGE_WORKFLOW);
        insert know1;

        Knowledge__kav know2 = TestDataKnowledgeArticle.getKnowledgeArticle('New Sample "Article"',KNOWLEDGE_WORKFLOW,KNOWLEDGE_WORKFLOW);
        insert know2;
        
        Knowledge_Association__c ka = new Knowledge_Association__c();
        ka.Parent_Knowledge__c = know.id;
        ka.Related_Knowledge__c = know1.id;
        insert ka;
        Knowledge__kav objKA = [Select id,KnowledgeArticleId from Knowledge__kav where Id =:know2.id][0];
        KbManagement.PublishingService.publishArticle(objKA.KnowledgeArticleId, false);
        
    }
    
    /**
    *    @author Anisha Bharti
    *    @date   25-Nov-2020
    *    @test Method of fetchKnowledgeArticles
    */
    @isTest
    static void testfetchKnowledgeArticles(){
        
        Knowledge__kav know = [select id, Title, Summary, Article_Body__c, UrlName, Primary_Workflow__c from Knowledge__kav where Title = 'New "Article"'];
        Test.startTest();
        String strResult = KnowledgeAssociationComponentController.fetchKnowledgeArticles('New', know.id);
        Test.stopTest();
        List<KnowledgeAssociationComponentController.AssociatedKnowledgeRecords> lstReturn = (List<KnowledgeAssociationComponentController.AssociatedKnowledgeRecords>)JSON.deserialize(strResult, List<KnowledgeAssociationComponentController.AssociatedKnowledgeRecords>.class);
        System.assertEquals(1,lstReturn.size(),'Incorrect Search Result');
        
    }
    /**
    *    @author Anisha Bharti
    *    @date   25-Nov-2020
    *    @test Method of fetchRelatedKnowledge
    */
    @isTest
    static void testfetchRelatedKnowledge(){
        
        Knowledge__kav know = [select id, Title, Summary, Article_Body__c, UrlName, Primary_Workflow__c from Knowledge__kav where Title = 'New "Article"'];
        Test.startTest();
        String strResult = KnowledgeAssociationComponentController.fetchRelatedKnowledge(know.id);
        Test.stopTest();
        Map<String,List<KnowledgeAssociationComponentController.AssociatedKnowledgeRecords>> mapReturn = (Map<String,List<KnowledgeAssociationComponentController.AssociatedKnowledgeRecords>>)
                    JSON.deserialize(UtilsObject.getJSONPart(strResult,'{"lstKnowledgeAssociationWrap": ', ', "mapLabels":'), Map<String,List<KnowledgeAssociationComponentController.AssociatedKnowledgeRecords>>.class);
        System.assertEquals(1,mapReturn.keySet().size(),'Incorrect Related List');
    }


}