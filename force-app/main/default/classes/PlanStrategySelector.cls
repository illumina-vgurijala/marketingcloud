/**
 *    @author KD
 *    @date   25-July-2020
 *    @description : Selector class for Plan_Strategy__c object.
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    KD                     17-Sept                     DCP-39967 : Plan CLone
 *    Bharath Varma          20-Sept-2021                DCP-49634 : Added method to return Strategies based on Ids   
 *    Adyasha                23-Mar-2022                 DCP-52242 : Added field in getPlanStrategyWithObjective method             
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class PlanStrategySelector extends ilib_SObjectSelector {
    /*
    * @description  describe the object
    *
    */
    public Schema.SObjectType getSObjectType(){
        return Plan_Strategy__c.sObjectType;
    }
    /*
    * @author Kushagra Desai
    * @date     
    * @description  set select fields
    */
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Plan_Strategy__c.id,
            Plan_Strategy__c.Name,
            Plan_Strategy__c.Plan__c,
            Plan_Strategy__c.Due_Date__c,
            Plan_Strategy__c.IsActive__c,
            Plan_Strategy__c.Description__c
        }; 
    }

    private Boolean removeDefaultOrderBy=false;
    /*  
    * @description  Override Default ordering 
    */
    public override String getOrderBy() {
        if(removeDefaultOrderBy){
            return 'LastModifiedDate DESC';
        }else{
            return super.getOrderBy();
        }
        
    }   
    /**
     * @author : KD
     * @description return all active plan strategy 
     * Returns List<Plan_Strategy__c> sObject Record 
     **/
    public List<Plan_Strategy__c> getTerritoryStrategyWithTerritoryPlan(String strTerritoryPlanId) {
        removeDefaultOrderBy = TRUE;
        return (List<Plan_Strategy__c>) Database.query(
            newQueryFactory().setCondition('Plan__c  = :strTerritoryPlanId AND  IsActive__c = TRUE')
            .toSOQL()
            );
    }
    /**
     * @author : KD
     * @description return all active plan strategy with objectives
     * Returns List<Plan_Strategy__c> sObject Record 
     **/
    public List<Plan_Strategy__c> getPlanStrategyWithObjective(String strStrategyId) {
        removeDefaultOrderBy = TRUE;
        ilib_QueryFactory qryTerritoryStrategy = newQueryFactory();
        qryTerritoryStrategy.selectField('Plan__r.RecordType.DeveloperName'); // Added for DCP-52242
        qryTerritoryStrategy.subselectQuery('Plan_Objectives__r').selectFields(new PlanObjectiveSelector().getSObjectFieldList())
        .selectField('Plan_Strategy__r.Name')
        .selectField('Plan_Strategy__r.Plan__r.Name')
        .selectField('Plan_Strategy__r.Plan__r.Owner.Name')
        .addOrdering('LastModifiedDate', ilib_QueryFactory.SortOrder.DESCENDING, true)
        .setCondition('IsActive__c = TRUE');

        qryTerritoryStrategy.setCondition('Id  = :strStrategyId AND  IsActive__c = TRUE');
        return (List<Plan_Strategy__c>) Database.query(qryTerritoryStrategy.toSOQL());
    }
    /**
     * @author : KD
     * @description return all active plan strategy with objectives
     * Returns List<Plan_Strategy__c> sObject Record 
     // DCP-39967 : Plan CLone
     **/
    public List<Plan_Strategy__c> getPlanStrategyWithObjectiveByPlan(String strPlanId) {
        ilib_QueryFactory qryTerritoryStrategy = newQueryFactory();
        qryTerritoryStrategy.subselectQuery('Plan_Objectives__r')
            .selectFields(new PlanObjectiveSelector().getSObjectFieldList())
            .setCondition('IsActive__c = TRUE');
        qryTerritoryStrategy.setCondition('Plan__c  = :strPlanId AND  IsActive__c = TRUE');
        return (List<Plan_Strategy__c>) Database.query(qryTerritoryStrategy.toSOQL());
    }

    /**
     * @author : Bharath Varma
     * @description return all strategies with ids
     * Returns List<Plan_Strategy__c> sObject Record 
     * DCP-49634 : Plan Clone
     **/
    public List<Plan_Strategy__c> getPlanStrategyWithIds(Set<Id> setStrategyId) {
        return (List<Plan_Strategy__c>) Database.query(
            newQueryFactory()
            .setCondition('Id  in :setStrategyId AND  IsActive__c = TRUE')
            .toSOQL()
        );
    }


    /**
     *  @author Vinay S Reddy
     *  @description fetch Plan strategies from Plan Ids
     *  @param idSet set of plan ids
     *  @return list of plan strategy records
     **/
    public List<Plan_Strategy__c> selectPlanStrategies(Set<Id> planIds)
    {
           
                return (List<Plan_Strategy__c>) Database.query(
                                newQueryFactory()
            					.selectField('Id')
                                .selectField('Plan__c')
                                .setCondition('Plan__c IN :planIds')
                                .toSOQL()
                );    

}
    
}