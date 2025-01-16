/**
*    @author: Govind Dubey
*    @date:   20th Aug 2018
*    @description:  Lock Quantity for Professional Services & Service Contracts Products for DCP-1063
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Govind Dubey               20th Aug 2018          Add Price list items for Locking Quantity of Professional Services & Service Contracts Products
*             Aman Tyagi                 31st March 2022        Codescan fixes
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class PriceListItems extends ilib_SObjectDomain {

    public static final String PRICE_TYPE_ONE_TIME = 'One Time';
    public static final String PRICE_TYPE_RECURRING = 'Recurring';
    public static final String PRICE_TYPE_USAGE = 'Usage';
    public static final String PRICE_TYPE_INCLUDED = 'Included Usage';

    /*
    * @Author:   Govind Dubey  
    * @Description : parameterized constructor of class PriceListItems and instantiating Apttus_Config2__PriceListItem__c
    * @param :List<Apttus_Config2__PriceListItem__c> sObjectList
    */ 
    public PriceListItems(List<Apttus_Config2__PriceListItem__c> sObjectList)
    {
        super(sObjectList);
    }
    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /*
        * @Author: Govind Dubey  
        * @Description : parameterized constructor of base class
        * @param :List<SObject> sObjectList
        */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new PriceListItems(sObjectList);
        }
    }
    
    /*
    * @author Govind Dubey
    * @date   20th Aug 2018 
    * @description    Add Price list items for Locking Quantity (Apttus_Config2__IsQuantityReadOnly__c as true) of Professional Services & Service Contracts Products 
    * Before insert trigger method
    *
    */
    public override void onBeforeInsert(){
        List<Apttus_Config2__PriceListItem__c> lstPriceListItem = (List<Apttus_Config2__PriceListItem__c>) records;
        Map<Id,List<Apttus_Config2__PriceListItem__c>> productIdToPriceListItems = UtilsCollection.getMapOfIdToSObjects(lstPriceListItem, 'Apttus_Config2__ProductId__c');        
        List<Product2> lstProduct = new ProductsSelector().selectProducts(productIdToPriceListItems.keySet());
        if(!productIdToPriceListItems.isEmpty()){
            PriceListItemsService.updatePLIDefaults(lstProduct,productIdToPriceListItems);
        }
    }
    
    /*
    * @author Govind Dubey
    * @date   20th Aug 2018 
    * @description    Add Price list items for Locking Quantity (Apttus_Config2__IsQuantityReadOnly__c as true) of Professional Services & Service Contracts Products 
    * Before insert trigger method
    *
    */
    public override void onBeforeUpdate(Map<Id, sObject> existingRecords){
        List<Apttus_Config2__PriceListItem__c> lstPriceListItem = (List<Apttus_Config2__PriceListItem__c>) records;
        Map<Id,List<Apttus_Config2__PriceListItem__c>> productIdToPriceListItems = UtilsCollection.getMapOfIdToSObjects(lstPriceListItem, 'Apttus_Config2__ProductId__c');        
        List<Product2> lstProduct = new ProductsSelector().selectProducts(productIdToPriceListItems.keySet());
        if(!productIdToPriceListItems.isEmpty()){
            PriceListItemsService.updatePLIDefaults(lstProduct,productIdToPriceListItems);
        }
    }
}