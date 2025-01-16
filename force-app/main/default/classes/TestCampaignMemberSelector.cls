/**
 *    @author Rishab Wali
 *    @date   01-Sep-2021
 *    @description: Test class for CampaignMemberSelector
 *    Modification Log:
 *    ------------------------------------------------------------------------------------
 *    Developer                      Date                Description
 *    Rishab Wali                  01-Sep-2021          Original version
 *    ------------------------------------------------------------------------------------
 *
 */
@istest
public without sharing class TestCampaignMemberSelector {


    static testMethod void testFeatureFlagOn(){

        // config environment to enable query logs
        Feature.setMockFeatureFlag('MarketingQueryLogs', true);
                
        // setting query threshold to zero to log all queries for testing
        setThreshholdsToZero();

        Test.startTest();
        Campaign objCampaign=new Campaign(name='Test Campaign',Type='Tele Prospecting / Sales Campaign');
        insert objCampaign;
        lead objLead=TestDataMarketing.createLeadForMarketable('testfirstname1','testlastname1','test1@gmail.com','Germany','test1Company');
        Contact objCon=TestDataMarketing.createContact('FirstName','LastName','Test@f.com');
        insert objLead;
        CampaignMember objCampaignMember1=TestDataMarketing.createCampaignMember(objLead.id,objCampaign.id,'Attended');
        CampaignMember objCampaignMember2=TestDataMarketing.createCampaignMemberContact(objCon.id,objCampaign.id,'Attended'); 
        new CampaignMemberSelector().selectCampaignMembersList(new List<CampaignMember>{objCampaignMember1,objCampaignMember2});
        new CampaignMemberSelector().selectCampaignMembersListContact(new Set<String>{objCon.Id},new Set<String>{objCampaign.Id});
        new CampaignMemberSelector().selectCampaignMembersListLead(new Set<String>{objLead.Id},new Set<String>{objCampaign.Id});
        new CampaignMemberSelector().selectOrderedMarketingCampaignMembersLead(new Set<Id>{objLead.Id});
        new CampaignMemberSelector().selectOrderedMarketingCampaignMembersContact(new Set<Id>{objCon.Id});
        new CampaignMemberSelector().selectCampaignMembersContact(new Set<Id>{objCon.Id},new Set<Id>{objCampaignMember1.Id});
        new CampaignMemberSelector().selectCampaignMembersLead(new Set<Id>{objLead.Id},new Set<Id>{objCampaignMember1.Id});
        new CampaignMemberSelector().selectCampaignMembers(new Set<Id>{objCampaignMember1.Id,objCampaignMember2.Id});
        new CampaignMemberSelector().selectCampaignMembersListCampaign(new Set<Id>{objCampaign.Id});
        ilib_LogEvent.emit();
        Test.getEventBus().deliver();
        Test.stopTest();
        System.debug([SELECT Id,Title__c FROM ILMN_Debug_Log__c LIMIT 10]);
        String slowQueryTitle = ilib_LogEvent.SLOW_QUERY_LOG_TITLE_PREFIX + 'CampaignMemberSelector.selectCampaignMembersList';
        List<ILMN_Debug_Log__c> lstDebugs = [SELECT Id FROM ILMN_Debug_Log__c WHERE Title__c LIKE :slowQueryTitle];
        System.assert(!lstDebugs.isEmpty(),'No queries found');
    }

    static testMethod void testFeatureFlagOff(){

        // config environment to enable query logs
        Feature.setMockFeatureFlag('MarketingQueryLogs', false);
                
        // setting query threshold to zero to log all queries for testing
        setThreshholdsToZero();

        Test.startTest();
        Campaign objCampaign=new Campaign(name='Test Campaign',Type='Tele Prospecting / Sales Campaign');
        insert objCampaign;
        lead objLead=TestDataMarketing.createLeadForMarketable('testfirstname1','testlastname1','test1@gmail.com','Germany','test1Company');
        Contact objCon=TestDataMarketing.createContact('FirstName','LastName','Test@f.com');
        insert objLead;
        CampaignMember objCampaignMember1=TestDataMarketing.createCampaignMember(objLead.id,objCampaign.id,'Attended');
        CampaignMember objCampaignMember2=TestDataMarketing.createCampaignMemberContact(objCon.id,objCampaign.id,'Attended'); 
        new CampaignMemberSelector().selectCampaignMembersList(new List<CampaignMember>{objCampaignMember1,objCampaignMember2});
        new CampaignMemberSelector().selectCampaignMembersListContact(new Set<String>{objCon.Id},new Set<String>{objCampaign.Id});
        new CampaignMemberSelector().selectCampaignMembersListLead(new Set<String>{objLead.Id},new Set<String>{objCampaign.Id});
        new CampaignMemberSelector().selectOrderedMarketingCampaignMembersLead(new Set<Id>{objLead.Id});
        new CampaignMemberSelector().selectOrderedMarketingCampaignMembersContact(new Set<Id>{objCon.Id});
        new CampaignMemberSelector().selectCampaignMembersContact(new Set<Id>{objCon.Id},new Set<Id>{objCampaignMember1.Id});
        new CampaignMemberSelector().selectCampaignMembersLead(new Set<Id>{objLead.Id},new Set<Id>{objCampaignMember1.Id});
        new CampaignMemberSelector().selectCampaignMembers(new Set<Id>{objCampaignMember1.Id,objCampaignMember2.Id});
        new CampaignMemberSelector().selectCampaignMembersListCampaign(new Set<Id>{objCampaign.Id});
        ilib_LogEvent.emit();
        Test.getEventBus().deliver();
        Test.stopTest();
        String slowQueryTitle = ilib_LogEvent.SLOW_QUERY_LOG_TITLE_PREFIX + 'CampaignMemberSelector.selectCampaignMembersList';
        System.assertEquals(0,[SELECT count() FROM ILMN_Debug_Log__c WHERE Title__c LIKE :slowQueryTitle],'No Slow Queries.');
    }

    private static void setThreshholdsToZero()
    {
        PS_Log_Setting__mdt settings = new ilib_LogSettings().query();
        settings.Slow_Query_Threshold__c = 0.0;
        settings.Slow_Transaction_Threshold__c = 0.0;
        settings.Disable_All_Log_Persistence__c = false;
        settings.Disable_Slow_Query_Publish__c = false;
        settings.Disable_Slow_Transaction_Publish__c = false;
        //CMSI-2 Pause_Publishes_Until__c moved to code params metadata

        ilib_LogSettings.unitTestSettingsRecord = settings;
    }

}