/***************************************************************************************************************************************
 * NAME   : TestStockedSerials
 * DESCRIPTION  : TestClass for QualtricsSurveyResponses Trigger handler 
 *           
 * @AUTHOR : Gaurav
 * @DATE   :
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 *  
  ****************************************************************************************************************************************/ 
  @isTest
  public class TestStockedSerials {
	  
	 /*************************
     * @description test method for productStockList
    */
	 @isTest
	  public static void stockedSerialtestmethod() {
		  SVMXC__Site__c site = new SVMXC__Site__c();
		  site.Name = 'Test Site';
		  insert site;
		  
		  Product2 prod = new Product2();
		  prod.Name = 'Test Product';
		  insert prod;
		  
		  // Retrieve only 1 record, which is the one that was just inserted
		  List<SVMXC__Site__c> siteList = new List<SVMXC__Site__c>(
			  [SELECT Id FROM SVMXC__Site__c WHERE Id = :site.Id LIMIT 1]
		  );
		  List<Product2> productList = new List<Product2>(
			  [SELECT Id FROM Product2 WHERE Id = :prod.Id LIMIT 1]
		  );
		  
		  SVMXC__Product_Stock__c prodStock = new SVMXC__Product_Stock__c();
		  prodStock.SVMXC__Location__c = siteList[0].Id;
		  prodStock.SVMXC__Product__c = productList[0].Id;
		  insert prodStock;
		  
		  // Retrieve only 1 record, which is the one that was just inserted
		  List<SVMXC__Product_Stock__c> productStockList = new List<SVMXC__Product_Stock__c>(
			  [SELECT Id, SVMXC__Location__c, SVMXC__Product__c 
			   FROM SVMXC__Product_Stock__c 
			   WHERE Id = :prodStock.Id LIMIT 1]
		  );
  
		  SVMXC__Product_Serial__c prodSerial = new SVMXC__Product_Serial__c();
		  prodSerial.Name = 'Test Name';
		  prodSerial.SVMXC__Product_Stock__c = productStockList[0].Id;
		  insert prodSerial;
		  
		  // Retrieve only 1 record, which is the one that was just inserted
		  List<SVMXC__Product_Serial__c> productSerialList = new List<SVMXC__Product_Serial__c>(
			  [SELECT Id, Location__c, SVMXC__Product__c 
			   FROM SVMXC__Product_Serial__c 
			   WHERE Id = :prodSerial.Id LIMIT 1]
		  );
		  
		  // Perform assertions to validate the inserted data
		  System.assertEquals(productStockList[0].SVMXC__Location__c, productSerialList[0].Location__c);
		  System.assertEquals(productStockList[0].SVMXC__Product__c, productSerialList[0].SVMXC__Product__c);
	  }
  }
  