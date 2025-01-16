/***************************************************************************************************************************************
 * NAME   : TestServiceContractSelector
 * DESCRIPTION  : TestClass for ServiceContractSelector class.
 *    
 * @AUTHOR : Prashanth
 * @DATE   : 29-Aug-2021  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Prashanth             29-Aug-2021             Initial Version
 * Siddartha Reddy Kalam 28-Nov-2023             CMCM-3980 Added LWC Related Selectors
  ***************************************************************************************************************************************
*/
@isTest(seeAllData = false)
public with sharing class TestServiceContractSelector {
    static SVMXC__Service_Contract__c testServCont = new SVMXC__Service_Contract__c();
    static Account objAccount = new Account();
    static SVMXC__Service_Plan__c svcPlan = new SVMXC__Service_Plan__c();
    /**
      *  @author Prashanth
      *  @description - initialize test data
    **/
    @TestSetup
    public static void initializeTestData(){
        objAccount = TestDataAccount.getNewAccount();
        svcPlan = TestDataFieldService.createServicePlan('Illumina Product Care Dedicated On-Site Additional FSE Plan');
        system.assert(objAccount.id != null);
        testServCont = TestDataFieldService.createServiceContract(objAccount.Id);
        testServCont.SVMXC__Start_Date__c = system.today();
        testServCont.SVMXC__End_Date__c = system.today().addYears(1);
        testServCont.SVMXC__Service_Plan__c = svcPlan.Id;
        testServCont.Zuora_Subscription_ID__c = '808080';
        testServCont.ProductCode__c = '12345';
        testServCont.ERP_Contract_Type__c = 'Software Contract (ZWV)';
        insert testServCont;
    }
    /**
      *  @author Prashanth
      *  @description - test the stockTransfersSelector class 
    **/
    @IsTest
    static void serviceContractSelectorTest() {
        initializeTestData();
        List<SVMXC__Service_Contract__c> testServContList = new List<SVMXC__Service_Contract__c>();
        testServContList.add(testServCont);
        Test.startTest();
        SVMXC__Service_Contract__c svcContract = new SVMXC__Service_Contract__c();
        svcContract = TestDataFieldService.createServiceContract(objAccount.Id);
        svcContract.SVMX_PS_External_ID__c = 'Consumable Contract '+System.today().year();
        insert svcContract;
        ServiceContractSelector selctor = new ServiceContractSelector();
        System.assertEquals(1, selctor.selectServiceContractsByStatus(new Set<Id>{testServCont.Id}, 'Active').size(), 'Assertion Failed');
        System.assertEquals(1, selctor.selectServiceContracts(new Set<Id>{testServCont.Id}).size(), 'Assertion Failed');
        System.assertEquals(2, selctor.selectServContractsByAccountId(new Set<Id>{objAccount.Id}).size(), 'Assertion Failed');
        Id [] fixedSearchResults= new Id[2];
        fixedSearchResults[0] = svcContract.Id;
        fixedSearchResults[1] = testServCont.Id;
        Test.setFixedSearchResults(fixedSearchResults);
        System.assertEquals(2, selctor.selectServContractsWithSearchSOSL('808080').size(), 'Assertion Failed');
        System.assertEquals(1, selctor.selectServContractsWithid(new List<Id>{testServCont.Id}).size(), 'Assertion Passed');
        System.assertEquals(1, selctor.selectServContractsWithAccountIdandSearch(objAccount.Id,'808080').size(), 'Assertion Passed');
        System.assertEquals(1, testServContList.size(), 'Assertion Failed');
        System.assertEquals(1, selctor.selectServiceContractByIds(new Set<Id>{testServCont.Id}).size(), 'Assertion Passed'); // CMCM-263
        System.assertEquals(1, selctor.selectServiceContractByExternalId('Consumable Contract '+System.today().year()).size(), 'Assertion Passed'); // CMCM-263
        Test.stopTest();
        
    }
}
