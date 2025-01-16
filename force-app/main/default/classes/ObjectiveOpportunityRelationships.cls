/**
 *    @author Adyasha Satapathy
 *    @date   01-December-2021
 *    @description : DCP-50392 : Trigger handler class for Objective_Opportunity_Relationship__c object
 *    @Test Class for above 90% coverage.
 *    -TestPlanAssociatedOppsController
 *    @Test Class for atleast 75% coverage.
      -TestPlanAssociatedOppsController
 *    Modification Log:
 *    ----------------------------------------------------------------------------------------------- 
 *    Developer             Date                      Description
 *    Adyasha           01-December-2021            Initial Version
 *  Nishan Shetty        24-Aug-2022                DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
 *    -----------------------------------------------------------------------------------------------        
 */
public with sharing class ObjectiveOpportunityRelationships extends ilib_SObjectDomain
{
    /** 
     * @description  Constructor
     * @param List of ObjectiveOpportunityRelationships
     */
    public ObjectiveOpportunityRelationships(List<Objective_Opportunity_Relationship__c> sObjectList)
    {
        super(sObjectList);
    }

    /** 
     * @description  implements ilib_SObjectDomain.IConstructable
     */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /** 
         * @description  construct method
         */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new ObjectiveOpportunityRelationships(sObjectList);
        }
    }

    /** 
     * @description  onAfterInsert
     */
    public override void onAfterInsert()
    {
        createShareRecords((List<Objective_Opportunity_Relationship__c>) records);
    }
     
    /** 
     * @description  create share records for inserted relationship records
     */
    public void createShareRecords(List<Objective_Opportunity_Relationship__c> lstObjectiveOpportunityRelationship)
    {
        Map<Id, List<Objective_Opportunity_Relationship__c>> mapPlanIdToObjectiveOppRelationship = new Map<Id, List<Objective_Opportunity_Relationship__c>>();                
        Set<Id> setAccPlanRelationshipIds = new Set<Id>();

        for(Objective_Opportunity_Relationship__c relationship : lstObjectiveOpportunityRelationship) 
        {
            if(String.isNotBlank(relationship.Plan_Objective__c) && String.isNotBlank(relationship.Plan__c))
            {               
                if(!mapPlanIdToObjectiveOppRelationship.containsKey(relationship.Plan__c))
                {
                    mapPlanIdToObjectiveOppRelationship.put(relationship.Plan__c, new List<Objective_Opportunity_Relationship__c>());
                }
                mapPlanIdToObjectiveOppRelationship.get(relationship.Plan__c).add(relationship);
            }
            else if(String.isNotBlank(relationship.Account_Plan_Objective__c)) 
            {                                        
                setAccPlanRelationshipIds.add(relationship.Id);
            }
        }
        if(!mapPlanIdToObjectiveOppRelationship.isEmpty())
        {
            ObjectiveOppRelationshipShareService.sharePlanObjectiveOppRecords(mapPlanIdToObjectiveOppRelationship);
        }
        if(!setAccPlanRelationshipIds.isEmpty())
        {
            TAPS_OrchestratorInterface tapsOrchestrator = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
            tapsOrchestrator.recalculateRecordChanges(setAccPlanRelationshipIds, getSObjectType());//DCP-44091
        }
    }
}