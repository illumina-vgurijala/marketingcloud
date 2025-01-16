/**
* @author Akash Kumar
* @date :   2018-08-22
* @description :   US-11936: Email Method to for sending Notification when Sold To,UC or Distributor Changes
* Modification Log:
* ------------------------------------------------------------------------------------ 
*       Akash Kumar         2018-10-07            Original Version
*       Himanshu            2022-03-29             Code Scan Fixes 
* ------------------------------------------------------------------------------------    
*/

public class AutomateEmailMethodOnAccountChange {
    /*
    *  @author       : Akash Kumar
    *  @description  : Email Method to for sending Notification when Sold To,UC or Distributor Changes
    *  @param        : String strToEmail,String strTemplateName,String strOppId
    *  @return       : void
    */
	public static void sendEmailOnAccountChange(String strToEmail,String strTemplateName,String strOppId){
    System.debug('strToEmail--->' +strToEmail);
    List<EmailTemplate> lstTemplate = new EmailTemplatesSelector().selectByNameOrDeveloperName(new List<String>{strTemplateName});
    System.debug('objTemplate-->' +lstTemplate[0].Id);
    List<Messaging.SingleEmailMessage> lstMails = new List<Messaging.SingleEmailMessage>();
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setWhatId(strOppId);
    mail.setTargetObjectId (strToEmail);
    mail.setTemplateID(lstTemplate[0].Id); 
    mail.setSaveAsActivity(false);
    lstMails.add(mail);
    Messaging.SendEmailResult[] results = Messaging.sendEmail(lstMails);
    if (results[0].success) {
    System.debug('The email was sent successfully.');
    } else {
    System.debug('The email failed to send: '
          + results[0].errors[0].message);
    }
    }
}