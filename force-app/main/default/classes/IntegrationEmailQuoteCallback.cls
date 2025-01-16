/**
*    @author Todd Newman
*    @date   2020-05-26
*    @description    DCP-34910 Email Service Handler Class
*    @Test Class for 75% coverage : TestIntegrationEmailQuoteCallback
*    @Test Class for 90% coverage : TestIntegrationEmailQuoteCallback
*    Modification Log:
*   ------------------------------------------------------------------------------------------------------ 
*    Developer                      Date                Description
*    Todd Newman                 2020-05-26            Initial Version  
*    Rishab Wali                 2020-05-27            Added logic for Validate Scenario DCP-34910
*    Prabhsimran Singh           2020-06-11            Added logic for Generate Scenario DCP-37888
*    Jitesh Lakhwani             6-July-2022           Code Scan fixes of Comments
*    Anshaj Sinha                14-Sep-2022           CMSI-203 Instrumented class for logging framework
*    ----------------------------------------------------------------------------------------------------- 
*/
global without sharing class IntegrationEmailQuoteCallback implements IntegrationEmailMessageHandler.IntegrationEmailProcessor_I {
    
    public static final String LOG_TITLE = 'IntegrationEmailQuoteCallback';
    public static final String CHECKPRICECLASSNAME = 'ApttusCheckPriceController';
    public static final String VALIDATECARTQUOTE = 'Validate cart for quote ';
    public static final String EXCPTION = 'EXCEPTION';
    
    /**
    * @description: This method will prepare all the necessary data and will send mail. This method is used on Quote.
    * @param : Messaging.InboundEmail email, Messaging.InboundEnvelope env, String parameter
    * @return : Messaging.InboundEmailResult
    **/
    global Messaging.InboundEmailResult process(Messaging.InboundEmail email, Messaging.InboundEnvelope env, String parameter)
    {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        //DCP-34910 Logic for large cart
        try{
            //Quote Id --> From EmailMessageHandler 
            String quoteName = parameter;
            ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SALES);
            ilib_LogEvent.push(LOG_TITLE+ '.process()');
            if(String.isNotBlank(quoteName))
            {
                ApttusProposalsSelector apttusProposalsSelector = new ApttusProposalsSelector();
                Apttus_Proposal__Proposal__c objQuotation = apttusProposalsSelector.fetchQuotation(new Set<String> {quoteName})[0];

                objQuotation.Validation_In_Progress__c = false;
                //DCP-37888 Logic for generate cart.
                objQuotation.Generate_In_Progress__c = false;
                update objQuotation;
                ilib_LogEvent.info('Quotation Updated, Id : '+objQuotation.Id);
                
                ApttusProductConfigurationsSelector apttusConfigSelector = new ApttusProductConfigurationsSelector();
                List<Apttus_Config2__ProductConfiguration__c> lstProdConfig =  apttusConfigSelector.selectSavedProductConfigurationByQuotIds(new Set<Id> {objQuotation.Id});
                
                if(!lstProdConfig.isEmpty())
                {
                    lstProdConfig[0].Sap_Errors__c = email.htmlBody;
                    update lstProdConfig[0];    
                }                          
                //Log Creation
                ilib_LogEvent.info('Log creation started');
                ilib_RestInterface.InterfaceDetails interfaceDetails = ilib_RestInterface.getInterfaceDetails(CHECKPRICECLASSNAME);
                ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails,VALIDATECARTQUOTE + objQuotation.Name);
                ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_FAIL,email.htmlBody, objQuotation.Id);
                
                String emailSubj = System.Label.UI_Quotation_String + ' ' + objQuotation.Name + ' ' + System.Label.UI_Large_Cart_Failed_Message;
                ilib_LogEvent.info('Email Subject : '+emailSubj);
                String emailBody = '<body>'+ System.Label.UI_Hi_Message + ' ' + objQuotation.Owner.Name + '<br><br>';
                ilib_LogEvent.info('Email Body : '+emailBody);
                emailBody += email.htmlBody + '<br></body>';

                sendEmail(emailSubj,objQuotation.OwnerId,emailBody);
                
                EmailMessage[] newEmail = new EmailMessage[0];
                
                newEmail.add(new EmailMessage(FromAddress = email.fromAddress,
                                              FromName = email.fromName,
                                              ToAddress = objQuotation.Owner.Email,
                                              Subject = emailSubj,
                                              htmlBody = emailBody,
                                              RelatedToId = objQuotation.Id));
                
                insert newEmail;
            }
            
            result.success = true;
            ilib_LogEvent.info('result.success = True');
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return result;
        }
        catch (Exception e)
        {
            ilib_LogEvent.error(EXCPTION);
            ilib_LogEvent.error('Exception Messagge : '+e.getMessage());
            ilib_LogEvent.error('result.success = False');
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            ApexExceptions.emit(LOG_TITLE, e, ilib_LogEvent.SALES);
            
            result.success = false;
            return result;
        }
    }

    /**
    * @description: This method will send mail. This method is used by process method from the same class.
    * @param : String subject,Id quoteOwnerId, String emailBody
    * @return : Void
    **/
    public static void sendEmail(String subject,Id quoteOwnerId, String emailBody)
    {
        ilib_LogEvent.push(LOG_TITLE + '.sendEmail()');
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject(subject);
        email.setTargetObjectId(quoteOwnerId);
        email.setSaveAsActivity(false);
        email.setHtmlBody(emailBody);
        if(!test.isRunningTest()){    
            Messaging.SendEmailResult [] sendEmails = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
            ilib_LogEvent.info('sendEmails' + sendEmails); 
        }
        ilib_LogEvent.pop();
    }
}