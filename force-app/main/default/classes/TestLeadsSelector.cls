/**
 *    @author Monika
 *    @date   28-Sep-2020
 *    @description: Test class for LeadsSelector
 *    Modification Log:
 *    ------------------------------------------------------------------------------------
 *    Developer                      Date                Description
 *    Monika Parihar              28-Sep-2020          Original version
 *    Deep Diwakar                Jun-27-2024          CMCM-6457: Added test method for selectConvertedLeadsWithWaterfall method
 *    Deep Diwakar                Jul-29-2024          CMCM-7519: Added test method for selectLeadFieldsForTask method
 *    Deep Diwakar                Aug-09-2024          CMCM-9421: Added test method for selectContactsForCampMemberFields method
 *    ------------------------------------------------------------------------------------
 *
 */
@istest
public class TestLeadsSelector {
    /**
    *  @description Test class for LeadsSelector methods.
    *
    **/
    @istest
    static void testAll(){
        Lead objLead1=TestDataMarketing.createLeadForMarketable('testfirstname2','testlastname1','test2@gmail.com','Germany','test2Company');
        objLead1.CountryCode='DE';
        objLead1.Email_Verification_Date__c = Date.today();
        objLead1.Email_Verification_Status__c = 'Verified Successfully';
        insert objLead1;
        System.assert(objLead1.Id != null);
        Test.startTest();
        List<Lead> lstLeads = new LeadsSelector().selectLeadsWithSftwDwnldByEmail(new Set<String>{objLead1.Email});
        System.assert(lstLeads != null);
        new LeadsSelector().selectLeadsForPGUID(new Set<String>{'123456'});
        new LeadsSelector().returnAutoConvertMergeCheckbox(new List<Id>{objLead1.Id});
        new LeadsSelector().returnNonConvertedLeads(new List<Id>{objLead1.Id});


        //CMCM-6457: testing this selector method
        List<Lead> lstTestLeads = new LeadsSelector().selectConvertedLeadsWithWaterfall(new Set<Id>{objLead1.Id});
        Assert.areEqual(0, lstTestLeads.size(), 'Converted lead query did not work correctly');
        Test.stopTest();
    }

    @isTest
    static void testSelectLeadFieldsForTask() {
        Lead testLead = TestDataMarketing.createLeadForMarketable('Marketing', 'Testing', 'marketing_task@testing.com', 'USA', 'Marketing Task Testing Inc');
        testLead.Form_Type__c = 'Gated Files';
        testLead.Product_Interest__c = 'Consumables';
        testLead.Questions_For_Rep__c = 'Please refer to the Questions for Rep field for more information about this Lead inquiry';
        testLead.Last_Form_Submission_URL__c = 'www.test.com';

        insert testLead;

        Test.startTest();
        List<Lead> lstLeadtWithTaskFields = new LeadsSelector().selectLeadFieldsForTask(new Set<Id>{testLead.Id});
        Test.stopTest();

        Assert.areEqual('Gated Files',lstLeadtWithTaskFields.get(0).Form_Type__c, 'Selector method selectLeadFieldsForTask did not query form type field correctly ');
    

    }

    @isTest
    static void testSelectLeadsForCampMemberFields() {
        Lead testLead = TestDataMarketing.createLeadForMarketable('Marketing', 'Testing', 'marketing_task@testing.com', 'USA', 'Marketing Task Testing Inc');
        testLead.Form_Type__c = 'Gated Files';
        testLead.Media_Code__c = 'Random123';
       

        insert testLead;

        Test.startTest();
        List<Lead> lstLeadtWithTaskFields = new LeadsSelector().selectLeadsForCampMemberFields(new Set<Id>{testLead.Id});
        Test.stopTest();

        Assert.areEqual('Gated Files',lstLeadtWithTaskFields.get(0).Form_Type__c, 'Selector method selectLeadsForCampMemberFields did not query form type field correctly ');
    

    }

    /**
     * @author:         Deep Diwakar
     * @date:           07-16-2021
     * @description     This method test SOQL instrumentation when feature flag is On
     */
    @isTest
     static void leadsSelectorFFOn() {

         // config environment to enable query logs
         Feature.setMockFeatureFlag('MarketingQueryLogs', true);

         // setting query threshold to zero to log all queries for testing
         setThreshholdsToZero();

         Lead testLead = TestDataMarketing.createLeadForMarketable('testfirstname2','testlastname1','test2@gmail.com','Germany','test2Company');
         insert testLead;

         Set<String> testSet = new Set<String>();
         testSet.add('testPGUID');
         testSet.add('testEmail');

         List<Id> leadIdList = new List<Id>();
         leadIdList.add(testLead.Id);

         Test.startTest();
         // instrumented queries from LeadsSelector class
         new LeadsSelector().selectLeadsForPGUID(testSet);
         new LeadsSelector().selectLeadsWithSftwDwnldByEmail(testSet);
         new LeadsSelector().returnAutoConvertMergeCheckbox(leadIdList);
         new LeadsSelector().returnNonConvertedLeads(leadIdList);

         ilib_LogEvent.emit();
         Test.getEventBus().deliver();
         Test.stopTest();

         String slowQueryTitle = ilib_LogEvent.SLOW_QUERY_LOG_TITLE_PREFIX + 'LeadsSelector.selectLeadsForPGUID';

         // Adjusted assert for UAT build fix
         Assert.isTrue([SELECT count() FROM ILMN_Debug_Log__c WHERE Title__c LIKE :slowQueryTitle] > 0, 'slow query log did not create');


     }

  /**
    * @author:         Deep Diwakar
    * @date:           07-16-2021
    * @description     This method test SOQL instrumentation when feature flag is Off
    */
     @isTest
     static void leadsSelectorFFOff() {

         // config environment to enable query logs
         Feature.setMockFeatureFlag('MarketingQueryLogs', false);

         // setting query threshold to zero to log all queries for testing
         setThreshholdsToZero();

         Lead testLead = TestDataMarketing.createLeadForMarketable('testfirstname2','testlastname1','test2@gmail.com','Germany','test2Company');
         insert testLead;

         Set<String> testSet = new Set<String>();
         testSet.add('testPGUID');
         testSet.add('testEmail');

         List<Id> leadIdList = new List<Id>();
         leadIdList.add(testLead.Id);

         Test.startTest();
         // instrumented queries from LeadsSelector class
         new LeadsSelector().selectLeadsForPGUID(testSet);
         new LeadsSelector().selectLeadsWithSftwDwnldByEmail(testSet);
         new LeadsSelector().returnAutoConvertMergeCheckbox(leadIdList);
         new LeadsSelector().returnNonConvertedLeads(leadIdList);

         ilib_LogEvent.emit();
         Test.getEventBus().deliver();
         Test.stopTest();

         String slowQueryTitle = ilib_LogEvent.SLOW_QUERY_LOG_TITLE_PREFIX + 'LeadsSelector.selectLeadsForPGUID';
         System.assertEquals(0, [SELECT count() FROM ILMN_Debug_Log__c WHERE Title__c LIKE :slowQueryTitle]);

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