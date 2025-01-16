/**
*    @author Rohan Chandarana
*    @date   
*    @description    Class to get the Product Classification records based on different conditions
*    Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                Description
*    Rohan Chandarana                               Initial Version
*    Aman Tyagi                  31 Mar 2022        CodeScan Fixes
*    ------------------------------------------------------------------------------------                  
*/
public with sharing class ApttusProductClassificationSelector extends ilib_SObjectSelector{
	/**
    *  @author Rohan Chandarana 
    *  @description  Class to get the Product Classification records based on different conditions
    *  @return SObjectType The Schema.SObjectType of the Product Classification
    **/
   public Schema.SObjectType getSObjectType(){
        return Apttus_Config2__ProductClassification__c.sObjectType;
   }
    
    /**
     *  @author  Rohan Chandarana 
     *  @description Retrieve list of fields for Product Classification sObject
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList(){
       return new List<Schema.SObjectField> {
           Apttus_Config2__ProductClassification__c.Apttus_Config2__ClassificationId__c,
           Apttus_Config2__ProductClassification__c.Apttus_Config2__ProductId__c
       };
    }


    /**
     *  @author  Rohan Chandarana 
     *  @description find the product classificaiton related to given set of product ids
     *  @return List of Product Classificaiton Records
     **/
    public List<Apttus_Config2__ProductClassification__c> findByProductIds(Set<Id> setProductIds){
        return (List<Apttus_Config2__ProductClassification__c>) Database.query(
            newQueryFactory().
            selectField('Apttus_Config2__ClassificationId__c').
            selectField('Apttus_Config2__ClassificationId__r.Name').
            selectField('Apttus_Config2__ProductId__c').
            selectField('Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__AncestorId__r.Name').
            selectField('Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__AncestorId__c').
            selectField('Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Name').
            selectField('Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c').
            setCondition('Apttus_Config2__ProductId__c IN :setProductIds').
            toSOQL()
        );
    }

    /**
     *  @author Rohan Chandarana 
     *  @description fetch Product Classification for the ids passed in the argument
     *  @param idSet set of Product Classification ids
     *  @return list of Product Classification records
     **/
    public List<Apttus_Config2__ProductClassification__c> selectById(Set<ID> idSet){
        return (List<Apttus_Config2__ProductClassification__c>) selectSObjectsById(idSet);
    }
}