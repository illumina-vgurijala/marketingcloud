@isTest
private class TestEmailBuilder {

    private final static String TEMPLATE_NAME = 'Master_Data_Request_Address_Change_Request';
    private final static String SUBJECT = 'test class';
    private final static String HTMLBODY = '<br>Email Body</br>';
    private final static String SENDER = 'Unit Tester';
    private final static Id RECIP_ID = UserInfo.getUserId();
    private final static String RECIP_EMAIL = 'scooby@doo.com';
    private final static String CC_EMAIL = 'scrappy@doo.com';

    @isTest
    static void subjectAndBody()
    {
        Test.startTest();

        Messaging.SingleEmailMessage email = 
            new EmailBuilder(UserInfo.getUserId()) // target ID
            .addSubject(SUBJECT)
            .addHtmlBody(HTMLBODY)
            .setSenderDisplayName(SENDER)
            .emailMessage(); // get built-up email

        Test.stopTest();

        System.assertEquals(SUBJECT, email.getSubject());
        System.assertEquals(HTMLBODY, email.getHtmlBody());
        System.assertEquals(SENDER, email.getSenderDisplayName());
    }

    @isTest
    static void templateAndTarget()
    {
        Id emailTemplateId = new EmailTemplatesSelector().selectByNameOrDeveloperName(new List<String> {TEMPLATE_NAME}).get(0).Id;

        Test.startTest();

        Messaging.SingleEmailMessage email = 
            new EmailBuilder(emailTemplateId, RECIP_ID)
            .addTo(new List<String> {RECIP_EMAIL})
            .doNotSendToTargetId()
            .addCc(new List<String> {CC_EMAIL})
            .emailMessage();

        Test.stopTest();

        System.assertEquals(RECIP_ID, email.getTargetObjectId());
        System.assertEquals(RECIP_EMAIL, email.getToAddresses().get(0));
        System.assertEquals(CC_EMAIL, email.getCcAddresses().get(0));
    }

    @isTest
    static void templateAndEmail()
    {
        Id emailTemplateId = new EmailTemplatesSelector().selectByNameOrDeveloperName(new List<String> {TEMPLATE_NAME}).get(0).Id;
        Account a = TestDataAccount.getNewAccount();

        Test.startTest();

        Messaging.SingleEmailMessage email = 
            new EmailBuilder(emailTemplateId, RECIP_EMAIL)
            .addWhatId(a.Id)
            .emailMessage();

        Test.stopTest();

        System.assertEquals(a.Id, email.getWhatId());
    }

    @isTest
    static void templateAndEmails()
    {
        Id emailTemplateId = new EmailTemplatesSelector().selectByNameOrDeveloperName(new List<String> {TEMPLATE_NAME}).get(0).Id;

        Test.startTest();

        Messaging.SingleEmailMessage email = 
            new EmailBuilder(emailTemplateId, new List<String> {RECIP_EMAIL})
            .emailMessage();

        Test.stopTest();

        System.assertEquals(emailTemplateId, email.getTemplateId());
    }

}