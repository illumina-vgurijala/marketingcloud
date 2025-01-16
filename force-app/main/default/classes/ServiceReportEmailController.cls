/**
 *    @author Soumya Ranjan Sahu
 *    @date   10-03-2020
 *    @description    Controller for "ServiceReportEmail" Lightning Web Component
 *    90% Code Coverage: TestServiceReportEmailController
 *    75% Code Coverage: TestServiceReportEmailController
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Soumya Ranjan Sahu           10-03-2020           Initial Version
 *    Sibin P Kuriakose            25-08-2022           [CMSI-218]: Instrumentation of the Class.
 *    ------------------------------------------------------------------------------------                   
 */
public with sharing class ServiceReportEmailController {

    public static final String STRING_EMAIL_TEMPLATE_NAME = 'Send_Service_Report_Email';

    //Store initials of Service Report Output File
    public static final String STRING_ATTACHMENT_NAME = 'Service_Report';

    //Store the Account to Field Support Roles to be prepopulated in CC Address
    public static final set<String> SET_FSE_ROLES = new set<String>{'Primary Field Service Engineer','Primary Field Application Scientist'};

    public static final String LOG_TITLE = 'ServiceReportEmailController'; //CMSI-218

    /**
    *  @author Soumya Ranjan Sahu 
    *  @description : To get all the Direct and Indirect Contacts of Account
    *  @return List of Contact Ids
    **/
    @AuraEnabled(cacheable=true)
    public static List<id> getRelatedContacts (string accountId){
        ilib_LogEvent.push(LOG_TITLE + 'getRelatedContacts'); //CMSI-218
        List<id> lstAllRelatedContacts = new List<id>();
        if(accountId!=null && accountId!=''){
            //get all the indirect accounts
            For(AccountContactRelation objACR: new AccountContactRelationsSelector().getAccountContactRelationByAccount(new set<id>{accountId})){
                lstAllRelatedContacts.add(objACR.ContactId);
                ilib_LogEvent.message('Account Indirect Contacts' + objACR.ContactId); //CMSI-218
            }
            //get all the direct accounts
            For(Contact objContact: new ContactsSelector().selectContactsFromAccount(new set<id>{accountId})){
                lstAllRelatedContacts.add(objContact.Id);
                ilib_LogEvent.message('Account Direct Contacts' + objContact.Id); //CMSI-218
            }
        }
        ilib_LogEvent.pop(); //CMSI-218
        return lstAllRelatedContacts;

    }

    /**
    *  @author Soumya Ranjan Sahu 
    *  @description : To search for Associated Acc to Field Supp records based on the roles specified
    *  @return List of Wrapper SObJectResult
    **/
    @AuraEnabled(cacheable=true)
    public static List<SObJectResult> getCCAddresses (string accountId){
        
        ilib_LogEvent.push(LOG_TITLE + 'getCCAddresses'); //CMSI-218
        Map<Id,Map<String,Account_to_Field_Support__c>> accountIdToFSERoles = new Map<Id,Map<String,Account_to_Field_Support__c>>();
        //To store the Account to FS and Logged inUser data
        List<SObJectResult> ccResultList = new List<SObJectResult>();
        
        //Get details of logged in User
        User loggedInUser = new UsersSelector().selectByUserId(new set<id>{UserInfo.getUserId()})[0];
        if(accountId != null){
            //Fetch the Account to Field Supports
            accountIdToFSERoles = ServiceUtilityCollection.fetchAccountRoles(new set<String>{accountId}, SET_FSE_ROLES);
            if(accountIdToFSERoles.containskey(accountId) && accountIdToFSERoles.get(accountId).size()>0){
                //Prepare Wrapper instance to push to Final Output
                For(String objAccToFs:accountIdToFSERoles.get(accountId).keyset()){
                    if(accountIdToFSERoles.get(accountId).get(objAccToFs).User__r.SVMXC__Salesforce_User__c != null){
                        String id = accountIdToFSERoles.get(accountId).get(objAccToFs).User__r.SVMXC__Salesforce_User__c;
                        String name = accountIdToFSERoles.get(accountId).get(objAccToFs).User__r.Name;
                        String emailId = accountIdToFSERoles.get(accountId).get(objAccToFs).User__r.SVMXC__Salesforce_User__r.Email;
                        ccResultList.add(new SObjectResult(name, id,emailId));
                    }
                }
                ilib_LogEvent.info('Account to Field Support' + ccResultList); //CMSI-218
            }
        }
        //Add logged in user to the final list of CC addresses
        String id = loggedInUser.Id;
        String name = loggedInUser.Name;
        String emailId = loggedInUser.Email;
        ccResultList.add(new SObjectResult(Name, id,EmailId));
        ilib_LogEvent.info('@@ccResultList'+ccResultList);
        ilib_LogEvent.pop(); //CMSI-218
        return(ccResultList);
        
    }
     /**
    *  @author Soumya Ranjan Sahu 
    *  @description : To fetch the latest Service Report on the work order
    *  @return Attachment Object
    **/
    @AuraEnabled(cacheable=true)
    public static Attachment getLatestServiceReportfromWorkOrder (string workOrderId){
        ilib_LogEvent.push(LOG_TITLE + 'getLatestServiceReportfromWorkOrder'); //CMSI-218
        //Fetch the latest Service Report
        //List<Attachment> lstServiceReports = [SELECT Id,Name FROM Attachment WHERE ParentId = :workOrderId AND Name LIKE :STRING_ATTACHMENT_NAME+'%' ORDER BY LastModifiedDate DESC];
        List<Attachment> lstServiceReports = new AttachmentsSelector().getLatestAttachmentByParentId(new set<Id>{workOrderId},STRING_ATTACHMENT_NAME); 
        
        if(lstServiceReports.size()>0){
            ilib_LogEvent.info('Service Report' + lstServiceReports); //CMSI-218
            ilib_LogEvent.pop(); //CMSI-218
            return lstServiceReports[0];
        }
        else 
        {
            ilib_LogEvent.pop(); //CMSI-218
            return null;
        } 
    }

    //(cacheable=true) is intentionally removed to allow DML opertaion (Updating WorkOrder) from same context
    @AuraEnabled()
   /**
    *  @author Soumya Ranjan Sahu 
    *  @description : Handles sending email from the component
    *  @return Result of Send Email (String)
    **/
    public static string sendServiceReportEmail(List<String> lstToAddresses,List<String> lstCCAddresses,string subject, string body, List<id> setContentDocumentIds,List<id> setAttachmentIds,string strWoId, String caseId){
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SERVICE); //CMSI-218
        ilib_LogEvent.push(LOG_TITLE + 'sendServiceReportEmail'); //CMSI-218
        //To store the ContentVersions from ContentDocuments
        set<id> setContentVersionIds = new set<id>();
        if(setContentDocumentIds !=null && setContentDocumentIds.size()>0){
            For(ContentVersion objConVer:new ContentVersionsSelector().selectByContentDocumentId(new set<id>(setContentDocumentIds))){
                setContentVersionIds.add(objConVer.Id);
                ilib_LogEvent.message('new Content Versions' + objConVer.Id); //CMSI-218
            }
        }
        //Add fetched content versions to Final Attachment List
        List<id> lstAttachment = new List<id>(setContentVersionIds);
        lstAttachment.addAll(setAttachmentIds);
        //Contruction of Email Message
         Messaging.SingleEmailMessage objEmail = new Messaging.SingleEmailMessage();
         If(lstToAddresses.size()>0)
         objEmail.setToAddresses(lstToAddresses);
         If(lstCCAddresses.size()>0)
         objEmail.setCcAddresses(lstCCAddresses);
         If(lstAttachment.size()>0)
         objEmail.setEntityAttachments(lstAttachment);
         objEmail.setSubject(subject);
         objEmail.setHtmlBody(body);

         if(String.isNotBlank(caseId)){
         objEmail.setWhatId(caseId);//DCP-44235 - attach it to the case of work order.    
         }
         
         //To prevent User signature getting appended to the final output
         objEmail.setUseSignature(false);

         Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {objEmail};
         ilib_LogEvent.info('objEmail'+objEmail); //CMSO-218
         List<Messaging.SendEmailResult> results = new List<Messaging.SendEmailResult>();
         try{
            //invoke Outbound Email
            results = Messaging.sendEmail(messages);
            if (results[0].success) {
                ilib_LogEvent.info('@@@Email Sent');
                updateWorkOrder(strWoId);
                ilib_LogEvent.pop(); //CMSI-218
                ilib_LogEvent.emit(); //CMSI-218
                return('The email was sent successfully.');
            } 
         }
        
        catch(EmailException e) {
            //Log Email Exceptions if any
            ilib_LogEvent.info('Email Exception------'+e.getmessage());
            ApexExceptions.emit('ServiceReportEmailController', e);
            ilib_LogEvent.pop(); //CMSI-218
            ilib_LogEvent.emit(); //CMSI-218
            return(e.getmessage());
        }
        ilib_LogEvent.pop(); //CMSI-218
        ilib_LogEvent.emit(); //CMSI-218
        return('The email failed to send. Please check if all emails are valid.');
   }
    /**
    *  @author Soumya Ranjan Sahu 
    *  @description : To prefill subject and Description
    *  @return Map<String, String> 
    **/
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getTemplateData(string workOrderId){
        ilib_LogEvent.push(LOG_TITLE + 'getTemplateData'); //CMSI-218
        //To fetch logged in User's Signature
        String userSignature = new UsersSelector().selectByUserId(new set<id>{UserInfo.getUserId()})[0].Signature;
        Map<String, String> templateData = new Map<String, String>();
        emailTemplate emailTemplateInstance = new EmailTemplatesSelector().selectByNameOrDeveloperName(new List<String>{STRING_EMAIL_TEMPLATE_NAME})[0]; 
        Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(emailTemplateInstance.Id, UserInfo.getUserId(), workOrderId);
        templateData.put('subject', email.getSubject());
        //Append User Signature to template body
        templateData.put('body', email.getHtmlBody()+userSignature);
        ilib_LogEvent.info('Template Data' + templateData); //CMSI-218
        ilib_LogEvent.pop(); //CMSI-218
        return templateData;
    }
    /**
    *  @author Soumya Ranjan Sahu 
    *  @description : Updated the Work Order Last_Service_Report_Sent__c field with current timestamp
    *  @return null
    **/
    @future
    public static void updateWorkOrder(string workOrderId){
        SVMXC__Service_Order__c objWorkOrder= new SVMXC__Service_Order__c(id=workOrderId,Last_Service_Report_Sent__c = System.now());
        update objWorkOrder;
        ilib_LogEvent.info('Updated Work Order' + objWorkOrder); //CMSI-218
    }
    /**
    *  @author Soumya Ranjan Sahu 
    *  @description : To search for entered text in Contacts and User
    *  @return List of Wrapper SObJectResult
    **/
    @AuraEnabled(cacheable=true)
    public static List<SObJectResult> getResults(String value, List<String> setContactIds, List<String> setUserIds, List<String> setRelatedContacts) {
        ilib_LogEvent.push(LOG_TITLE + 'getResults'); //CMSI-218
        //Wrapper Instance for Dynamic Query Result
        List<SObJectResult> sObjectResultList = new List<SObJectResult>();
        if(String.isNotEmpty(value)) {
            String searchStr=escapeSosl(value);
            String searchStr1 = '*'+searchStr+'*';
            String searchQuery = 'FIND \''+ searchStr1 + '\' IN ALL FIELDS RETURNING  User(Id,Name, Email WHERE ID NOT IN :setUserIds), Contact(Id,Name,Email WHERE (ID IN :setRelatedContacts  AND ID NOT IN :setContactIds)) LIMIT 1000';
            system.debug(searchQuery);
            system.debug('SOSL Main class results='+search.query(searchQuery));
            for(List<sObject> lstObj : search.query(searchQuery)){
                for(sObject so : lstObj) {
                    String name = (String)so.get('Name');
                    String emailId = (String)so.get('Email');
                    sObjectResultList.add(new SObjectResult(Name, so.Id,EmailId));
                    ilib_LogEvent.message('Contacts and Users' + sObjectResultList); //CMSI-218
                }
            }
        }
       
        ilib_LogEvent.pop(); //CMSI-218
        return sObjectResultList;
    }

    /**
    *  @author Soumya Ranjan Sahu 
    *  @description : To handle escape characters
    *  @return void
    **/    
    public Static String escapeSosl( String text ) {

        ilib_LogEvent.push(LOG_TITLE + 'escapeSosl'); //CMSI-218
        // handle single quotes
        String escapedText = String.escapeSingleQuotes( text ) ;
    
        // remove reserved logical operators
        escapedText = escapedText.replaceAll( '(?i)( AND NOT | AND | OR )', ' ' );
    
        // match special characters to escape
        Pattern myPattern = Pattern.compile( '(\\?|\\&|\\||\\!|\\{|\\}|\\[|\\]|\\(|\\)|\\^|\\~|\\*|\\:|\\"|\\+|\\-)' );
        Matcher myMatcher = myPattern.matcher( escapedText );
    
        // escape special characters
        escapedText = myMatcher.replaceAll( '\\\\\\\\$1' );
    
        // collapse extra whitespace
        escapedText = escapedText.replaceAll( '( )+', ' ' ).trim();
        ilib_LogEvent.info('Escape Charecters' + escapedText); //CMSI-218
        ilib_LogEvent.pop(); //CMSI-218
        return escapedText;
    }
    
    /**
    *  @author Soumya Ranjan Sahu 
    *  @description : Generic Wrapper to Store data
    **/
    public class SObjectResult {
        
        @AuraEnabled
        public Id recId;

        @AuraEnabled
        public String recName;

        @AuraEnabled
        public String recEmail;

		/*
         * Constructor
         */        
        public SObJectResult(String recNameTemp, Id recIdTemp,String recEmailTemp) {
            recName = recNameTemp;
            recId = recIdTemp;
            recEmail = recEmailTemp;
        }

		/*
         * Constructor
         */		
        public SObJectResult() {
          
        }
    }
}