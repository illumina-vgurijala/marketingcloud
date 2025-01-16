/**
 *   @author: Deep Diwakar
*    @date:   March-23-2022
*    @description: Test class class for PardotCattrMediaCodeQueueable
*    @Test Class: TestPardotMediaCodeSyncQueueable
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*        Deep Diwakar       March-23-2023        DCP-59535: Test class for campaign attribution - media code sync queuable and sender
*        Deep Diwakar       June-14-2023         CMCM-1164: Adjusted test methods to execute based on platform event implementation
*    --------------------------------------------------------------------------------------------------
 */

@IsTest
private class TestPardotCattrMediaCodeQueueable {


     /**
      * @author: Deep Diwakar
      * @date: March-23-2022
      * @description: test data setup method
      * @param: NA
      * @return: NA
      */
      @testSetup
      static void testSetup() {
          Lead testLead = TestDataMarketing.createLeadForMarketable('PardotTest', 'MediaCode', 'pardot_media_code@testing.com', 'USA', 'Media Code Testing Inc');
          insert testLead;
      }

    /**
      * @author: Deep Diwakar
      * @date: March-23-2022
      * @description: Test method for queueable and callout
      * @param: NA
      * @return: NA
      */
     @isTest
     static void testMediaCodeSyncQueueable() {

         Lead testLead = [SELECT Id, Name, Email FROM Lead WHERE Email = 'pardot_media_code@testing.com']; 
         testLead.Media_Code__c = 'Media Code Testing';

         Map<String, Map<String, Boolean>> emailToSyncFieldsMap = new Map<String, Map<String, Boolean>>();
         Map<String, Boolean> syncFieldMap = new Map<String, Boolean>();
         syncFieldMap.put('MediaCode', true);
         emailToSyncFieldsMap.put(testLead.Email, syncFieldMap);
 
         // Setting up mock response for Resignation Form Handler.
         // Reusing Sync Attribution Form Handler response as Pardot Form Hanlder response remains exactly same
         StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
         mock.setStaticResource('PardotSynCampaignAttributionMoc');
         mock.setStatusCode(200);
         mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
         // Associate the callout with a mock response
         Test.setMock(HttpCalloutMock.class, mock);
 
         Test.startTest();
         PardotCattrMediaCodeQueueable queueable = new PardotCattrMediaCodeQueueable(emailToSyncFieldsMap);
         System.enqueueJob(queueable);
         Test.stopTest();
 
         // query Interface_Log__c to check result
         Interface_Log__c log = [Select Id, Interface_Name__c, Result__c From Interface_Log__c where Interface_Name__c = 'PardotCattrMediaCodeSender'];
         System.assertEquals('Success', log.Result__c, 'PardotCattrMediaCodeSender queueable did not work correctly in success scenario!');
 
     }

         /**
      * @author: Deep Diwakar
      * @date: March-23-2022
      * @description: Test method for failure scenario
      * @param: NA
      * @return: NA
      */
      @isTest
      static void testMediaCodeFailure() {

        Lead testLead = [SELECT Id, Name, Email FROM Lead WHERE Email = 'pardot_media_code@testing.com']; 
        testLead.Media_Code__c = 'Media Code Testing';

        Map<String, Map<String, Boolean>> emailToSyncFieldsMap = new Map<String, Map<String, Boolean>>();
        Map<String, Boolean> syncFieldMap = new Map<String, Boolean>();
        syncFieldMap.put('MediaCode', true);
        emailToSyncFieldsMap.put(testLead.Email, syncFieldMap);
  
        // Setting up mock response for Resignation Form Handler.
        // Reusing Sync Attribution Form Handler response as Pardot Form Hanlder response remains exactly same
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('PardotSynCampaignAttributionMoc');
        mock.setStatusCode(400);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        PardotCattrMediaCodeQueueable queueable = new PardotCattrMediaCodeQueueable(emailToSyncFieldsMap);
        System.enqueueJob(queueable);
        Test.stopTest();

        // query Interface_Log__c to check result
        Interface_Log__c log = [Select Id, Interface_Name__c, Result__c From Interface_Log__c where Interface_Name__c = 'PardotCattrMediaCodeSender'];
        System.assertEquals('Fail', log.Result__c, 'PardotCattrMediaCodeSender queueable did not work correctly in failure scenario!');
 
      }

         /**
      * @author: Deep Diwakar
      * @date: March-23-2022
      * @description: Test method for queueable and callout
      * @param: NA
      * @return: NA
      */
     @isTest
     static void testCattrSyncQueueable() {

        Lead testLead = [SELECT Id, Name, Email FROM Lead WHERE Email = 'pardot_media_code@testing.com']; 
        testLead.Campaign_Attribution__c = 'Campaign Attribution Testing';

        Map<String, Map<String, Boolean>> emailToSyncFieldsMap = new Map<String, Map<String, Boolean>>();
        Map<String, Boolean> syncFieldMap = new Map<String, Boolean>();
        syncFieldMap.put('Cattr', true);
        emailToSyncFieldsMap.put(testLead.Email, syncFieldMap);
 
         // Setting up mock response for Resignation Form Handler.
         // Reusing Sync Attribution Form Handler response as Pardot Form Hanlder response remains exactly same
         StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
         mock.setStaticResource('PardotSynCampaignAttributionMoc');
         mock.setStatusCode(200);
         mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
         // Associate the callout with a mock response
         Test.setMock(HttpCalloutMock.class, mock);
 
         Test.startTest();
         PardotCattrMediaCodeQueueable queueable = new PardotCattrMediaCodeQueueable(emailToSyncFieldsMap);
         System.enqueueJob(queueable);
         Test.stopTest();
 
         // query Interface_Log__c to check result
         Interface_Log__c log = [Select Id, Interface_Name__c, Result__c From Interface_Log__c where Interface_Name__c = 'PardotCattrMediaCodeSender'];
         System.assertEquals('Success', log.Result__c, 'PardotCattrMediaCodeSender queueable did not work correctly in success scenario!');
 
     }

         /**
      * @author: Deep Diwakar
      * @date: March-23-2022
      * @description: Test method for failure scenario
      * @param: NA
      * @return: NA
      */
      @isTest
      static void testCattrSyncFailure() {

        Lead testLead = [SELECT Id, Name, Email FROM Lead WHERE Email = 'pardot_media_code@testing.com']; 
        testLead.Campaign_Attribution__c = 'Campaign Attribution Testing';

        Map<String, Map<String, Boolean>> emailToSyncFieldsMap = new Map<String, Map<String, Boolean>>();
        Map<String, Boolean> syncFieldMap = new Map<String, Boolean>();
        syncFieldMap.put('Cattr', true);
        emailToSyncFieldsMap.put(testLead.Email, syncFieldMap);
  
        // Setting up mock response for Resignation Form Handler.
        // Reusing Sync Attribution Form Handler response as Pardot Form Hanlder response remains exactly same
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('PardotSynCampaignAttributionMoc');
        mock.setStatusCode(400);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        PardotCattrMediaCodeQueueable queueable = new PardotCattrMediaCodeQueueable(emailToSyncFieldsMap);
        System.enqueueJob(queueable);
        Test.stopTest();

        // query Interface_Log__c to check result
        Interface_Log__c log = [Select Id, Interface_Name__c, Result__c From Interface_Log__c where Interface_Name__c = 'PardotCattrMediaCodeSender'];
        System.assertEquals('Fail', log.Result__c, 'PardotCattrMediaCodeSender queueable did not work correctly in failure scenario!');
 
      }


    /**
      * @author: Deep Diwakar
      * @date: March-23-2022
      * @description: Test method for queueable and callout
      * @param: NA
      * @return: NA
      */
     @isTest
     static void testCattrMediaCodeSyncQueueable() {

        Lead testLead = [SELECT Id, Name, Email FROM Lead WHERE Email = 'pardot_media_code@testing.com']; 
        testLead.Campaign_Attribution__c = 'Campaign Attribution Testing';
        testLead.Media_Code__c = 'Media Code Testing';

        Map<String, Map<String, Boolean>> emailToSyncFieldsMap = new Map<String, Map<String, Boolean>>();
        Map<String, Boolean> syncFieldMap = new Map<String, Boolean>();
        syncFieldMap.put('Cattr', true);
        syncFieldMap.put('MediaCode', true);
        emailToSyncFieldsMap.put(testLead.Email, syncFieldMap);
 
         // Setting up mock response for Resignation Form Handler.
         // Reusing Sync Attribution Form Handler response as Pardot Form Hanlder response remains exactly same
         StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
         mock.setStaticResource('PardotSynCampaignAttributionMoc');
         mock.setStatusCode(200);
         mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
         // Associate the callout with a mock response
         Test.setMock(HttpCalloutMock.class, mock);
 
         Test.startTest();
         PardotCattrMediaCodeQueueable queueable = new PardotCattrMediaCodeQueueable(emailToSyncFieldsMap);
         System.enqueueJob(queueable);
         Test.stopTest();
 
         // query Interface_Log__c to check result
         Interface_Log__c log = [Select Id, Interface_Name__c, Result__c From Interface_Log__c where Interface_Name__c = 'PardotCattrMediaCodeSender'];
         System.assertEquals('Success', log.Result__c, 'PardotCattrMediaCodeSender queueable did not work correctly in success scenario!');
 
     }

    /**
     * @author: Deep Diwakar
    * @date: March-23-2022
    * @description: Test method for catch block
    * @param: NA
    * @return: NA
    */
    @IsTest
    static void testCatchBlock() {

    Boolean exceptionThrown = false;

    Lead testLead = [SELECT Id, Name, Email FROM Lead WHERE Email = 'pardot_media_code@testing.com']; 
    testLead.Media_Code__c = 'Media Code Testing';

    Map<String, Map<String, Boolean>> emailToSyncFieldsMap = new Map<String, Map<String, Boolean>>();
    Map<String, Boolean> syncFieldMap = new Map<String, Boolean>();
    syncFieldMap.put('MediaCode', true);
    emailToSyncFieldsMap.put(testLead.Email, syncFieldMap);


    try {

        Test.startTest();
        PardotCattrMediaCodeQueueable queueable = new PardotCattrMediaCodeQueueable(emailToSyncFieldsMap);
        queueable.testCodeCoverage = true;
        System.enqueueJob(queueable);
        Test.stopTest();

    } catch(Exception ex) {
        exceptionThrown = ex.getMessage().contains('Test exception to cover catch block');
    }

    System.assert(exceptionThrown, 'Catch block did not throw exception properly');

    }

}