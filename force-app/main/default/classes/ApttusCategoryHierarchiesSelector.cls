/**
  *  @author Rohan Chandarana 
  *  @description  Class to get the Product Hierarchy records based on different conditions
  *  @return SObjectType The Schema.SObjectType of the Category Hierarchy
**/
   
public with sharing class ApttusCategoryHierarchiesSelector extends ilib_SObjectSelector{
    public static final String YES = 'Yes';

     /**
    *  @author Rohan Chandarana
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the Product Classification
    **/
	public Schema.SObjectType getSObjectType(){
        return Apttus_Config2__ClassificationHierarchy__c.sObjectType;
   }
    
    /**
     *  @author  Rohan Chandarana 
     *  @description Retrieve list of fields for Categpry Hierarchy sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList(){
       return new List<Schema.SObjectField> {
           Apttus_Config2__ClassificationHierarchy__c.id
       };
    }


    /**
     *  @author  Rohan Chandarana 
     *  @description Select Leaf Hierarchy Records from Category Hierarchy
     *  @return List<Apttus_Config2__ClassificationHierarchy__c> List of 
     **/
    public List<Apttus_Config2__ClassificationHierarchy__c> selectLeaf(){
        String strCondition = 'Apttus_Config2__IsLeaf__c='+'\''+ YES +'\'';
        return (List<Apttus_Config2__ClassificationHierarchy__c>) Database.query(
            newQueryFactory().
            selectField('id').
            selectField('Apttus_Config2__Level__c'). // DCP-25216 : adding level
            selectField('Apttus_Config2__AncestorId__r.id').
            selectField('Apttus_Config2__AncestorId__r.Apttus_Config2__AncestorId__r.id').
            selectField('Name').
            selectField('Apttus_Config2__AncestorId__r.Name').
            selectField('Apttus_Config2__AncestorId__r.Apttus_Config2__AncestorId__r.Name').
            setCondition(strCondition).
            toSOQL()
        );
    }

    /**
     *  @author Rohan Chandarana 
     *  @description fetch Category Hierarchies for the ids passed in the argument
     *  @param idSet set of Category Hierarchy ids
     *  @return list of Category Hierarchy records
     **/
    public List<Apttus_Config2__ClassificationHierarchy__c> selectById(Set<ID> idSet){
        return (List<Apttus_Config2__ClassificationHierarchy__c>) selectSObjectsById(idSet);
    }
}