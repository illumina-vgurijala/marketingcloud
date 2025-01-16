/***************************************************************************************************************************************
* NAME         : TestProductLookupController
* DESCRIPTION  : Test class for ProductLookupController.
*                    
* @AUTHOR      : Prashanth 
* @DATE        : 12-Mar-2020  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
  Prashanth              12-Mar-2020            Initial version
****************************************************************************************************************************************/
@isTest
public class TestProductLookupController {
    /**
   *  Method Name: getResultTest
   *  @description test method for testing productlookup functionality.
   *  @param NA.
   *  @return void
   **/
    @isTest
    static void getResultTest(){
        //insert product
        Product2 toolProduct = TestDataMaster.initProduct('Test Product','Tools');
        toolProduct.SVMXC__Product_Type__c = 'Spare';
        toolProduct.Description = 'test Description';
        insert toolProduct;

        System.assert(toolProduct.Id != null);
        //start test
        Test.startTest();
        List<ProductLookupController.sObJectResult> lstsObjectResult = ProductLookupController.getResults('Product2','ProductCode','Test','Name','Description');
        System.assertEquals(1,lstsObjectResult.size(),'More than 1 record returned');
        Test.stopTest();
    }
}