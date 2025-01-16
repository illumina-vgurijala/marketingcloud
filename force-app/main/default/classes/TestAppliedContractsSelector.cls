/***************************************************************************************************************************************
 * NAME   : TestAppliedContractsSelector
 * DESCRIPTION  : TestClass for AppliedContractsSelector class.
 *    
 * @AUTHOR : Prashanth
 * @DATE   : 30-Aug-2021
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Prashanth             30-Aug-2021             Initial Version
 * Abhishek              29-Feb-2021             CMCM-273
  ***************************************************************************************************************************************
*/
@isTest(seeAllData=false)
public with sharing class TestAppliedContractsSelector {
    /**
      *  @author Prashanth
      *  @description - test the LMSCertificationMappingSelector class.
    **/
    @IsTest
    static void appliedContractsSelectorTest() {
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;

        Contact con = TestDataPerson.getNewContact(acc.Id);

        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
       
        Test.startTest();
        SVMXC__Service_Order__c workOrder1 = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder1.SVMXC__Order_Type__c='Installation';
        workOrder1.Is_Auto_Created__c = true;
        insert workOrder1;
        
        SVMXC__Service_Contract__c objServiceContract1 = TestDataFieldService.createServiceContract(acc.Id);
        objServiceContract1.Consumables_Included__c=false;
        objServiceContract1.Status__c = 'Active';
        objServiceContract1.Labor_Included__c = True;
        insert objServiceContract1;

        SVMXC__Service_Contract__c objServiceContract2 = TestDataFieldService.createServiceContract(acc.Id);
        objServiceContract2.Consumables_Included__c=false;
        objServiceContract2.Status__c = 'Active';
        objServiceContract2.Labor_Included__c = True;
        objServiceContract2.SVMX_PS_External_ID__c = AppliedContractsSelector.CONSUMABLE_CONTRACT + ' ' + System.today().year();
        insert objServiceContract2;

        Associated_Product__c apc = new Associated_Product__c();
        apc.Product_Serial_Number__c ='TEST5678345678';
        apc.Case__c = cs.Id;
        apc.Work_Order__c = workOrder1.Id;
        apc.Account__c = acc.Id;
        apc.Is_Primary__c=true;
        insert apc;
        Applied_Contract__c objEntitlement = new Applied_Contract__c();
        objEntitlement.Work_Order__c = workOrder1.id;
        objEntitlement.Case_Number__c = cs.Id;
        objEntitlement.Service_Contract__c = objServiceContract1.Id;
        insert objEntitlement;
        
        Applied_Contract__c objEntitlement1 = new Applied_Contract__c();
        objEntitlement1.Associated_Product__c = apc.Id;
        objEntitlement1.Service_Contract__c = objServiceContract1.Id;
        insert objEntitlement1; 

        Applied_Contract__c objEntitlement2 = new Applied_Contract__c();
        objEntitlement2.Associated_Product__c = apc.Id;
        objEntitlement2.Service_Contract__c = objServiceContract2.Id;
        insert objEntitlement2; 
        
        AppliedContractsSelector selector = new AppliedContractsSelector();
        System.assertEquals(1, selector.selectCaseEntitlements(new Set<Id>{cs.Id}).size(),'Assertion Failed.');
        System.assertEquals(1, selector.selectWorkOrderEntitlements(new Set<Id>{workOrder1.Id}).size(),'Assertion Failed');
        System.assertEquals(1, selector.selectEntitlements(new Set<Id>{cs.Id}, new Set<Id>{workOrder1.Id}).size(),'Assertion Failed');
        System.assertEquals(1, selector.selectEntitlementsFromIds(new Set<Id>{objEntitlement.Id}).size(),'Assertion Failed');
        System.assertEquals(1, selector.selectWOEntitlements(new Set<Id>{workOrder1.Id}).size(),'Assertion Failed');
        System.assertEquals(2, selector.selectEntitlementsFromSMCIds(new Set<Id>{objServiceContract1.Id}).size(),'Assertion Failed');
        System.assertEquals(1, selector.selectActiveEntitlementsFromWO(new Set<Id>{} , new Set<Id>{workOrder1.id}).size(),'Assertion Failed');
        System.assertEquals(1, selector.selectActiveAppliedContractFromWO(new Set<Id>{workOrder1.id}).size(),'Assertion Failed');
        System.assertEquals(2, selector.selectAssociatedProductEntitlements(new Set<Id>{apc.id}).size(),'Assertion Failed'); 
        System.assertEquals(2, selector.selectActiveAppliedContractForWO(new Set<Id>{apc.id}).size(),'Assertion Failed');
        System.assertEquals(1, selector.selectCaseAndWorkOrderEntitlements(new Set<Id>{} , new Set<Id>{workOrder1.id}).size(),'Assertion Failed');
        System.assertEquals(1, selector.selectAssociatedProductEntitlementsExcludingConsumables(new Set<Id>{apc.id}).size(),'Assertion Failed');
        Test.stopTest();
        
    }
}