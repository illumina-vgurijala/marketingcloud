/**
*    @author Divyansh Giri
*    @date   23rd Aug 2018
*    @description    DCP-9620: RestrictedProduct Selector class
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                  Date                   Description
*    Divyansh Giri              23rd Aug 2018           RestrictedProduct Selector class
*    Aman Tyagi                 31st Mar 2022           CodeScan Fixes
*    ------------------------------------------------------------------------------------ 
*                    
*/

public with sharing class RestrictedProductsSelector extends ilib_SObjectSelector{

  /*
  * @Author: Divyansh Giri
  * @Description : method to return the SObject type
  * @param : null
  */
  public Schema.SObjectType getSObjectType()
    {
        return Restricted_Product__c.sObjectType;
    }
    
    /**
     *  @author  Divyansh Giri
     *  @description Retrieve list of fields for Retricted Product object
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
          Restricted_Product__c.Product__c
       };
    }
    
    /**
    *  @author Divyansh Giri
    *  @description method to query restricted product records
    *  @param set of Product ids
    *  @return list of restricted Products
    **/
    public List<Restricted_Product__c> selectByProductIds(Set<Id> setProductIds){
        return (List<Restricted_Product__c>) Database.query(
                newQueryFactory().
                selectField('Product__c').
                selectField('Account__c').
                selectField('Product__r.Name').
                setCondition('Product__c IN : setProductIds').
                toSOQL()
               );
    }
}