/**
*    @author Satya Swain
*    @date   2019-05-28
*    @description   Logic to send email and chatter post to user regarding the details of error occured.
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Satya Swain                 28 May 2019            Initial Version
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class NotifyUsers { //extends NotificationsHandler

    /**
    * @owner Satya Swain
    * @description Send Notification to users via email 
    */
    public void notifyViaEmail(List<Error_Notification__c> notifications)
    {
        if (notifications == null) return;

        try
        {
            List<Messaging.SingleEmailMessage> lstMails = new List<Messaging.SingleEmailMessage>();

            for (Error_Notification__c notification : notifications)
            {
                // identify users to whom email is to be sent
                String userIds = notification.Known_Error_Notification__r.Recipients__c;
                Set<Id> setUserIds = new Set<Id>((List<Id>)userIds.split(';'));

                for (Id idRecipient : setUserIds)
                {
                    if (idRecipient == null) continue;

                    String emailBody = 'Interface Exception occurred. Details below: \n\n '
                        + notification.Known_Error_Notification__r.Message__c + '\n\n'
                        + 'Error details here: ' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + notification.Id;
                    // In future add option to give full error text (not appropriate for most users)
                    // + 'Full error text\n\n' + notification.Full_Error_Text__c

                    //create email message to be sent
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setWhatId(notification.Interface_Log__c);
                    mail.setTargetObjectId(idRecipient);
                    mail.setSubject(notification.Source__c + ' Error Occurred');
                    mail.setPlainTextBody(emailBody);
                    mail.setSaveAsActivity(false);

                    lstMails.add(mail);
                }
            }

            System.debug('@@@ lstmails: ' + lstMails);
            if (lstMails.size() > 0)
            {
                List<Messaging.SendEmailResult> lstEmailResults = Messaging.sendEmail(lstMails);
                if (lstEmailResults.get(0).success)
                {
                    System.debug('The email was sent successfully.');
                }
                else
                {
                    System.debug('The email failed to send: '+ lstEmailResults.get(0).errors.get(0).message);
                }
            }
        }
        catch (Exception e)
        {
            // this code should not cause user issues, trap exceptions here
            System.debug(e.getMessage());
        }
    }

    /**
    * @owner Satya Swain
    * @description Send Notification to users via chatter mention 
    */
    public void notifyViaChatter(List<Error_Notification__c> notifications)
    {
        if (notifications == null) return;

        List<FeedItem> lstPost = new List<FeedItem>();
        List<Id> lstUserIds = new List<Id>();

        for (Error_Notification__c notification : notifications)
        {
            String userIds = notification.Known_Error_Notification__r.Recipients__c;
            lstUserIds = (List<Id>)userIds.split(';');

            for (Id userId : lstUserIds)
            {
                // create feed item for every user in the recipient field
                lstPost.add(new FeedItem(
                    ParentId = userId,
                    Body = 'Interface Exception occurred. Details below: \n ' + notification.Known_Error_Notification__r.Message__c + '\n'
                        + 'Error details here: ' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + notification.Interface_Log__c
                ));
            }
        }

        System.debug('@@@ lstPost: '+lstPost);
        if (lstPost.size()>0)
            insert lstPost;
    }

}