/**
 *   @author: Deep Diwakar
*    @date:   July-12-2023
*    @description: Test class class for PardotContactsResignationSync. Other scenarios are covered through TestContact and 
*                  TestPardotResignationNtfQueueable
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*        Deep Diwakar       July-12-2023         DCP-60096: Test class for platform event subscriber trigger
*    --------------------------------------------------------------------------------------------------
 */

@isTest
private class TestPardotContactsResignationSync {

    @isTest
    static void testPardotSyncResigEvent() {

        PardotContactResignationSync__e event1 = new PardotContactResignationSync__e();
        event1.Contact_Email__c = 'pardot_resignation_event1@testing.com';

        PardotContactResignationSync__e event2 = new PardotContactResignationSync__e();
        event2.Contact_Email__c = 'pardot_resignation_event2@testing.com';

        PardotContactResignationSync__e event3 = new PardotContactResignationSync__e();
        event3.Contact_Email__c = 'pardot_resignation_event3@testing.com';


        List<PardotContactResignationSync__e> eventList = new List<PardotContactResignationSync__e>();

        eventList.add(event1);
        eventList.add(event2);
        eventList.add(event3);

        // Reusing Sync Attribution Form Handler response as Pardot Form Hanlder response remains exactly same
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('PardotSynCampaignAttributionMoc');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        Database.SaveResult[] srList = EventBus.publish(eventList); 
        Test.stopTest();

        Boolean result = true;
        for (Database.SaveResult sr : srList) {
            if (!sr.isSuccess()) {
                result = false;
            }
        }

        Assert.isTrue(result, 'Platform event did not publish correctly!');

    }

}