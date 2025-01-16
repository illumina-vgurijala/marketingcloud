@isTest
private class ilib_ScheduledNotificationsTest {

    @isTest
    static void runBatch()
    {
        Test.startTest();
        Database.executeBatch(new ilib_ScheduledNotificationsTestImpl());
        Test.stopTest();

        // nothing to assert
    }

    @isTest
    static void templateId()
    {
        EmailTemplate extantTemplate = [SELECT Id, DeveloperName FROM EmailTemplate LIMIT 1].get(0);

        Test.startTest();
        ilib_ScheduledNotificationsTestImpl impl = new ilib_ScheduledNotificationsTestImpl();
        Id templateId = impl.getTemplateId(extantTemplate.DeveloperName);
        Test.stopTest();

        System.assertEquals(extantTemplate.Id, templateId);
    }

}