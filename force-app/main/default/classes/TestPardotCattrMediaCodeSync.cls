/**
 *   @author: Deep Diwakar
*    @date:   June-14-2023
*    @description: Test class class for PardotCattrMediaCodeSync. Other scenarios are covered through TestCampaignMembers and 
*                  TestPardotCattrMediaCodeQueueable
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*        Deep Diwakar       June-14-2023         CMCM-1164: Test class for platform event subscriber trigger
*    --------------------------------------------------------------------------------------------------
 */

@isTest
private class TestPardotCattrMediaCodeSync {


    @isTest
    static void testPardotSyncPlatEventDelivery() {

        PardotCattrMediaCodeSync__e event1 = new PardotCattrMediaCodeSync__e();
        event1.Email__c = 'pardotsyncevent1@testing.com';
        event1.Cattr__c = true;
        event1.Media_Code__c = true;

        PardotCattrMediaCodeSync__e event2 = new PardotCattrMediaCodeSync__e();
        event2.Email__c = 'pardotsyncevent2@testing.com';
        event2.Cattr__c = false;
        event2.Media_Code__c = true;

        PardotCattrMediaCodeSync__e event3 = new PardotCattrMediaCodeSync__e();
        event3.Email__c = 'pardotsyncevent3@testing.com';
        event3.Cattr__c = true;
        event3.Media_Code__c = false;

        List<PardotCattrMediaCodeSync__e> eventList = new List<PardotCattrMediaCodeSync__e>();
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

        System.assert(result, 'Platform event did not publish correctly!');
     
    }

}