/**
 *    @author KD
 *    @date   25-Aug-2020
 *    @description  Controller class for ViewTerritoryPlan component
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------------------
 *     Developer                    Date                   Description
 *    Akshay Mohan                  21-Sep-2020            DCP-41644: Change overlay logic for getting leaf nodes
 *    Rucha Dalvi                   30-May-2022            DCP-52588 : Violation Reduction Sales(Q3) Codescan Issue
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
 */
public with sharing class ViewTerritoryPlansController {
    public static final String AURA_EXCEPTION = 'No Association Found';
    /**
    *  @author KD
    *  @description Fetch all active plans in territory
    *  @param Plan Record Id
    *  @return String
    **/
    @AuraEnabled(cacheable = true)
    public static String initRecords(String recordId){
        try{
            List<PlanWrapper> wrapPlanList = new List<PlanWrapper>();
            List<Plan__c> territoryPlan = new PlanSelector().getTerritoryPlanbyId(recordId);
            Id idOwner = territoryPlan[0].OwnerId;
            List<UserTerritory2Association> lstUTA = new UserTerritory2AssociationSelector().selectOnlyDirectByUserId(new Set<Id>{idOwner});
            if(lstUTA.isEmpty()){
                AuraHandledException e = new AuraHandledException(AURA_EXCEPTION);
                e.setMessage(AURA_EXCEPTION);
                throw e;
            }
            //DCP-41644
            Set<Id> setTerritoryIds = UtilsCollection.getSetOfIds(lstUTA,'Territory2Id');
            System.debug('setTerritoryIds: '+setTerritoryIds);
            Set<String> setTerritoryCode = new Set<String>();
            List<Territory2> lstLeafTerritories = new TerritoriesSelector().selectLeafTerritoriesByTerritoryId(setTerritoryIds);
            for(Territory2 objTerr : lstLeafTerritories){
                setTerritoryCode.add(objTerr.Territory_Code__c);
            }
            List<Plan__c> lstActivePlan = new PlanSelector().getActivePlanByTerritoryCode(setTerritoryCode);
            for(Plan__c objPlan : lstActivePlan) {
                wrapPlanList.add(new PlanWrapper(objPlan));
            }
            return JSON.Serialize(wrapPlanList);
        }
        catch(Exception ex){
            AuraHandledException e = new AuraHandledException(AURA_EXCEPTION);
            e.setMessage(AURA_EXCEPTION);
            throw e;
        }
    }
    /* Wrapper class for data table*/
    public class PlanWrapper{
        public string strPlanName ,strPlanId,strOwnerName;
        public Decimal decPlanTarget;
        /* Constructor for wrapper*/
        public PlanWrapper(Plan__c objPlan){
            this.strPlanId = '/'+objPlan.Id;
            this.strPlanName = objPlan.Name;
            this.strOwnerName = objPlan.Owner.Name;
            this.decPlanTarget = objPlan.Plan_Target__c;
        }
    }
}