/**
 *   @author: Deep Diwakar
*    @date:   Oct-16-2023
*    @description: Created this class as a separate test clas for CampaignMemberService class. This will reduce the dependency of CampaignMemberService
*                  class on other test classes e.g. TestCampaignMembers and TestMoveCampaignMembersController going forward. 
*    @Test Class:  Test class for CampaignMemberService. Other parts of CampaignMemberService is covered through
*                  TestCampaignMembers and TestMoveCampaignMembersController
*     
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Oct-16-2023        CMCM-1188: New test class for CampaignMemberService in order to removed dependency on other test classes
*    --------------------------------------------------------------------------------------------------
 */

@IsTest
private class TestCampaignMemberService {

    @TestSetup
    static void testDataSetup() {

        Lead testLead = TestDataMarketing.createLeadForMarketable('CventTest', 'CventMediaCode', 'cvent_media_code@testing.com', 'USA', 'Cvent Media Code Testing Inc');
        Lead testLead2 = TestDataMarketing.createLeadForMarketable('CventTest2', 'CventMediaCode2', 'cvent_media_code2@testing.com', 'USA', 'Cvent Media Code Testing 2 Inc');
        insert new List<Lead>{testLead, testLead2};

        Contact testContact = TestDataMarketing.createContactForMarketable('CventTestFN', 'CventTestLN', 'cvent_catt@testing.com', 'US');
        Contact testContact2 = TestDataMarketing.createContactForMarketable('CventTestFN2', 'CventTestLN2', 'cvent_catt2@testing.com', 'US');
        insert new List<Contact>{testContact, testContact2};

        Campaign testWebinalCmp =new Campaign(name='Cvent Catt Media Code Testing',type='Webinar',channel__c='Live',Campaign_Region__c='AMR', Marketing_Segment__c = 'Microbiology' , Marketing_Campaign__c = 'Brand' , Program_Type__c = 'Education',Funnel__c='Top');
        insert testWebinalCmp;

    }

    @isTest
    static void testRunCattMediaLogicForCvent() {

        Lead testLead = [SELECT Id FROM Lead WHERE Email = 'cvent_media_code@testing.com' LIMIT 1];
        Lead testLead2 = [SELECT Id FROM Lead WHERE Email = 'cvent_media_code2@testing.com' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'cvent_catt@testing.com' LIMIT 1];
        Contact testContact2 = [SELECT Id FROM Contact WHERE Email = 'cvent_catt2@testing.com' LIMIT 1];
        Campaign testWebinalCmp = [SELECT Id FROM Campaign WHERE Name = 'Cvent Catt Media Code Testing' LIMIT 1];


        CampaignMember testCmpMemberLead = TestDataMarketing.initCampaignMemberLead(testLead.Id,testWebinalCmp.Id,'Attended');
        testCmpMemberLead.Campaign_Attribution__c = 'catt=Medium_Source+media=1234567';

        CampaignMember testCmpMemberContact = TestDataMarketing.initCampaignMemberContact(testContact.Id,testWebinalCmp.Id,'Attended');
        testCmpMemberContact.Campaign_Attribution__c = 'catt=Medium_Source';

        CampaignMember testCmpMemberLead2 = TestDataMarketing.initCampaignMemberLead(testLead2.Id,testWebinalCmp.Id,'Attended');
        testCmpMemberLead2.Campaign_Attribution__c = 'media=1234567';

        // inserting record to later update it
        CampaignMember testCmpMemberContact2 = TestDataMarketing.createCampaignMemberContact(testContact2.Id,testWebinalCmp.Id,'Attended');

        List<CampaignMember> lstCampaignMember = new List<CampaignMember>();
        lstCampaignMember.add(testCmpMemberLead);
        lstCampaignMember.add(testCmpMemberContact);
        lstCampaignMember.add(testCmpMemberLead2);

        User cventUser = [select id from user where name=:CampaignMembers.STRING_CVENT_USER];

        Test.startTest();
        System.runAs(cventUser) {
            insert lstCampaignMember;

            // updating campaign member to test update scenario
            testCmpMemberContact2.Campaign_Attribution__c = 'catt=Medium_Source2';
            update testCmpMemberContact2;
        }
        Test.stopTest();

        CampaignMember cmpCombined = [Select Id, Campaign_Attribution__c, Media_Code__c From CampaignMember WHERE Id =: testCmpMemberLead.Id];
        Assert.areEqual('Medium_Source', cmpCombined.Campaign_Attribution__c, 'Campaign attribution did not set correctly for Cvent user');
        Assert.areEqual('1234567', cmpCombined.Media_Code__c, 'Media code did not set correctly for Cvent user');

        CampaignMember cmpCatt = [Select Id, Campaign_Attribution__c From CampaignMember WHERE Id =: testCmpMemberContact.Id];
        Assert.areEqual('Medium_Source', cmpCatt.Campaign_Attribution__c, 'Campaign attribution did not set correctly for Cvent user');

        CampaignMember cmpMedia = [Select Id, Media_Code__c From CampaignMember WHERE Id =: testCmpMemberLead2.Id];
        Assert.areEqual('1234567', cmpMedia.Media_Code__c, 'Media code did not set correctly for Cvent user');

        CampaignMember cmpUpdateCatt = [Select Id, Campaign_Attribution__c From CampaignMember WHERE Id =: testCmpMemberContact2.Id];
        Assert.areEqual('Medium_Source2', cmpUpdateCatt.Campaign_Attribution__c, 'Media code did not set correctly for Cvent user');


    }

    @isTest
    static void testRunCattMediaLogicForCventNegative() {

        Lead testLead = [SELECT Id FROM Lead WHERE Email = 'cvent_media_code@testing.com' LIMIT 1];
        Lead testLead2 = [SELECT Id FROM Lead WHERE Email = 'cvent_media_code2@testing.com' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'cvent_catt@testing.com' LIMIT 1];
        Contact testContact2 = [SELECT Id FROM Contact WHERE Email = 'cvent_catt2@testing.com' LIMIT 1];
        Campaign testWebinalCmp = [SELECT Id FROM Campaign WHERE Name = 'Cvent Catt Media Code Testing' LIMIT 1];


        CampaignMember testCmpMemberLead = TestDataMarketing.initCampaignMemberLead(testLead.Id,testWebinalCmp.Id,'Attended');
        // set incorrect combined value
        testCmpMemberLead.Campaign_Attribution__c = '+media=12345'; 

        CampaignMember testCmpMemberContact = TestDataMarketing.initCampaignMemberContact(testContact.Id,testWebinalCmp.Id,'Attended');
        // set campaign attribution value with whitespace
        testCmpMemberContact.Campaign_Attribution__c = 'catt= Medium_Source';

        CampaignMember testCmpMemberLead2 = TestDataMarketing.initCampaignMemberLead(testLead2.Id,testWebinalCmp.Id,'Attended');
        // set media code value without using '='
        testCmpMemberLead2.Campaign_Attribution__c = 'media1234567';

        CampaignMember testCmpMemberContact2 = TestDataMarketing.initCampaignMemberContact(testContact2.Id,testWebinalCmp.Id,'Attended');
        // set campaign attribution value with whitespace
        testCmpMemberContact2.Campaign_Attribution__c = 'catt=Paid_Social+Facebook+media=523255';

        List<CampaignMember> lstCampaignMember = new List<CampaignMember>();
        lstCampaignMember.add(testCmpMemberLead);
        lstCampaignMember.add(testCmpMemberContact);
        lstCampaignMember.add(testCmpMemberLead2);
        lstCampaignMember.add(testCmpMemberContact2);

        User cventUser = [select id from user where name=:CampaignMembers.STRING_CVENT_USER];

        Test.startTest();
        System.runAs(cventUser) {
            insert lstCampaignMember;
        }
        Test.stopTest();

        CampaignMember cmpCombined = [Select Id, Campaign_Attribution__c, Media_Code__c From CampaignMember WHERE Id =: testCmpMemberLead.Id];
        Assert.areEqual('+media=12345', cmpCombined.Campaign_Attribution__c, 'Campaign attribution did not set correctly for Cvent user');
        Assert.areEqual('12345', cmpCombined.Media_Code__c, 'Media code did not set correctly for Cvent user');

        CampaignMember cmpCatt = [Select Id, Campaign_Attribution__c From CampaignMember WHERE Id =: testCmpMemberContact.Id];
        Assert.areEqual('Medium_Source', cmpCatt.Campaign_Attribution__c, 'Campaign attribution did not set correctly for Cvent user');

        CampaignMember cmpMedia = [Select Id, Campaign_Attribution__c, Media_Code__c From CampaignMember WHERE Id =: testCmpMemberLead2.Id];
        Assert.isNull(cmpMedia.Media_Code__c, 'Media code did not set correctly for Cvent user');
        Assert.areEqual('media1234567', cmpMedia.Campaign_Attribution__c, 'Campaign attribution did not set correctly for Cvent user');

        CampaignMember cmpCombined2 = [Select Id, Campaign_Attribution__c, Media_Code__c From CampaignMember WHERE Id =: testCmpMemberContact2.Id];
        Assert.areEqual('catt=Paid_Social+Facebook+media=523255', cmpCombined2.Campaign_Attribution__c, 'Campaign attribution did not set correctly for Cvent user');
        Assert.isNull(cmpCombined2.Media_Code__c, 'Media code did not set correctly for Cvent user');

    }

}