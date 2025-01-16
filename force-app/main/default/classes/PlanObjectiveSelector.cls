/**
 *    @author KD
 *    @date   25-July-2020
 *    @description : Selector class for Plan_Objective__c object.
 *    @Test Class Coverage: 90% --> TestTerritoryPlanStrategyController , TestPlanCloneController 75% --> TestTerritoryPlanStrategyController
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    KD                            21-Sept-2020         DCP-41752 : Added related fields.
 *    Akshay Mohan                  24-Sept-2020         DCP-41751 : Modify related fields.
 *    Bharath Varma                 20-Sept-2021         DCP-49634 : Added method to query objectives by Ids
 *    Adyasha                       30-Aug-2022          DCP-54419 : Updated method getPlanObjectivesByIds() to fetch the related fields also.
 *    Pravallika                    05-Sep-2022          DCP-52623 : Added Comments field to FieldList
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class PlanObjectiveSelector extends ilib_SObjectSelector {
    private Boolean removeDefaultOrderBy=false;
    private static final String LOG_TITLE = 'PlanObjectiveSelector';
    private static final string QUERY_LOGS_SALES = 'SalesQueryLogs';
    /*
    * @description  describe the object
    *
    */
    public Schema.SObjectType getSObjectType(){
        return Plan_Objective__c.sObjectType;
    }
    /*
    * @author Kushagra Desai
    * @date     
    * @description  set select fields
    */
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Plan_Objective__c.id,
            Plan_Objective__c.Name,
            Plan_Objective__c.Objective_Status__c,
            Plan_Objective__c.Priority__c,
            Plan_Objective__c.Plan_Strategy__c,
            Plan_Objective__c.IsActive__c,
            Plan_Objective__c.No_of_Completed_Actions__c,
            Plan_Objective__c.Percent_Action_Completed__c,
            Plan_Objective__c.Closed_Status__c,
            Plan_Objective__c.Due_Date__c,
            Plan_Objective__c.Market_Segment__c,
            Plan_Objective__c.Priority__c,
            Plan_Objective__c.Product_Type__c,
            Plan_Objective__c.No_of_Actions__c,
            Plan_Objective__c.Owner_Name__c,
            Plan_Objective__c.Comments__c // DCP-52623

        }; 
    }
    private ilib_QueryFactory getRelatedFieldsQuery(){
        return newQueryFactory()
            .selectField('Plan_Strategy__r.Name')
            .selectField('Plan_Strategy__r.Plan__r.Name')
            // DCP-41752
            .selectField('Plan_Strategy__r.Plan__r.Channel_Partner_Territory_Code__c')
            .selectField('Plan_Strategy__r.Plan__r.Territory_Code__c')
            .selectField('Plan_Strategy__r.Plan__r.RecordType.DeveloperName')
            .selectField('Plan_Strategy__r.Plan__c')
            .selectField('Plan_Strategy__r.Plan__r.Owner.Name')
            .selectField('Plan_Strategy__r.Plan__r.OwnerId')
            //DCP-41751
            .selectField('Plan_Strategy__r.Plan__r.Name');
    }

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
     * @description return all active plan Objective 
     * Returns List<Plan_Objective__c> sObject Record 
     **/
    public Plan_Objective__c getTerritoryObjectiveWithId(String strPlanObjectiveId) {
        removeDefaultOrderBy = TRUE;
        return (Plan_Objective__c) Database.query(
            getRelatedFieldsQuery()
            .setCondition('Id  = :strPlanObjectiveId AND IsActive__c = TRUE ')
            .toSOQL()
        );
    }

    /**
     * @author : KD
     * @description return all plan Objective by Plan Id
     * Returns List<Plan_Objective__c> sObject Record 
     **/
    public List<Plan_Objective__c> getPlanObjectiveById(String strPlanID) {
        removeDefaultOrderBy = TRUE;
        return (List<Plan_Objective__c>) Database.query(
            getRelatedFieldsQuery()
            .setCondition('Id  = : strPlanID')
            .toSOQL()
        );
    }
    /**
     * @author : Kushagra Desai
     * @description return all Plan Objectives with Tasks
     * Returns List<Plan_Objective__c> sObject Record 
     **/

    public List<Plan_Objective__c> getPlanObjectivesWithTasks(Set<ID> setPlanObjectiveIds) 
    { 
        
         ilib_QueryFactory objectiveQuery = getRelatedFieldsQuery();
         ilib_QueryFactory taskQueryFactory = new TaskSelector().addQueryFactorySubselect(objectiveQuery,'Tasks');
         taskQueryFactory.selectField('Status');
        return (List<Plan_Objective__c>) Database.query(objectiveQuery.setCondition('Id in :setPlanObjectiveIds').toSOQL());
    }
    /**
     * @author : Kushagra Desai
     * @description DCP-40334  return all Plan Objectives by Plan Id
     * Returns List<Plan_Objective__c> sObject Record 
     **/

    public List<Plan_Objective__c> getPlanObjectivesByPlanId(Set<ID> setPlanIds) 
    {
        return (List<Plan_Objective__c>) Database.query(
            getRelatedFieldsQuery()
            .setCondition('Plan_Strategy__r.Plan__c  IN : setPlanIds AND IsActive__c = TRUE AND Plan_Strategy__r.IsActive__c = TRUE')
            .toSOQL()
        );
    }

    /**
     * @author : Bharath Varma
     * @description DCP-49634  return all Plan Objectives by Set of Ids
     * Returns List<Plan_Objective__c> sObject Record 
     **/
    public List<Plan_Objective__c> getPlanObjectivesByIds(Set<ID> setPlanObjectiveIds) 
    { 
        ilib_LogQuery logger = null;
        if (Feature.isOn(QUERY_LOGS_SALES)) {
            logger = new ilib_LogQuery (LOG_TITLE + '.getPlanObjectivesByIds', UtilsCollection.serializeIds(setPlanObjectiveIds));
        }

        List<Plan_Objective__c> res = (List<Plan_Objective__c>) Database.query(
             getRelatedFieldsQuery()
            .setCondition('Id in :setPlanObjectiveIds')
            .toSOQL()
        );

        if (Feature.isOn(QUERY_LOGS_SALES)) logger.stop(res.size());
        return res;
    }

    /**
     *  @author Vinay S Reddy
     *  @description fetch Plan objectives from plan strategy ids
     *  @param idSet set of plan strategies ids
     *  @return list of plan objective records
     **/
    public List<Plan_Objective__c> selectPlanObjectives(Set<Id> strategyIds)
    {
        return (List<Plan_Objective__c>) Database.query(
                                newQueryFactory()
            					.selectField('Id')
                                .selectField('Objective_Status__c')
                                .selectField('Plan_Strategy__c')
                                .selectField('IsActive__c')
                                .setCondition('Plan_Strategy__c IN :strategyIds')
                                .toSOQL()
        );
    }
}