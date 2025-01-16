/**
 *    @author Adyasha Satapathy
 *    @date   06-December-2021
 *    @description : DCP-50392 : Selector class to query share records of Objective Opportunity Relationship object
 *    Modification Log:
 *    ----------------------------------------------------------------------------------------------- 
 *    Developer             Date                      Description
 *    Adyasha           06-December-2021            Initial Version
 *    -----------------------------------------------------------------------------------------------        
 */
public with sharing class ObjectiveOppRelationshipShareSelector extends ilib_SObjectSelector{
    /*
    * @description  describe the object
    *
    */
    public Schema.SObjectType getSObjectType()
    {
        return Objective_Opportunity_Relationship__Share.sObjectType;
    }
    /*  
    * @description  set select fields
    */
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
            Objective_Opportunity_Relationship__Share.ParentId,
            Objective_Opportunity_Relationship__Share.UserOrGroupId,
            Objective_Opportunity_Relationship__Share.AccessLevel,
            Objective_Opportunity_Relationship__Share.RowCause,
            Objective_Opportunity_Relationship__Share.LastModifiedDate
       };
    }
    /*
    * Author : Adyasha
    * Description : Method to Query Share Records with Parent Id and row cause.
    */
    public List<Objective_Opportunity_Relationship__Share> getShareRecordsWithParentPlanId(Set<Id> setPlanId, String strManualRowCause){
        return (List<Objective_Opportunity_Relationship__Share>)Database.query(
            newQueryFactory(true)
            .setCondition('Parent.Plan__c IN :setPlanId AND RowCause = :strManualRowCause')
            .toSOQL()
        );
    }
}