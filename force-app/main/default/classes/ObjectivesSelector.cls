/**
 *    @author Kushagra Desai
 *    @date   9-Sept-2019
 *    @description  
 *    @Test Class Coverage: 90% --> TestAccountPlanCloneController,TestAccountPlanObjectivesController &  75% --> TestAccountPlanObjectivesController 
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    KD                            6-Aug-2020          DCP-39561 : ad new method getObjectiveByAccountPlanWithAssociation
 *    Bharath Varma                 22-Feb-2021         DCP-43570 : Added Product_Type__c
 *    Bharath Varma                 07-Sep-2021         DCP-46117 : Added a new method to return Objectives for a set of account plan Ids
 *    Adyasha Satapathy             03-Dec-2021         DCP-50392 : Added Account_Plan__r.Account_Name__c
 *    Pravallika                    05-Sep-2022         DCP-52623 : Added field Comments  to FieldList
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class ObjectivesSelector extends ilib_SObjectSelector{
    /*
    * @author Kushagra Desai
    * @date   8-Aug-2019   
    * @description  set select fields
    */
    public List<Schema.SObjectField> getSObjectFieldList()
    {   
        return new List<Schema.SObjectField> {
           Objective__c.id,
           Objective__c.name,
           Objective__c.Account_Plan__c,
           Objective__c.Closed_Status__c,
           Objective__c.Due_Date__c,
           Objective__c.Objective_Status__c,
           Objective__c.Priority__c,
           Objective__c.Action_Completed__c,
           Objective__c.Plan_Objective__c,
           Objective__c.Product_Type__c,
           Objective__c.Comments__c //DCP-52623
        };
    }

    /*
    * @author Kushagra Desai
    * @date   8-Aug-2019 
    * @description  describe the object
    *
    */
    public Schema.SObjectType getSObjectType()
    { 
        return Objective__c.sObjectType;
    }

    /**
     * @author : Kushagra Desai
     * @description return all Objectives by account plan
     * Returns  
     **/
    public List<Objective__c> getObjectiveByAccountPlanIds(String strAccountPlanId)
    {
        return (List<Objective__c>)Database.query(newQueryFactory()
            .setCondition('Account_Plan__c =: strAccountPlanId AND IsInactive__c = false')
            .toSOQL()
        );
    }

    /**
     * @author : Kushagra Desai
     * @description return all Objectives with Tasks
     * Returns List<Objective__c> sObject Record 
     **/
    public List<Objective__c> getObjectivesWithTasks(Set<ID> setObjectiveIds) 
    {
        ilib_QueryFactory objectiveQuery = newQueryFactory();
        objectiveQuery.selectField('Total_Task__c');
        objectiveQuery.selectField('Total_Closed_Task__c');
        ilib_QueryFactory taskQueryFactory = new TaskSelector().addQueryFactorySubselect(objectiveQuery,'Tasks');
        taskQueryFactory.selectField('Status');
        return (List<Objective__c>) Database.query(objectiveQuery.setCondition('Id in :setObjectiveIds').toSOQL());
    }
    /**
     * @author : Kushagra Desai
     * @description DCP-39561:return all Objectives by account plan withoout Plan Territory Association
     * Returns  List of objective
     **/
    public List<Objective__c> getObjectiveByAccountPlanWithAssociation(String strAccountPlanId)
    {
        return (List<Objective__c>)Database.query(
            newQueryFactory()
            .setCondition('Account_Plan__c =: strAccountPlanId AND IsInactive__c = false AND Plan_Objective__c != null')
            .toSOQL()
        );
    }

    /**
     * @author : Bharath Varma
     * @description return all Objectives by set of account plan ids
     * Returns  
     **/
    public List<Objective__c> getObjectiveBySetAccountPlanIds(Set<Id> setAccountPlanIds)
    {
        return (List<Objective__c>)Database.query(newQueryFactory()
            .setCondition('Account_Plan__c in :setAccountPlanIds AND IsInactive__c = false')
            .toSOQL()
        );
    }

    /**
     * @author : Bharath Varma
     * @description DCP-46117:return all Objectives based on a set of Objectives
     * Returns  List of objective
     **/
    public List<Objective__c> getObjectivesBySetOfIds(Set<Id> setObjectiveIds)
    {
        return (List<Objective__c>)Database.query(
            newQueryFactory()
            //DCP-50392
            .selectField('Account_Plan__r.Account_Name__c')
            .selectField('Account_Plan__c')
            //end of DCP-50392
            .setCondition('Id in :setObjectiveIds')
            .toSOQL()
        );
    }
}