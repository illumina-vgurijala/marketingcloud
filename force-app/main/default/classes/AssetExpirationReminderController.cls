/**
* @author      : Indra Ganesan
* @date        : 2018-10-28
* @description : Controller class To Set the Variables to be accessed from Template
* Modification Log 
* --------------------------------------------------------------------------------------------- 
*       Developer            Date                Description
*       Indra Ganesan        2018-10-28          Original Version
*       Roopal Verma         2019-07-15          Enabled with sharing for the class
*       Ashwin Kumar         2021-08-23          TASK0587523 - Update class to accept VF component inputs from Batch class and send email
* ---------------------------------------------------------------------------------------------   
*/
public with sharing class AssetExpirationReminderController {

    public static List<EmailTemplate> lstTemplate = new EmailTemplatesSelector().selectByNameOrDeveloperName(new List<String>{Label.AssetLine_Template_DeveloperName});
    private static final String LOG_TITLE = 'AssetExpirationReminderController';
    public static Boolean boolIsEmailSentFromTest = false;

    public String strAssetId {get; set;}
    public Apttus_Config2__AssetLineItem__c objALI {
        get {
          objALI = [SELECT Id, Apttus_Config2__AccountId__r.ERP_Customer_Id__c, Apttus_Config2__AccountId__r.Name, 
                    Apttus_Config2__AccountId__r.Territory_Name__c, Apttus_Config2__AccountId__r.Territory_Region__c, 
                    Apttus_Config2__ProductId__r.Family, Apttus_Config2__ProductId__r.ProductCode, Serial_Number__c,
                    Contract_Number__c, Contract_Type__c, Apttus_Config2__StartDate__c, Apttus_Config2__EndDate__c,
                    Status__c, Primary_Contact__c, Primary_Contact__r.Email
                    FROM Apttus_Config2__AssetLineItem__c WHERE id =:strAssetId];
          return objALI; }
       set;
    }

    /**
    *  @author Ashwin Kumar
    *  @description method to prepare VF component inputs and send email 
    *  @param map of Asset Id to List of recipient userIds
    *  @return void
    **/
    public static void sendEmailOnRenewalExpiration(Map<Id, List<Id>> mapAssetIdToRecipientEmails) {
        try {
            ilib_LogEvent.push(LOG_TITLE + '.sendEmailOnRenewalExpiration()');
            List<Messaging.SingleEmailMessage> lstMailsForAllAssets = new List<Messaging.SingleEmailMessage>();
            for(Id assetLineId : mapAssetIdToRecipientEmails.keyset()) {
                if(!(mapAssetIdToRecipientEmails.get(assetLineId)).isEmpty()) {
                    List<String> lstUserIds = mapAssetIdToRecipientEmails.get(assetLineId);
                    ilib_LogEvent.message('Recipient User Ids for an Asset: '+assetLineId+': '+String.join(lstUserIds, ', '));
                    for(Id userId: lstUserIds) {
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setWhatId(assetLineId);
                        mail.setTargetObjectId(userId);
                        mail.setTemplateID(lstTemplate[0].Id);
                        mail.setSaveAsActivity(false);
                        lstMailsForAllAssets.add(mail);
                    }
                }
            }
            Messaging.SendEmailResult[] results = Messaging.sendEmail(lstMailsForAllAssets);
            boolIsEmailSentFromTest = Test.isRunningTest() && !results.isEmpty() && results[0].success ? true : boolIsEmailSentFromTest;
            ilib_LogEvent.pop();
        } catch(Exception ex) {
            ApexExceptions.emit(LOG_TITLE + '.sendEmailOnRenewalExpiration()', ex);
        }
    }
}