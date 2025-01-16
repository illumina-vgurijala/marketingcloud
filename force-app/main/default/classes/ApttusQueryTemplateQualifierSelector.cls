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
public with sharing class ApttusQueryTemplateQualifierSelector extends ilib_SObjectSelector{

    public static final String QUOTE_OBJECT='Quote';
    public static final String TERRITORY_REGION_FIELD='Territory_Region__c';
    public static final String COMPARATOR_EQUALS='equal to';
    public static final String COMPARATOR_IN='in';
    
    /**
    *  @author Akshay Mohan
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the object
    **/
   public Schema.SObjectType getSObjectType()
   {
        return Apttus__QueryTemplateQualifier__c.sObjectType;
   }

   /**
     *  @author  Akshay Mohan 
     *  @description Retrieve list of fields for sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
        Apttus__QueryTemplateQualifier__c.id,
        Apttus__QueryTemplateQualifier__c.Apttus__CompOper__c,
        Apttus__QueryTemplateQualifier__c.Apttus__Value__c,
        Apttus__QueryTemplateQualifier__c.Apttus__Field__c,
        Apttus__QueryTemplateQualifier__c.Apttus__QueryTemplate__c,
        Apttus__QueryTemplateQualifier__c.Apttus__Sequence__c,
        Apttus__QueryTemplateQualifier__c.Apttus__SObjectType__c
       };
    }

    /**
     *  @author Akshay Mohan
     *  @description add ordering
     *  @param 
     *  @return String
     **/
    public override String getOrderBy(){
        return 'Apttus__QueryTemplate__r.Apttus__Sequence__c ASC, Apttus__QueryTemplate__c ASC';
     }

    /**
     *  @author Akshay Mohan
     *  @description fetch records by query template ids
     *  @param idSet set of query template ids
     *  @return list of Apttus__QueryTemplateQualifier__c records
     **/
    public List<Apttus__QueryTemplateQualifier__c> selectByQueryTemplateIds(Set<Id> setQueryTemplateIds){
        return (List<Apttus__QueryTemplateQualifier__c>) 
            Database.query(newQueryFactory()
                            .setCondition('Apttus__QueryTemplate__c IN :setQueryTemplateIds')
                            .toSOQL());
    }

    /**
     *  @author Akshay Mohan
     *  @description fetch records for quote by Region
     *  @param idSet set of proposal ids
     *  @return list of Apttus__QueryTemplateQualifier__c records
     **/
    public List<Apttus__QueryTemplateQualifier__c> selectQuoteTemplatesByTerritory(String strRegion){
        String strRegionLike='%'+strRegion+'%';
        return (List<Apttus__QueryTemplateQualifier__c>) 
            Database.query(newQueryFactory()
                .setCondition('Apttus__SObjectLabel__c = :QUOTE_OBJECT'
                                +' AND Apttus__QueryTemplate__r.Apttus__Active__c=true'
                                +' AND Apttus__Field__c=:TERRITORY_REGION_FIELD'
                                +' AND ((Apttus__CompOper__c=:COMPARATOR_EQUALS AND Apttus__Value__c=:strRegion)'
                                        +' OR (Apttus__CompOper__c=:COMPARATOR_IN AND Apttus__Value__c LIKE :strRegionLike))')
                .toSOQL());
    }
}