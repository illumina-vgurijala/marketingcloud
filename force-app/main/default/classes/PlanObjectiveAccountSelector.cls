/**
 *    @author Kushagra Desai
 *    @date   25-July-2020
 *    @description : Selector class for Plan_Objective_Account__c object.
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class PlanObjectiveAccountSelector extends ilib_SObjectSelector{
    /*
    * @description  describe the object
    *
    */
    public Schema.SObjectType getSObjectType(){
        return Plan_Objective_Account__c.sObjectType;
    }
    /*  
    * @description  set select fields
    */
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Plan_Objective_Account__c.id,
            Plan_Objective_Account__c.Name,
            Plan_Objective_Account__c.Account__c,
            Plan_Objective_Account__c.Plan_Objective__c    
        }; 
    }
    /**
     * @author : Kushagra Desai
     * @description return all Plan_Objective_Account__c by Objectiv Id
     * Returns  Plan_Objective_Account__c
     **/
    public List<Plan_Objective_Account__c> getAccountByPlanObjectiveId(String strTerritoryObjectiveId) {
        return (List<Plan_Objective_Account__c>) Database.query(
            getRelatedFieldsQuery()
            .setCondition('Plan_Objective__c = :strTerritoryObjectiveId')
            .toSOQL()
        );
    }
    /**
     * @author : Kushagra Desai
     * @description return allrelated fields
     **/
    private ilib_QueryFactory getRelatedFieldsQuery(){
        return newQueryFactory()
            .selectField('Plan_Objective__r.Id')
            .selectField('Plan_Objective__r.Name')
            .selectField('Plan_Objective__r.Objective_Status__c')
            .selectField('Plan_Objective__r.Closed_Status__c')
            .selectField('Plan_Objective__r.Due_Date__c')
            .selectField('Plan_Objective__r.Priority__c')
            .selectField('Plan_Objective__r.Plan_Strategy__c')
            .selectField('Plan_Objective__r.Plan_Strategy__r.Name')
            .selectField('Plan_Objective__r.IsActive__c')
            .selectField('Plan_Objective__r.Plan_Strategy__r.Plan__r.Name')
            .selectField('Plan_Objective__r.Plan_Strategy__r.Plan__c')
            .selectField('Plan_Objective__r.Plan_Strategy__r.Plan__r.Owner.Name')
            .selectField('Plan_Objective__r.Plan_Strategy__r.Plan__r.Status__c')
            .selectField('Account__r.Name')
            .selectField('Account__r.Owner.Name')
            .selectField('Account__r.ERP_Customer_Id__c');
    }

    /**
     * @author : Bharath Varma
     * @description return all Plan_Objective_Account__c by Objective Id
     * Returns  List of Plan_Objective_Account__c
     **/
    public List<Plan_Objective_Account__c> getAccountBySetPlanObjectiveId(Set<Id> setTerritoryObjectiveId) {
        return (List<Plan_Objective_Account__c>) Database.query(
            getRelatedFieldsQuery()
            .setCondition('Plan_Objective__c in :setTerritoryObjectiveId')
            .toSOQL()
        );
    }
}