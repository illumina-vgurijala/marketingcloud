/**
 * @author KD 
 * @description  Query Selector for Plan Share.
 * @Test Class for 90% coverage-TestPlanShareService
 * @Test Class for 75% coverage-TestPlanShareService
 * Modification Log:
*  ------------------------------------------------------------------------------------ 
*   Developer                Date                Description   
*   KD                       24-Sept-2020        DCP-39951 : Admin layout
*   Nishan Shetty            04-Oct-2022         Removed getShareRecords method as part of test class coverage.
*  -----------------------------------------------------------------------------------          
*/
public with sharing class PlanShareSelector extends ilib_SObjectSelector{
    /*
    * @description  describe the object
    *
    */
    public Schema.SObjectType getSObjectType()
    {
        return Plan__Share.sObjectType;
    }
    /*  
    * @description  set select fields
    */
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
            Plan__Share.ParentId,
            Plan__Share.UserOrGroupId,
            Plan__Share.AccessLevel,
            Plan__Share.RowCause,
            Plan__Share.LastModifiedDate
       };
    }

    /*
    Author : KD
    Description : Method to Query Share Records with Parent Id and row cause.
    */
    public List<Plan__Share> getShareRecordsWithParentId(Set<Id> setParentId, String strManualRowCause){
        return (List<Plan__Share>)Database.query(
            newQueryFactory(true)
            .setCondition('ParentId IN :setParentId AND RowCause = :strManualRowCause')
            .toSOQL()
        );
    }
    
    /*
    Author : KD
    Description : Method to Query Share Records with Parent Id.
    //DCP-39951
    */
    public List<Plan__Share> getAllShareRecordsWithParentId(List<Id> setParentId){
        return (List<Plan__Share>)Database.query(
            newQueryFactory(true)
            .selectField('UserOrGroup.Name')
            .setCondition('ParentId IN :setParentId')
            .toSOQL()
        );
    }
}