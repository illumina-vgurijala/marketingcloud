/* @ author      : Adyasha Satapathy
* @ date         : 07-01-2021
* @ Description  : TestBatchKnowledgeArticleICESync is the test class for the Classes BatchKnowledgeArticleICESync,BatchKnowledgeArticleICESyncHelper,
KnowledgeOnDemandSyncCmpController,KnowledgeArticleICESyncConnector,KnowledgeArticleICESyncEmailHandler
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Adyasha Satapathy       07-01-2021                 DCP-43401         Initial version.
* Gladis                  28-09-2021                 CMCP-122: Added an assert in the testOnDemand method for checking the article visibility for CP users
---------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class TestBatchKnowledgeArticleICESync {
    public static final String RECORD_TYPE_NAME = 'Bulletin';
    public static final String PUBLISH_STATUS_ARCHIVED = 'Archived';
    public static final String KA_TITLE = 'test';
    public static final String KA_SUMMARY = 'xyz';
    public static final String EMAIL_SUBJECT = '12345678-001.10-S';
    public static final String EMAIL_BODY = 'Hello, this a test email body. for testing purposes only.';
    public static final String EMAIL_FROM_ADDRESS = 'test@illumina.com';
    public static final String EMAIL_TO_ADDRESS = 'sfdc@illumina.com';
    public static final String EMAIL_ATTACHMENT = 'newfile.csv';
    /**
    *  @author      : Adyasha Satapathy
    *  @description : Setup method for KA creation
    **/
    @TestSetup
    static void setupData(){
        knowledge__kav newArticle1 = TestDataKnowledgeArticle.getKnowledgeArticle(KA_TITLE,'Instrumentation','Software');       
        newArticle1.External_Content_ID__c = '64ce217c-1fcd-48f7-b36c-a0cacd8b6c4e';
        newArticle1.Document_Number__c = '1111111111111';
		newArticle1.Knowledge_source__c ='ICE';
        knowledge__kav newArticle2 = TestDataKnowledgeArticle.getKnowledgeArticle('test2','Instrumentation','Software');
        newArticle2.External_Content_ID__c = 'f4c964de-f964-41ae-8543-25e1f42763cb';
        newArticle2.Document_Number__c = '2222222222222';
		newArticle2.Knowledge_source__c ='ICE';
        insert new List<Knowledge__kav>{newArticle1,newArticle2};
        
        Set<Id> setKAIds = new Set<Id>{newArticle1.Id, newArticle2.Id};

        List<Knowledge__kav> lstKnowledge = [Select Id,KnowledgeArticleId from Knowledge__kav where Id IN :setKAIds];
        for(Knowledge__kav objKA : lstKnowledge)
        {
            KbManagement.PublishingService.publishArticle(objKA.KnowledgeArticleId, true);
        }
    }
    /**
    *  @author      :Adyasha Satapathy
    *  @description :test method to test Sync On Demand functionality
    **/

    @isTest
    public static void testOnDemand(){
        knowledge__kav newArticle = TestDataKnowledgeArticle.getKnowledgeArticle(KA_TITLE,'Instrumentation','Software');
        newArticle.External_Content_ID__c = '841d1e83-3efe-4048-b697-5f7e8ce22c53';
        newArticle.Document_Number__c = '3333333333333';
        insert newArticle;
        List<Knowledge__kav> lstKA = new KnowledgeArticlesSelector().selectArticleByContentId('841d1e83-3efe-4048-b697-5f7e8ce22c53','Draft');
        KbManagement.PublishingService.publishArticle(lstKA[0].KnowledgeArticleId, true);
        Test.startTest();
        KnowledgeOnDemandSyncCmpController.onDemandSync(lstKA[0].id);
        Test.stopTest();
        Knowledge__kav  objKA = [Select id,RecordType.DeveloperName,IsVisibleInPrm from Knowledge__kav LIMIT 1];
        System.assertEquals(true, objKA.IsVisibleInPrm, 'Visible for CP');//CMCP-122
        System.assertEquals(RECORD_TYPE_NAME, objKA.RecordType.DeveloperName, 'Record Type not synced.');
    }
    /**
    *  @author      :Adyasha Satapathy
    *  @description :test method to test Email functionality and call batch class
    **/
    @isTest
    public static void testKnowledgeEmailHandlerCreation(){

        Test.starttest();
        
        KnowledgeArticleICESyncEmailHandler  objKAICEHandler = new KnowledgeArticleICESyncEmailHandler();

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        email.subject = EMAIL_SUBJECT;
        email.plainTextBody = EMAIL_BODY;
        email.fromAddress = EMAIL_FROM_ADDRESS;
        email.toAddresses = new list<String>{EMAIL_TO_ADDRESS};

        Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
        binaryAttachment.Filename = EMAIL_ATTACHMENT;
        String strBody = '';
        strBody = strBody + '64ce217c-1fcd-48f7-b36c-a0cacd8b6c4e,1111111111111,ICEKA2,2020,2020,File,docx,TRUE,FALSE,2,www.ICEKA2.com,SAP,Commercial,176589c8-c229-45a7-b2ba-44e5930407c4,0858c564-9000-7194-081a-b87b10570588,Knowledge Management\n';
        strBody = strBody + '64ce217c-1fcd-48f7-b36c-a0cacd8b6cKD1,4444444444444,ICEKA3,2020,2020,File,docx,FALSE,TRUE,2,www.ICEKA3.com,SAP,Commercial,176589c8-c229-45a7-b2ba-44e5930407c4,0858c564-9000-7194-081a-b87b10570588,Knowledge Management';
        binaryAttachment.body = blob.valueOf(strBody);
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { binaryattachment };
        objKAICEHandler.handleInboundEmail(email, envelope);

        Test.stopTest();
        List<Knowledge__kav>  lstKA = [Select id,RecordType.DeveloperName,PublishStatus,VersionNumber from Knowledge__kav WHERE Document_Number__c IN ('4444444444444') LIMIT 1];
        System.assert(!lstKA.isEmpty(),'Knowledge Article not Created');
    }
    /**
    *  @author      :Adyasha Satapathy
    *  @description :test method to test Email functionality and call batch class
    **/
    @isTest
    public static void testKnowledgeEmailHandlerEdit(){

        Test.starttest();
        
        KnowledgeArticleICESyncEmailHandler  objKAICEHandler = new KnowledgeArticleICESyncEmailHandler();

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        email.subject = EMAIL_SUBJECT;
        email.plainTextBody = EMAIL_BODY;
        email.fromAddress = EMAIL_FROM_ADDRESS;
        email.toAddresses = new list<String>{EMAIL_TO_ADDRESS};

        Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
        binaryAttachment.Filename = EMAIL_ATTACHMENT;
        String strBody = '';
        strBody = strBody + '64ce217c-1fcd-48f7-b36c-a0cacd8b6cKD1,4444444444444,ICEKA3,2020,2020,File,docx,FALSE,TRUE,2,www.ICEKA3.com,SAP,Commercial,176589c8-c229-45a7-b2ba-44e5930407c4,0858c564-9000-7194-081a-b87b10570588,Knowledge Management\n';
        strBody = strBody + 'f4c964de-f964-41ae-8543-25e1f42763cb,2222222222222,ICEKA1,2020,2020,File,docx,FALSE,TRUE,2,www.ICEKA1.com,SAP,Commercial,176589c8-c229-45a7-b2ba-44e5930407c4,0858c564-9000-7194-081a-b87b10570588,Knowledge Management';
        binaryAttachment.body = blob.valueOf(strBody);
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { binaryattachment };
        objKAICEHandler.handleInboundEmail(email, envelope);

        Test.stopTest();
        List<Knowledge__kav>  lstKA = [Select id,RecordType.DeveloperName,PublishStatus,VersionNumber from Knowledge__kav WHERE Document_Number__c IN ('2222222222222') LIMIT 1];
        System.assert(!lstKA.isEmpty(),'Knowledge Article not Re-Published');
    }
    /**
    *  @author      :Adyasha Satapathy
    *  @description :test method to test Email functionality and call batch class
    **/
    @isTest
    public static void testKnowledgeEmailHandlerArchive(){

        Test.starttest();
        
        KnowledgeArticleICESyncEmailHandler  objKAICEHandler = new KnowledgeArticleICESyncEmailHandler();

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        email.subject = EMAIL_SUBJECT;
        email.plainTextBody = EMAIL_BODY;
        email.fromAddress = EMAIL_FROM_ADDRESS;
        email.toAddresses = new list<String>{EMAIL_TO_ADDRESS};

        Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
        binaryAttachment.Filename = EMAIL_ATTACHMENT;
        String strBody = '';
        strBody = strBody + 'f4c964de-f964-41ae-8543-25e1f42763cb,2222222222222,ICEKA1,2020,2020,File,docx,FALSE,TRUE,2,www.ICEKA1.com,SAP,Commercial,176589c8-c229-45a7-b2ba-44e5930407c4,0858c564-9000-7194-081a-b87b10570588,Knowledge Management\n';
        strBody = strBody + '64ce217c-1fcd-48f7-b36c-a0cacd8b6c4e,1111111111111,ICEKA2,2020,2020,File,docx,TRUE,FALSE,2,www.ICEKA2.com,SAP,Commercial,176589c8-c229-45a7-b2ba-44e5930407c4,0858c564-9000-7194-081a-b87b10570588,Knowledge Management';    
        binaryAttachment.body = blob.valueOf(strBody);
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { binaryattachment };
        objKAICEHandler.handleInboundEmail(email, envelope);

        Test.stopTest();
        Knowledge__kav  objKA = [Select id,RecordType.DeveloperName,PublishStatus from Knowledge__kav where Document_Number__c IN ('1111111111111') LIMIT 1];
        System.assertEquals('Archived', objKA.PublishStatus, 'Knowledge Article not archived');
		
		
    }
    /**
    *  @author      :Adyasha Satapathy
    *  @description :test method to test Email functionality and call batch class
    **/
    @isTest
    public static void testKnowledgeEmailHandlerNoAction(){

        Test.starttest();
        
        KnowledgeArticleICESyncEmailHandler  objKAICEHandler = new KnowledgeArticleICESyncEmailHandler();

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        email.subject = EMAIL_SUBJECT;
        email.plainTextBody = EMAIL_BODY;
        email.fromAddress = EMAIL_FROM_ADDRESS;
        email.toAddresses = new list<String>{EMAIL_TO_ADDRESS};

        Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
        binaryAttachment.Filename = EMAIL_ATTACHMENT;
        String strBody = '';
        strBody = strBody + 'f4c964de-f964-41ae-8543-25e1f42763cb,2222222222222,ICEKA1,2020,2020,File,docx,FALSE,TRUE,2,www.ICEKA1.com,SAP,Commercial,176589c8-c229-45a7-b2ba-44e5930407c4,0858c564-9000-7194-081a-b87b10570588,Knowledge Management\n';
        strBody = strBody + '64ce217c-1fcd-48f7-b36c-c4e,55555555555555,ICEKA2,2020,2020,File,docx,FALSE,TRUE,2,www.ICEKA2.com,SAP,Commercial,176589c8-c229-45a7-b2ba-44e5930407c4,0858c564-9000-7194-081a-b87b10570588,Knowledge Manage';    
        binaryAttachment.body = blob.valueOf(strBody);
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { binaryattachment };
        objKAICEHandler.handleInboundEmail(email, envelope);

        Test.stopTest();
        List<Knowledge__kav>  lstKA = [Select id,RecordType.DeveloperName,PublishStatus from Knowledge__kav where External_Content_ID__c = '64ce217c-1fcd-48f7-b36c-c4e'];
        System.assert(lstKA.isEmpty(), 'Knowledge Article not actiontaken');
    }
}
