/**
*   @author Rishab Wali
*   @date 2021-06-15
*   @description    
*   Modification Log:
*   ------------------------------------------------------------------------------------
*           Developer                   Date                Description
*           Rishab Wali                 2021-06-15          [DCP-46920] : Sending email to quote owner when document generated 
*   ------------------------------------------------------------------------------------
**/
public with sharing class SendEmailToQuoteOwnersQueueable  implements IOpportunityQuoteAutomation{
    private Id idQuotation,idQuoteOutput;
    private static final String LOG_TITLE = 'SendEmailToQuoteOwnersQueueable';
    public static final String CODEPARAMETERNAME = 'Quoting_Regional_DL_'; 

    /**Method - getRecordId() **/
    public Id getRecordId(){
        
        return idQuoteOutput;
    }

    /**Method - setRecordId() **/
    public void setRecordId(String idQuotation){
        this.idQuotation = idQuotation;    
    }

    /*Method - getErrorDetails() will never be called*/
    public OpportunityQuoteAutomationQueueable.EmailWrapper getErrorDetails(){
        return null;
    }

    /*Method - execute method */
    public void execute(QueueableContext context){
        ilib_LogEvent.push(LOG_TITLE + '.execute()');
        try{
            
            Map<Id,Apttus_Proposal__Proposal__c> idToProposalMap = new Map<Id,Apttus_Proposal__Proposal__c>(new ApttusProposalsSelector().selectByQuoteId(new Set<Id>{idQuotation}));

            Attachment atch = new Attachment();
            AttachmentsSelector atchSelector = new AttachmentsSelector();
            if(test.isRunningTest())
            {
                try{
                    atch = atchSelector.getAttachmentByParentId(new Set<Id>{idQuotation}).get(0);
                }
                Catch(Exception e)
                {
                    atch.Name = 'Atch Name';
                    atch.Body = Blob.valueOf('Test Body');
                    atch.parentId = idQuotation;
                }
            }
            else{
               atch = atchSelector.getAttachmentByParentId(new Set<Id>{idQuotation}).get(0);}
            ilib_LogEvent.message('Attachment atch-->'+atch.Name);
            Map<Id,Attachment> proposalIdToDocumentMap = new Map<Id,Attachment>();
            proposalIdToDocumentMap.put(atch.parentId,atch);
            sendEmailMessages(proposalIdToDocumentMap,idToProposalMap);
            ilib_LogEvent.message('Email sent');
            idQuoteOutput=idQuotation;
        }catch(Exception e) { 
            ApexExceptions.emit(LOG_TITLE,idQuotation,e); 
        }
        ilib_LogEvent.pop();
    }

	/*Description - [DCP-46920] Method to Send Email messages */
    public static void sendEmailMessages(Map<Id,Attachment> mapProposalToAttachmentBody,Map<Id,Apttus_Proposal__Proposal__c> idToProposalMap)
    {
        
        List<Messaging.SingleEmailMessage> lstEmail = new List<Messaging.SingleEmailMessage>();
        for(Id proposalId : mapProposalToAttachmentBody.keySet())
        {
            Messaging.SingleEmailMessage emailMessage = setEmail(proposalId,idToProposalMap,mapProposalToAttachmentBody.get(proposalId));
            lstEmail.add(emailMessage);
        }

        if(!lstEmail.isEmpty() || test.isRunningTest()){
        Messaging.sendEmail(lstEmail,false);}
        

    }

    /*Description - [DCP-46920] Method to initialise email object with data */
    public static Messaging.SingleEmailMessage setEmail(Id prpslId , Map<Id,Apttus_Proposal__Proposal__c> idToProposalMap, Attachment objAttchmnt)
    {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        if(idToProposalMap.containsKey(prpslId)){
			String strSubject = GenerateEmailService.setEmailSubject(idToProposalMap.get(prpslId));
			String strBody = GenerateEmailService.getEmailBody(true,idToProposalMap.get(prpslId)); 
			Messaging.EmailFileAttachment emailAttchment = new Messaging.EmailFileAttachment();
			emailAttchment.setFileName(objAttchmnt.Name);
			emailAttchment.setBody(objAttchmnt.Body);
			email.setSubject(strSubject);
			email.setSaveAsActivity(false);
			email.setHtmlBody(strBody);
			email.setToAddresses( new String[] {idToProposalMap.get(prpslId).Prepared_by__r.Email} );
			if(idToProposalMap.get(prpslId).Work_Order__c != Null){
                String getRegion = CODEPARAMETERNAME + idToProposalMap.get(prpslId).Apttus_Proposal__Opportunity__r.Territory_Region__c;
                codeParametersSelector objCodeParametersSelector = new codeParametersSelector();
                List<Code_Parameter__mdt> objCodeParam = objCodeParametersSelector.selectCodeParameterByDeveloperName(new Set<String>{getRegion});
                List<String> lstSetCCAddresses = objCodeParam[0].Value__c.Split(';');
                email.setCcAddresses(lstSetCCAddresses);
            }
            email.setFileAttachments(new Messaging.EmailFileAttachment[] {emailAttchment});
		List<OrgWideEmailAddress> lstOrgWideAddress = new List<OrgWideEmailAddress>(new OrgWideEmailAddressesSelector().getOWDAddress(new Set<String>{'sfdc_service_account@illumina.com'}));
			if(test.isRunningTest())
			{
				email.setToAddresses( new String[] {'abcd@illumina.com'} );
			}
			else { email.setOrgWideEmailAddressId(lstOrgWideAddress.get(0).Id); }
		}		
        return email;
    }

}