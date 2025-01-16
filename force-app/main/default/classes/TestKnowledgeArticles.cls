/******************************************************************************************************************************
* NAME         : TestKnowledgeArticles
* DESCRIPTION  : Test class for KnowledgeArticles
*                    
* @AUTHOR : Nitin
* @DATE   : 11-Oct-2019    
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Nitin                    11-Oct-2019          Initial Version.    
* Adyasha                  26-11-2020          Added method for random string generation to be used as urlname.        
****************************************************************************************************************************************/ 

@isTest(SeeAllData = false)  
public with sharing class TestKnowledgeArticles  {
    public static final String VALIDATIONSTATUS_PENDINGREVIEW = 'Pending Review';
    public static final String REVIEWSTATUS_PENDINGREVIEW = 'Pending Review - Review Not Started';
    public static final Id FAQ_RECORD_TYPE_ID = Schema.SObjectType.Knowledge__Kav.getRecordTypeInfosByName().get('FAQ').getRecordTypeId();
    public static final String REVIEWSTATUS_REVIEWCOMPLETE = 'Review Completed';
    public static final String RANDOMTEXT = 'Test';
    public static final String KATITLE = 'Test';
    public static final String CUSTOMMATRIX_INSTRUMENTATION  = 'Instrumentation';
    public static final String CUSTOMMATRIX_SOFTWARE  = 'Software';
    
	static testmethod void testInsertNewArticle() {
		 User serviceEngineer = [select id from user where Profile.Name =: System.Label.ProfileName_CustomerService and UserPermissionsKnowledgeUser = true and isactive = true limit 1];
		 System.runAs(serviceEngineer){
			Test.StartTest();
			knowledge__kav newArticle =TestDataKnowledgeArticle.getKnowledgeArticle(TestBatchKnowledgeArticleICESync.KA_TITLE,CUSTOMMATRIX_INSTRUMENTATION,CUSTOMMATRIX_SOFTWARE);
            insert newArticle;
			System.assert(newArticle.Id != null);
			Test.StopTest();
		}
	}

    static testmethod void testUpdateNewArticle() {
	//initializeData();
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
         acc.Account_Group__c='Distributor';
        insert acc;
        //Create dummy Contact to be used as target on Email Template
        TestDataContact.getNewContact(acc);
        User serviceEngineer = [select id from user where Profile.Name =: System.Label.ProfileName_CustomerService and UserPermissionsKnowledgeUser = true and isactive = true limit 1];
        System.runAs(serviceEngineer ){
            Test.StartTest();
            knowledge__kav newArticle = TestDataKnowledgeArticle.getKnowledgeArticle(TestBatchKnowledgeArticleICESync.KA_TITLE,CUSTOMMATRIX_INSTRUMENTATION,CUSTOMMATRIX_SOFTWARE);
            newArticle.RecordTypeId = FAQ_RECORD_TYPE_ID;
            insert newArticle;
            System.assert(newArticle.Id != null);
            
            /*knowledge__DataCategorySelection dataCategory = new knowledge__DataCategorySelection();
            dataCategory.ParentId = newArticle.ID;
            dataCategory.DataCategoryGroupName = 'Workflow';
            dataCategory.DataCategoryName = 'Instrumentation';
            insert dataCategory;*/
            
            newArticle.ValidationStatus = VALIDATIONSTATUS_PENDINGREVIEW;
            newArticle.Review_Status__c = REVIEWSTATUS_PENDINGREVIEW;
            update newArticle;
            
            KnowledgeReminderEmailController newClassVar = new KnowledgeReminderEmailController();
            newClassVar.knowledgeId = newArticle.Id;
            newClassVar.knowledgeTitle = newArticle.Title;
            newClassVar.versionNumber = newArticle.VersionNumber;
            newClassVar.knowledgeCategories = newArticle.Article_Categories__c;
            String sfdcURL = newClassVar.sfdcURL;
            String submitter = newClassVar.Submitter;
            
            KnowledgeArticles.sendEmailToArticleApprovers(new List<Id> {newArticle.Id});
            System.assert(Limits.getEmailInvocations() > 0);
            System.assertEquals('FAQ', [select id, Article_Categories__c from knowledge__kav where id =: newArticle.Id][0].Article_Categories__c);
            Test.StopTest();
        }
    }
    static testmethod void testPublishNewArticle(){
        User serviceEngineer = [select id from user where Profile.Name =: System.Label.ProfileName_CustomerService and UserPermissionsKnowledgeUser = true and isactive = true limit 1];
        
        PermissionSet objPermissionSet = new PermissionSet();
        objPermissionSet.Name = 'Test_Permission_Set';
        objPermissionSet.Label = 'Test_Permission_Set';
        insert objPermissionSet;
        
        SetupEntityAccess sea = new SetupEntityAccess();
        sea.ParentId = objPermissionSet.Id;
        sea.SetupEntityId = [select Id from CustomPermission where DeveloperName = 'SS_Manage_Knowledge'][0].Id;
        insert sea;
        
        PermissionSetAssignment objPSA = new PermissionSetAssignment();
        objPSA.AssigneeId = serviceEngineer.Id;
        objPSA.PermissionSetId = objPermissionSet.Id;
        insert objPSA;

        System.runAs(serviceEngineer){
            Test.StartTest();
            Knowledge__kav newArticle = TestDataKnowledgeArticle.getKnowledgeArticle(TestBatchKnowledgeArticleICESync.KA_TITLE,CUSTOMMATRIX_INSTRUMENTATION,CUSTOMMATRIX_SOFTWARE);
            insert newArticle;
            try{
                Knowledge__kav objInsertedArticle = [Select Id, ValidationStatus,Review_Status__c,Publish_Article__c from Knowledge__kav LIMIT 1];
                objInsertedArticle.ValidationStatus = KnowledgeArticles.VALIDATIONSTATUS_APPROVED;
                objInsertedArticle.Review_Status__c = REVIEWSTATUS_REVIEWCOMPLETE;
                objInsertedArticle.Publish_Article__c = true;
                update objInsertedArticle;

                Knowledge__kav objArticle = [Select Id, Date_of_Last_Annual_Review__c  from Knowledge__kav LIMIT 1];
                System.debug('objArticle: '+objArticle);
                system.assertEquals(System.today(), objArticle.Date_of_Last_Annual_Review__c);
            }catch(Exception e){
                System.debug('@@@ Exception details: '+e);
            }
            Test.stopTest();
        }
    }
    
    static testmethod void onAfterUpdate(){
	    User serviceEngineer = [select id from user where Profile.Name =: System.Label.ProfileName_CustomerService and UserPermissionsKnowledgeUser = true and isactive = true limit 1];
            System.runAs(serviceEngineer ){
            Knowledge__kav newArticle = TestDataKnowledgeArticle.getKnowledgeArticle(KATITLE,CUSTOMMATRIX_INSTRUMENTATION,CUSTOMMATRIX_SOFTWARE);
            insert newArticle;
            Custom_Approval_Matrix__c approvalmatrix = new Custom_Approval_Matrix__c(Name= CUSTOMMATRIX_INSTRUMENTATION, Email_Queue__c= 'KB_Instrumentation' , RecordtypeId = Schema.SObjectType.Custom_Approval_Matrix__c.getRecordTypeInfosByDeveloperName().get(label.Knowledge_Approval_Matrix_Recordtype).getRecordTypeId() );
            insert approvalmatrix;
            Custom_Approval_Matrix__c approvalmatrix1 = new Custom_Approval_Matrix__c(Name= CUSTOMMATRIX_SOFTWARE, Email_Queue__c= 'KB_Software' , RecordtypeId = Schema.SObjectType.Custom_Approval_Matrix__c.getRecordTypeInfosByDeveloperName().get(label.Knowledge_Approval_Matrix_Recordtype).getRecordTypeId() );
            insert approvalmatrix1;
			Test.StartTest();
            try{
                Knowledge__kav objInsertedArticle = [Select Id, ValidationStatus,Review_Status__c,Publish_Article__c,Primary_Workflow__c,Secondary_Workflow__c from Knowledge__kav LIMIT 1];
                objInsertedArticle.Review_Status__c = System.Label.Pending_Review_Primary_Review_Complete;
                update objInsertedArticle;
                
                objInsertedArticle.Review_Status__c = System.Label.Pending_Review_Secondary_Review_Complete;
                update objInsertedArticle;

                Knowledge__kav objArticle = [Select Id, Date_of_Last_Annual_Review__c  from Knowledge__kav LIMIT 1];
                System.debug('objArticle: '+objArticle);
                system.assertEquals(System.today(), objArticle.Date_of_Last_Annual_Review__c);
            }catch(Exception e){
                System.debug('@@@ Exception details: '+e);
            }
            Test.stopTest();
	}
    }
}
