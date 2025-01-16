/***************************************************************************************************************************************
* NAME         : TestBusinessHoursSettingMetadataSelector
* DESCRIPTION  : Test class businessHoursSettingMetadataSelector
* @AUTHOR      : Venkatesh Prabhu
* @DATE        : 2nd Dec 2024
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
 * Venkatesh Prabhu      2nd Dec 2024       CMCM-12168 Too Many SOQL Queries
****************************************************************************************************************************************/
@isTest
public class TestBusinessHoursSettingMetadataSelector {


    @IsTest
    private static void testGetBusinessHoursSettingMetadata() {
        Business_Hours_Setting__mdt expectedBusinessHoursSetting = [SELECT Id, DeveloperName, MasterLabel, Language, NamespacePrefix, Label, QualifiedApiName, SystemModstamp, EndHourOfTheDay__c, Rejection_Hour_For_SLA_Next_Day__c, Rejection_Hour_For_SLA_Post_Next_Day__c, StartTimeOfTheDay__c FROM Business_Hours_Setting__mdt LIMIT 1];

        Business_Hours_Setting__mdt actualBusinessHoursSetting = new BusinessHoursSettingMetadataSelector().selectDefaultBusinessHourSetting(expectedBusinessHoursSetting.DeveloperName)[0];

        System.assertEquals(expectedBusinessHoursSetting.DeveloperName, actualBusinessHoursSetting.DeveloperName, 'The returned Business_Hours_Setting__mdt record should match the expected record.');
    }

}
