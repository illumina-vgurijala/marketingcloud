//TestPMScheduleSelector
/*@ author       : Prashanth
* @ date         : 20-08-2019
* @ Description  : Test class for PMScheduleDefinitionSelector class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                              Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Prashanth                20-08-2019                        Initial version
*/
@isTest
public class TestPMScheduleSelector{
    static testMethod void selectSchForPMPlansTest(){
        //SVMXC__PM_Plan__c
        SVMXC__PM_Plan__c pmPlan = new SVMXC__PM_Plan__c();
        pmPlan.Name='BYANNUAL Plan';
        pmPlan.CurrencyIsoCode='USD';
        insert pmPlan;
        
        //PM schedule
        SVMXC__PM_Schedule__c sch = new SVMXC__PM_Schedule__c();
        sch.SVMXC__PM_Plan__c = pmPlan.Id;
        sch.SVMXC__Last_Run_Date__c = system.today();
        sch.SVMXC__Scheduled_On__c = system.today().addyears(1);
        insert sch;
        Test.startTest();
        List<SVMXC__PM_Schedule__c> lstSchDefs = new PMScheduleSelector().selectSchsForPMPlans(new Set<Id>{pmPlan.Id});
        System.assert(lstSchDefs.size() == 1);
        Test.stopTest();
    }
}