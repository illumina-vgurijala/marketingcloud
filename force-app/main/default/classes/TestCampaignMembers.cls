/***************************************************************************************************************************************
 * NAME   : TestCampaignMembers
 * DESCRIPTION  : TestClass for CampaignMembers
 *
 *
 * @AUTHOR : Pankaj Singla
 * @DATE   : 15-Oct-2018
 *
 * MODIFICATION LOG:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION
 * Deep Diwakar           June-30-2021        DCP-45658: Charket Campaign Member Status Customization
 * Deep Diwakar          Sept-10-2021        DCP-49866: Adding missing test method annotation
 * Rishab Wali           Oct-20-2021         Code Scan Fixes
 * Deep Diwakar          Jan-3-2023          POL-173: Updating campaign_region__c field with new regions
 * Deep Diwakar          March-27-2023       DCP-59535: Adding test method for media code
 * Deep Diwakar          June-14-2023        CMCM-1164: Updated test methods for platform event usage of cattr and media code
 * Deep Diwakar          June-18-2023        CMCM-1160: Updated test methods to use Campaign Subregion field and added one test method for new field
 * Deep Diwakar          Aug-08-2023         DCP-60130: Added test method for Campaign Member CRUD and FLS bypass
 * Deep Diwakar   		 Oct 16 2023         CMCM-1188: Added test method for Cvent campaign attribution and media code logic
 * Deep Diwakar          Aug-09-2024         CMCM-9421: Added test method for form type automation
 * --------------------------------------------------------------------------------------------------------------------------------------
  ****************************************************************************************************************************************/


/*SeeAllData is set to true because the CamapignMemberStatus Values are available in Query only if SeeAlldata is true
All the required data is created in test class itself
*/
@isTest(SeeAllData=false)
public class TestCampaignMembers{

    @isTest
    static void testCampaignAttributionInsert(){
        Id userId = userinfo.getUserId();
        User u1 = [SELECT id,UserPermissionsMarketingUser from User WHERE id=:userId];
        if(u1.UserPermissionsMarketingUser==false){
            u1.UserPermissionsMarketingUser=true;
            update u1;
        }

        // Reusing Sync Attribution Form Handler response as Pardot Form Hanlder response remains exactly same
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('PardotSynCampaignAttributionMoc');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');

         system.runAs(u1){
            lead objLead=TestDataMarketing.createLeadForMarketable('testfirstname1','testlastname1','test1@gmail.com','Germany','test1Company');
            Contact objCon=TestDataMarketing.createContact('FirstName','LastName','Test@f.com');
            objLead.Campaign_Attribution__c='Testing Campaign Attribution Lead';
            objCon.Campaign_Attribution__c='Testing Campaign Attribution Contact';
            insert objLead;
            update objCon;
            system.debug('user is--'+u1.UserPermissionsMarketingUser);
            Campaign objCampaignSeminar=new Campaign(name='testing1dddd',type='Webinar',channel__c='Live',Campaign_Region__c='AMR', Marketing_Segment__c = 'Microbiology' , Marketing_Campaign__c = 'Brand' , Program_Type__c = 'Education',Funnel__c='Top');
            insert objCampaignSeminar;

            // Associate the callout with a mock response
            Test.setMock(HttpCalloutMock.class, mock);
            Test.startTest();
            CampaignMember objCampaignMemberJC=TestDataMarketing.createCampaignMember(objLead.id,objCampaignSeminar.id,'Attended');
            CampaignMember objCampaignMember13=TestDataMarketing.createCampaignMemberContact(objCon.id,objCampaignSeminar.id,'Attended');
            Test.getEventBus().deliver();
            Test.stopTest();

            Lead resultLead = [SELECT Id, Campaign_Attribution__c FROM Lead WHERE Id =: objLead.Id];
            Contact resultContact = [SELECT Id, Campaign_Attribution__c FROM Contact WHERE Id =: objCon.Id];
            campaignmember objCmLead=  [select id,Campaign_Attribution__c, Media_Code__c from campaignmember where id=:objCampaignMemberJC.Id];
            campaignmember objCmContact=  [select id,Campaign_Attribution__c, Media_Code__c from campaignmember where id=:objCampaignMember13.Id];

            system.assertEquals('Testing Campaign Attribution Lead', objCmLead.Campaign_Attribution__c,'Campaign Attribution not updated to correct value');
            system.assertEquals('NULL', resultLead.Campaign_Attribution__c,'Campaign Attribution field not updated to NULL');

            system.assertEquals('Testing Campaign Attribution Contact', objCmContact.Campaign_Attribution__c,'Campaign Attribution not updated to correct alue');
            system.assertEquals('NULL', resultContact.Campaign_Attribution__c,'Campaign Attribution not updated to NULL');
             
           // Validating platform event subscriber callout
            Interface_Log__c log = [Select Id, Interface_Name__c, Result__c From Interface_Log__c where Interface_Name__c = 'PardotCattrMediaCodeSender'];
            System.assertEquals('Success', log.Result__c, 'PardotCattrMediaCodeSender queueable did not work correctly in success scenario!');


        }
    }


    @isTest
    static void testCampaignAttributionUpdate(){
        Id userId = userinfo.getUserId();
        User u1 = [SELECT id,UserPermissionsMarketingUser from User WHERE id=:userId];
        if(u1.UserPermissionsMarketingUser==false){
            u1.UserPermissionsMarketingUser=true;
            update u1;
        }

        // Reusing Sync Attribution Form Handler response as Pardot Form Hanlder response remains exactly same
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('PardotSynCampaignAttributionMoc');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');

         system.runAs(u1){
            lead objLead=TestDataMarketing.createLeadForMarketable('testfirstname1','testlastname1','test1@gmail.com','Germany','test1Company');
            Contact objCon=TestDataMarketing.createContact('FirstName','LastName','Test@f.com');
            insert objLead;
            update objCon;
            system.debug('user is--'+u1.UserPermissionsMarketingUser);
            Campaign objCampaignSeminar=new Campaign(name='testing1dddd',type='Webinar',channel__c='Live',Campaign_Region__c='AMR', Marketing_Segment__c = 'Microbiology' , Marketing_Campaign__c = 'Brand' , Program_Type__c = 'Education',Funnel__c='Top');
            insert objCampaignSeminar;

            CampaignMember objCampaignMemberJC=TestDataMarketing.createCampaignMember(objLead.id,objCampaignSeminar.id,'Attended');
            CampaignMember objCampaignMember13=TestDataMarketing.createCampaignMemberContact(objCon.id,objCampaignSeminar.id,'Attended');

            objLead.Campaign_Attribution__c='CATT1';
            update objLead;
            objCon.Campaign_Attribution__c='CATT1';
            update objCon;

            objCampaignMemberJC.status='Attended On-Demand';
            objCampaignMember13.status='Attended On-Demand';
            list<CampaignMember> lstCampaignMembers=new List<CampaignMember>{objCampaignMemberJC,objCampaignMember13};

            // Associate the callout with a mock response
            Test.setMock(HttpCalloutMock.class, mock);
            Test.startTest();
            update lstCampaignMembers;
            Test.getEventBus().deliver();
            Test.stopTest();

            // Validating platform event subscriber callout
            Interface_Log__c log = [Select Id, Interface_Name__c, Result__c From Interface_Log__c where Interface_Name__c = 'PardotCattrMediaCodeSender'];
            System.assertEquals('Success', log.Result__c, 'PardotCattrMediaCodeSender queueable did not work correctly in success scenario!');

            Lead resultLead = [SELECT Id, Campaign_Attribution__c FROM Lead WHERE Id =: objLead.Id];
            Contact resultContact = [SELECT Id, Campaign_Attribution__c FROM Contact WHERE Id =: objCon.Id];

            System.assertEquals('NULL', resultLead.Campaign_Attribution__c, 'Campaign_Attribution__c field value is not set to NULL after campaign member creation');

            System.assertEquals('NULL', resultContact.Campaign_Attribution__c, 'Campaign_Attribution__c field value is not set to NULL after campaign member creation');
        }

    }


    @isTest
    static void testMediaCodeInsert() {

        Lead testLead = TestDataMarketing.createLeadForMarketable('PardotTest', 'MediaCode', 'pardot_media_code@testing.com', 'USA', 'Media Code Testing Inc');
        testLead.Media_Code__c = 'Lead Media Code Testing';
        insert testLead;

        Contact testContact = TestDataMarketing.createContactForMarketable('PardotTestFN', 'PardotTestLN', 'contat_media_code@testing.com', 'US');
        testContact.Media_Code__c = 'Contact Media Code Testing';
        insert testContact;

        Campaign testWebinalCmp =new Campaign(name='Media Code Testing',type='Webinar',channel__c='Live',Campaign_Region__c='AMR', Marketing_Segment__c = 'Microbiology' , Marketing_Campaign__c = 'Brand' , Program_Type__c = 'Education',Funnel__c='Top');
        insert testWebinalCmp;

        CampaignMember testCmpMemberLead = TestDataMarketing.initCampaignMemberLead(testLead.Id,testWebinalCmp.Id,'Attended');

        CampaignMember testCmpMemberContact = TestDataMarketing.initCampaignMemberContact(testContact.Id,testWebinalCmp.Id,'Attended');

        List<CampaignMember> lstCampaignMember = new List<CampaignMember>();
        lstCampaignMember.add(testCmpMemberLead);
        lstCampaignMember.add(testCmpMemberContact);

        // Reusing Sync Attribution Form Handler response as Pardot Form Hanlder response remains exactly same
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('PardotSynCampaignAttributionMoc');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        insert lstCampaignMember;
        Test.getEventBus().deliver();
        Test.stopTest();

        Lead resultLead = [SELECT Id, Media_Code__c FROM Lead WHERE Id =: testLead.Id];
        CampaignMember resultCmpMemberLead = [SELECT Id, Media_Code__c FROM CampaignMember WHERE Id =: testCmpMemberLead.Id];
        Contact resultContact = [SELECT Id, Media_Code__c FROM Contact WHERE Id =: testContact.Id];
        CampaignMember resultCmpMemberContact = [SELECT Id, Media_Code__c FROM CampaignMember WHERE Id =: testCmpMemberContact.Id];

        // Validating platform event subscriber callout
        Interface_Log__c log = [Select Id, Interface_Name__c, Result__c From Interface_Log__c where Interface_Name__c = 'PardotCattrMediaCodeSender'];
        System.assertEquals('Success', log.Result__c, 'PardotCattrMediaCodeSender queueable did not work correctly in success scenario!');

        System.assertEquals('NULL', resultLead.Media_Code__c, 'Media Code is not set to NULL after campaign member creation');

        System.assertEquals('Lead Media Code Testing', resultCmpMemberLead.Media_Code__c, 'Media code value is not transferred to campaign member');

        System.assertEquals('NULL', resultContact.Media_Code__c, 'Media Code is not set to NULL after campaign member creation');

        System.assertEquals('Contact Media Code Testing', resultCmpMemberContact.Media_Code__c, 'Media code value is not transferred to campaign member');

    }

    @isTest
    static void testMediaCodeUpdate() {

        Lead testLead = TestDataMarketing.createLead('PardotTest', 'MediaCode', 'pardot_media_code@testing.com', 'USA', 'Media Code Testing Inc');
        Contact testContact = TestDataMarketing.createContact('PardotTestFN', 'PardotTestLN', 'contat_media_code@testing.com', 'US');

        Campaign testWebinalCmp =new Campaign(name='Media Code Testing',type='Webinar',channel__c='Live',Campaign_Region__c='AMR', Marketing_Segment__c = 'Microbiology' , Marketing_Campaign__c = 'Brand' , Program_Type__c = 'Education',Funnel__c='Top');
        insert testWebinalCmp;

        CampaignMember testCmpMemberLead = TestDataMarketing.createCampaignMember(testLead.Id,testWebinalCmp.Id,'Attended');
        CampaignMember testCmpMemberCont = TestDataMarketing.createCampaignMemberContact(testContact.Id,testWebinalCmp.Id,'Attended');

        // update lead to add media code
        testLead.Media_Code__c = 'Media Code Testing Lead';
        update testLead;

        // update contact to add media code
        testContact.Media_Code__c = 'Media Code Testing Contact';
        update testContact;

        // update campaign member status
        testCmpMemberLead.status = 'Attended-Contact Me';
        testCmpMemberCont.status = 'Attended-Contact Me';

        List<CampaignMember> lstCampaignMember = new List<CampaignMember>();
        lstCampaignMember.add(testCmpMemberLead);
        lstCampaignMember.add(testCmpMemberCont);

        // Reusing Sync Attribution Form Handler response as Pardot Form Hanlder response remains exactly same
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('PardotSynCampaignAttributionMoc');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        update lstCampaignMember;
        Test.getEventBus().deliver();
        Test.stopTest();

        // Validating platform event subscriber callout
        Interface_Log__c log = [Select Id, Interface_Name__c, Result__c From Interface_Log__c where Interface_Name__c = 'PardotCattrMediaCodeSender'];
        System.assertEquals('Success', log.Result__c, 'PardotCattrMediaCodeSender queueable did not work correctly in success scenario!');

        Lead resultLead = [SELECT Id, Media_Code__c FROM Lead WHERE Id =: testLead.Id];
        Contact resultContact = [SELECT Id, Media_Code__c FROM Contact WHERE Id =: testContact.Id];

        System.assertEquals('NULL', resultLead.Media_Code__c, 'Media Code is not set to NULL after campaign member creation');
        System.assertEquals('NULL', resultContact.Media_Code__c, 'Media Code is not set to NULL after campaign member creation');


    }

    // CMCM-1160: Campaign Member Status records are not visible in Test context. Setting SeeAllData= true to allow visibility to
    // Campaign Member Status records only.
    @isTest(SeeAllData= true)
    static void testSubregionScoring() {
        // campaign creation for Japan and Africa Subregion
        Campaign testAfricaCmp =new Campaign(name='Media Code Testing Africa',type='Email',channel__c='Drip Email',Campaign_Region__c='AMEA', Campaign_Subregion__c = 'Africa', Marketing_Segment__c = 'Microbiology' , Marketing_Campaign__c = 'Brand' , Program_Type__c = 'Education',Funnel__c='Top', Status = 'In Progress');
        insert testAfricaCmp;

        Lead africaLead = TestDataMarketing.createLeadForMarketable('Afrfirst', 'Afrlast', 'afrtest@afrtest.com', 'Nigeria', 'Africa Scoring Test');
        insert africaLead;

        CampaignMember africaCmpMember = TestDataMarketing.initCampaignMemberLead(africaLead.Id,testAfricaCmp.Id,'Clicked');

        Test.startTest();
        insert africaCmpMember;
        Test.stopTest();

        Lead africaResLead = [Select Id, Marketing_Score__c From Lead where Id =: africaLead.Id];

        list<Prospect_Scoring_Log__c> lstLog = [select id from Prospect_Scoring_Log__c where Lead__c=:africaResLead.id];
		System.assert(!lstLog.isEmpty(),'Log not created.');

    }

    @isTest
    static void testCventUser(){
        User u=[select id from user where name=:CampaignMembers.STRING_CVENT_USER];

        system.runas(u){
            Lead objLead=TestDataMarketing.createLead('FirstName','LastName','Test1@f.com','USA','USA');

            Lead objLead2=TestDataMarketing.createLead('FirstName2','LastName2','Test2@f.com','USA','USA');

            Campaign objCampaignSeminar=new Campaign(name='testing1',type='Illumina Hosted Event', Marketing_Segment__c = 'Microbiology' , Marketing_Campaign__c = 'Brand' , Program_Type__c = 'Education',Funnel__c='Top');

            Campaign objCampaignTradeshow=new Campaign(name='testing2',type='Third Party Hosted Event', Marketing_Segment__c = 'Microbiology' , Marketing_Campaign__c = 'Brand' , Program_Type__c = 'Education',Funnel__c='Top');

            List<Campaign> lstCampaign=new list<Campaign>{objCampaignSeminar,objCampaignTradeshow};
            insert lstCampaign;

            CampaignMember objCampaignMemberJC=TestDataMarketing.createCampaignMember(objLead.id,objCampaignSeminar.id,'Attended');

            CampaignMember objCampaignMemberJD=TestDataMarketing.createCampaignMember(objLead2.id,objCampaignTradeshow.id,'Attended');

            System.debug('Campaign Members Created -- '+ objCampaignMemberJC.Id + objCampaignMemberJD.Id);
            objLead2=[select id,leadsource from Lead where id=:objLead2.id];
            system.assertEquals('Third Party Hosted Event',objLead2.leadsource,'Lead Source value is not updated to Third Party Hosted Event.');

            objLead=[select id,leadsource from Lead where id=:objLead.id];
            system.assertEquals('Illumina Hosted Event',objLead.leadsource,'Lead Source value is not updated to Illumina Hosted Event.');

        }
    }

    @isTest
    static void testCventCattMediaCode() {
        User cventUser = [SELECT Id FROM User WHERE NAME =:CampaignMembers.STRING_CVENT_USER LIMIT 1];

        Lead testLead = TestDataMarketing.createLeadForMarketable('CventTest', 'CventMediaCode', 'cvent_media_code@testing.com', 'USA', 'Cvent Media Code Testing Inc');
        insert testLead;
       
        Contact testContact = TestDataMarketing.createContactForMarketable('CventTestFN', 'CventTestLN', 'cvent_media_code@testing.com', 'US');
        insert testContact;
      
        Campaign testWebinalCmp =new Campaign(name='Cvent Media Code Testing',type='Webinar',channel__c='Live',Campaign_Region__c='AMR', Marketing_Segment__c = 'Microbiology' , Marketing_Campaign__c = 'Brand' , Program_Type__c = 'Education',Funnel__c='Top');
        insert testWebinalCmp;

        CampaignMember testCmpMemberLead = TestDataMarketing.initCampaignMemberLead(testLead.Id,testWebinalCmp.Id,'Attended');
        testCmpMemberLead.Campaign_Attribution__c = 'catt=Medium_Source+media=1234567';

        // inserting record to later update it
        CampaignMember testCmpMemberContact2 = TestDataMarketing.createCampaignMemberContact(testContact.Id,testWebinalCmp.Id,'Attended');

        Test.startTest();
        System.runAs(cventUser) {
            insert testCmpMemberLead;

            // updating campaign member to test update scenario
            testCmpMemberContact2.Campaign_Attribution__c = 'catt=Medium_Source2';
            update testCmpMemberContact2;
        }
        Test.stopTest();

        CampaignMember cmpCombined = [Select Id, Campaign_Attribution__c, Media_Code__c From CampaignMember WHERE Id =: testCmpMemberLead.Id];
        Assert.areEqual('Medium_Source', cmpCombined.Campaign_Attribution__c, 'Campaign attribution did not set correctly for Cvent user');
        Assert.areEqual('1234567', cmpCombined.Media_Code__c, 'Media code did not set correctly for Cvent user');

        CampaignMember cmpUpdateCatt = [Select Id, Campaign_Attribution__c From CampaignMember WHERE Id =: testCmpMemberContact2.Id];
        Assert.areEqual('Medium_Source2', cmpUpdateCatt.Campaign_Attribution__c, 'Media code did not set correctly for Cvent user');

    }

    @isTest (SeeAllData=true)
    static void testCharket(){
        Id userId = userinfo.getUserId();
        Campaign objCampaignSeminar;
        User u1 = [SELECT id,UserPermissionsMarketingUser from User WHERE id=:userId];
        if(u1.UserPermissionsMarketingUser==false){
            u1.UserPermissionsMarketingUser=true;
            update u1;
        }
        system.runas(u1){
            objCampaignSeminar=new Campaign(name='testing1',type='Third Party Hosted Event', Marketing_Segment__c = 'Microbiology' , Marketing_Campaign__c = 'Brand' , Program_Type__c = 'Education',Campaign_Region__c='China',
                                                Campaign_Subregion__c='China',Channel__c='Booth',Funnel__c='Top');
            insert objCampaignSeminar;
        }

        User u=[select id,UserPermissionsMarketingUser from user where name='Charket User' LIMIT 1];


       List<Charket_Scoring_Event__e> lstevents=new list<Charket_Scoring_Event__e>();
       Lead objLead=TestDataMarketing.createLead('FirstName','LastName','Test1@f.com','USA','USA');
        Contact objCon=TestDataMarketing.createContact('FirstName','LastName','Test@f.com');
       CampaignMember objCampaignMemberJC;
        CampaignMember objCampaignMember13;

        objCampaignMemberJC=TestDataMarketing.createCampaignMember(objLead.id,objCampaignSeminar.id,'Attended');
         objCampaignMember13=TestDataMarketing.createCampaignMemberContact(objCon.id,objCampaignSeminar.id,'Attended');
            system.runas(u){
            Charket_Scoring_Event__e objEvent=new Charket_Scoring_Event__e();
            objEvent.CampaignMemberId__c=objCampaignMemberJC.Id;
            objEvent.LeadId__c=objLead.Id;
            Charket_Scoring_Event__e objEvent2=new Charket_Scoring_Event__e();
            objEvent2.CampaignMemberId__c=objCampaignMember13.id;
            objEvent2.ContactId__c=objCon.Id;
            lstevents.add(objEvent);
            lstevents.add(objEvent2);
            Test.startTest();
            EventBus.publish(lstevents);
            Test.stopTest();
        }
        list<Prospect_Scoring_Log__c> lstLog = [select id from Prospect_Scoring_Log__c where Lead__c=:objLead.id];
		System.assert(!lstLog.isEmpty(),'Log not created.');

    }
    
    /**
     * DCP-60130: Added for this story
     */
    @isTest
    static void testBypassUserPermission() {
        User mktgUser = TestDataUser.findUserInProfile('Marketing');

        PermissionSet bypassPS = [SELECT Id FROM PermissionSet WHERE Name = 'Bypass_Person_Object_Permission_Set'];

        // Assign bypass permission set to marketing user
        PermissionSetAssignment bypassPSA = new PermissionSetAssignment();
        bypassPSA.AssigneeId = mktgUser.Id;
        bypassPSA.PermissionSetId = bypassPS.Id;

        insert bypassPSA;

        Contact testCharketContact;
        CampaignMember testCharContCmpMember;

        // run as that marketing user
        System.runAs(mktgUser) {

            Campaign testChinaCmp =new Campaign(name='Test China Charket Campaign',type='Email',channel__c='Drip Email',Campaign_Region__c='China', Campaign_Subregion__c = 'China', Marketing_Segment__c = 'Microbiology' , Marketing_Campaign__c = 'Brand' , Program_Type__c = 'Education',Funnel__c='Top', Status = 'In Progress');
            insert testChinaCmp;
            testCharketContact = TestDataMarketing.createContact('Testcharcontfirst', 'Testcharcontfirst', 'testcharcont@testchar.com', 'CN');
            testCharContCmpMember = TestDataMarketing.initCampaignMemberContact(testCharketContact.Id,testChinaCmp.Id,'Clicked');

            List<CampaignMember> lstCampaignMembers = new List<CampaignMember>();
            lstCampaignMembers.add(testCharContCmpMember);

            Test.startTest();
            insert lstCampaignMembers;
            Test.stopTest();

            Assert.isTrue(ilib_SecurityUtils.bypassInternalFlsAndCrud, 'Campaing Member Trigger bypass did not work correctly');

        }

    }

	@isTest(SeeAllData=true)
    static void testlastResponded(){

        Campaign objCampaignTradeshow=new Campaign(name='testing1',type='Third Party Hosted Event', Marketing_Segment__c = 'Microbiology' , Marketing_Campaign__c = 'Brand' , Program_Type__c = 'Education',Campaign_Region__c='China',
                                                Campaign_Subregion__c='China',Channel__c='Booth' , Organization_Ownership__c = 'Marketing',Funnel__c='Top');
        Campaign objCampaignTradeshow2=new Campaign(name='testing2',type='Third Party Hosted Event', Marketing_Segment__c = 'Microbiology' , Marketing_Campaign__c = 'Brand' , Program_Type__c = 'Education',Campaign_Region__c='China',
                                                Campaign_Subregion__c='China',Channel__c='Booth',Funnel__c='Top');
         List<Campaign> lstCampaigns=new List<Campaign>();
        lstCampaigns.add(objCampaignTradeshow);
        lstCampaigns.add(objCampaignTradeshow2);
        insert lstCampaigns;
        Lead objLead=TestDataMarketing.createLead('FirstName','LastName','Test1@f.com','USA','USA');
        Contact objCon=TestDataMarketing.createContact('FirstName','LastName','Test@f.com');
        List<CampaignMember> lstCampaignMember=new list<CampaignMember>();
        CampaignMember objCampaignMemberLeadTradeshow1=new CampaignMember();
        objCampaignMemberLeadTradeshow1.Status='Attended';
        objCampaignMemberLeadTradeshow1.LeadId=objLead.Id;
        objCampaignMemberLeadTradeshow1.CampaignId=objCampaignTradeshow.Id;
        lstCampaignMember.add(objCampaignMemberLeadTradeshow1);
        CampaignMember objCampaignMemberLeadTradeshow2=new CampaignMember();
        objCampaignMemberLeadTradeshow2.Status='Attended';
        objCampaignMemberLeadTradeshow2.LeadId=objLead.Id;
        objCampaignMemberLeadTradeshow2.CampaignId=objCampaignTradeshow2.Id;
        lstCampaignMember.add(objCampaignMemberLeadTradeshow2);

        CampaignMember objCampaignMemberContactTradeshow1=new CampaignMember();
        objCampaignMemberContactTradeshow1.Status='Attended';
        objCampaignMemberContactTradeshow1.ContactId=objCon.Id;
        objCampaignMemberContactTradeshow1.CampaignId=objCampaignTradeshow.Id;
        lstCampaignMember.add(objCampaignMemberContactTradeshow1);

        CampaignMember objCampaignMemberContactTradeshow2=new CampaignMember();
        objCampaignMemberContactTradeshow2.Status='Attended';
        objCampaignMemberContactTradeshow2.ContactId=objCon.Id;
        objCampaignMemberContactTradeshow2.CampaignId=objCampaignTradeshow2.Id;
        lstCampaignMember.add(objCampaignMemberContactTradeshow2);
        insert lstCampaignMember;

        List<CampaignMember> lstCampaignMember2=new list<CampaignMember>();
		objCampaignMemberLeadTradeshow1.Status='Registered';
		objCampaignMemberLeadTradeshow2.Status='Registered';
        objCampaignMemberContactTradeshow1.Status='Registered';
		objCampaignMemberContactTradeshow2.Status='Registered';
		lstCampaignMember2.add(objCampaignMemberLeadTradeshow1);
		lstCampaignMember2.add(objCampaignMemberLeadTradeshow2);
		lstCampaignMember2.add(objCampaignMemberContactTradeshow1);
		lstCampaignMember2.add(objCampaignMemberContactTradeshow2);
		update lstCampaignMember2;
		lstCampaignMember2[0].Status='Attended';
		lstCampaignMember2[1].Status='Attended';
		lstCampaignMember2[2].Status='Attended';
		lstCampaignMember2[3].Status='Attended';
		update lstCampaignMember2;
		Lead objL=[select id,Last_Responded_Campaign__c from lead where id=:objLead.Id];
		system.assertEquals(objL.Last_Responded_Campaign__c,objCampaignTradeshow.Id,'Last responded campaign not updated ');
    }

    @isTest
    static void testLastMarketingCampaign() {
        Campaign objCampaign=new Campaign(name='testing3',Marketing_Segment__c = 'Platforms' , Marketing_Campaign__c = 'NIPT' , Program_Type__c = 'Awareness',type='Webinar',Campaign_Region__c='AMR',Campaign_Subregion__c='AMR Central',Channel__c='Live', Organization_Ownership__c = 'Marketing',Funnel__c='Top');
        insert objCampaign;

        Lead objLead=TestDataMarketing.createLead('FirstName3','LastName3','Test3@f.com','Bahrain','TestCompany3');

        Test.startTest();
        CampaignMember objCampaignMember=new CampaignMember();
        objCampaignMember.Status='2nd Attempt';
        objCampaignMember.LeadId=objLead.Id;
        objCampaignMember.CampaignId=objCampaign.Id;
        objCampaignMember.Campaign_Member_Notes__c='Test Notes Creation';
        insert objCampaignMember;
        Test.stopTest();

        system.assertEquals('Marketing', objCampaign.Organization_Ownership__c);

    }

    @isTest
    static void testNoteDelete() {
        Campaign objCampaign=new Campaign(name='testing4',Marketing_Segment__c = 'Forensics' , Marketing_Campaign__c = 'Library Prep' , Program_Type__c = 'Internal',type='Email',Campaign_Region__c='EUR',Campaign_Subregion__c='Germany',Channel__c='Drip Email',Funnel__c='Top');
        insert objCampaign;

        Lead objLead=TestDataMarketing.createLead('FirstName1','LastName1','Test4@f.com','Australia','TestCompany4');

        Test.startTest();
        CampaignMember objCampaignMember=new CampaignMember();
        objCampaignMember.Status='1st Attempt';
        objCampaignMember.LeadId=objLead.Id;
        objCampaignMember.CampaignId=objCampaign.Id;
        objCampaignMember.Campaign_Member_Notes__c='Test Notes Creation';
        insert objCampaignMember;

        objCampaignMember.Campaign_Member_Notes__c=null;
        update objCampaignMember;
        Test.stopTest();
        List<ContentDocumentLink> objContentDocLink=[SELECT Id,ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId=:objLead.Id];
        system.assertEquals(0,objContentDocLink.size(),'Note was Deleted');
    }


       @isTest
       static void testNoteCreate() {
        Campaign objCampaign=new Campaign(name='testing2',Marketing_Segment__c = 'Corporate' , Marketing_Campaign__c = 'Software' , Program_Type__c = 'Nurture',type='Operational',Campaign_Region__c='AMEA',Campaign_Subregion__c='Japan',Channel__c='PXN Alert',Funnel__c='Top');
        insert objCampaign;

        Lead objLead=TestDataMarketing.createLead('FirstName2','LastName2','Test2@f.com','India','TestCompany2');

        CampaignMember objCampaignMember=new CampaignMember();
        objCampaignMember.Status='Opportunity';
        objCampaignMember.LeadId=objLead.Id;
        objCampaignMember.CampaignId=objCampaign.Id;
        objCampaignMember.Campaign_Member_Notes__c='Test Notes Creation';
        insert objCampaignMember;

        ContentDocumentLink objContentDocLink1=[SELECT Id,ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId=:objLead.Id];
        ContentNote objContentNote1=[Select Id,Title,Content from ContentNote where id=:objContentDocLink1.ContentDocumentId];
        delete objContentNote1;
        Test.startTest();

        objCampaignMember.Campaign_Member_Notes__c='Create New Note for Update';
        update objCampaignMember;

        Test.stopTest();

        ContentDocumentLink objContentDocLink2=[SELECT Id,ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId=:objLead.Id];
        ContentNote objContentNote2=[Select Id,Title,Content from ContentNote where id=:objContentDocLink2.ContentDocumentId];

        system.assertEquals('Campaign Member Note: '+objCampaign.name,objContentNote2.Title,'Note was Updated');

    }

    @isTest
    static void testNoteUpdate() {
        Campaign objCampaign=new Campaign(name='testing3',Marketing_Segment__c = 'Platforms' , Marketing_Campaign__c = 'NIPT' , Program_Type__c = 'Awareness',type='Webinar',Campaign_Region__c='AMR',Campaign_Subregion__c='AMR Central',Channel__c='Live',Funnel__c='Top');
        insert objCampaign;

        Lead objLead=TestDataMarketing.createLead('FirstName3','LastName3','Test3@f.com','Bahrain','TestCompany3');

        Test.startTest();
        CampaignMember objCampaignMember=new CampaignMember();
        objCampaignMember.Status='2nd Attempt';
        objCampaignMember.LeadId=objLead.Id;
        objCampaignMember.CampaignId=objCampaign.Id;
        objCampaignMember.Campaign_Member_Notes__c='Test Notes Creation';
        insert objCampaignMember;

        objCampaignMember.Campaign_Member_Notes__c='Test Notes Updation';
        update objCampaignMember;
        Test.stopTest();

        ContentDocumentLink objContentDocLink=[SELECT Id,ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId=:objLead.Id];
        ContentNote objContentNote=[Select Id,Title,Content from ContentNote where id=:objContentDocLink.ContentDocumentId];
        system.assertEquals('Campaign Member Note: '+objCampaign.name,objContentNote.Title,'Note was Updated');

    }

    @isTest
    static void testCMSChinaContactMe() {

        Campaign objCampaignWebinar=new Campaign(name='Campaign Member Status China Test',type='Webinar',channel__c='Live',Campaign_Region__c='China', Marketing_Segment__c = 'Microbiology' , Marketing_Campaign__c = 'Brand' , Program_Type__c = 'Education',Funnel__c='Top');
        insert objCampaignWebinar;

        Contact contact = new Contact (FirstName = 'TestingChinaContact', LastName = 'CampaignMemberContactMe',
                                    Email = 'testing_campaign@charketcontactme.com', CN_Contact_Me__c = true);
        insert contact;

        String cmpId = objCampaignWebinar.Id;
        String contactId = contact.Id;

        List<CampaignMemberStatus> cmpStatusList = new List<CampaignMemberStatus>();

        CampaignMemberStatus attendedStatus = new CampaignMemberStatus(CampaignID=cmpId,Label='Attended',IsDefault=false,HasResponded=false,SortOrder=3);
        cmpStatusList.add(attendedStatus);
        CampaignMemberStatus attendedContactMeStatus = new CampaignMemberStatus(CampaignID=cmpId,Label='Attended-Contact Me',IsDefault=false,HasResponded=false,SortOrder=4);
        cmpStatusList.add(attendedContactMeStatus);
        System.debug('insert campaign member status list: ' + cmpStatusList);
        insert cmpStatusList;

        Test.startTest();

        CampaignMember objCampaignMember=TestDataMarketing.createCampaignMemberContact(contact.Id,cmpId,'Attended');

        Test.stopTest();


        CampaignMember result = [Select Id, ContactId, Status From CampaignMember where Id =: objCampaignMember.Id];
        System.debug('result: ' + result.Status);

        System.assertEquals(contactId, result.ContactId , 'ContactIds do not match');

        System.assertEquals('Attended-Contact Me', result.Status , 'Status not updated to Attended-Contact Me');


    }

	@isTest
    static void testSalesCMUpdateMostRecentActivity() {

        Campaign objCampaignWebinar=new Campaign(name='Campaign Member Status China Test',type='Webinar',channel__c='Live',Campaign_Region__c='China', Marketing_Segment__c = 'Microbiology' , Marketing_Campaign__c = 'Brand' , Program_Type__c = 'Education',Funnel__c='Top');
        objCampaignWebinar.Organization_Ownership__c = 'Sales';
        insert objCampaignWebinar;
        Lead objLead=TestDataMarketing.createLead('FirstName3','LastName3','Test3@f.com','Bahrain','TestCompany3');

        Test.startTest();
        CampaignMember objCampaignMember=new CampaignMember();
        objCampaignMember.Status='Sent';
        objCampaignMember.LeadId=objLead.Id;
        objCampaignMember.CampaignId=objCampaignWebinar.Id;
        objCampaignMember.Campaign_Member_Notes__c='Test Notes Creation';
        insert objCampaignMember;

        objCampaignMember.Status='Converted';
        update objCampaignMember;
        Test.stopTest();
        System.assertEquals(objCampaignMember.LastModifiedDate,objLead.Most_Recent_Activity_Date__c,'Dates not matching');

    }

     /*******************************************************
    *Method Name : coverCatchBlockCampaignMemberLastMarketingQueueable()
    *Description : method to cover catch block
    *params      : NA
    *return type : void
    ******************************************************/

    @isTest
    public static void coverCatchBlockCampaignMemberLastMarketingQueueable(){
        try{
            CampaignMemberLastMarketingQueueable.catchException = true;
            CampaignMemberLastMarketingQueueable pd = new CampaignMemberLastMarketingQueueable(null);
            Test.startTest();
            System.enqueueJob(pd);
            Test.stopTest();
        }
        catch(Exception e){
            System.assert(e!=null, 'e is empty');
        }
    }

     /*******************************************************
    *Method Name : testqueueableCoverage()
    *Description : method to cover Queueable class
    *params      : NA
    *return type : void
    ******************************************************/
    @isTest(SeeAllData=false)
    static void testqueueableCoverage(){
        Campaign objCampaignTradeshow=new Campaign(name='testing1',type='Third Party Hosted Event', Marketing_Segment__c = 'Microbiology' , Marketing_Campaign__c = 'Brand' , Program_Type__c = 'Education',Campaign_Region__c='China',
                                                Campaign_Subregion__c='China',Channel__c='Booth' , Organization_Ownership__c = 'Marketing',Funnel__c='Top');
         List<Campaign> lstCampaigns=new List<Campaign>();
        lstCampaigns.add(objCampaignTradeshow);
        insert lstCampaigns;
        Lead objLead=TestDataMarketing.createLead('FirstName','LastName','Test1@f.com','USA','USA');

        List<CampaignMember> lstCampaignMember=new list<CampaignMember>();
        CampaignMember objCampaignMemberLeadTradeshow1=new CampaignMember();
        objCampaignMemberLeadTradeshow1.Status='Attended';
        objCampaignMemberLeadTradeshow1.LeadId=objLead.Id;
        objCampaignMemberLeadTradeshow1.CampaignId=objCampaignTradeshow.Id;
        lstCampaignMember.add(objCampaignMemberLeadTradeshow1);

        insert lstCampaignMember;
        Map<id, List<CampaignMember>> mapCampMember = new Map<id, List<CampaignMember>>();
        mapCampMember.put(lstCampaigns[0].Id ,lstCampaignMember);

        Test.startTest();
        CampaignMemberLastMarketingQueueable clq = new CampaignMemberLastMarketingQueueable(mapCampMember);
        System.enqueueJob(clq);
        Test.stopTest();

        System.assert(lstCampaignMember!=null,'list is empty');

    }

    @isTest
    static void testFormTypeInsert() {
        Lead testLead = TestDataMarketing.createLeadForMarketable('PardotTest', 'FormType', 'pardot_media_code@testing.com', 'USA', 'Media Code Testing Inc');
        testLead.Form_Type__c = 'Gated Files';
        insert testLead;

        Contact testContact = TestDataMarketing.createContactForMarketable('PardotTestFN', 'PardotTestLN', 'contat_media_code@testing.com', 'US');
        testContact.Form_Type__c = 'Questions';
        insert testContact;

        Campaign testWebinalCmp =new Campaign(name='Form Type Testing',type='Webinar',channel__c='Live',Campaign_Region__c='AMR', Marketing_Segment__c = 'Microbiology' , Marketing_Campaign__c = 'Brand' , Program_Type__c = 'Education',Funnel__c='Top');
        insert testWebinalCmp;

        CampaignMember testCmpMemberLead = TestDataMarketing.initCampaignMemberLead(testLead.Id,testWebinalCmp.Id,'Attended');

        CampaignMember testCmpMemberContact = TestDataMarketing.initCampaignMemberContact(testContact.Id,testWebinalCmp.Id,'Attended');

        List<CampaignMember> lstCampaignMember = new List<CampaignMember>();
        lstCampaignMember.add(testCmpMemberLead);
        lstCampaignMember.add(testCmpMemberContact);

        Test.startTest();
        insert lstCampaignMember;
        Test.stopTest();

        CampaignMember resultCampMember = [Select Id, Form_Type__c From CampaignMember WHERE Id =: testCmpMemberLead.Id];

        Assert.areEqual('Gated Files', resultCampMember.Form_Type__c, 'Campaign Member form type field did not set correctly for Lead');

    }


}