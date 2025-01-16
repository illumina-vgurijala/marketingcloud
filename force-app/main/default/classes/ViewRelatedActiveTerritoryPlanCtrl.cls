/**
 *    @author KD
 *    @date   21-Aug-2020
 *    @description  Controller class for ViewRelatedActiveTerritoryPlan component
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------------------
*     Developer                      Date                Description
*     Rucha Dalvi                    31-May-2022         DCP-52588 : Violation Reduction Sales(Q3) Codescan Issue
*    ------------------------------------------------------------------------------------------------------------------------------------------------
 */
public with sharing class ViewRelatedActiveTerritoryPlanCtrl {
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
            String strTerritoryCode = territoryPlan[0].Territory_Code__c;
            for(Plan__c objPlan : new PlanSelector().getPlanByTerritoryCodeExceptRecordId(strTerritoryCode,recordId)) {
                wrapPlanList.add(new PlanWrapper(objPlan));
            }
            Map<String,String> mapLabels = new Map<String,String>();
            mapLabels.put('UI_Message_No_Active_TP',Label.UI_Message_No_Active_TP);
            return '{"wrapPlanList": '+JSON.serialize(wrapPlanList)+','
                    +' "mapLabels": '+JSON.serialize(mapLabels)+'}';
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
    *   @author KD
    *   @description Wrapper class for data table
    **/
    public class PlanWrapper{
        //DCP-52500 Changing variable name to camelCase to resolve Codescan Issue
        public string planName ,planId,ownerName,channelPartner,recordType ;
        /**
        *   @author KD
        *   @description Wrapper class Constructor
        **/
        public PlanWrapper(Plan__c objPlan){
            this.planId = '/'+objPlan.Id;
            this.planName = objPlan.Name;
            this.ownerName = objPlan.Owner.Name;
            this.channelPartner = objPlan.Channel_Partner__r.Name;
            this.recordType = objPlan.RecordType.Name;
        }
    }
}