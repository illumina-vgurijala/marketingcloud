/**
*    @author Himanshu Malik
*    @date   2022-08-03
*    @description    DCP-54500: Apex class for sending approval/rejection email for open offer agreenment
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                       Date                    Description         
*         Himanshu                      2022-06-02                Initial Version
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class AgreementSendEmailForOpenOfferAgreement {
    private static final String LOG_TITLE = 'AgreementSendEmailForOpenOfferAgreement';

    @InvocableMethod(label='Send Email For Agreement'description='Send Email When Agreement Is Approved/Rejected'category='Apttus__APTS_Agreement__c')
    /*
    *  @AUTHOR:         Himanshu
    *  @DESCRIPTION:    Method to send email when agrrement is Approved Or Rejected
    *  @PARAM :         List<VaariableForEmail> lstOfDataInputsForEmail
    *  @RETURN:         void
    */    
    public static void sendEmail(List<DataInputsForEmail> lstOfDataInputsForEmail) {

            ilib_LogEvent.push(LOG_TITLE + '.sendEmail()');
            ilib_LogEvent.message('lstEmailAddressOfAffiliates -->: '+lstOfDataInputsForEmail);
            List<String> lstEmailAddressOfAffiliates = new List<String>();

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            if(lstOfDataInputsForEmail.get(0).ccEmailAddress != null) {
                Set<String> setEmailAddressOfAffiliates = new Set<String>(lstOfDataInputsForEmail.get(0).ccEmailAddress);
                    lstEmailAddressOfAffiliates.addAll(setEmailAddressOfAffiliates);
                    email.setCcAddresses(lstEmailAddressOfAffiliates);
            }
            email.setSubject(lstOfDataInputsForEmail.get(0).emailSubject);
            email.setHTMLBody(lstOfDataInputsForEmail.get(0).emailBody);
            email.settoaddresses(lstOfDataInputsForEmail.get(0).toEmailAddress);
            try {
                Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>{email};
                Messaging.SendEmailResult[] results = Messaging.sendEMail(messages);
            } catch(Exception e) {
                ApexExceptions.emit('AgreementSendEmailForOpenOfferAgreement', e);
            }
           
            ilib_LogEvent.pop();
     }
    /**
    *  @author      : Himanshu
    *  @description : wrapper class for Storing Invocable variables that will be passed through the flow
    *  @param       : NA
    *  @return      : NA
    **/ 
    public class DataInputsForEmail{
        @InvocableVariable(label='strEMailBody' description = 'Email body to be sent' required =false)
        public string emailBody;
        @InvocableVariable(label='strEmailAddress' description = 'Email Address of the Affiliates' required =false)
        public List<String> ccEmailAddress;    
        @InvocableVariable(label='strEmailSubject' description = 'Email Subject For Approved/Rejected' required =false)
        public string emailSubject;
        @InvocableVariable(label='strEmailRecipient' description = 'Email Address Of TAM' required =false)
        public List<String> toEmailAddress;
    }

}