/***************************************************************************************************************************************
 * NAME   : TestEntitlements
 * DESCRIPTION  : TestClass for Entitlements Trigger
 *          
 * @AUTHOR : Mandeep
 * @DATE   : 13-Sep-2018  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Mandeep               13-Sep-2018             Initial Version
  ****************************************************************************************************************************************/ 
@isTest(SeeAllData = false)  
public with sharing class TestEntitlements {
  
   
 
  /***************************************************************************************************************************************
     * NAME   : newEntitlementCreation
     * DESCRIPTION  : Creation of Entitlement
     *    
     * @AUTHOR : Mandeep
     * @DATE   : 13-Sep-2018  
     *
     * MODIFICATION LOG:  
     * --------------------------------------------------------------------------------------------------------------------------------------
     * DEVELOPER                DATE                DESCRIPTION 
     * --------------------------------------------------------------------------------------------------------------------------------------
      ****************************************************************************************************************************************/ 
    static testmethod void newEntitlementCreation() {
        
        Test.startTest();

        // Insert Account
        Account objAccount = TestDataAccount.getAccount('Test Account', 'USD');
        insert objAccount;

        //insert objInstalledProduct;
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        insert objInstalledProduct;
        SVMXC__Installed_Product__c insertedInstalledProduct = [Select SVMXC__Status__c from SVMXC__Installed_Product__c where Id =: objInstalledProduct.Id];
        System.assertEquals('New',insertedInstalledProduct.SVMXC__Status__c);

        BusinessHours objBuinessHours = [SELECT Id FROM BusinessHours where Name =: 'Default'];
        
        SVMXC__Service_Level__c objServiceLevel = TestDataFieldService.createServiceLevel();
        objServiceLevel.SVMXC__Business_Hours__c = objBuinessHours.id;
        insert objServiceLevel;
        
        SVMXC__Service_Contract__c objServiceContract= TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.SVMXC__Service_Level__c = objServiceLevel.Id;
        insert objServiceContract;
         
        // Insert Covered Product
        SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(objInstalledProduct.Id );
        objCoveredProduct.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert objCoveredProduct;        
        SVMXC__Service_Contract_Products__c insertedCoveredProduct = [Select SVMXC__Installed_Product__c from SVMXC__Service_Contract_Products__c where SVMXC__Installed_Product__c =: objInstalledProduct.Id];
        System.assertEquals(insertedCoveredProduct.SVMXC__Installed_Product__c, objInstalledProduct.Id);

        //insert Contact
        Contact objContact = TestDataPerson.getNewContact(objAccount.Id);            
        Contact insertedContact = [Select AccountId from Contact where Id =: objContact.Id];
        System.assertEquals(insertedContact.AccountId , objAccount.Id);

        // Insert Work Order
        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
        objWorkOrder.SVMXC__Component__c = objInstalledProduct.Id;
        objWorkOrder.SVMXC__Order_Type__c='Installation';
		objWorkOrder.Is_Auto_Created__c = true;
        insert objWorkOrder;
        SVMXC__Service_Order__c insertedWorkOrder = [Select SVMXC__Order_Status__c from SVMXC__Service_Order__c where Id =: objWorkOrder.Id];
        System.assertEquals('Initiated',insertedWorkOrder.SVMXC__Order_Status__c);
         /*Applied_Contract__c objEntitlement = new Applied_Contract__c();
        objEntitlement.CurrencyIsoCode='USD';
        objEntitlement.Work_Order__c =objWorkOrder.id;
        objEntitlement.Service_Contract__c = objServiceContract.Id;
        insert objEntitlement;*/
        Applied_Contract__c insertedEntitlement = [Select Work_Order__c from Applied_Contract__c where Work_Order__c =: objWorkOrder.Id];
        System.assertEquals(insertedEntitlement.Work_Order__c, objWorkOrder.Id);

        Test.stopTest();
    }
}