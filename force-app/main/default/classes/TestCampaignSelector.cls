/**
 *    @author Rishab Wali
 *    @date   01-Sep-2021
 *    @description: Test class for CampaignSelector
 *    Modification Log:
 *    ------------------------------------------------------------------------------------
 *    Developer                      Date                Description
 *    Rishab Wali                  01-Sep-2021          Original version
 *    ------------------------------------------------------------------------------------
 *
 */
@istest
public without sharing class TestCampaignSelector {

    static testMethod void testFeatureFlagOn(){
        
        // config environment to enable query logs
        Feature.setMockFeatureFlag('MarketingQueryLogs', true);
        
        // setting query threshold to zero to log all queries for testing
        setThreshholdsToZero();
            
        Test.startTest();
        Campaign objCampaign=new Campaign(name='Test Campaign',Type='Tele Prospecting / Sales Campaign',Funnel__c='Top');
        insert objCampaign; 
        new CampaignSelector().selectCampaign(new Set<String>{'testZouraId'});
        new CampaignSelector().selectCampaignOrganizationOwnership(new Set<Id>{objCampaign.Id});
        new CampaignSelector().selectCampaigns(new Set<Id>{objCampaign.Id});
        ilib_LogEvent.emit();
        Test.getEventBus().deliver();
        Test.stopTest();
        String slowQueryTitle = ilib_LogEvent.SLOW_QUERY_LOG_TITLE_PREFIX + 'CampaignSelector.selectCampaignOrganizationOwnership'; 
        Assert.isTrue([SELECT count() FROM ILMN_Debug_Log__c WHERE Title__c LIKE :slowQueryTitle] > 0, 'slow query log did not create');   
    }

    static testMethod void campaignSelectorFFOff() {

        // config environment to enable query logs
        Feature.setMockFeatureFlag('MarketingQueryLogs', false);

        // setting query threshold to zero to log all queries for testing
        setThreshholdsToZero();

        Campaign objCampaignWebinar=new Campaign(name='Campaign Member Selector Test',type='Webinar',channel__c='Live',Campaign_Region__c='AMR', Marketing_Segment__c = 'Microbiology' , Marketing_Campaign__c = 'Brand' , Program_Type__c = 'Education',Funnel__c='Top');
        insert objCampaignWebinar;

        Set<Id> campIdSet = new Set<Id>();
        campIdSet.add(objCampaignWebinar.Id);

        Set<String>dummyZuoraProductSet = new Set<String>();

        //adding random text in product set
        dummyZuoraProductSet.add('Zuora');

        Test.startTest();
        new CampaignSelector().selectCampaigns(campIdSet);
        new CampaignSelector().selectCampaignOrganizationOwnership(campIdSet);
        new CampaignSelector().selectCampaign(dummyZuoraProductSet);
        ilib_LogEvent.emit();
        Test.getEventBus().deliver();
        Test.stopTest();

        String slowQueryTitle = ilib_LogEvent.SLOW_QUERY_LOG_TITLE_PREFIX + 'CampaignSelector.selectCampaigns';
        System.assertEquals(0, [SELECT count() FROM ILMN_Debug_Log__c WHERE Title__c LIKE :slowQueryTitle],'No Slow Queries.');

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