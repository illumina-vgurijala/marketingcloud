/***************************************************************************************************************************************
 * NAME   : TestPMOfferingsSelector
 * DESCRIPTION  : TestClass for PMOfferingsSelector class.
 *    
 * @AUTHOR : Prashanth
 * @DATE   : 29-Aug-2021
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Prashanth             29-Aug-2021             Initial Version
  ***************************************************************************************************************************************
*/
@isTest(seeAllData = false)
public with sharing class TestPMOfferingsSelector {
    static SVMXC__Service_Plan__c testServicePlan = new SVMXC__Service_Plan__c();
    static SVMXC__Service_Contract__c testServCont = new SVMXC__Service_Contract__c();
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
        testServicePlan = new SVMXC__Service_Plan__c();
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
        
        SVMXC__PM_Offering__c offering = new SVMXC__PM_Offering__c();
        offering.SVMXC__Service_Contract__c = testServCont.Id;
        offering.SVMXC__PM_Plan_Template__c=pmTemplate.Id;
        offering.SVMXC__Service_Plan__c = testServicePlan.Id;
        insert offering;
    }
    /**
      *  @author Prashanth
      *  @description - test the PMOfferingsSelector class.
    **/
    @IsTest
    static void pmOfferingsSelectorTest(){      
        Set<Id> settestServCont = new Set<Id>{testServCont.Id};
        Set<Id> settestServicePlan = new Set<Id>{testServicePlan.Id};
        
        Test.startTest(); 
        PMOfferingsSelector selector = new PMOfferingsSelector();
        selector.selectPMOfferingsForSMC(settestServCont);
        selector.selectPMOfferingsForServicePlan(settestServicePlan);
        System.assertEquals(1,settestServCont.size());
        System.assertEquals(1,settestServicePlan.size());
        Test.stopTest();
        
    }
}