/**
*    @author Prabhsimran Singh
*    @date   2020-06-10
*    @description    Invocable apex class to post chatter and send Emails
*    Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                Description    
*    Aman Tyagi                   31 March 2022          CodeScan Fixes
*    ------------------------------------------------------------------------------------                  
*/
public without sharing class PostToChatterAfterGenerate {
    
    public static final String NORESPONSERECIEVED = 'Response not recieved in expected time.';
    public static final String GENERATEQUOTECLASSNAME = 'ApttusGenerateQuoteController';
    public static final String GENERATECARTQUOTE = 'Generate cart for quote ';    
    
    @InvocableMethod(label='PostToChatterGenerate')

    /*
    * @Author: Prabhsimran Singh
    * @Description : this method has logic for postToChatter based on quotation id
    * @param : List<Id> lstQuotationId
    * @return : void
    */
    public static void postToChatter(List<Id> lstQuotationId)
    {
        ApttusProposalsSelector apttusProposalsSelector = new ApttusProposalsSelector();
        Apttus_Proposal__Proposal__c objQuotation = apttusProposalsSelector.selectProposalById(String.valueOf(lstQuotationId[0]));
        
        try{
            if(objQuotation.Generate_In_Progress__c == true && objQuotation.Async_Generation_Complete__c == false)
            {
                objQuotation.Generate_In_Progress__c = false;
                update objQuotation;
                
                //creating logs
                ilib_RestInterface.InterfaceDetails interfaceDetails = ilib_RestInterface.getInterfaceDetails(GENERATEQUOTECLASSNAME);
                ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails,GENERATECARTQUOTE + objQuotation.Name);
                ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_FAIL,NORESPONSERECIEVED, objQuotation.Id);
                
                //create chatter feed
                String chatterBody = System.Label.UI_Generate_Cart_Failed +' '+ objQuotation.Name +'. '+ System.Label.UI_Regenerate_Quote;
                PostToChatterAfterValidation.createFeedItem(objQuotation.OwnerId,chatterBody);
                
                String subject = System.Label.UI_Quotation_String + ' ' + objQuotation.Name + ' ' + System.Label.UI_Large_Cart_Failed_Message;
                String body = System.Label.UI_Hi_Message +' '+ objQuotation.Owner.Name + ', \n \n' + System.Label.UI_Quote_Processing_Failed +' '+ objQuotation.Name + ' \n\n';
                body += System.Label.UI_Quote_Number +' '+ objQuotation.Name + '(' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + objQuotation.Id + ') \n';
                body += System.Label.UI_Opp_Name + ' ' + objQuotation.Apttus_Proposal__Opportunity__r.Name + '(' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + objQuotation.Apttus_Proposal__Opportunity__c + ') \n\n';
                PostToChatterAfterValidation.sendEmail(subject,objQuotation.OwnerId,body);
            }
            if(objQuotation.Generate_In_Progress__c == false && objQuotation.Async_Generation_Complete__c == true)
            {
                String subject = System.Label.UI_Quotation_String + ' ' + objQuotation.Name + ' ' + System.Label.UI_Large_Cart_Success_Message;
                String body = '<body>'+ System.Label.UI_Hi_Message +' '+ objQuotation.Owner.Name + ', <br><br>' + System.Label.UI_Quote_Processing_Complete + ' ' + objQuotation.Name + ' <br><br>';                

                if(String.isNotBlank(objQuotation.SAP_Errors__c))
                {                    
                    body += System.Label.UI_Errors_in_Generate + '<br><br>'+objQuotation.SAP_Errors__c.replaceAll('&#39;','');                    
                }                

                body += System.Label.UI_Quote_Number +' '+ objQuotation.Name + '(' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + objQuotation.Id + ') <br>';
                body += System.Label.UI_Opp_Name+' '+ objQuotation.Apttus_Proposal__Opportunity__r.Name + '(' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + objQuotation.Apttus_Proposal__Opportunity__c + ') <br><br></body>';
                IntegrationEmailQuoteCallback.sendEmail(subject,objQuotation.OwnerId,body);
                
                String chatterSuccessMsg = System.Label.UI_Generation_Complete+' '+ objQuotation.Name+' '+System.Label.UI_Successful_Message_PB;
                PostToChatterAfterValidation.createFeedItem(objQuotation.OwnerId,chatterSuccessMsg);
            }
        }
        Catch(Exception e)
        {
            System.debug('Error ---- ' + e.getMessage());
            ilib_RestInterface.InterfaceDetails interfaceDetails = ilib_RestInterface.getInterfaceDetails(GENERATEQUOTECLASSNAME);
            ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails,GENERATECARTQUOTE + objQuotation.Name);
            ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_FAIL,e.getLineNumber() +'-'+ e.getMessage()+'-'+ e.getTypeName()+'-'+ e.getCause() +'-'+ e.getStackTraceString(), objQuotation.Id);
        }
    }
}