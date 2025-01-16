/**
*    @author Anand Palla
*    @date   10 June 2021
*    @description  DCP-46168: send an email notification to Tender team
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*       Developer            Date            Description
*    -----------------------------------------------------------------------------------------------------------------------------------
*
*/
public class EmailAlertforClosedWonTenderOpptyClass
{
    /* @author Anand Palla
     * @date   10-Jun-2021
     * @description DCP-46168
    **/
    @future
    public static void sendEmailAlert(Set<Id> opportunityIds)
    {
        String emailTemplateName = 'Tender_Opportunity_Closed_Won_Template';
        Opportunity objOppty = new Opportunity();
        List<Opportunity> lstOppty = new OpportunitySelector().selectOpportunities(opportunityIds);
        try
        {
            List<Messaging.SingleEmailMessage> lstEmailMsgs = new List<Messaging.SingleEmailMessage>();  
            List<Region_to_Email_Mapping__mdt> ccEmailMdt = new TenderRegiontoEmailSelector().selectAllRecords();
            Messaging.SingleEmailMessage email;
            EmailTemplatesSelector emailTemplateSlctr = new EmailTemplatesSelector();
            List<EmailTemplate> lstEmailTemplate = emailTemplateSlctr.selectByNameOrDeveloperName(new List<String> {emailTemplateName});
            String ccEmail = '';
            
            Map<String,String> regionToEmailMap = new Map<String,String>();
            for(Region_to_Email_Mapping__mdt metadataVal : ccEmailMdt)
            {
                regionToEmailMap.put(metadataVal.Region__c,metadataVal.Email__c);
            }
            for(Opportunity opp : (List<Opportunity>)lstOppty)
            {
                objOppty = opp;
                email = new Messaging.SingleEmailMessage();
                
                if(opp.Related_Agreement__r.Apttus__Account__r.Territory_Region__c!=null && regionToEmailMap.containsKey(opp.Related_Agreement__r.Apttus__Account__r.Territory_Region__c) 
                   && regionToEmailMap.get(opp.Related_Agreement__r.Apttus__Account__r.Territory_Region__c) != '')
                {
                    ccEmail=regionToEmailMap.get(opp.Related_Agreement__r.Apttus__Account__r.Territory_Region__c);
                }    
                
                email.setTemplateId(lstEmailTemplate[0].Id);
                email.setTargetObjectId(opp.Related_Agreement__r.OwnerId);
                email.setTreatTargetObjectAsRecipient(false);
                email.setWhatId(opp.id);
                email.setSaveAsActivity(false);
                email.setUseSignature(false);
                String[] toAddresses = opp.Related_Agreement__r.Owner.Email.split(';', 0);
                email.setToAddresses(toAddresses);
                
                if(ccEmail!=null){
                    String[] ccAddresses = ccEmail.split(';', 0);
                    email.setCcAddresses(ccAddresses);
                    lstEmailMsgs.add(email);
                    
                }
            }
            Messaging.sendEmail(lstEmailMsgs, false);
        }
        Catch(Exception e) { ApexExceptions.emit('EmailAlertforClosedWonTenderOpptyClass',objOppty.Id,e); }
    }   
}