/**
*    @author: Pankaj
*    @date:   05-Oct-2020
*    @description:  Test class for BatchUpdateLastRespondedDate
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla                 05 Oct 2020          Initial build
              
*    ------------------------------------------------------------------------------------
*
*/
@isTest
public class TestBatchUpdateLastRespondedDate{

    @isTest (SeeAllData=true)
    /*See All data is true for Campaign MemberStatus records. However, the main class takes care that it does not
    affect the system data*/
    static void testBatchExecution(){
        lead objLead=TestDataMarketing.createLeadForMarketable('testfirstname1','testlastname1','test1@gmail.com','Germany','test1Company');
        insert objLead;
        Contact objCon=TestDataMarketing.createContact('FirstName','LastName','Test@f.com');
        Campaign objCampaignSeminar=new Campaign(name='testing1dddd',type='Webinar',channel__c='Live',Campaign_Region__c='AMR', Marketing_Segment__c = 'Microbiology' , Marketing_Campaign__c = 'Brand' , Program_Type__c = 'Education',Funnel__c='Top');
        insert objCampaignSeminar;
        Campaign objCampaignWebinar=new Campaign(name='testing1eee',type='Webinar',channel__c='Live',Campaign_Region__c='AMR', Marketing_Segment__c = 'Microbiology' , Marketing_Campaign__c = 'Brand' , Program_Type__c = 'Education',Funnel__c='Top');
        insert objCampaignWebinar;
        
        CampaignMember objCampaignMemberJC=TestDataMarketing.createCampaignMember(objLead.id,objCampaignSeminar.id,'Attended');
        CampaignMember objCampaignMember13=TestDataMarketing.createCampaignMemberContact(objCon.id,objCampaignSeminar.id,'Attended');
        
        
        CampaignMember objCampaignMemberTC=TestDataMarketing.createCampaignMember(objLead.id,objCampaignWebinar.id,'Attended');
        CampaignMember objCampaignMemberW3=TestDataMarketing.createCampaignMemberContact(objCon.id,objCampaignWebinar.id,'Attended');
		
		objLead.Last_Responded_Campaign_Date__c=null;
        objCon.Last_Responded_Campaign_Date__c=null;
        update objLead;
        update objCon;
        Test.StartTest();
        Database.executebatch(new BatchUpdateLastRespondedDate());
        Test.StopTest();
        
        Lead obLead=[select id,Last_Responded_Campaign__c from Lead where id=:objLead.Id];
        system.assert(obLead.Last_Responded_Campaign__c!=null, 'Last responded campaign is null');
    }
}