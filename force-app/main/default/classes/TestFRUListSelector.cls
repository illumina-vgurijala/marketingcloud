/***************************************************************************************************************************************
 * NAME   : TestFRUListSelector
 * DESCRIPTION  : TestClass for FRUListSelector class.
 *    
 * @AUTHOR : Prashanth
 * @DATE   : 29-Aug-2021
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Prashanth             30-Aug-2021             Initial Version
  ***************************************************************************************************************************************
*/
@isTest(seeAllData = false)
public with sharing class TestFRUListSelector {
    static final string STRING_PRODUCT_NAME = 'Test Product VM';
    static Service_Bill_Of_Materials__c serviceBOM = new Service_Bill_Of_Materials__c();
    /**
      *  @author Prashanth
      *  @description - test the FRUListSelector class.
    **/
    @IsTest
    static void fruListSelectorTest(){
        Product2 objProduct2 = new Product2();
        objProduct2.Name = 'Test';
        objProduct2.Service_Product_Type__c = 'Spare';
        insert objProduct2;

        serviceBOM = new Service_Bill_Of_Materials__c();
        serviceBOM.Name = 'Test Service BOM';
        serviceBOM.ERP_Service_BoM_Number__c = '100291';
        insert serviceBOM;

        FRU_List__c fruList = new FRU_List__c();
        fruList.Service_Bill_Of_Materials__c=serviceBOM.Id;
        fruList.ERP_Product__c=objProduct2.id;
        insert fruList;
        
        Set<Id> setServiceBOM = new Set<Id>{serviceBOM.Id};
        Set<String> setobjProduct2 = new Set<String>{objProduct2.Service_Product_Type__c};
        Set<String> setserviceBOM1 = new Set<String>{'1234'};
        
        Test.startTest();
        FRUListSelector selector = new FRUListSelector();
        selector.selectFRUListForServiceBOM(setServiceBOM, setobjProduct2);
        selector.selectFRUListForServiceBOMNumber(setserviceBOM1);
        System.assertNotEquals(1, selector.selectFRUListForSBOM(new Set<Id>{serviceBOM.Id}, 'Test Product VM2').size(),'Assertion Failed');
        Test.stopTest();
        
    }
}