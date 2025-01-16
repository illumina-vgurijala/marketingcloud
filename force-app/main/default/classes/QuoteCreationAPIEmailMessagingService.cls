/**
 *    @author Arquimidez Mora
 *    @date   30-10-2024
 *    @description Class to send emails if QuoteCreationAPI is not successful
 *    @Tested By: TestQuoteCreationAPIErrorHandler
 *    Modification Log:
 *    -----------------------------------------------------------------------------------------------------------------------------------
 *             Developer                      Date                Description
 *    -----------------------------------------------------------------------------------------------------------------------------------
 *         Arquimidez Mora                 06 Nov 2024          Initial Version
 */
public with sharing class QuoteCreationAPIEmailMessagingService {
    private static final String STR_DEFAULT_EMAIL = 'Default';
    private static final String PRODUCTION_ENVIRONMENT_NAME = 'production';
    public static final String STRING_OPPORTUNITY_EMAIL = 'Opportunity';
    public static final String STRING_QUOTE_EMAIL = 'Quote';

    /**
    * @description Method to handle the emails creation
    * @author Arquimidez Mora | 11-06-2024 
    * @param lstOppCreationWrapper 
    * @param mapCustomerIds 
    **/
    public static void handleErrorEmail(List<QuoteCreationAPIOppCartWrapper> lstErrorRecords, Map<String, Account> mapCustomerIds, String strType, String errorReason){
        if(!lstErrorRecords.isEmpty()){
            List<Messaging.SingleEmailMessage> lstEmailAdresses = new List<Messaging.SingleEmailMessage>();
            Map<String, Quote_Creation_API_Email_Notification__mdt> mapEmailsByRegion = Quote_Creation_API_Email_Notification__mdt.getAll();
            String strOrgName = getOrgInstanceName();
            system.debug('lstErrorRecords '+lstErrorRecords);

            // Loop to collect errored quote ids
            List<ID> errorQuoteId = new List<ID>();
            for(QuoteCreationAPIOppCartWrapper objWrapper : lstErrorRecords){
                errorQuoteId.add(objWrapper.objRequestWrapper.quoteId);
            }

            List<Apttus_Proposal__Proposal__c> collectErrorQuote =[Select Id,Name From Apttus_Proposal__Proposal__c Where Id IN:errorQuoteId];
            Map<Id,String> collectErrorQuoteName = new Map<Id,String>();
            for(Apttus_Proposal__Proposal__c temp:collectErrorQuote){
                collectErrorQuoteName.put(temp.Id,temp.Name);
            }

            for(QuoteCreationAPIOppCartWrapper objWrapper : lstErrorRecords) {
                List<String> lstEmails = new List<String>();
                Account objSoldTo = mapCustomerIds.get(objWrapper.objRequestWrapper.soldTo);
                Quote_Creation_API_Email_Notification__mdt email = (objSoldTo != null && mapEmailsByRegion.containsKey(objSoldTo.Territory_Region__c) ) ? mapEmailsByRegion.get(objSoldTo.Territory_Region__c) : mapEmailsByRegion.get(STR_DEFAULT_EMAIL);
                system.debug('email  '+email);
                system.debug('STR TYPE '+strType);
                if(!objWrapper.objErrorHandler.lstErrors.isEmpty()) {
                    if(strOrgName != PRODUCTION_ENVIRONMENT_NAME){
                        lstEmails = email.Sandbox_Email__c.split(',');
                        lstEmailAdresses.add(createErrorEmail(objWrapper, lstEmails, strType,errorReason,collectErrorQuoteName));
                    }else{
                        lstEmails = email.Production_Email__c.split(',');
                        lstEmailAdresses.add(createErrorEmail(objWrapper, lstEmails, strType,errorReason,collectErrorQuoteName));
                    }
                }
            }
            system.debug('lstEmailAdresses  '+lstEmailAdresses);
            if (!lstEmailAdresses.isEmpty()) {
                Messaging.sendEmail(lstEmailAdresses);
            }  
        }
    }

    /**
    * @description Method to create an Error Email
    * @author Arquimidez Mora | 11-11-2024 
    * @param objWrapper 
    * @param strEmail 
    * @return Messaging.SingleEmailMessage 
    **/
    public static Messaging.SingleEmailMessage createErrorEmail( QuoteCreationAPIOppCartWrapper objWrapper, List<String> lstEmails, String strType, String errorReason,Map<Id,String> collectErrorQuoteName){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String strSourceSystem = objWrapper.objRequestWrapper.sourceSystem;
        mail.setToAddresses(lstEmails);
        String emailMessageJSON = JSON.serializePretty(objWrapper.objErrorHandler.lstErrors);
        String emailErrorMessage = '<p> <b>Error Details: </b></p>';

        for(QuoteCreationAPIErrorHandler.ErrorItemWrapper tempError : objWrapper.objErrorHandler.lstErrors){
         emailErrorMessage += '<p>'+tempError.message+'</p>';
        }
        String linkURL = '';
        String linkUrlQuote='';
        if(strType == STRING_OPPORTUNITY_EMAIL){
            linkURL = (objWrapper.strOpportunityId != null ? URL.getOrgDomainUrl().toExternalForm()+'/'+ objWrapper.strOpportunityId : '');
        }else if(strType == STRING_QUOTE_EMAIL){            
            linkURL = (objWrapper.objRequestWrapper.quoteId != null ? URL.getOrgDomainUrl().toExternalForm()+'/'+ objWrapper.objRequestWrapper.quoteId : '');
            linkUrlQuote = '<a href="'+linkURL+'">'+collectErrorQuoteName.get(objWrapper.objRequestWrapper.quoteId)+'</a>';
        }
        
        mail.setSubject(strSourceSystem + ' Request Quote Error Handling Notification ');
        String strBody = '<p>We have received a request for quote from '+ strSourceSystem+'. We encountered the error below during the ' + strType+ ' creation process.</n></p>';
        strBody += '<p> Link to ' + strType+ ': '+ linkURL +'</p> ';
        strBody += '<p> System generated error message: </p> ';
        strBody += emailMessageJSON.replace('},', '}, </br>');
        strBody += '</br>';
        strBody += '<p> Request details received from '+ strSourceSystem +':</p>';
        strBody += '<p>'+ objWrapper.strJsonPayload.replace('",', '", </br>') +'</p> ';
        
        if(strType == STRING_OPPORTUNITY_EMAIL){
            mail.setHtmlBody(strBody); 
        }

        String strBodyQuote = '<p>We have received a request for quote from '+ strSourceSystem+'. We encountered the error below during the ' + strType+ ' creation process.</n></p>';
        strBodyQuote += '<p> <b>Link to ' + strType+ ': </b>'+ linkUrlQuote +'</p>';
        strBodyQuote += '<p> <b>Reason For Failure:</b>  '+errorReason+'</p> ';
        strBodyQuote += emailErrorMessage;
        strBodyQuote += '</br>';
        strBodyQuote += '==============================================';
        strBodyQuote += '<p> Request details received from '+ strSourceSystem +':</p>';
        strBodyQuote += '==============================================';
        strBodyQuote += '<p>'+ objWrapper.strJsonPayload.replace('",', '", </br>') +'</p>';

        if(strType == STRING_QUOTE_EMAIL){
            mail.setHtmlBody(strBodyQuote); 
        }

        return mail;
    }

    /**
    * @description Method to get the Environment name
    * @author Arquimidez Mora | 11-11-2024 
    * @return String 
    **/
    public static String getOrgInstanceName(){
        System.Domain objContext = System.DomainParser.parse(URL.getOrgDomainUrl());
        String strOrgName = objContext.getSandboxName() == null ? 'Production' : objContext.getSandboxName();

        return strOrgName;
    }
}