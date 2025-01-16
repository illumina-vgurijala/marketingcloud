/**************************************************************************************************************************************
* NAME   : TestBatchWODataRemediation
* DESCRIPTION  : Test class for BatchCaseDataRemediation2
*  
*
* @AUTHOR : Nitin Z 
* @DATE   : 25 -jun -2024  
*  
* MODIFICATION LOG: 
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
  Nitin Z                  25-jun -2024   

****************************************************************************************************************************************/ 

@isTest
public class TestBatchWODataRemediation {
     public static final String STRING_PRODUCT_MATERIAL_CLASS = 'Consumables';
 	 public static final String STRING_PRODUCT_CODE = 'Test 1234';
    
      @testSetup
    	static void setupTestData() {
             	Account objAccount = new Account(Name = 'Test Account', 
                                         Account_Group__c = 'Distributor', 
                                         Clinical_Type__c = 'Clinical',
                                         BillingStreet = 'test billing street',
                                         BillingCity = 'test billing city',
                                         BillingPostalCode = '90909',
                                         BillingStateCode = '',
                                         BillingCountryCode = 'JP',
                                         Customer_Sub_Type__c = 'Genome Center',
                                         Customer_Type__c = 'Academic',
                                         Market_Segment__c = 'Forensics',
                                         Tier__c = 'Tier 1',
                                         CurrencyIsoCode = 'USD');
        		insert objAccount;
            
             // Create Test Products
        Product2 product = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        product.Service_Product_Type__c = 'Core';
        product.Regulatory_Type__c = 'DX';
        product.Source_System__c = 'SAP';
        insert product;
            
         // Insert Installed Product
        SVMXC__Installed_Product__c objInstalledProduct = new SVMXC__Installed_Product__c(
            Name = 'Test IP VM', 
            SVMXC__Company__c = objAccount.Id,
            CurrencyIsoCode = 'USD'
        );
        insert objInstalledProduct;    

    	}
    
     @isTest
    static void testBatchWoDataRemediationMethod() {
      SVMXC__Installed_Product__c objInstalledProduct = [SELECT Id from SVMXC__Installed_Product__c LIMIT 1];
      Product2 product = [SELECT Id from Product2 LIMIT 1];
      User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
   		 Test.startTest(); 
      SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c(
            SVMXC__Component__c = objInstalledProduct.Id,
            SVMXC__Product__c = product.Id,
            Product_Lot_Number__c = 'LOT001',
            Product_Serial_Number__c = 'SN001',
            CreatedById = testUser.Id,
            OwnerId = testUser.Id,
            SVMXC__Order_Type__c = 'Field Service',
            Record_Created_from_SFM__c = true
        );
        
         AssociatedProduct.skipAPTrigger=true;
         Cases.skipCaseTrigger=true;
         WorkOrders.skipWOTrigger=true;
         insert wo;
		BatchWODataRemediation batch = new BatchWODataRemediation(10000);
        Database.executeBatch(batch, 200);
        Test.stopTest(); 
        List<SVMXC__Service_Order__c> woList = [SELECT Id, Legacy_Case_Subject__c FROM SVMXC__Service_Order__c WHERE Legacy_Case_Subject__c = 'PROCESSED' LIMIT 200];

        
          for (SVMXC__Service_Order__c woObj : woList) {
            System.assertEquals('PROCESSED', woObj.Legacy_Case_Subject__c, 'The AP Conversion Flag should be PROCESSED.');
        }

        // Verify that the case lines have been updated
        // for (SVMXC__Case_Line__c caseLine : caseLines) {
        //      System.assertEquals('PROCESSED', caseLine.Associated_Product__c, 'The Associated Product flag should be PROCESSED.');
        // }

        // Verify that the associated products have been inserted
        Integer associatedProductCount = [SELECT COUNT() FROM Associated_Product__c limit 1];
        System.assert(associatedProductCount > 0, 'There should be associated products inserted.');


    }
    
}