/**
*    @author: prashanth 
*    @date:   20-Jan-2021
*    @description:  Test Class for  BatchCreatePMPlans batch class.
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    ------------------------------------------------------------------------------------ 
*             Prashanth                   20-Jan-2021           Initial Development            
*/
@isTest
public class TestBatchCreatePMPlans {
	/**
	* Method:pmPlanCreationTest
	* params: NA
	* return: NA
	* Description: Tests the BatchCreatePMPlans class functionality to create PM plans.
	*/
    static testMethod void pmPlanCreationTest(){
		//Account
        Account objAccount = TestDataAccount.getNewAccount();
		//Installed product
        SVMXC__Installed_Product__c ip = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
        insert ip;
		System.assert(ip.id != null);

		SVMXC__Service_Plan__c sp1 = new SVMXC__Service_Plan__c();
        sp1.Name = 'Test1';
        sp1.Item_Number__c = '1111';
        insert sp1;
		
		SVMXC__PM_Plan_Template__c pmTemplate = new SVMXC__PM_Plan_Template__c();
		pmTemplate.Name='Test PM Template';
		pmTemplate.CurrencyIsoCode='USD';
		insert pmTemplate;
		
		SVMXC__PM_Offering__c pm = new SVMXC__PM_Offering__c();
		pm.SVMXC__Service_Plan__c=sp1.id;
		pm.SVMXC__PM_Plan_Template__c=pmTemplate.id;
        insert pm;
		System.assert(pm.id != null);

		SVMXC__Service_Contract__c testServCont = TestDataFieldService.createServiceContract(objAccount.Id);
        testServCont.SVMXC__Service_Plan__c = sp1.id;
		testServCont.SVMXC__Start_Date__c = system.today();
		testServCont.SVMXC__End_Date__c = system.today().addYears(1); 
        insert testServCont;
		
		SVMXC__Service_Contract_Products__c cp = TestDataFieldService.createCoveredProduct(ip.Id);
		cp.SVMXC__Service_Contract__c = testServCont.Id;
		insert cp;
		Test.startTest();
		//execute PM batch for creation of PM plan
		database.executebatch(new BatchCreatePMPlans());
		//test scheduler
		BatchCreatePMPlans testObj = new BatchCreatePMPlans();      
        String strCron = '0 0 23 * * ?';
        String jobId = system.schedule('Test Schedule Batch', strCron, testObj);
		CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
		System.assertEquals(strCron,ct.CronExpression);
		Test.stopTest(); 		
    }
}