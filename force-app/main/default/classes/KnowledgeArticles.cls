/********************************************************************************************************************************************************************************
* NAME         : Knowledge
* DESCRIPTION  : Domain class for Knowledge
*                    
* @AUTHOR : Nitin
* @DATE   : 11-Oct-2019    
* Test class coverage for 75%: TestAddArticletoCaseController, TestBatchDCPKnowledgeArticlesUpdate, TestBatchKnowledgeArticleICESync, TestBatchUpdateKnowledgeArticles,TestCaseENBAListViewController
                                TestEnableKnowledgeArticleForCPLwc, TestFeedItem, TestFeedbacks, TestKAFeedbackController, TestKnowledgeArticleDataRemediate, TestKnowledgeArticles
                                TestKnowledgeAssociationController, TestKnowledgeCreationMasterController, TestScheduledBatchKnowledgeArchiveRecord, TestSubmitKAApprovalController
* Test class coverage for 90%: TestAddArticletoCaseController, TestBatchDCPKnowledgeArticlesUpdate, TestBatchKnowledgeArticleICESync, TestBatchUpdateKnowledgeArticles,TestCaseENBAListViewController
                                TestEnableKnowledgeArticleForCPLwc, TestFeedItem, TestFeedbacks, TestKAFeedbackController, TestKnowledgeArticleDataRemediate, TestKnowledgeArticles
                                TestKnowledgeAssociationController, TestKnowledgeCreationMasterController, TestScheduledBatchKnowledgeArchiveRecord, TestSubmitKAApprovalController
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Nitin                 11-Oct-2019           Initial Version.
* Adyasha               24-Nov-2020           DCP-43596, Removed code to assign default record type as draft and prevent setting of record type to Publish after review completion.
* Monika                01-Dec-2020           DCP-43373, Updated Before Update and After update method
* Gladis                16-Sept-2021          CMCP-98,  Grant Access of KA to CP Users.  
* Nitin Reddy           09-Sept-2022          CMSI-220, Instrumentation 
* Vineeta Verma         12-Jul-2024           TASK1037157-Remove creation and deletion of dummy contact and query it 
**********************************************************************************************************************************************************************************/ 

global with sharing class KnowledgeArticles extends ilib_SObjectDomain {
    
    private static final String LOG_TITLE = 'KnowledgeArticles';//CMCP-98
	public static final String VALIDATION_STATUS = 'Not Submitted For Review';
    public static final String VALIDATIONSTATUS_APPROVED = 'Approved';//33494
    public static final String VALIDATIONSTATUS_PENDINGREVIEW = 'Pending Review';
    public static final String REVIEWSTATUS_REVIEWCOMPLETED = 'Review Completed';
    public static final String REVIEWSTATUS_PENDINGREVIEW = 'Pending Review - Review Not Started';
    public static final String OTHER_CATEGORY = 'Other';
    public static final String KNOWLEDGE_REMINDER_EMAIL_TEMPLATE = 'Knowledge_Send_Reminder_to_Approvers';		
    public static final String DATA_CATEGORIES = 'Service_and_Support';
    public static final String STRING_CP_ARTICLE_APPROVAL_STATUS_PENDING_APPROVAL='Pending Approval';//CMCP-98
    public static final String STRING_APPROVED_PUBLISH_STATUS = 'Online';
    public static final String NULLSTR = 'Null';
    public static final String KNOWLEDGE_SOURCE_DCP = 'DCP';
    //Dummy contact name-TASK1037157
    private static final String CONTACT_NAME = 'Master Data Request Dummy Contact';
	
		/*
         * Constructor
         */    
    public KnowledgeArticles(List<Knowledge__kav> sObjectList)
    {
        super(sObjectList);
    }
    
    /*
* Boilerplate which is required for base class instantiation logic
*/
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
	    /*Param - sobjectList  */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new KnowledgeArticles(sObjectList);
        }
    }
    /**
*  @author Nitin Sood
*  @description - 
*                 To be executed, when the Knowledge Version is inserted.                
*  @PARAM :  
*  @RETURN:  void
*/   
    public override void onBeforeInsert()
    { 
        flipRecordTypeOnInsertion((List<Knowledge__kav>)records);
    }
    
    /**
    *  @author Vignesh
    *  @description - Method to be called after Insert.                 
    *  @PARAM :  
    *  @RETURN:  void
    */   
    public override void onAfterInsert(){
        insertDataCategories((List<Knowledge__kav>)records);
    }

    /**
    *  @author Nitin Sood
    *  @description - 
    *                 To be executed, when the Knowledge Version is inserted.                
    *  @PARAM :  
    *  @RETURN:  void
    */ 
    public override void onBeforeUpdate(Map<Id, SObject> oldRecords)
    { 
        List<Knowledge__kav> lstknowledgesReviewSubmitted = new List<Knowledge__kav>();
        for(Knowledge__kav objKnowledge : (List<Knowledge__kav>)records){
            Knowledge__kav oldObjKnowledge = (Knowledge__kav)oldRecords.get(objKnowledge.Id);
            
            if(objKnowledge.ValidationStatus != oldObjKnowledge.ValidationStatus && objKnowledge.ValidationStatus == VALIDATIONSTATUS_PENDINGREVIEW){
                lstknowledgesReviewSubmitted.add(objKnowledge);
            }


            if(objKnowledge.Publish_Article__c != oldObjKnowledge.Publish_Article__c && objKnowledge.Publish_Article__c == true){
                objKnowledge.Review_Status__c = REVIEWSTATUS_REVIEWCOMPLETED;
                objKnowledge.Date_of_Last_Annual_Review__c = system.today();
                ilib_LogEvent.message('objKnowledge.Review_Status__c : '+objKnowledge.Review_Status__c);
                ilib_LogEvent.message('objKnowledge.Date_of_Last_Annual_Review__c : '+objKnowledge.Date_of_Last_Annual_Review__c);
        	}
        }
		
		//Start Changes DCP 43373
        updateKAApprovers((List<Knowledge__kav>)records,oldRecords);
        //Stop Changes DCP 43373

		
        if(!lstknowledgesReviewSubmitted.isEmpty()){
        	populateDataCategories(lstknowledgesReviewSubmitted);
        }
    }
	
	/**
	*  @author Nitin Sood
	*  @description - 
	*                 To be executed, after the Knowledge Version is update.                
	*  @PARAM :  
	*  @RETURN:  void
	*/   
    public override void onAfterUpdate(Map<Id, SObject> mapOld)
    {
		Map<Id,string> mapWorkFlowValues = new Map<Id,string>();        
        for(Knowledge__kav objKnowledge : (List<Knowledge__kav>)records){
            Knowledge__kav oldObjKnowledge = (Knowledge__kav)mapOld.get(objKnowledge.Id);

            if(objKnowledge.Publish_Article__c != oldObjKnowledge.Publish_Article__c && objKnowledge.Publish_Article__c == true){
                KbManagement.PublishingService.publishArticle(objKnowledge.KnowledgeArticleId, false);
            }
            //Start Changes DCP-43373 sending for secondary approval
            if(objKnowledge.Review_Status__c != oldObjKnowledge.Review_Status__c && objKnowledge.Review_Status__c == System.Label.Pending_Review_Primary_Review_Complete){          
                mapWorkFlowValues.put(objKnowledge.Id, objKnowledge.Secondary_Workflow__c);
            }
        }
           
        if(!mapWorkFlowValues.isEmpty()){
            ilib_LogEvent.info('mapWorkFlowValues : '+mapWorkFlowValues); 
            submitKAForSecondaryApproval(mapWorkFlowValues);
        }
        //Stop Changes DCP-43373
		
	} 
    /**
	*  @author Nitin Sood
	*  @description - 
	*                 To be executed, when the Knowledge Version is inserted.                
	*  @PARAM :  
	*  @RETURN:  void
	*/ 

    Public static void flipRecordTypeOnInsertion(List<Knowledge__kav> lstNewRecords){
        ilib_LogEvent.push(LOG_TITLE + '.flipRecordTypeOnInsertion()');
        for(Knowledge__kav  objKNowledge: lstNewRecords){
            //INC0244207
            if(objKNowledge.Knowledge_Source__c == KNOWLEDGE_SOURCE_DCP){
                objKNowledge.ValidationStatus = VALIDATION_STATUS;
                ilib_LogEvent.message('objKNowledge.ValidationStatus : '+objKNowledge.ValidationStatus);
            }    
            //INC0281613
           	objKNowledge.Review_Status__c = null;
            objKnowledge.Primary_Approver__c = null;
            objKnowledge.Secondary_Approver__c = null;
            ilib_LogEvent.message('objKNowledge.Review_Status__c : '+objKNowledge.Review_Status__c);
            ilib_LogEvent.message('objKNowledge.Primary_Approver__c : '+objKNowledge.Primary_Approver__c);
            ilib_LogEvent.message('objKNowledge.Secondary_Approver__c : '+objKNowledge.Secondary_Approver__c);
        }   
        ilib_LogEvent.pop();
    }

     /**
	*  @author Vignesh
	*  @description - Method to insert data Categories                
	*  @PARAM :  
	*  @RETURN:  void
	*/ 

    Public static void insertDataCategories(List<Knowledge__kav> lstNewRecords){
        ilib_LogEvent.push(LOG_TITLE + '.insertDataCategories()');
        Map<Id,String> mapRecorTypeIdName = new Map<Id,String>();
        for(Schema.RecordTypeInfo objRecordType : Knowledge__kav.SObjectType.getDescribe().getRecordTypeInfos()){
            mapRecorTypeIdName.put(objRecordType.getRecordTypeId() , objRecordType.getDeveloperName() );
        }
        ilib_LogEvent.info('mapRecorTypeIdName : '+mapRecorTypeIdName);
        list<Knowledge__DataCategorySelection> lstDC = new list<Knowledge__DataCategorySelection>();
        for(Knowledge__kav  objKnowledge : lstNewRecords){
            if(objKnowledge.Knowledge_Source__c == System.Label.Knowledge_Source_DCP){
                Knowledge__DataCategorySelection objDC = new Knowledge__DataCategorySelection();
                objDC.DataCategoryGroupName = DATA_CATEGORIES;
                objDC.DataCategoryName = mapRecorTypeIdName.get(objKnowledge.RecordTypeId);
                objDC.ParentId = objKnowledge.id;
                lstDC.add(objDC);
            }
        }
          
        insert lstDC;
        ilib_LogEvent.info('lstDC : '+UtilsCollection.getSetOfIds(lstDC)); 
        ilib_LogEvent.pop();
    }

    /*
*  @AUTHOR:  Tapas C
*  @DESCRIPTION: This method is invoked by Process Builder "Knowledge : Send Approval Reminder" to send reminder email to knowledge approvers after 48hrs
				 of review submission
*  @PARAM :  List<Id> lstKnowledgeIds
*  @RETURN:  void
*/ 
    @InvocableMethod(label = 'Send Email To Knowledge Approvers') 
    global static void sendEmailToArticleApprovers(List<Id> lstKnowledgeIds){
        try{
            ilib_LogEvent.setTitle(LOG_TITLE,ilib_LogEvent.SERVICE);
            ilib_LogEvent.push(LOG_TITLE + '.sendEmailToArticleApprovers()');
            ilib_LogEvent.info('lstKnowledgeIds : '+lstKnowledgeIds);
            List<Messaging.SingleEmailMessage>  lstEmailNotifications = new List<Messaging.SingleEmailMessage>();
            //TASK1037157:query Contact- Dummy Contact
            Contact objDummyContact = null;
            try{
                objDummyContact = [select Id from Contact where Name = :CONTACT_NAME and Is_Active__c = true limit 1];
                ilib_LogEvent.info('objDummyContact found : '+objDummyContact);
            } 
            catch(QueryException queryException) {
                ilib_LogEvent.info('Dummy contact not found, using random contact instead');
                ApexExceptions.emit(LOG_TITLE, 'Dummy contact not found, using random contact instead',ilib_LogEvent.SERVICE);
                objDummyContact = [select Id from Contact where Is_Active__c = true limit 1];
            }
            EmailTemplate knowledgeReminderTemplate = [Select id from EmailTemplate where DeveloperName =: KNOWLEDGE_REMINDER_EMAIL_TEMPLATE];
            ilib_LogEvent.info('knowledgeReminderTemplate : '+knowledgeReminderTemplate);
            //fetch all Category-Email pairs from the custom metadata
            Map<String,Knowledge_Category_and_Reviewers__mdt> mapKnowledgeDetails = new Map<String,Knowledge_Category_and_Reviewers__mdt>();
            for(Knowledge_Category_and_Reviewers__mdt objKnowledgeDetails : [select DeveloperName, MasterLabel, Category_Reviewer_Emails__c from Knowledge_Category_and_Reviewers__mdt]){
                mapKnowledgeDetails.put(objKnowledgeDetails.MasterLabel, objKnowledgeDetails); 
            }
			ilib_LogEvent.info('mapKnowledgeDetails : ' +  (mapKnowledgeDetails != Null ? String.valueof(mapKnowledgeDetails.keySet()):NULLSTR));
			//Added as Part of INC0284516
            OrgWideEmailAddress[] owea = [select id from OrgWideEmailAddress where displayName = 'SystemNotification' ];
            
            for(Knowledge__Kav objKnowledge : new KnowledgeArticlesSelector().selectlKnowledgeRecordsByValidationAndReviewStatuses(lstKnowledgeIds,VALIDATIONSTATUS_PENDINGREVIEW,REVIEWSTATUS_PENDINGREVIEW)){
				Set<String> setToAddress = new Set<String>();
                List<String> lstToAddress = new List<String>();
				String categories = objKnowledge.Article_Categories__c;
                ilib_LogEvent.message('categories : '+categories);
				//match categories from knowledge record with the Category-Email pair Map and add those emails in to Address
				if(categories != null){                                 
					List<String> lstCategories = categories.split(', ');
								
					for(String category : lstCategories){
                            Knowledge_Category_and_Reviewers__mdt objKnowledgeDetailMdt = mapKnowledgeDetails.get(category);
                            if(objKnowledgeDetailMdt != null){
                                setToAddress.addAll((objKnowledgeDetailMdt.Category_Reviewer_Emails__c).split(','));
						}
					}
				}
                if(setToAddress.isEmpty())
                    setToAddress.addAll((mapKnowledgeDetails.get(OTHER_CATEGORY).Category_Reviewer_Emails__c).split(','));
				ilib_LogEvent.message('setToAddress : '+setToAddress);
                lstToAddress.addAll(setToAddress);
                Messaging.SingleEmailMessage objEmail = new Messaging.SingleEmailMessage();
                objEmail.setTemplateId(knowledgeReminderTemplate.Id);
                objEmail.setToAddresses(lstToAddress);
                objEmail.setTargetObjectId(objDummyContact.Id);
                objEmail.setTreatTargetObjectAsRecipient(false);
                objEmail.setSaveAsActivity(false);
				objEmail.setUseSignature(false);
                objEmail.setWhatId(objKnowledge.Id);
				
				  if ( owea.size() > 0 ) {
					objEmail.setOrgWideEmailAddressId(owea.get(0).Id);
				  }
				lstEmailNotifications.add(objEmail);
            }
            Messaging.SendEmailResult[] lstResults = Messaging.sendEmail(lstEmailNotifications,false); 
            
        }
        catch(Exception ee){
            ApexExceptions.emit('KnowledgeArticles', ee,ilib_LogEvent.SERVICE);
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
    
        /*
    *  @AUTHOR:  Tapas C
    *  @DESCRIPTION: This method is called in beforeupdate on review submission to populate all categories selected on an article to a text field as comma separated values
    *  @PARAM :  List<Knowledge__kav> lstKnowledgeArticles
    *  @RETURN:  void
    */        
    public static void populateDataCategories(List<Knowledge__kav> lstKnowledgeArticles){ 
        ilib_LogEvent.push(LOG_TITLE + '.populateDataCategories()');
        List<Knowledge__DataCategorySelection> lstDC = [SELECT ParentId, DataCategoryName   FROM Knowledge__DataCategorySelection
                                                        WHERE ParentId IN: lstKnowledgeArticles];
        
        Map<Id, String> datacategoryNameMap = new Map<Id, String>();
        
        for(Knowledge__DataCategorySelection dcObj:lstDC){  
            if(datacategoryNameMap.containsKey(dcObj.ParentId)){
                String str =  datacategoryNameMap.get(dcObj.ParentId);
                datacategoryNameMap.put(dcObj.ParentId, str + ', ' + dcObj.DataCategoryName);
            }
            else{
                datacategoryNameMap.put(dcObj.ParentId, dcObj.DataCategoryName);
            }
        }
        ilib_LogEvent.info('datacategoryNameMap : '+datacategoryNameMap);
        for(Knowledge__kav artObj:lstKnowledgeArticles)
        {
            if(datacategoryNameMap.containsKey(artObj.Id))
            {
                artObj.Article_Categories__c = (datacategoryNameMap.get(artObj.Id)).replace('_',' ');
                ilib_LogEvent.message('artObj.Article_Categories__c : '+artObj.Article_Categories__c);
            }
        }
        ilib_LogEvent.pop();
    }
	  /*
    *  @AUTHOR:  Monika
    *  @DESCRIPTION: This method is called in beforeupdate update the primary and secondary approver and related validations DCP-43373 
    *  @PARAM :  List<Knowledge__kav> lstNewRecords and Map<Id, SObject> oldRecords
    *  @RETURN:  void
    */        
    public static void updateKAApprovers(List<Knowledge__kav> lstNewRecords,Map<Id, SObject> oldRecords){
        ilib_LogEvent.push(LOG_TITLE + '.updateKAApprovers()');
        Id userId= UserInfo.getUserId(); // currentuserId
        ilib_LogEvent.info('userId : '+userId);
        for(Knowledge__kav objKnowledge : lstNewRecords){
            Knowledge__kav oldObjKnowledge = (Knowledge__kav)oldRecords.get(objKnowledge.Id);
            //update primary and secondary approver
            if(objKnowledge.Review_Status__c != oldObjKnowledge.Review_Status__c && objKnowledge.Review_Status__c == System.Label.Pending_Review_Primary_Review_Complete){
                objKnowledge.Primary_Approver__c = userinfo.getuserid();
                ilib_LogEvent.message('objKnowledge.Primary_Approver__c : '+objKnowledge.Primary_Approver__c);
            }
            if(objKnowledge.Review_Status__c != oldObjKnowledge.Review_Status__c && objKnowledge.Review_Status__c == System.Label.Pending_Review_Secondary_Review_Complete){
                objKnowledge.Secondary_Approver__c = userinfo.getuserid();
                ilib_LogEvent.message('objKnowledge.Secondary_Approver__c : '+objKnowledge.Secondary_Approver__c);
            }
            //Primary and Secondary Reviewer cannot be same
            if(objKnowledge.Review_Status__c != oldObjKnowledge.Review_Status__c && objKnowledge.Review_Status__c == System.Label.Pending_Review_Secondary_Review_Complete && objKnowledge.Primary_Approver__c== userId){
                objKnowledge.adderror(System.Label.Primary_Approver_cannot_be_Secondary_Approver);
            }
            //Primary Approver cannot reject the record awaiting for Secondary Approval
            if(objKnowledge.Review_Status__c != oldObjKnowledge.Review_Status__c && objKnowledge.Review_Status__c == System.Label.Pending_Review_Rejected && objKnowledge.Primary_Approver__c== userId){
                objKnowledge.adderror(System.Label.Primary_Approver_Reject_Sec_Approval);
            }
        }
        ilib_LogEvent.pop();
    }
    /*
    *  @AUTHOR:  Monika 
    *  @DESCRIPTION: This method is called in afterUpdate ,submitting knowledge record for secondary approval.
    *  @PARAM :  Map<Id,string> mapKnowledgeArticle
    *  @RETURN:  void
    */        
    public static void submitKAForSecondaryApproval(Map<Id,string> mapKnowledgeArticle){ 
        ilib_LogEvent.push(LOG_TITLE + '.submitKAForSecondaryApproval()');
        Map<String,String> mapWorkFlowQueueId = new Map<String,String>();
        Map<String,String> mapGroupNameId = new Map<String,String>();
        string initialApprovalComments = NULL;

        // get initial submission approval comments 
        List<Knowledge__kav> knowledgeArticleLst =  [Select id,(Select Id,StepStatus,Comments FROM ProcessSteps ORDER BY CreatedDate ASC) From Knowledge__kav WHERE Id IN : mapKnowledgeArticle.keyset()];
        for(Knowledge__kav kav : knowledgeArticleLst) {
            if (!kav.ProcessSteps.isEmpty()) {
                initialApprovalComments = kav.ProcessSteps[0].Comments;  
            }
        }
        ilib_LogEvent.info('initialApprovalComments : '+initialApprovalComments);
        // get custom approval matrix record
            
        Id idKnowledgeMatrixApproval =  Schema.SObjectType.Custom_Approval_Matrix__c.getRecordTypeInfosByDeveloperName().get(label.Knowledge_Approval_Matrix_Recordtype).getRecordTypeId();
        ilib_LogEvent.info('idKnowledgeMatrixApproval : '+idKnowledgeMatrixApproval);
        List <Custom_Approval_Matrix__c> lstCustomAppMatrix = new CustomApprovalMatrixSelector().returnCustomApprovalMatrixObj(mapKnowledgeArticle.Values() , idKnowledgeMatrixApproval );
        if(lstCustomAppMatrix.size()>0){
            for(Custom_Approval_Matrix__c approvalMatrix : lstCustomAppMatrix){
                mapWorkFlowQueueId.put(approvalMatrix.Name,approvalMatrix.Email_Queue__c);
            }
        }
        ilib_LogEvent.info('mapWorkFlowQueueId : '+mapWorkFlowQueueId);
        // get queue record
        for(Group objGroup : new GroupsSelector().getQueueIdbyDeveloperName(mapWorkFlowQueueId.values(),Label.Queue)){
            mapGroupNameId.put(objGroup.DeveloperName,objGroup.Id);
        }
        ilib_LogEvent.info('mapGroupNameId : '+mapGroupNameId);
        for(Id objKnowledgeId : mapKnowledgeArticle.keyset()){
            String strWorkFlowVal = mapKnowledgeArticle.get(objKnowledgeId);
            ilib_LogEvent.message('strWorkFlowVal : '+strWorkFlowVal);
            // submit for Approval  
            SubmitKAApprovalController.submitApprovalProcess(objKnowledgeId, mapGroupNameId.get(mapWorkFlowQueueId.get(strWorkFlowVal)) ,initialApprovalComments);        
        }   
        ilib_LogEvent.pop(); 
    }
    
    /**
    *  @author Nitin Reddy Vatti
    *  @description  CMSI-220,method will return the workstream
    *  @return string
    **/
    public override string getWorkstream(){
        return ilib_LogEvent.SERVICE;
    }


}