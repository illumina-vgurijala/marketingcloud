/**
 *    @author         : Illumina
 *    @date           :
 *    @description    : Test class for UtilsSettings
 *    Modification Log:
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
 *    Developer                     Date                Description
 *    Vivek R                       06-Oct-22           Codescan fixes: added comments
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
*/ 
@isTest
public class TestUtilsSettings {

    /**
     *  @author      : Illumina
     *  @description : Method to test UtilsSettings methods
    */
    @isTest
    public static void testUtilsSettingsMethods(){
        System.assert(UtilsSettings.CPQCLM_RO_Approver_Steps.size() > 0);
        System.assert(UtilsSettings.getCustomMetadataPicklistMap('Apttus_Config2__Order__c','ERP',false).size() > 0);
        System.assert(UtilsSettings.parseIntegerFromSettingsMap(UtilsSettings.getCustomMetadataMap('Attempt_auto_case_completion'), 
                                                  'AttempCaseCompletion', 200) > 0);
    } 

    @isTest
    private static void isAutomatedUser() {
        Boolean res;
        System.runAs(TestDataUser.getAutomatedUser()) {
            res = UtilsSettings.isAutomatedUser();
        }

        Assert.isTrue(res, 'This user should be considered AutomatedUser');
    }
}