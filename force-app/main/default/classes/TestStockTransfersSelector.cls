/***************************************************************************************************************************************
 * NAME   : TestStockTransfersSelector
 * DESCRIPTION  : TestClass for StockTransfersSelector class.
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
public with sharing class TestStockTransfersSelector {
    static SVMXC__Stock_Transfer__c stockTransfer = new SVMXC__Stock_Transfer__c();
    /**
      *  @author Prashanth
      *  @description - initialize test data
    **/
    @TestSetup
    public static void initializeTestData(){
        stockTransfer = new SVMXC__Stock_Transfer__c();
        stockTransfer.SVMX_PS_VS_Perform_Stock_Transfer__c = true;
        insert stockTransfer;
        System.assert(stockTransfer.Id != null);
    }
    /**
      *  @author Prashanth
      *  @description - test the stockTransfersSelector class 
    **/
    @IsTest
    static void stockTransfersSelectorTest(){
        initializeTestData();
        Test.startTest();
        System.assertEquals(1, new stockTransfersSelector().selectStockTransferById(new Set<Id>{stockTransfer.Id}).size(),'Assertion Failed.');
        Test.stopTest();
    }
}
