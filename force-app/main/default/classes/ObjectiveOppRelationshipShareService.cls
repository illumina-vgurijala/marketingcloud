/**
 *    @author Adyasha Satapathy
 *    @date   01-December-2021
 *    @description : DCP-50392 : Service class to handle sharing of Objective Opportunity Relationship records
 *    Modification Log:
 *    ----------------------------------------------------------------------------------------------- 
 *    Developer             Date                      Description
 *    Adyasha           01-December-2021            Initial Version
 *    -----------------------------------------------------------------------------------------------        
 */
public with sharing class ObjectiveOppRelationshipShareService 
{
    /**
     * @description  DCP-50392 Share Objective Opportunity Relationship records on the basis of Territory Plan sharing
     * @param List of plan records to share
     */
    public static void sharePlanObjectiveOppRecords(Map<Id, List<Objective_Opportunity_Relationship__c>> mapPlanIdToObjectiveOppRelationship)
    {   
        if(mapPlanIdToObjectiveOppRelationship == null || mapPlanIdToObjectiveOppRelationship.isEmpty()) { return; }
        List<Plan__c> lstPlans = new PlanSelector().getPlanbyIds(mapPlanIdToObjectiveOppRelationship.keySet());

        PlanShareService.mapTerritoryCodeToPlan = new Map<String,List<Plan__c>>();
        PlanShareService.mapOwnerIdToPlan = new Map<Id ,List<Plan__c>>();
        PlanShareService.mapTerritoryIdToPlan = new Map<Id,List<Plan__c>>();
        PlanShareService.mapParentIdToLeafNodeCode = new Map<Id,String>();
        PlanShareService.mapUserIdToPlan = new Map<Id, List<Plan__c>>();
        PlanShareService.mapTerritoryIdToUser = new Map<Id, Set<Id>>();
        PlanShareService.mapParentIdToUser = new Map<Id,Set<Id>>();
        
        PlanShareService.generateMapofPlans(lstPlans);
        
        if(!PlanShareService.mapOwnerIdToPlan.isEmpty())
        {
            PlanShareService.generateTerritoryMapWithPlans();        
        }
        
        PlanShareService.generateParentTerritoryMap();
        
        Set<Id> setTerritoryId = new Set<Id>();
        setTerritoryId.addAll(PlanShareService.mapParentIdToLeafNodeCode.keySet());
        setTerritoryId.addAll(PlanShareService.mapTerritoryIdToPlan.keySet());
        createShareRecordsForRelatedTerritoryPlan(setTerritoryId,mapPlanIdToObjectiveOppRelationship);
    }

    /**     
     * @description  DCP-50392 Logic to Insert share records for created objective opportunity relationship based on hierarchy
     * @param setTerritoryId
     */
    public static void createShareRecordsForRelatedTerritoryPlan(Set<Id> setTerritoryId, Map<Id, List<Objective_Opportunity_Relationship__c>> mapPlanIdToObjectiveOppRelationship)
    {   
        List<Objective_Opportunity_Relationship__Share> lstRelationshipShare = new List<Objective_Opportunity_Relationship__Share>();
        for(Group objGroup : new GroupsSelector().getIdByRelatedBy(setTerritoryId)) 
        {
            if(objGroup.Type == GroupsSelector.GROUP_TYPE_TERRITORY && PlanShareService.mapParentIdToLeafNodeCode.containsKey(objGroup.RelatedId))
            {
                for(Plan__c objPlan : PlanShareService.mapTerritoryCodeToPlan.get(PlanShareService.mapParentIdToLeafNodeCode.get(objGroup.RelatedId)))
                {
                    populateListOfSharesForInsert(objPlan,objGroup.Id,lstRelationshipShare,mapPlanIdToObjectiveOppRelationship);
                }
            }
            else if(objGroup.Type == GroupsSelector.GROUP_TYPE_TERRITORY_SUB && PlanShareService.mapTerritoryIdToPlan.containsKey(objGroup.RelatedId))
            {
                for(Plan__c objPlan : PlanShareService.mapTerritoryIdToPlan.get(objGroup.RelatedId))
                {
                    populateListOfSharesForInsert(objPlan,objGroup.Id,lstRelationshipShare,mapPlanIdToObjectiveOppRelationship); 
                }
            }
        }
        if(!lstRelationshipShare.isEmpty())
        {
            Database.SaveResult[] lstSaveResult = Database.insert(lstRelationshipShare,false);
            ApexExceptions.emitSaveErrors(lstSaveResult, 'ObjectiveOppRelationshipShareService');
        }
    }

    private static void populateListOfSharesForInsert(Plan__c objPlan, Id groupId,List<Objective_Opportunity_Relationship__Share> lstRelationshipShare,Map<Id, List<Objective_Opportunity_Relationship__c>> mapPlanIdToObjectiveOppRelationship)
    {
        if(!mapPlanIdToObjectiveOppRelationship.containsKey(objPlan.Id)) { return; }
        for(Objective_Opportunity_Relationship__c relationship : mapPlanIdToObjectiveOppRelationship.get(objPlan.Id))
        {
            lstRelationshipShare.add(new Objective_Opportunity_Relationship__Share(
                UserOrGroupId = groupId,
                ParentId = relationship.Id,
                AccessLevel = 'Edit',
                RowCause = Schema.Objective_Opportunity_Relationship__Share.RowCause.Manual)
            );
        }
    }
    
    /**     
     * @description  DCP-50392 delete share records
     * @param List<Objective_Opportunity_Relationship__Share>
     */
    public static void deleteObjectiveOpportunityRelationshipShares(List<Objective_Opportunity_Relationship__Share> lstRelationshipShare)
    {
        List<Database.DeleteResult> lstDeleteResult = Database.delete(lstRelationshipShare, false);
        ApexExceptions.emitDeleteErrors(lstDeleteResult,'ObjectiveOppRelationshipShareService.deleteShare');
    }
}