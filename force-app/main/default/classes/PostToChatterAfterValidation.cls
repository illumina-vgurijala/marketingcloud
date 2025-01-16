/**
*    @author Rishab Wali
*    @date   2020-05-23
*    @description    Invocable apex class to post chatter and send Emails
*    Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                Description
*    Rishab Wali                  2020-05-23          Initial Version
*    ------------------------------------------------------------------------------------                  
*/
public without sharing class PostToChatterAfterValidation {
    
    public static final String FEEDITEMTYPE = 'TextPost';
    public static final String NORESPONSERECIEVED = 'Response not recieved in expected time.';
    public static final String CHECKPRICECLASSNAME = 'ApttusCheckPriceController';
    public static final String VALIDATECARTQUOTE = 'Validate cart for quote ';
    public static final String SOLD_TO_SALES_ORGANIZATION = 'CN03';
    
    /* Method to Call SendEmail and PostToChatter Methods */
    @InvocableMethod(label='PostToChatter')
    public static void postToChatter(List<Id> lstQuotationId)
    {
        ApttusProposalsSelector apttusProposalsSelector = new ApttusProposalsSelector();
        Apttus_Proposal__Proposal__c objQuotation = apttusProposalsSelector.selectProposalById(String.valueOf(lstQuotationId[0]));
        
        try{
            if(objQuotation.Validation_In_Progress__c == true && objQuotation.Async_Validation_Complete__c == false)
            {
                objQuotation.Validation_In_Progress__c = false;
                update objQuotation;
                
                //creating logs
                ilib_RestInterface.InterfaceDetails interfaceDetails = ilib_RestInterface.getInterfaceDetails(CHECKPRICECLASSNAME);
                ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails,VALIDATECARTQUOTE + objQuotation.Name);
                ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_FAIL,NORESPONSERECIEVED, objQuotation.Id);
                
                //create chatter feed
                String chatterBody = System.Label.UI_Validate_Cart_Failed +' '+ objQuotation.Name +'. '+ System.Label.UI_Revalidate_Quote;
                createFeedItem(objQuotation.OwnerId,chatterBody);
                
                String subject = System.Label.UI_Quotation_String + ' ' + objQuotation.Name + ' ' + System.Label.UI_Large_Cart_Failed_Message;
                String body = System.Label.UI_Hi_Message +' '+ objQuotation.Owner.Name + ', \n \n' + System.Label.UI_Quote_Processing_Failed +' '+ objQuotation.Name + ' \n\n';
                body += System.Label.UI_Quote_Number + ' ' + objQuotation.Name + '(' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + objQuotation.Id + ') \n';
                body += System.Label.UI_Opp_Name + ' ' + objQuotation.Apttus_Proposal__Opportunity__r.Name + '(' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + objQuotation.Apttus_Proposal__Opportunity__c + ') \n\n';
                sendEmail(subject,objQuotation.OwnerId,body);
            }
            if(objQuotation.Validation_In_Progress__c == false && objQuotation.Async_Validation_Complete__c == true)
            {
                String subject = System.Label.UI_Quotation_String + ' ' + objQuotation.Name + ' ' + System.Label.UI_Large_Cart_Success_Message;
                String body = System.Label.UI_Hi_Message+' '+ objQuotation.Owner.Name + ', \n \n' + System.Label.UI_Quote_Processing_Complete + ' ' + objQuotation.Name + ' \n\n';

                ApttusProductConfigurationsSelector apttusConfigSelector = new ApttusProductConfigurationsSelector();
                List<Apttus_Config2__ProductConfiguration__c> lstProdConfig =  apttusConfigSelector.selectSavedProductConfigurationByQuotIds(new Set<Id> {objQuotation.Id});

                if(!lstProdConfig.isEmpty() && String.isNotBlank(lstProdConfig[0].SAP_Errors__c))
                {
                    body += System.Label.UI_Errors_in_Cart + '\n';
                }

                If(objQuotation.Sold_to_Sales_Organization__c == SOLD_TO_SALES_ORGANIZATION && 
                (objQuotation.Fapiao_Type_Code__c == null || String.isBlank(objQuotation.Fapiao_Type_Code__c)))
                {
                    String chatterBody = objQuotation.Name + ' - ' + System.Label.UI_Error_Message_For_Fapiao_Type_Missing ;
                    createFeedItem(objQuotation.OwnerId,chatterBody);
                    
                    body += System.Label.UI_Error_Message_For_Fapiao_Type_Missing + '\n';       
                }

                body += System.Label.UI_Quote_Number + ' ' + objQuotation.Name + '(' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + objQuotation.Id + ') \n';
                body += System.Label.UI_Opp_Name + ' ' + objQuotation.Apttus_Proposal__Opportunity__r.Name + '(' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + objQuotation.Apttus_Proposal__Opportunity__c + ') \n\n';
                sendEmail(subject,objQuotation.OwnerId,body);
                
                String chatterSuccessMsg = System.Label.UI_Validation_Complete_PB+' '+ objQuotation.Name+' '+System.Label.UI_Successful_Message_PB;
                createFeedItem(objQuotation.OwnerId,chatterSuccessMsg);
            }
        }
        Catch(Exception e)
        {
            System.debug('Error ---- ' + e.getMessage());
            ilib_RestInterface.InterfaceDetails interfaceDetails = ilib_RestInterface.getInterfaceDetails(CHECKPRICECLASSNAME);
            ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails,VALIDATECARTQUOTE + objQuotation.Name);
            ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_FAIL,e.getLineNumber() +'-'+ e.getMessage()+'-'+ e.getTypeName()+'-'+ e.getCause() +'-'+ e.getStackTraceString(), objQuotation.Id);
        }
    }
    
    /* Method to Send Email */
    public static void sendEmail(String subject,Id quoteOwnerId, String emailBody)
    {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject(subject);
        email.setTargetObjectId(quoteOwnerId);
        email.setSaveAsActivity(false);
        email.setPlainTextBody(emailBody);
        if(!test.isRunningTest()){    
            Messaging.SendEmailResult [] sendEmails = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email}); 
            System.debug('sendEmails ---' + sendEmails);
        }
    }

    /* Method to post to chatter */
    public static void createFeedItem(Id parentId,String body)
    {
        FeedItem post = new FeedItem();
        post.Type = FEEDITEMTYPE;    
        post.ParentId = parentId;
        post.Body = body;
        insert post;
    }

}