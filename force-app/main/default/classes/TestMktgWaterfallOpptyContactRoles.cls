/**
 *   @author: Deep Diwakar
*    @date:   Aug-16-2023
*    @description: This test class covers Marketing waterfall functionality related to Opportunity-Contact
     @Test Class:  It is a Test class for ProcessContactsForWaterfallOppty, MktgWaterfallOpptySrvc, MktgWaterfallServiceHelper, 
*                  MktgWaterfallOpptySrvcInjector, IMktgWaterfallOpptySrvc
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Aug-16-2023        DCP-60131: Test class for ProcessContactsForWaterfallOppty, MktgWaterfallOpptySrvc, MktgWaterfallServiceHelper, 
*                                                          MktgWaterfallOpptySrvcInjector, IMktgWaterfallOpptySrvc 
*    --------------------------------------------------------------------------------------------------
 */

@IsTest
private class TestMktgWaterfallOpptyContactRoles {

    @TestSetup
    static void testDataSetup() {
        Account testAcct = TestDataAccount.getAccount('Test Waterfall');
        insert testAcct;

        Contact testCont1 = TestDataMarketing.createContactForMarketable('testWaterfallFN1', 'testWaterfallLN1', 'test_waterfall1@testing.com', 'US');
        Contact testCont2 = TestDataMarketing.createContactForMarketable('testWaterfallFN2', 'testWaterfallLN2', 'test_waterfall2@testing.com', 'US');
        
        //testCont.Marketing_Contact_Status__c = 'Open Opportunity';
        insert new List<Contact>{testCont1, testCont2};

        Opportunity testOpptyFunnel = TestDataOpportunity.initOpportunity(testAcct);
        testOpptyFunnel.LeadSource = 'Funnel Marketing';
        //testOpptyFunnel.StageName = 'Create';
        //testOpptyFunnel.Competitor_Name__c = '';
        insert testOpptyFunnel;

        OpportunityContactRole testOcr = TestDataOpportunity.getNewOpportunityContactRole('Power Sponsor', testCont1.Id, testOpptyFunnel.Id);
        insert testOcr;

        // publish platform events to set initial waterfall stage
        Test.getEventBus().deliver();

    }

    @isTest
    static void testWaterfallOcrInsert() {

        Contact ocrTestCont = [SELECT Id FROM Contact WHERE Email = 'test_waterfall2@testing.com' LIMIT 1];
        Opportunity ocrTestOppty = [SELECT Id FROM Opportunity WHERE LeadSource = 'Funnel Marketing' LIMIT 1];

        Test.startTest();
        OpportunityContactRole testOcr = TestDataOpportunity.getNewOpportunityContactRole('Power Sponsor', ocrTestCont.Id, ocrTestOppty.Id);
        insert testOcr;
        Test.getEventBus().deliver();
        Test.stopTest();

        Contact resultCont = [SELECT Id, Waterfall_Stage__c, Marketing_Contact_Status__c FROM Contact WHERE Id =: ocrTestCont.Id];

        Assert.areEqual('Opportunity', resultCont.Waterfall_Stage__c, 'Waterfall stage did not set correctly');
        Assert.areEqual('Open Opportunity', resultCont.Marketing_Contact_Status__c, 'Contact status did not set correctly');

    }

    @isTest
    static void testWaterfallOcrDelete() {

        OpportunityContactRole testOcr = [SELECT Id, ContactId FROM OpportunityContactRole WHERE Contact.Email = 'test_waterfall1@testing.com' LIMIT 1];

        Test.startTest();
        delete testOcr;
        Test.getEventBus().deliver();
        Test.stopTest();

        Contact resultCont = [SELECT Id, Waterfall_Stage__c, Marketing_Contact_Status__c FROM Contact WHERE Id =: testOcr.ContactId];

        //Assert.areEqual('', resultCont.Waterfall_Stage__c, 'Waterfall stage did not set correctly after OCR deletion.');
        Assert.isNull(resultCont.Waterfall_Stage__c, 'Waterfall stage did not set correctly after OCR deletion.');
        Assert.areEqual('Recycled', resultCont.Marketing_Contact_Status__c, 'Contact status did not set correctly after OCR deletion');

    }

    @isTest
    static void testWaterfallOcrEdit() {

        Contact ocrTestCont = [SELECT Id FROM Contact WHERE Email = 'test_waterfall2@testing.com' LIMIT 1];
        OpportunityContactRole testOcr = [SELECT Id, ContactId FROM OpportunityContactRole WHERE Contact.Email = 'test_waterfall1@testing.com' LIMIT 1];

        // edit ocr contact
        testOcr.ContactId = ocrTestCont.Id;

        Test.startTest();
        update testOcr;
        Test.getEventBus().deliver();
        Test.stopTest();

        Contact resultContWaterfallSet = [SELECT Id, Waterfall_Stage__c, Marketing_Contact_Status__c FROM Contact WHERE Id =: ocrTestCont.Id LIMIT 1];
        Assert.areEqual('Opportunity', resultContWaterfallSet.Waterfall_Stage__c, 'Waterfall stage did not set correctly after update');
        Assert.areEqual('Open Opportunity', resultContWaterfallSet.Marketing_Contact_Status__c, 'Contact status did not set correctly after update');

        Contact resultContWaterfallReset = [SELECT Id, Waterfall_Stage__c, Marketing_Contact_Status__c FROM Contact WHERE Email = 'test_waterfall1@testing.com' LIMIT 1];
        //Assert.areEqual('', resultContWaterfallReset.Waterfall_Stage__c, 'Waterfall stage did not set correctly after OCR deletion.');
        Assert.isNull(resultContWaterfallReset.Waterfall_Stage__c, 'Waterfall stage did not set correctly after OCR deletion after update.');
        Assert.areEqual('Recycled', resultContWaterfallReset.Marketing_Contact_Status__c, 'Contact status did not set correctly after update');

    }

    @IsTest
    static void testWaterfallOpptyLeadSourceChange() {
        Opportunity ocrTestOppty = [SELECT Id FROM Opportunity WHERE LeadSource = 'Funnel Marketing' LIMIT 1];

        ocrTestOppty.LeadSource = 'Direct Mail';

        Test.startTest();
        update ocrTestOppty;
        Test.getEventBus().deliver();
        Test.stopTest();

        OpportunityContactRole ocrResult = [SELECT Id, Contact.Waterfall_Stage__c, Contact.Marketing_Contact_Status__c
                                            FROM OpportunityContactRole
                                            WHERE OpportunityId =: ocrTestOppty.Id];

        System.debug('ocrResult.Contact.Waterfall_Stage__c: ' + ocrResult.Contact.Waterfall_Stage__c);
        Assert.isNull(ocrResult.Contact.Waterfall_Stage__c, 'Waterfall statge did not set correctly after LeadSource change');
       // Assert.areEqual('Recycled', ocrResult.Contact.Marketing_Contact_Status__c, 'Marketing contact status did not set correctly after LeadSource change');

    }

}