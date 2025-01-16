/**
 *   @author: Deep Diwakar
*    @date:   Nov-27-2023
*    @description: Test class for AreaOfWorkContactDecorator class
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Nov-27-2023        CMCM-4510: Initial version
*         Deep Diwakar       Dec-14-2023        CMCM-4509: Added test methods for lead conversion scenario
*         Deep Diwakar       Mar-21-2023        CMCM-5683: Added test method for contact's primary account change
*    --------------------------------------------------------------------------------------------------
*/

@IsTest
private class TestAreaOfWorkContactDecorator {

    @TestSetup
    static void dataSetup() {
        //Create Account
        Account objAccount = TestDataAccount.getCustomerAccount();
        objAccount.Market_Segment__c = null;
        insert objAccount;
    }

    @IsTest
    static void testContInsertOneMktgSegment() {

        Account testAcct = [SELECT Id FROM Account LIMIT 1];

        Market_Segment__c objMarketSegment1 = new Market_Segment__c(Market_Segment__c = 'Agrigenomics',Account__c=testAcct.Id,
                                                                Market_Sub_Segment__c='Plant Testing',Percent_Allocation__c = 100);

        insert objMarketSegment1;

        Contact testCont = TestDataPerson.initContact(testAcct.Id);
        Test.startTest();
        insert testCont;
        Test.stopTest();

        // validate results
        Contact result = [Select Id, Area_Of_Work__c From Contact where AccountId =: testAcct.Id LIMIT 1];

        Assert.areEqual('Agrigenomics', result.Area_Of_Work__c, 'Contact market segment did not set correctly');

    }

    @IsTest
    static void testContInsertMultipleMktgSegment() {

        Account testAcct = [SELECT Id FROM Account LIMIT 1];

        Market_Segment__c objMarketSegment1 = new Market_Segment__c(Market_Segment__c = 'Agrigenomics',Account__c=testAcct.Id,
                                                                Market_Sub_Segment__c='Plant Testing',Percent_Allocation__c = 20);
        Market_Segment__c objMarketSegment2 = new Market_Segment__c(Market_Segment__c = 'Financial Services',Account__c=testAcct.Id,
                                                                    Percent_Allocation__c = 50);
        Market_Segment__c objMarketSegment3 = new Market_Segment__c(Market_Segment__c = 'Oncology Testing',Account__c=testAcct.Id,
                                                                Percent_Allocation__c = 30);

        insert new List<Market_Segment__c> {objMarketSegment1, objMarketSegment2, objMarketSegment3};

        Contact testCont = TestDataPerson.initContact(testAcct.Id);
    
        Test.startTest();
        insert testCont;
        Test.stopTest();

        // validate results
        Contact result = [Select Id, Area_Of_Work__c From Contact where AccountId =: testAcct.Id LIMIT 1];

        Assert.areEqual('Oncology Testing', result.Area_Of_Work__c, 'Contact market segment did not set correctly');

    }

    @IsTest
    static void testContUpdateWithinSegments() {

        Account testAcct = [SELECT Id FROM Account LIMIT 1];

        Market_Segment__c objMarketSegment1 = new Market_Segment__c(Market_Segment__c = 'Agrigenomics',Account__c=testAcct.Id,
                                                                Market_Sub_Segment__c='Plant Testing',Percent_Allocation__c = 30);
        Market_Segment__c objMarketSegment2 = new Market_Segment__c(Market_Segment__c = 'Financial Services',Account__c=testAcct.Id,
                                                                    Percent_Allocation__c = 50);
        Market_Segment__c objMarketSegment3 = new Market_Segment__c(Market_Segment__c = 'Oncology Testing',Account__c=testAcct.Id,
                                                                Percent_Allocation__c = 20);

        insert new List<Market_Segment__c> {objMarketSegment1, objMarketSegment2, objMarketSegment3};

        Contact testCont = TestDataPerson.getNewContact(testAcct.Id);

        testCont.Area_Of_Work__c = 'Oncology Testing';

        Test.startTest();
        update testCont;
        Test.stopTest();

        // validate results
        Contact result = [Select Id, Area_Of_Work__c From Contact where AccountId =: testAcct.Id LIMIT 1];

        Assert.areEqual('Oncology Testing', result.Area_Of_Work__c, 'Contact market segment did not update correctly');

    }

    @IsTest
    static void testContUpdateOutsideSegments() {

        Account testAcct = [SELECT Id FROM Account LIMIT 1];

        Market_Segment__c objMarketSegment1 = new Market_Segment__c(Market_Segment__c = 'Agrigenomics',Account__c=testAcct.Id,
                                                                Market_Sub_Segment__c='Plant Testing',Percent_Allocation__c = 30);
        Market_Segment__c objMarketSegment2 = new Market_Segment__c(Market_Segment__c = 'Financial Services',Account__c=testAcct.Id,
                                                                    Percent_Allocation__c = 50);
        Market_Segment__c objMarketSegment3 = new Market_Segment__c(Market_Segment__c = 'Oncology Testing',Account__c=testAcct.Id,
                                                                Percent_Allocation__c = 20);

        insert new List<Market_Segment__c> {objMarketSegment1, objMarketSegment2, objMarketSegment3};

        Contact testCont = TestDataPerson.getNewContact(testAcct.Id);

        testCont.Area_Of_Work__c = 'Cancer Research';

        Test.startTest();
        update testCont;
        Test.stopTest();

        // validate results
        Contact result = [Select Id, Area_Of_Work__c From Contact where AccountId =: testAcct.Id LIMIT 1];

        Assert.areEqual('Agrigenomics', result.Area_Of_Work__c, 'Contact market segment did not update correctly');

    }

    @IsTest
    static void testLeadConvertNoMarketSegment() {

        Account testAcct = [SELECT Id FROM Account LIMIT 1];

        Lead lead = TestDataMarketing.createLeadForMarketable('aowleadfirst', 'aowleadlast', 'aow_lead_convert@testing.com', 'USA', 'Lead Convert Test');
        lead.Email_Verification_Date__c = Date.today();
        lead.Email_Verification_Status__c = 'Verified Successfully';
        lead.Area_Of_Work__c = 'Forensics';

        insert lead;

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(lead.id);
        lc.setAccountId(testAcct.id);
        //lc.setContactId(objCon1.id);
        lc.setOwnerId(userinfo.getUserId());

        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true and MasterLabel='Lead Converted No Opp'];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        lc.setDoNotCreateOpportunity(true);

        Test.startTest();
        Database.convertLead(lc);
        Test.stopTest();

        Contact resultCont = [SELECT Id, Area_Of_Work__c, Email FROM Contact WHERE Email =: lead.Email LIMIT 1];

        Assert.areEqual(lead.Area_Of_Work__c, resultCont.Area_Of_Work__c, 'Area of work did not pass correctly');

    }

    @IsTest
    static void testLeadConvertMultipleMarketSegment() {

        Account testAcct = [SELECT Id FROM Account LIMIT 1];

        Market_Segment__c objMarketSegment1 = new Market_Segment__c(Market_Segment__c = 'Agrigenomics',Account__c=testAcct.Id,
                                                                Market_Sub_Segment__c='Plant Testing',Percent_Allocation__c = 30);
        Market_Segment__c objMarketSegment2 = new Market_Segment__c(Market_Segment__c = 'Financial Services',Account__c=testAcct.Id,
                                                                    Percent_Allocation__c = 50);
        Market_Segment__c objMarketSegment3 = new Market_Segment__c(Market_Segment__c = 'Oncology Testing',Account__c=testAcct.Id,
                                                                Percent_Allocation__c = 20);

        insert new List<Market_Segment__c> {objMarketSegment1, objMarketSegment2, objMarketSegment3};

        // first lead with market segment value inside account market segment
        Lead lead1 = TestDataMarketing.createLeadForMarketable('aowleadfirst', 'aowleadlast', 'aow_lead_convert@testing.com', 'USA', 'Lead Convert Test');
        lead1.Email_Verification_Date__c = Date.today();
        lead1.Email_Verification_Status__c = 'Verified Successfully';
        lead1.Area_Of_Work__c = 'Oncology Testing';

        // second lead with market segment value outside account market segment
        Lead lead2 = TestDataMarketing.createLeadForMarketable('aowleadfirst2', 'aowleadlast2', 'aow_lead_convert2@testing.com', 'USA', 'Lead Convert Test 2');
        lead2.Email_Verification_Date__c = Date.today();
        lead2.Email_Verification_Status__c = 'Verified Successfully';
        lead2.Area_Of_Work__c = 'Forensics';

        insert new List<Lead>{lead1, lead2};

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(lead1.id);
        lc.setAccountId(testAcct.id);
        //lc.setContactId(objCon1.id);
        lc.setOwnerId(userinfo.getUserId());

        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true and MasterLabel='Lead Converted No Opp'];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        lc.setDoNotCreateOpportunity(true);


        Database.LeadConvert lc2 = new Database.LeadConvert();
        lc2.setLeadId(lead2.id);
        lc2.setAccountId(testAcct.id);
        //lc.setContactId(objCon1.id);
        lc2.setOwnerId(userinfo.getUserId());

        LeadStatus convertStatus2 = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true and MasterLabel='Lead Converted No Opp'];
        lc2.setConvertedStatus(convertStatus2.MasterLabel);
        lc2.setDoNotCreateOpportunity(true);

        Test.startTest();
        Database.convertLead(new List<Database.LeadConvert>{lc, lc2});
        Test.stopTest();

        Contact resultCont1 = [SELECT Id, Area_Of_Work__c, Email FROM Contact WHERE Email =: lead1.Email LIMIT 1];
        Contact resultCont2 = [SELECT Id, Area_Of_Work__c, Email FROM Contact WHERE Email =: lead2.Email LIMIT 1];

        // market segment value inside account market segment
        Assert.areEqual('Oncology Testing', resultCont1.Area_Of_Work__c, 'Area of work did not pass correctly');

        // market segment value inside account market segment therefore highest market segment is picked
        Assert.areEqual('Agrigenomics', resultCont2.Area_Of_Work__c, 'Area of work did not pass correctly');

    }


    @isTest
    static void testLeadConvertExistingContact() {
        Account testAcct = [SELECT Id FROM Account LIMIT 1];

        Market_Segment__c objMarketSegment1 = new Market_Segment__c(Market_Segment__c = 'Agrigenomics',Account__c=testAcct.Id,
                                                                Market_Sub_Segment__c='Plant Testing',Percent_Allocation__c = 20);
        Market_Segment__c objMarketSegment2 = new Market_Segment__c(Market_Segment__c = 'Financial Services',Account__c=testAcct.Id,
                                                                    Percent_Allocation__c = 50);
        Market_Segment__c objMarketSegment3 = new Market_Segment__c(Market_Segment__c = 'Oncology Testing',Account__c=testAcct.Id,
                                                                Percent_Allocation__c = 30);

        insert new List<Market_Segment__c> {objMarketSegment1, objMarketSegment2, objMarketSegment3};

        Contact testCont = TestDataPerson.getNewContact(testAcct.Id);

        Lead lead = TestDataMarketing.createLeadForMarketable('aowleadfirst', 'aowleadlast', 'aow_lead_convert@testing.com', 'USA', 'Lead Convert Test');
        lead.Email_Verification_Date__c = Date.today();
        lead.Email_Verification_Status__c = 'Verified Successfully';
        lead.Area_Of_Work__c = 'Agrigenomics';

        insert lead;

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(lead.id);
        lc.setAccountId(testAcct.id);
        lc.setContactId(testCont.id);
        lc.setOwnerId(userinfo.getUserId());

        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true and MasterLabel='Lead Converted No Opp'];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        lc.setDoNotCreateOpportunity(true);

        Test.startTest();
        Database.convertLead(lc);
        Test.stopTest();

        Contact resultCont = [SELECT Id, Area_Of_Work__c, Email FROM Contact WHERE Id =: testCont.Id LIMIT 1];

        Assert.areEqual('Oncology Testing', resultCont.Area_Of_Work__c, 'Area of work did not pass correctly');


    }

    @isTest
    static void testAccountChange() {
        Account testAcct = [SELECT Id FROM Account LIMIT 1];

        Market_Segment__c objMarketSegment1 = new Market_Segment__c(Market_Segment__c = 'Agrigenomics',Account__c=testAcct.Id,
                                                                Market_Sub_Segment__c='Plant Testing',Percent_Allocation__c = 100);

        insert objMarketSegment1;

        Contact testCont = TestDataPerson.initContact(testAcct.Id);
        insert testCont;

        Contact beforeCont = [SELECT Id, Area_Of_Work__c FROM Contact WHERE Id =: testCont.Id];
        Assert.isTrue(String.isNotBlank(beforeCont.Area_Of_Work__c), 'AOW did not set correctly on before account change stage');

        Account newAccount = TestDataAccount.getCustomerAccount();
        newAccount.Market_Segment__c = null;
        insert newAccount;

        testCont.AccountId = newAccount.Id;

        Test.startTest();
        update testCont;
        Test.stopTest();

        Contact resultCont = [SELECT Id, Area_Of_Work__c FROM Contact WHERE Id =: testCont.Id];

        Assert.isTrue(String.isBlank(resultCont.Area_Of_Work__c), 'AOW did not set correctly on after account change stage');

    }

}