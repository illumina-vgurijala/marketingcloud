/*
* Not a functional class.  Used in ilib_ScheduledNotificationsTest only
*/
public with sharing class ilib_ScheduledNotificationsTestImpl extends ilib_ScheduledNotifications
{
    /* dummy commetn */
    public override String getQuery()
    {
        return 'SELECT Id, Email FROM User WHERE UserType = \'Standard\' AND IsActive = true LIMIT 20';
    }

    /* dummy commetn */
    public override Messaging.SingleEmailMessage createEmail(SObject record)
    {
        return new EmailBuilder(record.Id)
            .addSubject('Test Subject')
            .addHtmlBody('Test Body')
            .emailMessage();
    }

}