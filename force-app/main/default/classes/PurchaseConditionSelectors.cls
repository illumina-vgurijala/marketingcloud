/*
 *    @author Prem Ranjan
 *    @date   20-Sep-2021
 *    @description    Class to get the Purchase Condition records based on different conditions ,
 *    Modification Log:
 *   ---------------------------------------------------------------------------------------------------------------------------
 *    Developer                      Date                Description
 *    
 *   --------------------------------------------------------------------------------------------------------------------------
 */ 
public with sharing class PurchaseConditionSelectors extends ilib_SObjectSelector{
    /**
    *  @author Prem Ranjan 
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the Line Items
    **/
    public Schema.SObjectType getSObjectType()
    {
       return Purchase_Conditions__c.sObjectType;
    }
    /**
    *  @author - Prem Ranjan
    *  @description - Retrieve list of fields for Purchase Condition records based on different conditions 
    *  @return - sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Purchase_Conditions__c.Id,
            Purchase_Conditions__c.Agreement__c
        };
    }

    /**
    *  @author Prem Ranjan
    *  @description Fetch Product and End Date Durations records
    *  @return list of CLM Preferred Language to Template records
    **/
    public List<Purchase_Conditions__c> selectAllRecordsById(Set<Id> pcId){
        ilib_QueryFactory query = newQueryFactory();
            query.setCondition('id IN : pcId');
            query.selectfield('Agreement__c');
            return (List<Purchase_Conditions__c>) Database.query(
                query.toSOQL()
            );
    }
}