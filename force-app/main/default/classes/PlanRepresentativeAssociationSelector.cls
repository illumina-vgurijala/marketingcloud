/**
 *    @author Akshay Mohan
 *    @date   13-Aug-2020
 *    @description : Selector class for Plan_Representative_Association__c object
 *    @Test Class for 90% Code Coverage
 *    @Test Class for 75% Code Coverage
 *    TestPlanRepresentativeController
 *    TestPlanCloneController
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                  Description
 *    Nishan Shetty                 14-Sept-2022            DCP-56402 [CodeScanFix].
 *    
 *    ------------------------------------------------------------------------------------ 
 *                    
 */

public with sharing class PlanRepresentativeAssociationSelector extends ilib_SObjectSelector {
    /*
    * @description  describe the object
    *
    */
    public Schema.SObjectType getSObjectType() {//DCP-56402 [CodeScan Fix]
        return Plan_Representative_Association__c.sObjectType;
    }
    /*  
    * @description  set select fields
    */
    public List<Schema.SObjectField> getSObjectFieldList() {//DCP-56402 [CodeScan Fix]
        return new List<Schema.SObjectField> {
            Plan_Representative_Association__c.id,
            Plan_Representative_Association__c.Name,
            Plan_Representative_Association__c.Is_Removed__c,
            Plan_Representative_Association__c.Territory_Plan__c,
            Plan_Representative_Association__c.User__c
           
        }; 
    }
    
    /**
     * @author Akshay
     * @date   13-Aug-2020
     * @description  Get removed Users for a Territory Plan
     * @param String strTerritoryPlanId
     */
    public List<Plan_Representative_Association__c> getRemovedUsersByTPId(String strTerritoryPlanId) {
        return (List<Plan_Representative_Association__c>) Database.query(newQueryFactory()
                .setCondition('Territory_Plan__c = :strTerritoryPlanId AND Is_Removed__c=true')
                .toSOQL());
    }

    /**
     * @author Akshay
     * @date   13-Aug-2020
     * @description  Get removed Users for a Territory Plan
     * @param String strTerritoryPlanId
     */
    public List<Plan_Representative_Association__c> getAddedUsersByTPId(String strTerritoryPlanId) {
        return (List<Plan_Representative_Association__c>) Database.query(newQueryFactory()
                .selectField('User__r.Name')
                .setCondition('Territory_Plan__c = :strTerritoryPlanId AND Is_Removed__c=false')
                .toSOQL());
    }

    /**
     * @author Bharath Varma
     * @date   20-Sep-2021
     * @description  Get Users Asscoiated to a set of Territory Plans
     * @param String setPlanId
     */
    public List<Plan_Representative_Association__c> getUsersAssociatedToPlanById(Set<Id> setPlanId) {
        return (List<Plan_Representative_Association__c>) Database.query(newQueryFactory()
                .setCondition('Territory_Plan__c in :setPlanId')
                .toSOQL());
    }
}