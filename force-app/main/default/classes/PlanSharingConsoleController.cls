/**
 * @author KD 
 * @description  Controller class for Plan Sharing Console component
 * Modification Log:
*  ------------------------------------------------------------------------------------ 
*   Developer                Date                Description
  Nishan Shetty            03-Jun-2022         Implementation of Ilib Batch Manager DCP-50962
*  -----------------------------------------------------------------------------------          
*/
public with sharing class PlanSharingConsoleController {
    /**
    *   @author KD
    *   @description Method to rerun sharing for particular plan records
    *   @param List of plan id
    **/
    @auraEnabled
    public static String reRunPlanSharingForRecords(List<Id> recordIds){
        try{
            Set<Id> objRecordIds = new Set<Id> (recordIds);
            if(!checkPlanId(recordIds[0]))
                throw new AuraHandledException(Label.UI_Label_Share_Not_Supported);
            List<Plan__share> lstPlanShare =new PlanShareSelector().getShareRecordsWithParentId(objRecordIds,Schema.Plan__Share.RowCause.Manual);
            PlanShareService.deleteExistingSharing(lstPlanShare);
            PlanShareService.sharePlanRecords(new PlanSelector().getPlanbyIds(objRecordIds));
            return Label.UI_Label_Plan_Shared;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
    *   @author KD
    *   @description Method to check id is of plan
    *   @param  plan id
    **/
    public static Boolean checkPlanId(Id recordId){
        return recordId.getSObjectType() == Schema.Plan__c.getSObjectType();
    }
    /**
    *   @author KD
    *   @description Method to rerun all sharing
    **/
    @AuraEnabled
    public static string reShareAllPlans(){
        try{     
            if(fetchRunningJob().size()>0)
                throw new AuraHandledException('Quarterly Re-Share job is running');
                
            //DCP-50962 - implementation of batch manager
            ilib_BatchManager.executeBatch(new BatchQuarterlyPlanShare(),100);
            return 'New Re-Share job is running';
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
    *   @author KD
    *   @description Method to fetch any running sharing job
    **/
    public static List<AsyncApexJob> fetchRunningJob(){
        List<AsyncApexJob> lstApexJobs = [SELECT Id,MethodName,Status,TotalJobItems,JobItemsProcessed,NumberOfErrors FROM AsyncApexJob where ApexClass.Name = 'BatchQuarterlyPlanShare' and Status != 'Completed'];
        return lstApexJobs;
    }
    /**
    *   @author KD
    *   @description Method to check if any existing job is running
    **/
    @AuraEnabled
    public static String checkRunningJob(){
        try{
            Boolean boolRunningClass = false;
            List<AsyncApexJob> lstApexJobs = fetchRunningJob();
            if(!lstApexJobs.isEmpty())
                boolRunningClass = true;
            return '{"lstApexJobs": '+JSON.serialize(lstApexJobs)+','
                +' "boolRunningClass": '+boolRunningClass+'}';
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
}