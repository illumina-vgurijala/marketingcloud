/**
*    @author Divyansh Giri
*    @date  23rd Aug 2018
*    @description  Test Class for RestrictedProduct Selector class
*    Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                Description
*    Divyansh Giri                23rd Aug 2018         Initial Version
*    ------------------------------------------------------------------------------------                  
*/
@isTest(SeeAllData=false)
public with sharing class TestRestrictedProductsSelector{
    /*
    *@author: Divyansh Giri
    *@Desc: Test method  to query restricted product records
    */
    @isTest
    public static void testRestrictedProductsSelectorMethod(){
        Product2 prod = new Product2(Name='TestProd',
                                     Auto_Create_Installation_Workflow__c='Auto Create Install Work Order and Service Request Case',
                                     Service_Product_Type__c='Instrument',
                                     Regulatory_Type__c='DX',
                                     IsActive=true,
                                     ProductCode='43535',
                                     Material_Number__c = '1111',
                                     Service_Level__c = 'GOLD'
                                    );        
        insert prod;
        System.assertNotEquals(null, prod.Id);
		
        Restricted_Product__c objRestrictedProduct = new Restricted_Product__c();
        objRestrictedProduct.Product__c = prod.Id;
        insert objRestrictedProduct;
        System.assertNotEquals(null, objRestrictedProduct.Id);
		
        List<Restricted_Product__c> lstRestrictedProduct = new List<Restricted_Product__c>();
        lstRestrictedProduct = new RestrictedProductsSelector().selectByProductIds(new set<ID>{prod.Id});
        System.assertEquals(1, lstRestrictedProduct.size());
    }
}