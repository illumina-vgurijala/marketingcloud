/***************************************************************************************************************************************
 * NAME   : TestDupeblockerScenariosSelector
 * DESCRIPTION  : TestClass for DupeblockerScenariosSelector Apex Class
 *                 
 *    
 * @AUTHOR : Prashanth Kumar
 * @DATE   : 28-Aug-2020
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                        DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Prashanth               28-08-2020               Original version
 * Rishab Wali             21-11-2022               Added Feature Flag On check for Instrumentation Code
**/
@isTest(SeeAllData = false)
public class TestDupeblockerScenariosSelector {
	/**
     * method:selectDupeBlockerScenariosByTypeTest
     * descritpion: Test method for selectDupeBlockerScenariosByType method in DupeblockerScenariosSelector class.
     **/
    static testmethod void selectDupeBlockerScenariosByTypeTest(){

        // config environment to enable query logs
        Feature.setMockFeatureFlag('MarketingQueryLogs', true);
                
        // setting query threshold to zero to log all queries for testing
        setThreshholdsToZero();
        
        //create duplicate scenario
        CRMfusionDBR101__Scenario__c scenario1 = new CRMfusionDBR101__Scenario__c();
        scenario1.Name='Scenario1';
        scenario1.CRMfusionDBR101__Match_on_Insert_Action__c='Do Nothing';
        scenario1.CRMfusionDBR101__Match_on_Update_Action__c='Do Nothing';
        scenario1.CRMfusionDBR101__Scenario_Type__c='Contact';
        scenario1.CRMfusionDBR101__Error_Message__c = 'Duplicates Found!!';
        scenario1.CRMfusionDBR101__Create_Task__c = 'No';
        insert scenario1;
        Test.startTest();
        List<CRMfusionDBR101__Scenario__c> lstScenarios = new DupeblockerScenariosSelector().selectDupeBlockerScenariosByType('Contact');
        Test.getEventBus().deliver();
        System.assert(!lstScenarios.isEmpty(),'Scenario list is empty');
        Test.stopTest();
        
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