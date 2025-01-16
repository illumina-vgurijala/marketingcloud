/***************************************************************************************************************************************
 * NAME   : TestPreventiveMaintenancePlansSelector
 * DESCRIPTION  : TestClass for PreventiveMaintenancePlansSelector class.
 *    
 * @AUTHOR : Prashanth
 * @DATE   : 30-Aug-2021  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Prashanth             30-Aug-2021             Initial Version
  ***************************************************************************************************************************************
*/
@isTest(seeAllData = false)
public with sharing class TestPreventiveMaintenancePlansSelector {
    static SVMXC__Service_Contract__c testServCont = new SVMXC__Service_Contract__c();
    static SVMXC__PM_Plan__c pmPlan = new SVMXC__PM_Plan__c();
    /**
      *  @author Prashanth
      *  @description - initialize test data
    **/
    @TestSetup
    public static void initializeTestData(){
        
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;
        
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
        testServCont = TestDataFieldService.createServiceContract(acc.Id);
        testServCont.SVMXC__Service_Plan__c = TestServicePlan.id;
        testServCont.SVMXC__Start_Date__c = system.today();
        testServCont.SVMXC__End_Date__c = system.today().addYears(1);
        insert testServCont;
        
        //SVMXC__PM_Plan__c
        pmPlan = new SVMXC__PM_Plan__c();
        pmPlan.Name='BYANNUAL Plan';
        pmPlan.CurrencyIsoCode='USD';
        pmPlan.SVMXC__Status__c = 'Suspended';
        pmPlan.SVMXC__PM_Plan_Template__c=pmTemplate.Id;
        pmPlan.SVMXC__Service_Contract__c= testServCont.Id;
        insert pmPlan;
    }
    /**
      *  @author Prashanth
      *  @description - test the PreventiveMaintenancePlansSelector class.
    **/
    @IsTest
    static void preventiveMaintenancePlansSelectorTest(){
        
        Set<Id> settestServCont = new Set<Id>{testServCont.Id};
        Set<Id> setpmPlan = new Set<Id>{pmPlan.Id};
            
        Test.startTest();
        PreventiveMaintenancePlansSelector selector = new PreventiveMaintenancePlansSelector();
        selector.selectPMPlanForSMC(settestServCont);
        selector.selectPMPlanWithServicePlans(setpmPlan);
        System.assertNotEquals(null,settestServCont.size());
        System.assertNotEquals(null,setpmPlan.size());
        Test.stopTest();   
    }
}