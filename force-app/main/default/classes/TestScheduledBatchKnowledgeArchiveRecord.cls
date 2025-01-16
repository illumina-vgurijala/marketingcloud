/* @ author      : Adyasha Satapathy
* @ date         : 06-01-2021
* @ Description  : TestScheduledBatchKnowledgeArchiveRecord is the test class for the Class ScheduledBatchKnowledgeArchiveICERecords & ScheduledBatchKnowledgeArchiveHelper.
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Adyasha Satapathy       06-01-2021                 DCP-43401         Initial version.
*/
@isTest
public with sharing class TestScheduledBatchKnowledgeArchiveRecord {
    public static final String PUBLISH_STATUS_ARCHIVED = 'Archived';

    /**
    *  @author      :Adyasha Satapathy
    *  @description :test method to create, publish Knowledge Article
    **/

    @isTest
    public static void testScheduleUpsert(){

        knowledge__kav newArticle = TestDataKnowledgeArticle.getKnowledgeArticle(TestBatchKnowledgeArticleICESync.KA_TITLE,'Instrumentation','Software');
        newArticle.External_Content_ID__c = 'abcd';
        newArticle.Knowledge_Source__c = ScheduledBatchKnowledgeArchiveICERecords.SOURCE_ICE;
        insert newArticle;
        Knowledge__kav  objKA = [SELECT Id, KnowledgeArticleId FROM Knowledge__kav WHERE Id = :newArticle.Id];
        KbManagement.PublishingService.publishArticle(objKA.KnowledgeArticleId, true);
        Test.startTest();
        ScheduledBatchKnowledgeArchiveICERecords obj =new ScheduledBatchKnowledgeArchiveICERecords();
        obj.execute(null);
        Test.stopTest();
        Knowledge__kav  objArKA = [Select id,PublishStatus from Knowledge__kav LIMIT 1];
        System.assertEquals(PUBLISH_STATUS_ARCHIVED, objArKA.PublishStatus, 'Knowledge Article not archived.');
    }


}