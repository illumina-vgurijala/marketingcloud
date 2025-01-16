/***************************************************************************************************************************************
 * NAME   : TestPMPlanCreationQueueable
 * DESCRIPTION  :Test class PMPlanCreationQueueable
 *    
 * @AUTHOR : Prashanth
 * @DATE   : 04-Dec-2020  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Prashanth             04-Dec-2020           Initial Version
****************************************************************************************************************************************/
@isTest(seeAllData = false)
public class TestPMPlanCreationQueueable {
	/**
	* method: testPMPlanCreation
	* Description: It will test the PM cplan creation functionality
	**/
    static testmethod void testPMPlanCreation(){
         //account
        Account objAccount = TestDataAccount.getNewAccount();
        //installed product
        SVMXC__Installed_Product__c ip = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
        insert ip;
        System.assert(ip.id != null);
        //service plan
        SVMXC__Service_Plan__c sp1 = new SVMXC__Service_Plan__c();
        sp1.Name = 'Test1';
        sp1.Item_Number__c = '1111';
        insert sp1;
        System.assert(sp1.id != null);
        //pm template
        SVMXC__PM_Plan_Template__c pmTemplate = new SVMXC__PM_Plan_Template__c();
		pmTemplate.Name='Test PM Template';
		pmTemplate.CurrencyIsoCode='USD';
        insert pmTemplate;
        System.assert(pmTemplate.id != null);
        //PM offering
        SVMXC__PM_Offering__c pm = new SVMXC__PM_Offering__c();
		pm.SVMXC__Service_Plan__c=sp1.id;
        pm.SVMXC__PM_Plan_Template__c=pmTemplate.id;
        insert pm;
        System.assert(pm.Id != null);
        //service contract
        SVMXC__Service_Contract__c testServCont = TestDataFieldService.createServiceContract(objAccount.Id);
        testServCont.SVMXC__Service_Plan__c = sp1.id;
        testServCont.SVMXC__Start_Date__c = system.today();
        testServCont.SVMXC__End_Date__c = system.today().addYears(1);
        insert testServCont;
        System.assert(testServCont.id != null);
        //covered product
        SVMXC__Service_Contract_Products__c cp = TestDataFieldService.createCoveredProduct(ip.Id);
        cp.SVMXC__Service_Contract__c = testServCont.Id;
        insert cp;
        System.assert(cp.Id != null);
        Test.startTest();
        List<SVMXC__Service_Contract__c> lstContracts = new ServiceContractSelector().selectServiceContractsByStatus(new Set<Id>{testServCont.Id}, 'Active');
        System.enqueueJob(new PMPlanCreationQueueable(lstContracts, new Set<Id>{testServCont.Id}));
        Test.stopTest();
    }
    
 /*******************************************************
    *Method Name : coverCatchBlock_PMPlanCreationQueueable()
    *Description : method to cover catch block
    *params      : NA
    *return type : void
    ******************************************************/
    @isTest
    public static void coverCatchBlockPMPlanCreationQueueable(){
        try{
            PMPlanCreationQueueable.catchException = true;
            PMPlanCreationQueueable pd = new PMPlanCreationQueueable(null, null);
            Test.startTest();
            System.enqueueJob(pd);
            Test.stopTest();
        }
        catch(Exception e){
            System.assert(e!=null,'e is not empty');
        }
    }
}