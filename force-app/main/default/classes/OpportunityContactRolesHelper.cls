/**
*    @date          9 Dec 2021
*    @description   Opportunity Contact Role domain class Helper to make contact Role as power sponser
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Prem Ranjan                    9 Dec 2021          Initial Version
*    ------------------------------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class OpportunityContactRolesHelper {
    public static final String STRINGEXCEPTIONLOGMESSAGE = 'Error On Contact Role Insert/Update/Delete - OpportunityContactRolesHelper.makeContactPowerSponsorOnInsertAndUpdate()';
    /**
     * @author Prem Ranjan
     * @date   9 Dec 2021
     * @description    DCP-50538 Opp Mgmt: Ability to make first contact on an opportunity the default Power Sponsor
     * Before update/after delete trigger method
     **/
    public static void updateToPowerSponsor(Map<Id,OpportunityContactRole> mapOCRs){
        Map<Id,List<OpportunityContactRole>> mapOpportunityContactRole = new map<Id,List<OpportunityContactRole>>();
    
        for(OpportunityContactRole objOCR : mapOCRs.values()){
            mapOpportunityContactRole.put(objOCR.OpportunityId,new List<OpportunityContactRole>());
        }
        for(OpportunityContactRole objOCR : new OpportunityContactRoleSelector().selectRoles(mapOpportunityContactRole.keyset())){
            mapOpportunityContactRole.get(objOCR.OpportunityId).add(objOCR);
        }
        updateLastRecord(mapOpportunityContactRole,mapOCRs);
    }
    /**
     * @author Prem Ranjan
     * @date   9 Dec 2021
     * @description    DCP-50538 Opp Mgmt: Ability to make first contact on an opportunity the default Power Sponsor
     * Before update/after delete trigger method
     **/
    public static void updateLastRecord(Map<Id,List<OpportunityContactRole>> mapOpportunityContactRole,Map<Id,OpportunityContactRole> mapOCRs){
        List<OpportunityContactRole> lstOpportunityContactRoleToUpdate = new List<OpportunityContactRole>();
        for(OpportunityContactRole objOCR : mapOCRs.values()){
            if(mapOpportunityContactRole.get(objOCR.OpportunityId).size()==1 && System.Trigger.IsUpdate){
                objOCR.Role=System.Label.Power_Sponsor_Contact_Role; 
                lstOpportunityContactRoleToUpdate.add(objOCR);
            }
            if(mapOpportunityContactRole.get(objOCR.OpportunityId).size()==1 && mapOpportunityContactRole.get(objOCR.OpportunityId)[0].Role != System.Label.Power_Sponsor_Contact_Role && System.Trigger.IsDelete){
                mapOpportunityContactRole.get(objOCR.OpportunityId)[0].Role = System.Label.Power_Sponsor_Contact_Role;
                lstOpportunityContactRoleToUpdate.add(mapOpportunityContactRole.get(objOCR.OpportunityId)[0]);
            }
        }
        try { 
            if(!lstOpportunityContactRoleToUpdate.isEmpty() && System.Trigger.IsDelete){
                update lstOpportunityContactRoleToUpdate;
            }
        }catch(Exception e) { ApexExceptions.emit(OpportunityContactRolesHelper.STRINGEXCEPTIONLOGMESSAGE, e); } 
    }
    
    /**
     * @author Prem Ranjan
     * @date   9 Dec 2021
     * @description    DCP-50538 Opp Mgmt: Ability to make first contact on an opportunity the default Power Sponsor
     * Before create trigger method
     **/
    public static void makeContactPowerSponsorOnInsert(List<OpportunityContactRole> lstOCRs){
        Map<Id,List<OpportunityContactRole>> oppIdToLstContactRole = new Map<Id,List<OpportunityContactRole>>();
        Map<Id,Boolean> oppIdHasPowerSponsor = new Map<Id,Boolean>();
        String makePowerSponsorFirstContactRole = '';
        for(OpportunityContactRole objOCR : lstOCRs){
            oppIdToLstContactRole.put(objOCR.OpportunityId, new List<OpportunityContactRole>());
            oppIdHasPowerSponsor.put(objOCR.OpportunityId, false);
        }
        for(OpportunityContactRole objOCR : new OpportunityContactRoleSelector().selectRoles(oppIdToLstContactRole.keyset())){
            oppIdToLstContactRole.get(objOCR.OpportunityId).add(objOCR);
            if(objOCR.Role == System.Label.Power_Sponsor_Contact_Role){
                oppIdHasPowerSponsor.put(objOCR.OpportunityId,true);
            }
        }
        try{
            for(OpportunityContactRole objOCR : lstOCRs){
                
                if(oppIdToLstContactRole.get(objOCR.OpportunityId).isEmpty() && String.valueOf(objOCR.OpportunityId) != makePowerSponsorFirstContactRole){
                    objOCR.Role=System.Label.Power_Sponsor_Contact_Role;
                    makePowerSponsorFirstContactRole=String.valueOf(objOCR.OpportunityId);
                }
                if(!oppIdToLstContactRole.get(objOCR.OpportunityId).isEmpty() && !oppIdHasPowerSponsor.get(objOCR.OpportunityId) && String.valueOf(objOCR.OpportunityId) != makePowerSponsorFirstContactRole){
                    objOCR.Role=System.Label.Power_Sponsor_Contact_Role;
                    makePowerSponsorFirstContactRole=String.valueOf(objOCR.OpportunityId);
                }
            }
        }catch(Exception e) { ApexExceptions.emit(OpportunityContactRolesHelper.STRINGEXCEPTIONLOGMESSAGE, e); }  
    }
    
    }