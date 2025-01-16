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
public class TestPMScheduleDefinitionSelector{
    static testMethod void selectSchDefsForPMPlansTest(){
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;
        System.assert(acc.Id != null);
        //pm template
        SVMXC__PM_Plan_Template__c pmTemplate = new SVMXC__PM_Plan_Template__c();
		pmTemplate.Name='Test PM Template';
		pmTemplate.CurrencyIsoCode='USD';
		insert pmTemplate;
		
		//Service Plan
		SVMXC__Service_Plan__c testServicePlan = new SVMXC__Service_Plan__c();
		testServicePlan.Name = 'Test Service Plan';
		testServicePlan.SVMXC__Active__c = true;
		testServicePlan.OQ_Required__c = true;
		insert testServicePlan;
		
        //service contract
        SVMXC__Service_Contract__c testServCont = TestDataFieldService.createServiceContract(acc.Id);
        testServCont.SVMXC__Service_Plan__c = testServicePlan.id;
        testServCont.SVMXC__Start_Date__c = system.today();
        testServCont.SVMXC__End_Date__c = system.today().addYears(1);
        insert testServCont;

        //SVMXC__PM_Plan__c
        SVMXC__PM_Plan__c pmPlan = new SVMXC__PM_Plan__c();
        pmPlan.Name='BYANNUAL Plan';
        pmPlan.CurrencyIsoCode='USD';
        pmPlan.SVMXC__PM_Plan_Template__c=pmTemplate.Id;
        pmPlan.SVMXC__Service_Contract__c= testServCont.Id;
        insert pmPlan;

        //schedule definitions
        SVMXC__PM_Schedule_Definition__c schDef = new SVMXC__PM_Schedule_Definition__c();
        schDef.SVMXC__PM_Plan__c = pmPlan.Id;
        schDef.SVMXC__Frequency__c = 26;
        schDef.SVMXC__Frequency_Unit__c = 'Weeks';
        insert schDef;
        Test.startTest();
        List<SVMXC__PM_Schedule_Definition__c> lstSchDefs = new PMScheduleDefinitionSelector().selectSchDefsForPMPlans(new Set<Id>{pmPlan.Id});
		System.assertEquals(1,lstSchDefs.size());
        Test.stopTest();
    }
}