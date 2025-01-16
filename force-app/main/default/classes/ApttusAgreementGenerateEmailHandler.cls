/**
*    @author Vignesh S
*    @date   13 Feb 2020
*    @description  To Attach document generated from SAP TO Agreement.
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                      Date                Description
*    Vignesh S                    13 Feb 2020         Initial Version
*    Anand Palla                  15 Sep 2021         DCP-49423: Assigning ContentType to attachments
*    Anand Palla                  26 Apr 2022         CodeScan Fix-Avoid Literals in If condition
*    Nesar Mohan                  01 Apr 2022         CodeScan Fix - Code Comments
*    Aman Tyagi                   12 Dec 2022         Codescan Fixes
*    Balakrishna                  23 Jun 2023         CMCM-1058
*    ------------------------------------------------------------------------------------ 
*                    
*/
global without sharing class ApttusAgreementGenerateEmailHandler extends ilib_RestReceiver implements Messaging.InboundEmailHandler {

    //Start CodeScan Fix [Avoid Literals in If condition]
    private static final Integer INTEGER_ONE = 1;
    private static final Integer INTEGER_TWO = 2;
    //End CodeScan Fix

    /*
    * @author      : Vignesh S
    * @Description : Method to Attach document generated from SAP TO Agreement
    * @param       : Messaging.InboundEmail, Messaging.InboundEnvelope
    * @return      : Messaging.InboundEmailResult
    */
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        
        try{
            Id agreementId;
            string resultKey;
            
            if(string.isNotBlank(email.subject) ){
                list<string> lstSubject = email.subject.split('-');
                if(lstSubject.size() > INTEGER_ONE ){
                    agreementId = new ApttusAgreementSelectors().selectAgreementsByNumber(lstSubject[1]).Id;
                }
                
                if(lstSubject.size() > INTEGER_TWO ){
                    resultKey = lstSubject[2];
                }
                
                list<Attachment> lstAttachmentToInsert = new  list<Attachment>();
                if(string.isNotBlank(agreementId)){ 
					system.debug('email.binaryAttachments'+email.binaryAttachments);
					system.debug('email.textAttachments'+email.textAttachments);
				
                    if(email.binaryAttachments != null){
                        for(Messaging.InboundEmail.BinaryAttachment binAttachment : email.binaryAttachments){
                            Attachment objAttchment = new Attachment();
                            objAttchment.Body = binAttachment.body;
                            objAttchment.Name = binAttachment.fileName;
                            objAttchment.ParentId = agreementId;
                            if(binAttachment.fileName.containsignorecase('.xls')){
                                objAttchment.ContentType = Label.Content_Type_Excel;//CMCM-1058
                            } Else{
                            	objAttchment.ContentType = Label.Content_Type_PDF;//DCP-49423
                            }
                            lstAttachmentToInsert.add(objAttchment);
                        }
                    }
                    
                    if(email.textAttachments != null){
                        for(Messaging.InboundEmail.TextAttachment textAttachment : email.textAttachments){
                            Attachment objAttchment = new Attachment();
                            objAttchment.Body = blob.valueOf(textAttachment.body);
                            objAttchment.Name = textAttachment.fileName;
                            objAttchment.ParentId = agreementId;
                            if(textAttachment.fileName.containsignorecase('.xls')){
                                objAttchment.ContentType = Label.Content_Type_Excel;//CMCM-1058
                            } Else{
                                objAttchment.ContentType = Label.Content_Type_PDF;//DCP-49423
                            }
                            lstAttachmentToInsert.add(objAttchment);
                        }
                    }
					
					system.debug('lstAttachmentToInsert'+lstAttachmentToInsert);
                    if(!lstAttachmentToInsert.isEmpty()){
                        insert lstAttachmentToInsert;
                    }
                    
                    string pricingGenerationStatus = Label.UI_Agreement_Validation_Status_Completed.replace('{0}', 'Generate' );
                    if(lstAttachmentToInsert.isEmpty()){
                        pricingGenerationStatus = Label.AgreementValidationStatusFailed.replace('{0}', 'Generate' );
                    }
                    
                    Apttus__APTS_Agreement__c objAgreementToUpdate = new Apttus__APTS_Agreement__c(Id = agreementId, Pricing_Generation_Status__c = pricingGenerationStatus) ;
                    update objAgreementToUpdate;
                    
                    system.debug('===resultKey===='+ resultKey);  
                    system.debug('===email.htmlBody===='+ email.htmlBody);  
                    
                    string jsonExtract;
                    if ((resultKey == 'E' || resultKey == 'I' || resultKey == 'W') && String.isNotBlank(email.htmlBody) ){
                        jsonExtract = email.htmlBody.substringAfter('{').substringBeforeLast('}');
                        jsonExtract = '{'+ jsonExtract+'}';                         
                        ApttusAgreementValidateErrorWrapper.ValidateErrorWrapper validateErrorWrapper = (ApttusAgreementValidateErrorWrapper.ValidateErrorWrapper) System.JSON.deserialize( jsonExtract , ApttusAgreementValidateErrorWrapper.ValidateErrorWrapper.class);
                        ApttusAgreementErrorHandler.checkErrors(validateErrorWrapper,Label.AgreementActionGenerate);
                    }

                    string hasAttachment = lstAttachmentToInsert.size() > 0 ? 'True':'False';
                    ApttusAgreementGenerateEmailHandler instantiated = new ApttusAgreementGenerateEmailHandler();
                    ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
                    ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, 'Email Handler class');
                    ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_SUCCESS, hasAttachment+jsonExtract , agreementId); 
                }
            }
            result.success = true;
            
        }catch(exception e){
            system.debug('exception'+ e);  
            result.success = false;
        }
        
        return result;
    }
}