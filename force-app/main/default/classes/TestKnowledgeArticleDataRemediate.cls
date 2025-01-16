/* 
* @ author      : Vignesh Sethuramalingam   
* @ date         : 15-01-2021
* @ Description  : TestKnowledgeArticleDataRemediate is the test class for the KnowledgeArticleDataRemediate
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                   Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Vignesh Sethuramalingam  15-01-2021                 DCP-44322         Initial version.
*/
@isTest
public with sharing class TestKnowledgeArticleDataRemediate {
    
    /**
    *  @author      : Vignesh Sethuramalingam
    *  @description : Setup method for KA creation
    **/
    @TestSetup
    static void setupData(){
        
        Id draftRecordTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByName().get('Evaluation Aid').getRecordTypeId();
     
        knowledge__kav newArticle1 = new knowledge__kav(Title='test',Recordtypeid = draftRecordTypeId, summary='xyz',urlname=String.valueof(System.now()).replaceAll('[^a-zA-Z0-9\\-s+]', '-')+'Z1',Article_Body__c='test', Article_Version_Author__c = userinfo.getuserid(),Primary_Workflow__c='Software',Secondary_Workflow__c='Software');
        knowledge__kav newArticle2 = new knowledge__kav(Title='Draft',Recordtypeid = draftRecordTypeId, summary='xyz',urlname='Demo',Article_Body__c='test', Article_Version_Author__c = userinfo.getuserid(),Primary_Workflow__c='Software',Secondary_Workflow__c='Software');
		knowledge__kav newArticle3 = new knowledge__kav(Title='Archived',Recordtypeid = draftRecordTypeId, summary='xyz',urlname='Archived',Article_Body__c='test', Article_Version_Author__c = userinfo.getuserid(),Primary_Workflow__c='Software',Secondary_Workflow__c='Software');
		
		insert new List<Knowledge__kav>{newArticle1, newArticle2,newArticle3};
        
        Set<Id> setKAIds = new Set<Id>{newArticle1.Id};

        List<Knowledge__kav> lstKnowledge = [Select Id,KnowledgeArticleId from Knowledge__kav where Id IN :setKAIds];
        for(Knowledge__kav objKA : lstKnowledge)
        {
            KbManagement.PublishingService.publishArticle(objKA.KnowledgeArticleId, true);
        }
		
		
    }
    
    
    /**
    *  @author      :Vignesh Sethuramalingam
    *  @description :test method to Data remediate knowledge Articles.
    **/
    @isTest
    public static void testKnowledgeEmailHandlerCreation(){

        Test.starttest();
        
        Knowledge__kav objKnowledge = [Select Id,KnowledgeArticleId from Knowledge__kav where title = 'test' LIMIT 1];
        
        KnowledgeArticleDataRemediate  objKAICEHandler = new KnowledgeArticleDataRemediate();

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        email.subject = 'Knowledge Data Remediate  -subject';
        email.plainTextBody = 'Knowledge Data Remediate - Body';
        email.fromAddress = 'test@illumina.com';
        email.toAddresses = new list<String>{'sfdc@illumina.com'};

        Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
        binaryAttachment.Filename = 'newfile.csv';
        String strBody = '';
        strBody = strBody + 'KnowledgeArticleID,knowledgeArticleVersionID,PublishStatus,ApplicableRegion\n';
		strBody = strBody + objKnowledge.KnowledgeArticleId+','+objKnowledge.Id +',Online,Europe\n';
        binaryAttachment.body = blob.valueOf(strBody);
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { binaryattachment };
        objKAICEHandler.handleInboundEmail(email, envelope);

        Test.stopTest();
        
        Knowledge__kav objKnowledge1 = [SELECT Id, KnowledgeArticleId, Document_Number__c,Applicable_Region__c FROM Knowledge__kav WHERE title = 'test' LIMIT 1];
        system.assertEquals( 'Europe' , objKnowledge1.Applicable_Region__c , 'Region Update failed' );
    }
    
    /**
    *  @author      :Vignesh Sethuramalingam
    *  @description :test method to Data remediate knowledge Articles.
    **/
    @isTest
    public static void testKnowledgeDataRemediation(){

        Test.starttest();
        
        Knowledge__kav objKnowledge = [Select Id,KnowledgeArticleId from Knowledge__kav where title = 'Draft' LIMIT 1];
        
        KnowledgeArticleDataRemediate  objKAICEHandler = new KnowledgeArticleDataRemediate();

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        email.subject = 'Knowledge Data Remediate - sub';
        email.plainTextBody = 'Knowledge Data Remediate - TextBody';
        email.fromAddress = 'test@illumina.com';
        email.toAddresses = new list<String>{'sfdc@illumina.com'};

        Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
        binaryAttachment.Filename = 'newfile.csv';
        String strBody = '';
        strBody = strBody + 'KnowledgeArticleID,knowledgeArticleVersionID,PublishStatus,ApplicableRegion\n';
        strBody = strBody + objKnowledge.KnowledgeArticleId+','+objKnowledge.Id +',Draft,Europe\n';
        binaryAttachment.body = blob.valueOf(strBody);
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { binaryattachment };
        objKAICEHandler.handleInboundEmail(email, envelope);

        Test.stopTest();
        
        Knowledge__kav objKnowledge1 = [SELECT Id,KnowledgeArticleId, Document_Number__c, Applicable_Region__c FROM Knowledge__kav WHERE title = 'Draft' LIMIT 1];
        system.assertEquals( 'Europe' , objKnowledge1.Applicable_Region__c , 'Region Update failed' );
    }
	
	/**
    *  @author      :Vignesh Sethuramalingam
    *  @description :test method to Data remediate knowledge Articles.
    **/
    @isTest
    public static void testKnowledgeDataRemediationForArchived(){

        Test.starttest();
        
        Knowledge__kav objKnowledge = [Select Id,KnowledgeArticleId from Knowledge__kav where title = 'Archived' LIMIT 1];
        
		KbManagement.PublishingService.publishArticle( objKnowledge.KnowledgeArticleId , false);
		KbManagement.PublishingService.archiveOnlineArticle( objKnowledge.KnowledgeArticleId , null);
		
        KnowledgeArticleDataRemediate  objKAICEHandler = new KnowledgeArticleDataRemediate();
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        email.subject = 'Knowledge Data Remediate - sub';
        email.plainTextBody = 'Knowledge Data Remediate - TextBody';
        email.fromAddress = 'test@illumina.com';
        email.toAddresses = new list<String>{'sfdc@illumina.com'};

        Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
        binaryAttachment.Filename = 'newfile.csv';
        String strBody = '';
        strBody = strBody + 'KnowledgeArticleID,knowledgeArticleVersionID,PublishStatus,ApplicableRegion\n';
        strBody = strBody + objKnowledge.KnowledgeArticleId+','+objKnowledge.Id +',Archived,Europe\n';
        binaryAttachment.body = blob.valueOf(strBody);
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { binaryattachment };
        objKAICEHandler.handleInboundEmail(email, envelope);

        Test.stopTest();
        
        Knowledge__kav objKnowledge1 = [SELECT Id,KnowledgeArticleId, Document_Number__c, Applicable_Region__c FROM Knowledge__kav WHERE title = 'Archived' LIMIT 1];
        system.assertEquals( 'Europe' , objKnowledge1.Applicable_Region__c , 'Region Update failed' );
    }
}