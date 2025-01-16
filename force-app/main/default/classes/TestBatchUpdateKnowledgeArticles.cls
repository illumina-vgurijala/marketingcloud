/******************************************************************************************************************************
* NAME         : TestBatchUpdateKnowledgeArticles
* DESCRIPTION  : Test class for BatchUpdateKnowledgeArticles         
* @AUTHOR      : Vignesh
* @DATE        : 21-Dec-2020    
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Vignesh                21-Dec-2020          Initial Version.  
* Shivani                28-Sep-2022          Chnages to increase coverage
****************************************************************************************************************************************/ 

@isTest(SeeAllData = false)  
public class TestBatchUpdateKnowledgeArticles {
    
   /**
    *  @author      : Vignesh Sethuramalingam
    *  @description : Setup method for KA creation
    **/
    @TestSetup
    static void setupData(){
        
        Id draftRecordTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByName().get('Evaluation Aid').getRecordTypeId();
     
        knowledge__kav newArticle1 = new knowledge__kav(Title='test',Recordtypeid = draftRecordTypeId, summary='xyz',urlname=String.valueof(System.now()).replaceAll('[^a-zA-Z0-9\\-s+]', '-')+'Z1',Article_Body__c='test', Article_Version_Author__c = userinfo.getuserid(),Primary_Workflow__c='Software',Secondary_Workflow__c='Software');
        insert new List<Knowledge__kav>{newArticle1};
        
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
        email.subject = 'Knowledge Data Remediate - subject';
        email.plainTextBody = 'Knowledge Data Remediate - Body';
        email.fromAddress = 'test@illumina.com';
        email.toAddresses = new list<String>{'sfdc@illumina.com'};

        Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
        binaryAttachment.Filename = 'newfile.csv';
        String strBody = '';
        strBody = strBody + 'KnowledgeArticleID,documentNumber,RecordTypeName,Primary_Workflow__c,Secondary_Workflow__c,Instrument__c,Software_Category_c,Library_Prep_Category__c,IVDDx_Article__c,Review_Status__c\n';
        strBody = strBody + objKnowledge.KnowledgeArticleId+',123457,Evaluation Aid,Mega Guide,Mega Guide,MiSeq RUO, , ,false,Review Completed\n';
        binaryAttachment.body = blob.valueOf(strBody);
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { binaryattachment };
        objKAICEHandler.handleInboundEmail(email, envelope);

        Test.stopTest();
        
        Knowledge__kav objKnowledge1 = [Select Id,KnowledgeArticleId,Recordtype.Name from Knowledge__kav where title = 'test' LIMIT 1];
        system.assertEquals('Evaluation Aid' , objKnowledge1.Recordtype.Name, 'Record Type not updated');
    }
    
    /**
    *  @author      :Vignesh Sethuramalingam
    *  @description :test method to Data remediate knowledge Articles.
    **/
    @isTest
    public static void testKnowledgeDataRemediation(){

        Test.starttest();
        BatchUpdateKnowledgeArticles.testClassCoverage = true;
        
        Knowledge__kav objKnowledge = [Select Id,KnowledgeArticleId from Knowledge__kav where title = 'test' LIMIT 1];
        
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
        strBody = strBody + 'KnowledgeArticleID,RecordTypeName,documentNumber,Primary_Workflow__c,Secondary_Workflow__c,Instrument__c,Software_Category_c,Library_Prep_Category__c,IVDDx_Article__c,Review_Status__c\n';
        strBody = strBody + objKnowledge.KnowledgeArticleId+',123457,Evaluation Aid,,Mega Guide,MiSeq RUO, , ,false,Review Completed\n';
        binaryAttachment.body = blob.valueOf(strBody);
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { binaryattachment };
        objKAICEHandler.handleInboundEmail(email, envelope);

        Test.stopTest();
        
        Knowledge__kav objKnowledge1 = [Select Id,KnowledgeArticleId,Recordtype.Name from Knowledge__kav where title = 'test' LIMIT 1];
        system.assertEquals('Evaluation Aid' , objKnowledge1.Recordtype.Name, 'Record Type not updated');
    }
}