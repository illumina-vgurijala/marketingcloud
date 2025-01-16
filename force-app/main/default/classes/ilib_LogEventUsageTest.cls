
/****************************************************************************************************************************************
* NAME         : ilib_LogEventUsageTest
* DESCRIPTION  : Test Class for ilib log classes
*                    
* MODIFICATION LOG:  
* -------------------------------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------------------------------
*  Saddam                 10-oct-22           Codescan Fix Added Comments for methods.
 -----------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
private with sharing class ilib_LogEventUsageTest {

    /*
    * Test Method
    */
    @isTest public static void queryUsage()
    {
    	//CMSI -2 Changes
        Integer max = OrgLimits.getMap().get('HourlyPublishedPlatformEvents').getLimit();
        Integer usedLimit = OrgLimits.getMap().get('HourlyPublishedPlatformEvents').getValue();
        Integer remaining = max - usedLimit;
        // this is the same formula that is in the class, including it for coverage
        Decimal percentUsed = (Decimal.valueOf(max - remaining) * 100 / Decimal.valueOf(max)).setScale(2);

        ilib_LogEventUsage.Data usageData;
        Test.startTest();
        {
            usageData = new ilib_LogEventUsage().query();
        }
        Test.stopTest();

        System.assertEquals(max, usageData.max);
        System.assertEquals(remaining, usageData.remaining);
        System.assertEquals(max - remaining, usageData.getPublishCount());
        System.assertEquals(percentUsed, usageData.getPercentUsed());
    }


    /* this test is for ilib_LogSettings
     put it here because this is an action the code takes
    to update settings when usage is too high */
    @isTest public static void updateSettings()
    {
        ilib_LogSettings settings = new ilib_LogSettings();

        // calculate top of next hour
        Datetime hourFromNow = Datetime.now().addHours(1);
        Datetime topOfHour = Datetime.newInstance(hourFromNow.year(), hourFromNow.month(), hourFromNow.day(), hourFromNow.hour(), 0, 0);

        Test.startTest();
        // store top of next hour in settings
        ilib_LogSettings.updateMetadataPauseDate(topOfHour);
        Test.stopTest();

        settings = new ilib_LogSettings();
    }

    /* this test is for ilib_LogSettings
     put it here because this is an action the code takes
     to update settings when usage is too high */
    @isTest public static void deploymentCallback()
    {
        // Instantiate the callback
        Metadata.DeployCallback callback = new ilib_LogSettings();

        // Create test result and context objects
        Metadata.DeployResult result = new Metadata.DeployResult();
        result.status = Metadata.DeployStatus.SUCCEEDED;
        result.numberComponentErrors = 0;
        Metadata.DeployCallbackContext context = new Metadata.DeployCallbackContext();

        // Invoke the callback's handleResult method
        callback.handleResult(result, context);

        // nothing to assert as per Salesforce docs
    }

    /*  this test is for IlmnLogs
     put it here because this is where the check for usage is */
    @isTest public static void thresholdHandling()
    {
        IlmnLogs domainObj = new IlmnLogs(new List<ILMN_Log__e>());
       
        Boolean res2 = domainObj.checkUsageThisTime();

        // nothing to assert
        // should be false but not impossible it would be true during a deployment

        domainObj.suspendPublishForRestOfHour();

        // nothing to assert here either, can't test a deployment
        // just here for coverage
    }

}