/*
* @Author:  Todd
* @Date:    
* @Description: Handler class for common Opportunity logc
* Modification Log:
* ------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* ------------------------------------------------------------------------------------
* Todd                                         Initial Version
* Akshay Mohan             07-June-2021        DCP-46835: Add logic for setting Exclude from forecast
* Akshay Mohan             22-June-2021        DCP-38968: Remove OpportunitiesBatchSharing references
* KD                       18-June-2021        DCP-46224 : Update relocation type on Opportunity based on UC and CUC. 
* Gladis                   24-June-2021        DCP-38816: Send Opportunity Id's using Platform Event and sends email to the Owner
* Gladis                   25-June-2021        DCP-38816 Method to create email when an Opportunity is marked as Customer Abandoned
* Anand Palla              26-Apr-2022         CodeScan Fix-Avoid Literals in If condition
* Nitin Reddy              24-june-2022        CMSI-68 Instrumentation
* ------------------------------------------------------------------------------------
*/
public with sharing class OpportunitiesService {

    //DCP-46835
    private static final String LOG_TITLE = 'OpportunitiesService';
    //DCP-38816
    private static final String EMAILTEMPLATENAME = 'Opportunity_Opportunity_Updated_to_Closed_Abandoned';
    //Start CodeScan Fix [Avoid Literals in If condition]
    private static final Integer INTEGER_ONE = 1;
    //End CodeScan Fix

    /*
    * @Author: Akshay Mohan
    * @Description : DCP-46835 Logic to set Exclude_from_Forecast__c
    * @return: returns true if the opportunity passed is updated in the method
    */
    public static Boolean needsExcludeFromForecast(Opportunity objOpp){
        ilib_LogEvent.push(LOG_TITLE + '.needsExcludeFromForecast()');
        ilib_Logevent.info('objOpp : '+objOpp);
        if(objOpp.Exclude_from_Forecast__c){
            ilib_LogEvent.info('Opportunity already has Exclude_from_Forecast__c set');
            ilib_LogEvent.info('return: false');
            ilib_LogEvent.pop();
            return false;
        }else if(String.isNotBlank(objOpp.Product_Interest__c) && 
                    objOpp.Product_Interest__c.contains(Label.OpportunityProductInterestBreakFix)){
            ilib_LogEvent.info('Opportunity is Break fix');
            ilib_LogEvent.info('return: true');
            ilib_LogEvent.pop();
            return true;
        }
        ilib_LogEvent.info('Opportunity not qualifying for Exclude_from_Forecast__c');
        ilib_LogEvent.info('return: false');
        ilib_LogEvent.pop();
        return false;
    }
    /**
     * @author KD
     * @date   16-June-2021
     * @description    DCP-46224 : Update relocation type on Opportunity based on UC and CUC.       
    **/
	public static String updateRelocationType(Opportunity objOpp, Map<Id,Account> accIdToAccMap){
        ilib_LogEvent.push(LOG_TITLE+'updateRelocationType('+objOpp.Name+')');
        ilib_LogEvent.info('accIdToAccMap : '+(accIdToAccMap != Null ? String.valueof(accIdToAccMap.keySet()):'Null'));
        String strUCRegion = accIdToAccMap.containsKey(objOpp.Ultimate_Consignee__c) ? accIdToAccMap.get(objOpp.Ultimate_Consignee__c).Territory_Region__c : null;
        String strCUCRegion = accIdToAccMap.containsKey(objOpp.Current_Ultimate_Consignee__c) ? accIdToAccMap.get(objOpp.Current_Ultimate_Consignee__c).Territory_Region__c : null;
        ilib_LogEvent.info('strUCRegion : '+strUCRegion);
        ilib_LogEvent.info('strCUCRegion : '+strCUCRegion);
        if(String.isBlank(strUCRegion) || String.isBlank(strCUCRegion)){
            ilib_LogEvent.info('return: Null');
            ilib_LogEvent.pop();
            return null;
        }
        if(strUCRegion.equals(strCUCRegion)){
            if(String.isBlank(accIdToAccMap.get(objOpp.Ultimate_Consignee__c).BillingCountryCode) && String.isBlank(accIdToAccMap.get(objOpp.Current_Ultimate_Consignee__c).BillingCountryCode)){
                ilib_LogEvent.info('return: Null');
                ilib_LogEvent.pop();
                return null;
            }
            if(accIdToAccMap.get(objOpp.Ultimate_Consignee__c).BillingCountryCode.equals(accIdToAccMap.get(objOpp.Current_Ultimate_Consignee__c).BillingCountryCode)){
                ilib_LogEvent.info('return: Label.OpportunityRelocationStandard : '+Label.OpportunityRelocationStandard);
                ilib_LogEvent.pop();
                return Label.OpportunityRelocationStandard;
            }
            else{
                ilib_LogEvent.info('return: Label.OpportunityRelocationTransBorder : '+Label.OpportunityRelocationTransBorder);
                ilib_LogEvent.pop();
                return Label.OpportunityRelocationTransBorder;
            }
        }
        else{
                ilib_LogEvent.info('return: Label.OpportunityRelocationTransRegion : '+Label.OpportunityRelocationTransRegion);
                ilib_LogEvent.pop();
                return Label.OpportunityRelocationTransRegion;
        }
    }

    /*
    * @Author: Gladis
    * @Description : DCP-38816 Logic to send Opportunity Id's using Platform Event and sends email to the Owner
    * @return : set of Opportunity Id's
    */
    public static void updateOpportunityAbandoned( Map<Id,List<SVMXC__Service_Order__c>> mapOpportuntinyToLstWO){

        ilib_LogEvent.push(LOG_TITLE + '.updateOpportunityAbandoned()');
        ilib_LogEvent.info('mapOpportuntinyToLstWO : '+(mapOpportuntinyToLstWO != Null ? String.valueof(mapOpportuntinyToLstWO.keySet()):'Null'));
        List<Admin_Operation__e> lstAdminOperationOpportunityAbandonedUpdate = new List<Admin_Operation__e>();
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        for(Id opportunityId : mapOpportuntinyToLstWO.keySet()){
            if(mapOpportuntinyToLstWO.get(opportunityId).size() == INTEGER_ONE){
                lstAdminOperationOpportunityAbandonedUpdate.add(new Admin_Operation__e(Related_Record__c=opportunityId,Name__c='UpdateOpportunityAbandoned'));  
                mails.add(createAbandonedEmail(opportunityId, mapOpportuntinyToLstWO.get(opportunityId)[0]));
            }
            
        }
        if(!lstAdminOperationOpportunityAbandonedUpdate.isEmpty()){
            EventBus.publish(lstAdminOperationOpportunityAbandonedUpdate);
        }
        if(!mails.isEmpty()) {
            Messaging.sendEmail(mails);
            ilib_LogEvent.info('mails--'+mails);
        } 
        ilib_LogEvent.pop();
    }

    /*
    * @Author: Gladis
    * @Description : DCP-38816 Method to create email when an Opportunity is marked as Customer Abandoned
    * @return : Id
    */
    public static Messaging.SingleEmailMessage createAbandonedEmail(String oppId, SVMXC__Service_Order__c objWO){

        // Write logic to send mail here.
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        List<EmailTemplate> lstEmailTemp = new EmailTemplatesSelector().selectByNameOrDeveloperName(new List<String>{EMAILTEMPLATENAME});
        List<String> strEmailId = new List<String>();
        String strBaseURL= URL.getSalesforceBaseUrl().toExternalForm()+'/';
        ilib_LogEvent.message('strBaseURL--'+strBaseURL+oppId);
        EmailTemplate objEmailTemplate = lstEmailTemp[0];
        String htmlBody = objEmailTemplate.HtmlValue;
        String plainBody = objEmailTemplate.Body;
        ilib_LogEvent.message('objEmailTemplate : '+objEmailTemplate);
        ilib_LogEvent.message('htmlBody : '+htmlBody);
        ilib_LogEvent.message('plainBody : '+plainBody);
            strEmailId.add(objWO.Opportunity__r.Owner.email);
            ilib_LogEvent.message('strEmailId--'+strEmailId);
            htmlBody = htmlBody.replace('[[OpportunityLink]]', strBaseURL+oppId);
            htmlBody = htmlBody.replace('[[OpportunityName]]', objWO.Opportunity__r.Name);
            htmlBody = htmlBody.replace('[[WorkOrderLink]]', strBaseURL+objWO.Id);
            htmlBody = htmlBody.replace('[[WorkOrderName]]', objWO.Name);
            htmlBody = htmlBody.replace('[[OppAccountLink]]', strBaseURL+objWO.Opportunity__r.AccountId);
            htmlBody = htmlBody.replace('[[OppAccountName]]', objWO.Opportunity__r.Account.Name);    
            htmlBody = htmlBody.replace('[[WoSubject]]', objWO.SVMX_PS_Subject__c);
            htmlBody = htmlBody.replace('[[AbandonedReasonDetails]]', objWO.Abandoned_Reason__c);
            htmlBody = htmlBody.replace('[[EstimatedQuoteAmount]]', String.valueOf(objWO.Estimated_Quote_Amount__c));
            htmlBody = htmlBody.replace('[[WorkOrderCurrency]]', objWO.CurrencyIsoCode);
            
            plainBody = plainBody.replace('[[OpportunityName]]', objWO.Opportunity__r.Name);
            plainBody = plainBody.replace('[[OppAccountName]]', objWO.Opportunity__r.Account.Name);
            plainBody = plainBody.replace('[[WorkOrderName]]', objWO.Name);
            plainBody = plainBody.replace('[[WoSubject]]', objWO.SVMX_PS_Subject__c);
            plainBody = plainBody.replace('[[AbandonedReasonDetails]]', objWO.Abandoned_Reason__c);
            plainBody = plainBody.replace('[[EstimatedQuoteAmount]]', String.valueOf(objWO.Estimated_Quote_Amount__c));
            plainBody = plainBody.replace('[[WorkOrderCurrency]]', objWO.CurrencyIsoCode);
            Boolean boolHasIP = String.isNotBlank(objWO.SVMXC__Component__c);
            ilib_LogEvent.message('boolHasIP : '+boolHasIP);
            htmlBody = htmlBody.replace('[[WoInstalledProductLink]]', boolHasIP ? strBaseURL+objWO.SVMXC__Component__c : '');
            htmlBody = htmlBody.replace('[[WoInstalledProductName]]', boolHasIP ? objWO.SVMXC__Component__r.name : 'N/A');
            plainBody = plainBody.replace('[[WoInstalledProductName]]', boolHasIP ? objWO.SVMXC__Component__r.name : 'N/A');

            email.setHtmlBody(htmlBody);
            email.setPlainTextBody(plainBody);
            email.setToAddresses(strEmailId);
            email.setSubject(objEmailTemplate.Subject);
            ilib_LogEvent.message('email--'+email);
            
		
        return email;
    }
        
}