/**
 *    @author Adyasha Satapathy
 *    @date   03-December-2021
 *    @description : DCP-50392 : Selector class for Objective_Opportunity_Relationship__c object 
 *    @Test Class Coverage: 90% --> TestPlanAssociatedOppsController, TestPlanShareService , 75% --> TestPlanAssociatedOppsController, TestPlanShareService
 *    Modification Log:
 *    ----------------------------------------------------------------------------------------------- 
 *    Developer             Date                      Description
 *    Adyasha           01-December-2021            Initial Version
 *    Adyasha           30-August-2022              DCP-54419 : Added new fields to selectAssociationByObjectiveIds().
 *    Maruthi           07-Sep-2022                 DCP-54459 : Updated new fields to selectAssociationByObjectiveIds()
 *    -----------------------------------------------------------------------------------------------        
 */
public with sharing class ObjectiveOpportunityRelationshipSelector extends ilib_SObjectSelector
{
    private static final String LOG_TITLE = 'ObjectiveOpportunityRelationshipSelector';
    private static final String FEATURE_NAME = 'SalesQueryLogs';
    /*
    * @description  describe the object    
    */
    public Schema.SObjectType getSObjectType()
    {
        return Objective_Opportunity_Relationship__c.sObjectType;
    }

    /*  
    * @description  set select fields
    */
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> 
        {
            Objective_Opportunity_Relationship__c.Id,
            Objective_Opportunity_Relationship__c.Name,
            Objective_Opportunity_Relationship__c.Opportunity__c,
            Objective_Opportunity_Relationship__c.Account_Plan_Objective__c,
            Objective_Opportunity_Relationship__c.Plan_Objective__c,
            Objective_Opportunity_Relationship__c.Plan__c,
            Objective_Opportunity_Relationship__c.Account_Plan__c,
            Objective_Opportunity_Relationship__c.Stage__c //DCP-54419
        };
    }
    
    /**
     * @author Adyasha
     * @date   03-December-2021
     * @description  DCP-50392 get Objective Opportunity Relationship records on the basis of Objective Ids
     * @param set of Objective Ids
     */
    public List<Objective_Opportunity_Relationship__c> selectAssociationByObjectiveIds(Set<Id> setObjectiveIds,Boolean boolIsPlanObjective)
    {
        ilib_LogQuery logger = null;
        if (Feature.isOn(FEATURE_NAME)) { logger = new ilib_LogQuery(LOG_TITLE + '.SelectAssociationByObjectiveIds', boolIsPlanObjective+'~'+ UtilsCollection.serializeIds(setObjectiveIds)); }

        String strCondition = boolIsPlanObjective ? 'Plan_Objective__c' : 'Account_Plan_Objective__c';
        strCondition += ' IN :setObjectiveIds';

        List<Objective_Opportunity_Relationship__c> res = (List<Objective_Opportunity_Relationship__c>)Database.query(
            newQueryFactory()        
            .selectField('Opportunity__r.Account')
            .selectField('Opportunity__r.Account.Name')
            .selectField('Opportunity__r.Account.ERP_Customer_Id__c')
            .selectField('Opportunity__r.Account.Ultimate_Parent__c')
            .selectField('Opportunity__r.Name')
            .selectField('Opportunity__r.Owner.Name')
            .selectField('Opportunity__r.StageName')
            .selectField('Opportunity__r.CloseDate')
            .selectField('Opportunity__r.RecordType.Name')
            .selectField('Opportunity__r.Probability')
            .selectField('Opportunity__r.Market_Segment__c')
            .selectField('Opportunity__r.Amount')
            .selectField('Opportunity__r.Product_Type__c')
            .selectField('Opportunity__r.OwnerId')
            .selectField('Opportunity__r.CurrencyIsoCode')
            .selectField('Account_Plan_Objective__r.Name')
            .selectField('Account_Plan_Objective__r.Account_Plan__c')
            .selectField('Account_Plan_Objective__r.Account_Plan__r.Name')
            .selectField('Account_Plan_Objective__r.Account_Plan__r.Owner.Name')
            .selectField('Account_Plan_Objective__r.Account_Plan__r.Account_Name__c')
            .selectField('Account_Plan_Objective__r.Closed_Status__c')
            .selectField('Account_Plan_Objective__r.IsInactive__c')
            .selectField('Account_Plan_Objective__r.Priority__c')
            .selectField('Account_Plan_Objective__r.Account_Plan__r.OwnerId')
            .selectField('Plan_Objective__r.Plan_Strategy__r.Plan__r.Owner.Name')
            .selectField('Plan_Objective__r.Plan_Strategy__r.Plan__r.OwnerId')
            .selectField('Plan_Objective__r.Plan_Strategy__r.Plan__c')
            .setCondition(strCondition)
            .toSOQL()
        );

        if (Feature.isOn(FEATURE_NAME)) { logger.stop(res.size()); }
        return res;
    }
    /**
     * @author Adyasha
     * @date   03-December-2021
     * @description  DCP-50392 get Objective Opportunity Relationship records on the basis of Objective Ids
     * @param set of Objective Ids
     */
    public List<Objective_Opportunity_Relationship__c> selectAssociationByPlanIds(Set<Id> setPlanIds, Boolean isTerritoryPlan)
    {
        ilib_LogQuery logger = null;
        if (Feature.isOn(FEATURE_NAME)) { logger = new ilib_LogQuery(LOG_TITLE + '.selectAssociationByPlanIds', isTerritoryPlan+'~'+ UtilsCollection.serializeIds(setPlanIds)); }
        
        String strCondition = isTerritoryPlan ? 'Plan__c' : 'Account_Plan__c';
        strCondition += ' IN :setPlanIds';

        List<Objective_Opportunity_Relationship__c> res = (List<Objective_Opportunity_Relationship__c>)Database.query(
            newQueryFactory()        
            .setCondition(strCondition)
            .toSOQL()
        );

        if (Feature.isOn(FEATURE_NAME)) { logger.stop(res.size()); }
        return res;
    }
}