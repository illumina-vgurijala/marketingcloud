/**
 *   @author: Deep Diwakar
*    @date:   Jan-02-2024
*    @description: Test class for Platform event subscriber MarketSegmentChangeEvents
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       July-10-2023        DCP-60098: Test class for Platform event subscriber trigger handler class ProcessContactOnOpportunityClose
*    --------------------------------------------------------------------------------------------------
 */

@IsTest
private class TestMarketSegmentChangeEvents {

    @TestSetup
    static void testDataSetup() {
        //Create new customer account
        Account objAccount = TestDataAccount.getCustomerAccount();
        objAccount.Market_Segment__c = null;
        insert objAccount;

        // create new contact
        TestDataPerson.getNewContact(objAccount.Id);


    }

    @isTest
    static void testMarketSegmentInsertEvent() {

        Account testAccount = [Select Id From Account LIMIT 1];

        Market_Segment__c objMarketSegment = new Market_Segment__c(Market_Segment__c = 'Cancer Research',Account__c=testAccount.Id,Percent_Allocation__c = 100);

        Test.startTest();
        insert objMarketSegment;
        Test.getEventBus().deliver();
        Test.stopTest();

        Contact resultCont = [Select Id, Area_Of_Work__c From Contact where AccountId =: testAccount.Id];

        Assert.areEqual('Cancer Research', resultCont.Area_Of_Work__c, 'Market segment value did not set correctly');

    }

    @isTest
    static void testMarketSegmentEditEvent() {

        Account testAccount = [Select Id From Account LIMIT 1];

        Market_Segment__c ms1 = new Market_Segment__c(Market_Segment__c = 'Cancer Research',Account__c=testAccount.Id,Percent_Allocation__c = 60);
        Market_Segment__c ms2 = new Market_Segment__c(Market_Segment__c = 'Oncology Testing',Account__c=testAccount.Id,Percent_Allocation__c = 40);

        insert new List<Market_Segment__c>{ms1, ms2};

        Test.getEventBus().deliver();

        ms1.Percent_Allocation__c = 40;
        ms2.Percent_Allocation__c = 60;

        Test.startTest();
        update new List<Market_Segment__c>{ms1, ms2};
        Test.getEventBus().deliver();
        Test.stopTest();

        Contact resultCont = [Select Id, Area_Of_Work__c From Contact where AccountId =: testAccount.Id];

        Assert.areEqual('Cancer Research', resultCont.Area_Of_Work__c, 'Market segment value did not set correctly');

    }

    @isTest
    static void testMarketSegmentDeleteEvent() {

        Account testAccount = [Select Id From Account LIMIT 1];

        Market_Segment__c ms1 = new Market_Segment__c(Market_Segment__c = 'Cancer Research',Account__c=testAccount.Id,Percent_Allocation__c = 70);
        Market_Segment__c ms2 = new Market_Segment__c(Market_Segment__c = 'Oncology Testing',Account__c=testAccount.Id,Percent_Allocation__c = 30);
        insert new List<Market_Segment__c>{ms1, ms2};
        Test.getEventBus().deliver();

        Test.startTest();
        TestMarketSegments.boolRunValidations = false;
        delete ms1; 
        Test.getEventBus().deliver();
        TestMarketSegments.boolRunValidations = true;
        Test.stopTest();

        List<Market_Segment__c> lstMktgSegment = [Select Id, Market_Segment__c, Account__c
                                                 From Market_Segment__c where Account__c =: testAccount.Id];

        Assert.areEqual(1, lstMktgSegment.size());
        Assert.areEqual('Oncology Testing', lstMktgSegment.get(0).Market_Segment__c);

        Contact resultCont = [Select Id, Area_Of_Work__c From Contact where AccountId =: testAccount.Id];

        Assert.areEqual('Oncology Testing', resultCont.Area_Of_Work__c, 'Market segment value did not set correctly');

    }
}