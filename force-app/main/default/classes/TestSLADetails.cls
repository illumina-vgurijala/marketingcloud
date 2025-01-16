/***************************************************************************************************************************************
 * NAME   : TestSLADetails
 * DESCRIPTION  : TestClass for SLADetails Trigger
 *          
 * @AUTHOR : Mandeep
 * @DATE   : 13-Sep-2018  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Mandeep               13-Sep-2018             Initial Version
 * Nishan Shetty         17-Jan-2022             CodeScanFix- [Assert Argument Order]
  ****************************************************************************************************************************************/ 
@isTest(SeeAllData = false)  
public with sharing class TestSLADetails {
  
   
 
  /***************************************************************************************************************************************
     * NAME   : newSLADetailCreation
     * DESCRIPTION  : Creation of SLADetail
     *    
     * @AUTHOR : Mandeep
     * @DATE   : 13-Sep-2018  
     *
     * MODIFICATION LOG:  
     * --------------------------------------------------------------------------------------------------------------------------------------
     * DEVELOPER                DATE                DESCRIPTION 
     * --------------------------------------------------------------------------------------------------------------------------------------
      ****************************************************************************************************************************************/ 
    static testmethod void newSLADetailCreation() {
        
        Test.startTest();

        // Insert Account
        Account objAccount = TestDataAccount.getAccount('Test Account', 'USD');
        insert objAccount;

        //insert objInstalledProduct;
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        insert objInstalledProduct;
        SVMXC__Installed_Product__c insertedInstalledProduct = [Select SVMXC__Status__c from SVMXC__Installed_Product__c where Id =: objInstalledProduct.Id];
        System.assertEquals('New',insertedInstalledProduct.SVMXC__Status__c);//CodeScanFix [Assert Argument Order]

        BusinessHours objBuinessHours = [SELECT Id FROM BusinessHours where Name =: 'Default'];
        
        SVMXC__Service_Level__c objServiceLevel = TestDataFieldService.createServiceLevel();
        objServiceLevel.SVMXC__Business_Hours__c = objBuinessHours.id;
        insert objServiceLevel;
        
        SVMXC__SLA_Detail__c objServiceDetail = TestDataFieldService.createServiceDetail(objServiceLevel.Id);
        insert objServiceDetail;
        
        objServiceDetail.SVMXC__Customer_Commitment__c = 20;
        update objServiceDetail;
        
        Test.stopTest();
    }
}