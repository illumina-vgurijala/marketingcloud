/**
*    @author: Pankaj Singla
*    @date:   12-Aug-2020
*    @description:  TestClass for Attendees,AttendeesSelector,KeyOpinionLeaderSelector,ContractSelector
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla		        12-Aug-2020		       Initial Build
*             Rishab Wali               08-June-2022           [DCP-53883] CodeScan Tech Debt Fix		
*    ------------------------------------------------------------------------------------ 
*                    
*/
@isTest
public class TestAttendees {
    static testMethod void testTriggerinsert(){
        // config environment to enable query logs
        Feature.setMockFeatureFlag('MarketingQueryLogs', true);
        
        // setting query threshold to zero to log all queries for testing
        setThreshholdsToZero();
        Contact con1=TestDataMarketing.createContact('testfirstname','testlastname','test@gmail.com');
        openq__Interaction__c objInteraction=new openq__Interaction__c();
		objInteraction.openq__Date__c=datetime.now();
		objInteraction.openq__Interaction_Type__c='Web Presentation';
        objInteraction.Name='test';
        objInteraction.openq__Interaction_Name__c = 'Test Interaction';
        insert objInteraction;
        
        Contracts__c objContract=new Contracts__c();
        objContract.Contact__c=con1.id;
        objContract.Expiration_Date__c=Date.today();
        objContract.Status__c='Active';
        objContract.Start_Date__c=Date.today();
        insert objContract;
        
        openq__Attendee__c objAttendee=new openq__Attendee__c();
        objAttendee.openq__Contact__c=con1.id;
        objAttendee.openq__Interaction__c=objInteraction.id;
        insert objAttendee;
        
        Contracts__c objContract2=new Contracts__c();
        objContract2.Contact__c=Con1.id;
        objContract2.Expiration_Date__c=Date.today();
        objContract2.Status__c='Active';
        objContract2.Start_Date__c=Date.today();
        insert objContract2;
        Test.startTest();
        Database.executeBatch(new BatchOpenQDataUpdate());
        Test.stopTest();
        String slowQueryTitle = ilib_LogEvent.SLOW_QUERY_LOG_TITLE_PREFIX + 'AttendeeSelector.selectAttendeesByContactIds';
        System.assert([SELECT Id FROM ILMN_Debug_Log__c WHERE Title__c LIKE :slowQueryTitle].size()>0,'No queries found');
    }

    static testMethod void testFeatureFlagOff(){
        // config environment to enable query logs
        Feature.setMockFeatureFlag('MarketingQueryLogs', false);
        
        // setting query threshold to zero to log all queries for testing
        setThreshholdsToZero();
        Contact con1=TestDataMarketing.createContact('testfirstname','testlastname','test@gmail.com');
        openq__Interaction__c objInteraction=new openq__Interaction__c();
		objInteraction.openq__Date__c=datetime.now();
		objInteraction.openq__Interaction_Type__c='Web Presentation';
        objInteraction.Name='test';
        objInteraction.openq__Interaction_Name__c = 'Test Interaction';
        insert objInteraction;
        
        Contracts__c objContract=new Contracts__c();
        objContract.Contact__c=con1.id;
        objContract.Expiration_Date__c=Date.today();
        objContract.Status__c='Active';
        objContract.Start_Date__c=Date.today();
        insert objContract;
        
        openq__Attendee__c objAttendee=new openq__Attendee__c();
        objAttendee.openq__Contact__c=con1.id;
        objAttendee.openq__Interaction__c=objInteraction.id;
        insert objAttendee;
        
        Contracts__c objContract2=new Contracts__c();
        objContract2.Contact__c=Con1.id;
        objContract2.Expiration_Date__c=Date.today();
        objContract2.Status__c='Active';
        objContract2.Start_Date__c=Date.today();
        insert objContract2;
        Test.startTest();
        Database.executeBatch(new BatchOpenQDataUpdate());
        Test.stopTest();
        String slowQueryTitle = ilib_LogEvent.SLOW_QUERY_LOG_TITLE_PREFIX + 'AttendeeSelector.selectAttendeesByContactIds';
        System.assertEquals(0,[SELECT count() FROM ILMN_Debug_Log__c WHERE Title__c LIKE :slowQueryTitle],'Slow queries found');
    }

    private static void setThreshholdsToZero()
     {
         PS_Log_Setting__mdt settings = new ilib_LogSettings().query();
         settings.Slow_Query_Threshold__c = 0.0;
         settings.Slow_Transaction_Threshold__c = 0.0;
         settings.Disable_All_Log_Persistence__c = false;
         settings.Disable_Slow_Query_Publish__c = false;
         settings.Disable_Slow_Transaction_Publish__c = false;

         ilib_LogSettings.unitTestSettingsRecord = settings;
     }
}