/***************************************************************************************************************************************
 * NAME   : TestServiceBOMsSelector
 * DESCRIPTION  : TestClass for ServiceBOMsSelector class.
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
public with sharing class TestServiceBOMsSelector {
    static Service_Bill_Of_Materials__c serviceBOM = new Service_Bill_Of_Materials__c();
    static Product2 product1 = new product2();
    /**
      *  @author Prashanth
      *  @description - initialize test data
    **/
    @TestSetup
    public static void initializeTestData(){
        product1 = TestDataMaster.createProduct(true);
        System.assert(product1.Id != null);

        serviceBOM = TestDataFieldService.createServiceBOM(product1.Id);
        serviceBOM.Default__c = true;
        serviceBOM.ERP_Service_BoM_Number__c ='000';
        update serviceBOM;
        System.assert(serviceBOM.Id != null);
    }
    /**
      *  @author Prashanth
      *  @description - test the stockTransfersSelector class 
    **/
    @IsTest
    static void serviceBOMsSelectorTest(){
        initializeTestData();
        Set<Id> setProduct = new Set<Id>{product1.Id};
        Set<String> setBOM = new Set<String>{serviceBOM.ERP_Service_BoM_Number__c};
        Test.startTest();
        ServiceBOMsSelector selector = new ServiceBOMsSelector();
        selector.selectDefaultServiceBOMsForProduct(setProduct);
        selector.selectServiceBOMsByERPServiceBOMNumber(setBOM);
        System.assertNotEquals(null,setProduct.size());
        System.assertNotEquals(null,setBOM.size());
        Test.stopTest();
        
    }
}