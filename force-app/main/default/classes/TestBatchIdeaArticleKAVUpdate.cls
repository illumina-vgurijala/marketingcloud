/**
*    @author: Deep Diwakar
*    @date:   Oct-18-2024
*    @description: Test class for BatchIdeaArticleKAVUpdate class
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Oct-11-2024        CMCM-11914: Test class for BatchIdeaArticleKAVUpdate class
*    --------------------------------------------------------------------------------------------------
*/

@isTest
private class TestBatchIdeaArticleKAVUpdate {

    @TestSetup
    static void testDataSetup() {
        // create ideas
        List<innohub__Innovation_Idea__c> ideaList = new List<innohub__Innovation_Idea__c>();
        innohub__Innovation_Idea__c idea1 = new innohub__Innovation_Idea__c(Name = 'Test Idea 1', Category__c = 'Sequencer: Hardware/Control SW/Reagents',
                                                                            Sub_Category__c = 'iSeq 100', innohub__Description__c = 'Test Idea 1');
        innohub__Innovation_Idea__c idea2 = new innohub__Innovation_Idea__c(Name = 'Test Idea 2', Category__c = 'Software: Non-instrument Control SW',
                                                                            Sub_Category__c = 'BaseSpace CLI', innohub__Description__c = 'Test Idea 2');
        ideaList.add(idea1);
        ideaList.add(idea2);
        insert ideaList;

        // create knowledge article 
        Id draftRecordTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByName().get('Evaluation Aid').getRecordTypeId();

        knowledge__kav newArticle1 = new knowledge__kav(Title='Test Article 1',Recordtypeid = draftRecordTypeId, summary='xyz',urlname=String.valueof(System.now()).replaceAll('[^a-zA-Z0-9\\-s+]', '-')+'Z1',Article_Body__c='test', Article_Version_Author__c = userinfo.getuserid(),Primary_Workflow__c='Software',Secondary_Workflow__c='Software');
        knowledge__kav newArticle2 = new knowledge__kav(Title='Test Article 2',Recordtypeid = draftRecordTypeId, summary='xyz',urlname='Demo',Article_Body__c='test', Article_Version_Author__c = userinfo.getuserid(),Primary_Workflow__c='Software',Secondary_Workflow__c='Software');
        
        insert new List<Knowledge__kav>{newArticle1, newArticle2};
        
        Set<Id> setKAIds = new Set<Id>{newArticle1.Id, newArticle2.Id};

        List<Knowledge__kav> lstKnowledge = [Select Id,KnowledgeArticleId from Knowledge__kav where Id IN :setKAIds];
        for(Knowledge__kav objKA : lstKnowledge) {
            // publish knowledge article
            KbManagement.PublishingService.publishArticle(objKA.KnowledgeArticleId, true);
        }
            
        // link idea to knowledge article
        IdeaArticle__c testIdeaArticle = new IdeaArticle__c(Idea_Innohub__c = idea1.Id, Knowledge__c = newArticle1.Id);
        insert testIdeaArticle;
        
    }

    @isTest
    static void testIdeaArticleKAVUpdateBatch() {

        // get knowledge article version
        knowledge__kav testKAV = [Select Id, KnowledgeArticleId, Primary_Approver__c, Secondary_Approver__c From knowledge__kav Where Title = 'Test Article 1'];

        Id kaId = testKAV.KnowledgeArticleId;

        // this method archives current online version of knowledge article and starts a new draft version 
        String draftKavId =  KbManagement.PublishingService.editOnlineArticle(kaId, true);

        //Creating Object Instance to Update with draft version info
        Knowledge__kav objKnowledgeArticle = new Knowledge__kav();
        objKnowledgeArticle.Id=Id.valueOf(draftKavId);
        objKnowledgeArticle.IsVisibleInPrm=true;
        objKnowledgeArticle.ValidationStatus='Approved';
        objKnowledgeArticle.Review_Status__c='Review Completed';
        objKnowledgeArticle.Primary_Approver__c=testKAV.Primary_Approver__c;
        objKnowledgeArticle.Secondary_Approver__c=testKAV.Secondary_Approver__c;
        objKnowledgeArticle.CP_Article_Approval_Status__c = 'Approved';

        update objKnowledgeArticle;

        // publish new draft version
        KbManagement.PublishingService.publishArticle(kaId, true);

        Test.startTest();
        BatchIdeaArticleKAVUpdate batchInstance = new BatchIdeaArticleKAVUpdate();
        Database.executeBatch(batchInstance);
        Test.stopTest();

        IdeaArticle__c iaObj = [Select Id, Knowledge__c From IdeaArticle__c Limit 1];

        Assert.areEqual(draftKavId, iaObj.Knowledge__c, 'Batch job BatchIdeaArticleKAVUpdate did not update Idea Article records correctly');


    }

}