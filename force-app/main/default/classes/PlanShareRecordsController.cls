/**
 * @author KD 
 * @description  Controller class for Plan Share Records component
 * Modification Log:
*  ------------------------------------------------------------------------------------ 
*   Developer                Date                Description   
*  -----------------------------------------------------------------------------------          
*/
public with sharing class PlanShareRecordsController {
    /**
    *   @author KD
    *   @description method to fetch all Plan_share records
    *   @param List of plan id
    **/
    @AuraEnabled(cacheable = true)
    public static String initRecords(List<Id> lstRecordId){
        try{
            return JSON.serialize(fetchShareRecords(lstRecordId));
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
    *   @author KD
    *   @description method to fetch all Plan_share records [shared with sharing console]
    *   @param List of plan id
    **/
    public static List<SharingConsole.WrapperForUserRecord> fetchShareRecords(List<Id> lstRecordId){
        List<SharingConsole.WrapperForUserRecord> lstPlanShareWrap = new List<SharingConsole.WrapperForUserRecord>();
        Set<String> setGroupId = new Set<String>();
        Map<String,List<SharingConsole.WrapperForUserRecord>> mapGroupIdToPlanShareWrap = new Map<String,List<SharingConsole.WrapperForUserRecord>>();
        List<Plan__share> lstPlanShare = new PlanShareSelector().getAllShareRecordsWithParentId(lstRecordId);
        for(Plan__share objPlanShare : lstPlanShare){
            if(String.isBlank(objPlanShare.UserOrGroup.Name))
                setGroupId.add(objPlanShare.UserOrGroupId);
            if(!mapGroupIdToPlanShareWrap.containsKey(objPlanShare.UserOrGroupId))
                mapGroupIdToPlanShareWrap.put(objPlanShare.UserOrGroupId,new List<SharingConsole.WrapperForUserRecord>());
            mapGroupIdToPlanShareWrap.get(objPlanShare.UserOrGroupId).add(new SharingConsole.WrapperForUserRecord(objPlanShare));
        }
        if(!setGroupId.isEmpty()){ 
            List<Group> lstGroup = new GroupsSelector().getByGroupIds(setGroupId);
            for(Group objGrp : lstGroup){
                for(SharingConsole.WrapperForUserRecord objPlanShareWrapper : mapGroupIdToPlanShareWrap.get(objGrp.Id))
                    objPlanShareWrapper.userName = objGrp.DeveloperName;
            }
        }
        for(List<SharingConsole.WrapperForUserRecord> lstPlanWrap : mapGroupIdToPlanShareWrap.values())
            lstPlanShareWrap.addAll(lstPlanWrap);
        return lstPlanShareWrap;
    }
}