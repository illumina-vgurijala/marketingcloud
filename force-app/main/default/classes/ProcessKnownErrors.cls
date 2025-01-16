/**
*    @author Satya Swain
*    @date   2019-05-28
*    @description   Domain class to handle the type of notification to be sent to user.
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Satya Swain                 28 May 2019            Initial Version
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class ProcessKnownErrors {

    /**
    * @owner Satya Swain
    * @description Processes the known error notification errors and prepares to send notifications to appropriate users
    */
    @InvocableMethod(Label='NotifyUsersBasedOnKnownErrors')
    public static void handleKnownErrors(List<Id> recordIds)
    {
        System.debug('Notification Ids: ' + recordIds); 
        if (recordIds.isEmpty()) return;

        try
        {
            List<Error_Notification__c> notifications = [
                SELECT Id, Source__c, Interface_Log__c, ERP_Record_Id__c, Account__c, Result__c, Full_Error_Text__c, RecordTypeId,
                    Known_Error_Notification__c, Known_Error_Notification__r.Notification_Type__c, Known_Error_Notification__r.Recipients__c,
                    Known_Error_Notification__r.Message__c
                FROM Error_Notification__c
                WHERE Id IN :recordIds];

            List<Error_Notification__c> emailNotifications = new List<Error_Notification__c>();
            List<Error_Notification__c> chatterNotifications = new List<Error_Notification__c>();

            //Identify which record needs email notification and which needs chatter notification
            for (Error_Notification__c n : notifications)
            {
                if (n.Known_Error_Notification__r.Notification_Type__c.contains('Email'))
                    emailNotifications.add(n);

                if (n.Known_Error_Notification__r.Notification_Type__c.contains('Chatter'))
                    chatterNotifications.add(n);
            }
            System.debug('@@@ emailNotifications : ' + emailNotifications);
            System.debug('@@@ chatterNotifications : ' + chatterNotifications);

            NotifyUsers notifier = new NotifyUsers();
            if (!emailNotifications.isEmpty()) notifier.notifyViaEmail(emailNotifications);
            if (!chatterNotifications.isEmpty()) notifier.notifyViaChatter(chatterNotifications);
        }

        catch (Exception e)
        {
            // this code should not cause user issues, trap exceptions here
            System.debug(e.getMessage());
        }
    }

}