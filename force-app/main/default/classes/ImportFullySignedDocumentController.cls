/*
* @author :
* @description : 	This Apex controller class is developed to be used with 'ImportFullySignedDocCmp' Lightning Component.
* Test Class:		ImportFullySignedDocumentController
*
* Modification Log:
*       ------------------------------------------------------------------------------------
*        Developer             Date                 Description
*       Aman Tyagi           31/03/2022            CodeScan Fixes
*       ------------------------------------------------------------------------------------
*/
public with sharing class ImportFullySignedDocumentController {

    /*
    * @Description :constructor of class ImportFullySignedDocumentController
    * @param: null
    */
    public ImportFullySignedDocumentController(){
        
    } 
    
	@Auraenabled
    /*
    * @Description : static method having logic of server response message
    * @param: Id agreementId, Id documentId, String fileName
    * @return: ServerResponseMessage
    */
	public static ServerResponseMessage processDocument(Id agreementId, Id documentId, String fileName) {
		
        Savepoint sp;
        
        //Initializing the wrapper message 
        ServerResponseMessage returnMessage = new ServerResponseMessage();
        
        try{
            // get User's Session Id by readin VF Page as sessionid is not available through Userinfo.getSessionId() method
            
            PageReference ref = Page.SessionId;
            String content;
			
            if(!Test.isRunningTest()){
            	content = ref.getContent().toString();
            }else{
                content = 'Start_Of_Session_Id' + Userinfo.getSessionId() + 'End_Of_Session_Id';
            }
            Integer s = content.indexOf('Start_Of_Session_Id') + 'Start_Of_Session_Id'.length(),
                    e = content.indexOf('End_Of_Session_Id');
            String sessionId = content.substring(s, e);
            
            // prepare necessary parameter values and call authoring API
            List<Id> docIds = new List<Id>{documentId};
                
            
            
            String pLevel = 'Insert comments and tracked changes only';
            String apiServerURL = System.Url.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/44.0/' + UserInfo.getOrganizationId(); 
            boolean isSuccess;
            if(!Test.isRunningTest()){
            	isSuccess = Apttus.MergeWebService.enableAuthoring(agreementId, pLevel, docIds, sessionId, apiServerURL); 
            	
                ContentDocument c = new ContentDocumentSelector().selectById(documentId)[0];
                c.Title = c.Title+' '+Label.Attachment_Prefix_Signed;
                fileName = c.Title;
                update c;
                
            }else{
                isSuccess = true;
            }
            System.debug(LoggingLevel.FINER, '--->>'+ isSuccess);
            
            sp = Database.setSavepoint();
            
            if(isSuccess){
                // Update Agreement Status Category and Status
                Apttus__APTS_Agreement__c agreementObj = new Apttus__APTS_Agreement__c(Id = agreementId);
                agreementObj.Apttus__Status_Category__c = Label.InSignatures ;
    			agreementObj.Apttus__Status__c = Label.AgreementStatusFullySigned;
                update agreementObj;
            	
                // Create Activity History
                Task t = new Task();
                t.Subject = 'Imported Offline Document';
                t.Status = 'Completed';
                t.ActivityDate = System.today();
                t.Description = 'Document(s) imported: \n ------------------------------ \n'+fileName;
            	t.WhatId = agreementId;
                insert t;
                
                returnMessage.isSuccess = true;                    
            }else{
                returnMessage.isSuccess = false;                        
                returnMessage.errorMsg = 'Document couldn\'t be authored successfully!';        
                Database.rollback(sp);
            }           
        	
        }Catch(Exception ex){

			System.debug(LoggingLevel.FINER, '--->>'+ ex.getMessage());
            
            returnMessage.isSuccess = false;            
            //Adding the error message if an exception is occured
            returnMessage.errorMsg = ex.getMessage();
            
            //Rollback the transaction if an exception is occured
            Database.rollback(sp);
        }
        return returnMessage;
    }

    /*
    * @Author: 
    * @Description : class for Server Response message
    */   
    public class ServerResponseMessage { 
        
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String errorMsg; //error msg
        @AuraEnabled public String successMsg; //success msg

        /*
        * @Description :constructor of the class ServerResponseMessage
        * @param: null
        */
        public ServerResponseMessage(){
            isSuccess = true;
            errorMsg = '';
            successMsg = '';
        }
    }
}