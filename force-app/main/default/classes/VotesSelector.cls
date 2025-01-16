/**
 *    @author Adyasha Satapathy
 *    @date   20-Nov-2020
 *    @description    Class to get the Vote records based on different conditions
 *    Modification Log:
 *    -------------------------------------------------------------------------------------------------------------
 *    Developer                 Date                    Description
 *    Adyasha Satapathy      20-Nov-2020                Initial Version 
 *    -------------------------------------------------------------------------------------------------------------                   
 */
public with sharing class VotesSelector extends ilib_SObjectSelector{
    /**
    *  @author Adyasha
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the Vote
    **/
    public Schema.SObjectType getSObjectType()
    {
        return Vote.sObjectType;
    }
    /**
     *  @author  Adyasha
     *  @description Retrieve list of fields for Vote sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
       return new List<Schema.SObjectField> {
           Vote.Id,
           Vote.Type,
           Vote.CreatedById, 
           Vote.ParentId
       };
    }
    /*
    * @author Adyasha Satapathy
    * @params Set<Id> idSet
    * @returns List<Vote>
    */
    public List<Vote> selectByParentId(Id idParent)
    {
        return (List<Vote>) Database.query(
            newQueryFactory().
            setCondition('ParentId = :idParent')
            .toSOQL());
    }
}