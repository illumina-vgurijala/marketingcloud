/*@ author       : Bharath
* @ date         : 
* @ Description  : Test class for ProductsSelector class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                  Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Bharath                                       Initial version
* Gladis                 23-09-2022             Added test selector methods
*****************************************************************************************************************************************************
*/
@isTest(SeeAllData=false)
public with sharing class TestProductsSelector
{
 /**
     *  @author Bharath
     *  @description Written to increase coverage and cover ProductsSelector
     **/
    @isTest
    static void testProductSelector()
    { 
     TestDataMaster.createProduct(true);
      Test.startTest();

      set<id> prodIds = new set<id>();
      set<string> materialNumberSet = new set<string>();
      set<string> productCodeSet = new set<string>();
      Product2 objProduct = [SELECT Id,Name,ProductCode,Material_Number__c FROM Product2 LIMIT 1];
      prodIds.add(objProduct.id);

      Product2 objProduct1 = TestDataMaster.initProduct('12419677','Instrument');
      objProduct1.Serial_Number_Profile__c='IL02';
      objProduct1.Service_Product_Type__c = 'Instrument';
      objProduct1.CurrencyIsoCode= 'USD';
      objProduct1.Auto_Create_Installation_Workflow__c = 'Auto Create Install Work Order and Service Request Case';
      objProduct1.Service_Level__c = 'DEDICATE';
      objProduct1.Family = 'Laptop';
      objProduct1.Source_System__c = 'SFDC'; 
      insert objProduct1;
      prodIds.add(objProduct1.id);
      materialNumberSet.add(objProduct.Material_Number__c);
      productCodeSet.add(objProduct.ProductCode);
      ProductsSelector pse= new ProductsSelector();
      pse.selectProducts(prodIds);
      pse.selectProductsForMaterialNumber(materialNumberSet);
      pse.fetchProductId(productCodeSet);
	    pse.selectProductsFromMaterialId(prodIds);   //DCP 34078
      pse.selectInstrumentProductsForAutoWOCreation(prodIds);
      pse.selectProductsWithServiceProductType(prodIds,'Instrument');
      pse.selectProductsForBatch();
      pse.selectAutoWOCreationProducts(prodIds);
      pse.selectProductsForMaterialNumberOld(materialNumberSet);
      pse.selectProductsForMaterialClassType(prodIds, new Set<String>{'Instrument'});
      pse.selectIVDProducts(prodIds);
      pse.selectProductsId(prodIds);
      pse.selectProductFromProdCode(new Set<String>{'IL-SER-TRAVEL-Z1'});
      pse.selectProductWithServLevel(productCodeSet, 'DEDICATE');
      pse.selectProductsFromFamily(new Set <String>{'Laptop'});
      Id [] fixedSearchResults= new Id[1];
      fixedSearchResults[0] = objProduct1.id;
      Test.setFixedSearchResults(fixedSearchResults);
      List<Product2> productList = pse.selectProductsWithSearchSOSL(objProduct.Name);
      Assert.areEqual(1, productList.size(),'product is empty');
        Product2 testProd=[select id,ProductCode,Service_Product_Type__c,Source_System__c FROM Product2 where id in:prodIds and Service_Product_Type__c='Instrument' LIMIT 1];
        system.assertEquals('Instrument',testProd.Service_Product_Type__c);
        system.assertEquals('SFDC',testProd.Source_System__c);
        system.assertnotEquals(null,objProduct.ProductCode);
      Test.stopTest();
    }
}