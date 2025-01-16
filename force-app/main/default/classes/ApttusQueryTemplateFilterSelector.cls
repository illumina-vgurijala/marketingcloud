/**
*    @author Akshay Mohan
*    @date   2021-04-27
*    @description    DCP-38809: Auto generate quote
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer               Date                Description
*         Akshay Mohan            2021-05-06          Initial Version
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class ApttusQueryTemplateFilterSelector extends ilib_SObjectSelector{
    /**
    *  @author Akshay Mohan
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the object
    **/
   public Schema.SObjectType getSObjectType()
   {
        return Apttus__QueryTemplateFilter__c.sObjectType;
   }

   /**
     *  @author  Akshay Mohan 
     *  @description Retrieve list of fields for sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
        Apttus__QueryTemplateFilter__c.id,
        Apttus__QueryTemplateFilter__c.Apttus__Sequence__c,
        Apttus__QueryTemplateFilter__c.Apttus__CompOper__c,
        Apttus__QueryTemplateFilter__c.Apttus__Field__c,
        Apttus__QueryTemplateFilter__c.Apttus__QueryTemplate__c,
        Apttus__QueryTemplateFilter__c.Apttus__Value__c
       };
    }

    /**
     *  @author Akshay Mohan
     *  @description fetch records by query template ids
     *  @param idSet set of query template ids
     *  @return list of Apttus__QueryTemplateFilter__c records
     **/
    public List<Apttus__QueryTemplateFilter__c> selectByQueryTemplateIds(Set<Id> setQueryTemplateIds){
        return (List<Apttus__QueryTemplateFilter__c>) 
            Database.query(newQueryFactory()
                .setCondition('Apttus__QueryTemplate__c IN :setQueryTemplateIds')
                .toSOQL()
            );
    }
}