/**
*    @author Anish Pathak
*    @date   22nd August 2019
*    @description    Class to get the Custom Metadata records for Product Details 
*    Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                        Description
*    Anish Pathak                 22nd August 2019            Initial Version
*    Aman Tyagi                   31st March 2022             CodeScan Fixes
*    ------------------------------------------------------------------------------------                  
*/
public with sharing class ProductDetailsSelector extends ilib_SObjectSelector{

    /*
    * @Author: Anish Pathak
    * @Description : method to return the SObject type
    * @param : null
    */
    public Schema.SObjectType getSObjectType()
    {
        return Product_Detail__mdt.sObjectType;
    }    
    
    /**
    *  @author  Anish Pathak
    *  @description Retrieve list of fields for Product Details Metadata type 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
                Product_Detail__mdt.DeveloperName,
                Product_Detail__mdt.Product_Code__c
                };
                    }
    /**
    *  @author Anish Pathak
    *  @description Fetch Product Details records based on Developer name of metadata
    *  @return list of Code Parameter records
    **/
    public List<Product_Detail__mdt> selectProductDetailByDeveloperName(set<String> setProductDetailByDeveloperName){
        return (List<Product_Detail__mdt>) Database.query(
            newQueryFactory().setCondition('DeveloperName IN :setProductDetailByDeveloperName').toSOQL()
        );
    }
    
}