/**
 *   @author: Deep Diwakar
*    @date:   25-Sept-2022
*    @description: Test class class for PardotResignationNotificationQueueable and PardotResignationNotificationSender
*    @Test Class: TestPardotResignationNtfQueueable
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*        Deep Diwakar       25-Sept-2022        PM-911: Initial build
*        Deep Diwakar       July-12-2023        DCP-60096: Added test methods for this story
*    --------------------------------------------------------------------------------------------------
 */

 @isTest
 private class TestPardotResignationNtfQueueable {
 
     /**
      * @author: Deep Diwakar
      * @date: 25-Sept-2022
      * @description: test data setup method
      * @param: NA
      * @return: NA
      */
     @testSetup
     static void testSetup() {
         TestDataMarketing.createContact('Pardot', 'Resignation', 'pardot_resig@test.com');
     }
 
     /**
      * @author: Deep Diwakar
      * @date: 25-Sept-2022
      * @description: Test method for queueable and callout
      * @param: NA
      * @return: NA
      */
     @isTest
     static void testResignedNotificationQueueable() {
         Contact testCont = [Select Id, FirstName, LastName, Resigned_R_Q__c, Email From Contact where Email = 'pardot_resig@test.com'];
 
         // Setting up mock response for Resignation Form Handler.
         // Reusing Sync Attribution Form Handler response as Pardot Form Hanlder response remains exactly same
         StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
         mock.setStaticResource('PardotSynCampaignAttributionMoc');
         mock.setStatusCode(200);
         mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
         // Associate the callout with a mock response
         Test.setMock(HttpCalloutMock.class, mock);
 
         Test.startTest();
         PardotResignationNotificationQueueable queueable = new PardotResignationNotificationQueueable(testCont.Email);
         System.enqueueJob(queueable);
         Test.stopTest();
 
         // query Interface_Log__c to check result
         Interface_Log__c log = [Select Id, Interface_Name__c, Result__c From Interface_Log__c where Interface_Name__c = 'PardotResignationNotificationSender'];
         System.assertEquals('Success', log.Result__c, 'PardotResignationNotificationSender queueable did not work correctly!');
 
     }
 
     @isTest
     static void testResignedNotificationQueueableList() {
         Contact testCont = [Select Id, FirstName, LastName, Resigned_R_Q__c, Email From Contact where Email = 'pardot_resig@test.com'];
         List<String> emailList = new List<String>();
         emailList.add(testCont.Email);
 
         // Setting up mock response for Resignation Form Handler.
         // Reusing Sync Attribution Form Handler response as Pardot Form Hanlder response remains exactly same
         StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
         mock.setStaticResource('PardotSynCampaignAttributionMoc');
         mock.setStatusCode(200);
         mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
         // Associate the callout with a mock response
         Test.setMock(HttpCalloutMock.class, mock);
 
         Test.startTest();
         PardotResignationNotificationQueueable queueable = new PardotResignationNotificationQueueable(emailList);
         System.enqueueJob(queueable);
         Test.stopTest();
 
         // query Interface_Log__c to check result
         Interface_Log__c log = [Select Id, Interface_Name__c, Result__c From Interface_Log__c where Interface_Name__c = 'PardotResignationNotificationSender'];
         System.assertEquals('Success', log.Result__c, 'PardotResignationNotificationSender queueable did not work correctly!');
 
     }
 
     @isTest
     static void testResignedNotificationQueueableFailure() {
         Contact testCont = [Select Id, FirstName, LastName, Resigned_R_Q__c, Email From Contact where Email = 'pardot_resig@test.com'];
         List<String> emailList = new List<String>();
         emailList.add(testCont.Email);
 
         // Setting up mock response for Resignation Form Handler.
         // Reusing Sync Attribution Form Handler response as Pardot Form Hanlder response remains exactly same
         StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
         mock.setStaticResource('PardotSynCampaignAttributionMoc');
         mock.setStatusCode(400);
         mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
         // Associate the callout with a mock response
         Test.setMock(HttpCalloutMock.class, mock);
 
         Test.startTest();
         PardotResignationNotificationQueueable queueable = new PardotResignationNotificationQueueable(emailList);
         System.enqueueJob(queueable);
         Test.stopTest();
 
         // query Interface_Log__c to check result
         Interface_Log__c log = [Select Id, Interface_Name__c, Result__c From Interface_Log__c where Interface_Name__c = 'PardotResignationNotificationSender'];
         System.assertEquals('Fail', log.Result__c, 'PardotResignationNotificationSender queueable did not work correctly!');
 
     }
 
     @isTest
     static void testResignedNotificationQueueableCatchBlock() {
 
         Boolean exceptionThrown = false;
 
         Contact testCont = [Select Id, FirstName, LastName, Resigned_R_Q__c, Email From Contact where Email = 'pardot_resig@test.com'];
         List<String> emailList = new List<String>();
         emailList.add(testCont.Email);
 
         try {
             Test.startTest();
             PardotResignationNotificationQueueable queueable = new PardotResignationNotificationQueueable(emailList);
             queueable.testCodeCoverage = true;
             System.enqueueJob(queueable);
             Test.stopTest();
 
         } catch(Exception ex) {
             exceptionThrown = ex.getMessage().contains('Test exception to cover catch block');
         }
     
         System.assert(exceptionThrown, 'Catch block did not throw exception properly');
 
     }
 
 }