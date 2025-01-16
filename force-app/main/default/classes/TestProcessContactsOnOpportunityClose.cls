/**
 *   @author: Deep Diwakar
*    @date:   July-10-2023
*    @description: Test class for Platform event subscriber trigger handler class ProcessContactOnOpportunityClose
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       July-10-2023        DCP-60098: Test class for Platform event subscriber trigger handler class ProcessContactOnOpportunityClose
*    --------------------------------------------------------------------------------------------------
 */

 @isTest
 private class TestProcessContactsOnOpportunityClose {
 
     @TestSetup
     static void createTestData() {
         Account testAcct = TestDataAccount.getAccount('Test Contact Recycle Waterfall');
         insert testAcct;
 
         Contact testCont = TestDataPerson.initContact(testAcct.Id);
         testCont.Marketing_Contact_Status__c = 'Open Opportunity';
         insert testCont;
 
         Opportunity testOpptyFunnel = TestDataOpportunity.initOpportunity(testAcct);
         testOpptyFunnel.LeadSource = 'Funnel Marketing';
         testOpptyFunnel.StageName = 'Create';
         //testOpptyFunnel.Competitor_Name__c = '';
         insert testOpptyFunnel;
 
         OpportunityContactRole testOcr = TestDataOpportunity.getNewOpportunityContactRole('Power Sponsor', testCont.Id, testOpptyFunnel.Id);
         insert testOcr;
 
         //Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId()
         
     }
 
     @isTest
     static void testContUpdatesClosedWonOppty() {
         Opportunity testOppty = [SELECT Id, StageName FROM Opportunity WHERE LeadSource = 'Funnel Marketing' LIMIT 1];
         testOppty.StageName = 'Closed Won';
 
         Test.startTest();
         update testOppty;
         Test.getEventBus().deliver();
         Test.stopTest();
 
         OpportunityContactRole ocrResult = [SELECT Id, Contact.Marketing_Contact_Status__c, Contact.Waterfall_Stage__c, Contact.Waterfall_Closed_Won_Date__c FROM OpportunityContactRole WHERE OpportunityId =: testOppty.Id];
 
         Assert.isNotNull(ocrResult.Contact.Waterfall_Closed_Won_Date__c, 'Waterfall Closed Won data did not set');
         Assert.areEqual('Recycled', ocrResult.Contact.Marketing_Contact_Status__c, 'Contact status did not change to Recycled');
 
     }
 
     @isTest
     static void testContUpdatesClosedLostOppty() {
         Opportunity testOppty = [SELECT Id, StageName FROM Opportunity WHERE LeadSource = 'Funnel Marketing' LIMIT 1];
         testOppty.StageName = 'Closed Lost';
 
         Test.startTest();
         update testOppty;
         Test.getEventBus().deliver();
         Test.stopTest();
 
         OpportunityContactRole ocrResult = [SELECT Id, Contact.Marketing_Contact_Status__c, Contact.Waterfall_Stage__c, Contact.Waterfall_Closed_Won_Date__c FROM OpportunityContactRole WHERE OpportunityId =: testOppty.Id];
 
         Assert.isNull(ocrResult.Contact.Waterfall_Closed_Won_Date__c, 'Waterfall Closed Won data incorrectly set');
         Assert.isTrue(String.isBlank(ocrResult.Contact.Waterfall_stage__c), 'Waterfall stage did not clear');
         Assert.areEqual('Recycled', ocrResult.Contact.Marketing_Contact_Status__c, 'Contact status did not change to Recycled');
 
 
     }
 
     @isTest
     static void testRecycleWithOpenOppty() {
 
         Contact testCont = [SELECT Id FROM Contact LIMIT 1];
         Account testAcct = [SELECT Id FROM Account LIMIT 1];
 
         Opportunity testOpptyNotFunnel = TestDataOpportunity.initOpportunity(testAcct);
         testOpptyNotFunnel.StageName = 'Create';
         insert testOpptyNotFunnel;
 
         OpportunityContactRole testOcr = TestDataOpportunity.getNewOpportunityContactRole('Power Sponsor', testCont.Id, testOpptyNotFunnel.Id);
         insert testOcr;
 
         Opportunity testOpptyFunnel = [SELECT Id, StageName FROM Opportunity WHERE LeadSource = 'Funnel Marketing' LIMIT 1];
         testOpptyFunnel.StageName = 'Closed Won';
 
         Test.startTest();
         update testOpptyFunnel;
         Test.getEventBus().deliver();
         Test.stopTest();
 
         OpportunityContactRole ocrResult = [SELECT Id, Contact.Marketing_Contact_Status__c, Contact.Waterfall_Stage__c, Contact.Waterfall_Closed_Won_Date__c FROM OpportunityContactRole WHERE OpportunityId =: testOpptyFunnel.Id];
 
         Assert.isNotNull(ocrResult.Contact.Waterfall_Closed_Won_Date__c, 'Waterfall Closed Won data did not set');
         Assert.areEqual('Open Opportunity', ocrResult.Contact.Marketing_Contact_Status__c, 'Contact status changed incorrectly');
 
     }
 
 
     @isTest
     static void testRecycleWithMultipleUser() {
 
         Contact testCont = [SELECT Id FROM Contact LIMIT 1];
         Account testAcct = [SELECT Id FROM Account LIMIT 1];
 
         User salesUser = TestDataUser.findUserInProfile('Sales User');
 
         System.runAs(salesUser) {
             Opportunity testOpptySalesUser = TestDataOpportunity.initOpportunity(testAcct);
             testOpptySalesUser.StageName = 'Create';
             testOpptySalesUser.LeadSource = 'Funnel Marketing';
             insert testOpptySalesUser;
     
             OpportunityContactRole testOcr = TestDataOpportunity.getNewOpportunityContactRole('Power Sponsor', testCont.Id, testOpptySalesUser.Id);
             insert testOcr;
     
             Opportunity testOpptyUpdate = [SELECT Id, StageName FROM Opportunity WHERE Id =: testOpptySalesUser.Id LIMIT 1];
             testOpptyUpdate.StageName = 'Closed Abandoned';
             testOpptyUpdate.Abandon_Reason__c = 'Needs Changed';
 
             Test.startTest();
             update testOpptyUpdate;
             Test.getEventBus().deliver();
             Test.stopTest();
 
         }
 
         List<OpportunityContactRole> lstOcrResult = [SELECT Id, Contact.Marketing_Contact_Status__c, Contact.Waterfall_Stage__c, Contact.Waterfall_Closed_Won_Date__c
                                              FROM OpportunityContactRole WHERE ContactId =: testCont.Id];
 
         Assert.isNull(lstOcrResult.get(0).Contact.Waterfall_Closed_Won_Date__c, 'Waterfall Closed Won data incorrectly set');
         Assert.areEqual('Open Opportunity', lstOcrResult.get(0).Contact.Marketing_Contact_Status__c, 'Contact status changed incorrectly');
 
     }

     @isTest
     static void testWaterfallStageRevaluation() {
 
         Contact testCont = [SELECT Id FROM Contact LIMIT 1];
         Account testAcct = [SELECT Id FROM Account LIMIT 1];
 
         Opportunity testOpptyNotFunnel = TestDataOpportunity.initOpportunity(testAcct);
         testOpptyNotFunnel.StageName = 'Create';
         insert testOpptyNotFunnel;
 
         OpportunityContactRole testOcr = TestDataOpportunity.getNewOpportunityContactRole('Power Sponsor', testCont.Id, testOpptyNotFunnel.Id);
         insert testOcr;
         Test.getEventBus().deliver();
 
         Opportunity testOpptyFunnel = [SELECT Id, StageName FROM Opportunity WHERE LeadSource = 'Funnel Marketing' LIMIT 1];
         testOpptyFunnel.StageName = 'Closed Lost';
 
         Test.startTest();
         update testOpptyFunnel;
         Test.getEventBus().deliver();
         Test.stopTest();
 
         OpportunityContactRole ocrResult = [SELECT Id, Contact.Marketing_Contact_Status__c, Contact.Waterfall_Stage__c, Contact.Waterfall_Closed_Won_Date__c FROM OpportunityContactRole WHERE OpportunityId =: testOpptyFunnel.Id];
 
         Assert.isTrue(String.isBlank(ocrResult.Contact.Waterfall_stage__c), 'Waterfall stage did not clear');
         Assert.isNull(ocrResult.Contact.Waterfall_Closed_Won_Date__c, 'Waterfall Closed Won data did not set');
         Assert.areEqual('Open Opportunity', ocrResult.Contact.Marketing_Contact_Status__c, 'Contact status changed incorrectly');
 
     }
 
 
 }