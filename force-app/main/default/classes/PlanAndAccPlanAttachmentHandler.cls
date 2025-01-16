/* **************************************************************************************
* CLASS NAME   : PlanAndAccPlanAttachmentHandler
* DEVELOPER      : Prem Ranjan
* USER STORY     : DCP-50569 Territory Planning: Reporting ability T/F "Is file attached?"
* DESCRIPTION    : Populate Fields on Plan/Account Plan if it has Files Attached/Deattached

Modification Log:
*       ------------------------------------------------------------------------------------
*       Prem Ranjan         04/03/2022            TASK0720146-Updated future to Queueable
*       ------------------------------------------------------------------------------------
*******************************************************************************************/
public with sharing class PlanAndAccPlanAttachmentHandler {
    public static final String ACCOUNT_PLAN = 'Account_Plan__c'; 
    public static final String PLAN = 'Plan__c'; 
    public static final String SNOTE = 'SNOTE'; 
    private final static String SOURCE = 'PlanAndAccPlanAttachmentHandler';
    public static final String INSERT_ACTION = 'INSERT';
    public static final String DELETE_ACTION = 'DELETE';
    public static final String STREXECUTE = 'execute';
    public static String action;



/* METHOD NAME   : populateFieldsOnPlan
* DEVELOPER      : Prem Ranjan
* USER STORY     : DCP-50569 Territory Planning: Reporting ability T/F "Is file attached?"
* DESCRIPTION    : Populate Fields on Plan/Account Plan if it has Files Attached/Deattached
* RETURN TYPE    : NA
* PARAMETER      : Map<Id,ContentDocumentLink>
*/
Public static void populateFieldsOnPlan(Map<Id,ContentDocumentLink>contentDocMap){
    Set<Id> accPlanIdSet = getLinkedEntityId(contentDocMap.values(),ACCOUNT_PLAN);
    Set<Id> planIdSet = getLinkedEntityId(contentDocMap.values(),PLAN);
    if((!accPlanIdSet.isEmpty() || !planIdSet.isEmpty()) && System.Trigger.IsInsert){
        action = INSERT_ACTION;
    }
    if((!accPlanIdSet.isEmpty() || !planIdSet.isEmpty()) && System.Trigger.IsDelete){
        action = DELETE_ACTION;
    } 
    if(String.isNotBlank(action)) {
    PlanAndAccPlanAttachmentQueueable planAndAccPlanIsUpdate = new PlanAndAccPlanAttachmentQueueable(accPlanIdSet,planIdSet,action);
    ilib_Queueablethread queueableThread = new ilib_Queueablethread('ContentDocumentLink_PlanAndAccPlanAttachmentQueueable');
    queueableThread.logAndQueue(planAndAccPlanIsUpdate, 'PlanAndAccPlanAttachmentQueueable', STREXECUTE); 
    ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SALES);
    }
     
}
/* METHOD NAME   : getLinkedEntityId
* DEVELOPER      : Prem Ranjan
* USER STORY     : DCP-50569 Territory Planning: Reporting ability T/F "Is file attached?"
* DESCRIPTION    : get Object Id linked to Content Document link
* RETURN TYPE    : Set<Id>
* PARAMETER      : List<ContentDocumentLink>,String
*/
Public static Set<Id> getLinkedEntityId(List<ContentDocumentLink>contentDocLst,String strObjName){
Set<Id> linkedEntityIdByObject = new Set<Id>();
for(ContentDocumentLink objContentDocument : contentDocLst){
    String cdlObjName = objContentDocument.LinkedEntityId.getSObjectType().getDescribe().getName();
    if(String.isNotBlank(cdlObjName) && strObjName.equals(cdlObjName))
    {
        linkedEntityIdByObject.add(objContentDocument.LinkedEntityId);
    }
}
return linkedEntityIdByObject;      
}

/* METHOD NAME   : updateIsFileAttachedTrue
* DEVELOPER      : Prem Ranjan
* USER STORY     : DCP-50569 Territory Planning: Reporting ability T/F "Is file attached?"
* DESCRIPTION    : Populate Is File Attached Field as True on Plan/Account Plan if it has Files Attached
* RETURN TYPE    : NA
* PARAMETER      : Set<Id> , Set<Id> 
*/
public static void updateIsFileAttachedTrue(Set<Id> accPlanIdSet, Set<Id> planIdSet) {
    List<SObject> lstSObjectRecord = new List<SObject>();
if(!accPlanIdSet.isEmpty()){
    for(Account_Plan__c accPlan : new AccountPlanSelector().getAccPlanWithoutAttachment(accPlanIdSet)){
            accPlan.Is_file_attached__c = True;
            lstSObjectRecord.add(accPlan);
    }  
}
if(!planIdSet.isEmpty()){
    for(Plan__c planObj : new PlanSelector().getPlanWithoutAttachment(planIdSet)){           
        planObj.Is_file_attached__c = True;
        lstSObjectRecord.add(planObj);
    }  
}

if(!lstSObjectRecord.isEmpty()){
    List<Database.SaveResult> lstSaveErrorsAccPlan = Database.update(lstSObjectRecord, false); 
                ApexExceptions.emitSaveErrors(lstSaveErrorsAccPlan, SOURCE+' Plan/Account Plan '); 
}

}

/* METHOD NAME   : updateAccPlanIsFileAttachedFalse
* DEVELOPER      : Prem Ranjan
* USER STORY     : DCP-50569 Territory Planning: Reporting ability T/F "Is file attached?"
* DESCRIPTION    : Populate Is File Attached Field as False on Account Plan if it has Files Deattached
* RETURN TYPE    : NA
* PARAMETER      : Set<Id> 
*/
public static void updateAccPlanIsFileAttachedFalse(Set<Id> accPlanId) {
Map<Id,List<ContentDocumentLink>> mapAccPlanIdToContentDocLst = new Map<Id,List<ContentDocumentLink>>();
List<Account_Plan__c> lstAccPlanRecord = new List<Account_Plan__c>();
    for(Id accPlan : accPlanId){           
        mapAccPlanIdToContentDocLst.put(accPlan, new List<ContentDocumentLink>());
    } 
    for(ContentDocumentLink objContentDocument : new ContentDocumentLinksSelector().selectContentDocumentLinks(mapAccPlanIdToContentDocLst.keyset())){
        if(objContentDocument.ContentDocument.FileType != SNOTE){
            mapAccPlanIdToContentDocLst.get(objContentDocument.LinkedEntityId).add(objContentDocument); 
        }
    }
    for(Account_Plan__c objAccPlan : new AccountPlanSelector().getAccountPlanByIds(mapAccPlanIdToContentDocLst.keySet()))
    {
        if(mapAccPlanIdToContentDocLst.containsKey(objAccPlan.Id) &&  mapAccPlanIdToContentDocLst.get(objAccPlan.Id).isEmpty()){
            objAccPlan.Is_file_attached__c = False;
            lstAccPlanRecord.add(objAccPlan);
        }
        
    }
if(!lstAccPlanRecord.isEmpty()){
    List<Database.SaveResult> lstSaveErrorsAccPlan = Database.update(lstAccPlanRecord, false); 
        ApexExceptions.emitSaveErrors(lstSaveErrorsAccPlan, SOURCE+' Account Plan '); 
}
}
/* METHOD NAME   : updatePlanIsFileAttachedFalse
* DEVELOPER      : Prem Ranjan
* USER STORY     : DCP-50569 Territory Planning: Reporting ability T/F "Is file attached?"
* DESCRIPTION    : Populate Is File Attached Field as False on Plan if it has Files Deattached
* RETURN TYPE    : NA
* PARAMETER      : Set<Id> 
*/
public static void updatePlanIsFileAttachedFalse(Set<Id> planId) {
    Map<Id,List<ContentDocumentLink>> mapPlanIdToContentDocLst = new Map<Id,List<ContentDocumentLink>>();
    List<Plan__c> lstPlanRecord = new List<Plan__c>();
    for(Id plan : planId){
        mapPlanIdToContentDocLst.put(plan, new List<ContentDocumentLink>());
    } 
    for(ContentDocumentLink objContentDocument : new ContentDocumentLinksSelector().selectContentDocumentLinks(mapPlanIdToContentDocLst.keyset())){
        if(objContentDocument.ContentDocument.FileType != SNOTE){
            mapPlanIdToContentDocLst.get(objContentDocument.LinkedEntityId).add(objContentDocument);
        }   
    }
    for(Plan__c objPlan : new PlanSelector().getPlanbyIds(mapPlanIdToContentDocLst.keySet()))
    {
        if(mapPlanIdToContentDocLst.containsKey(objPlan.Id) && mapPlanIdToContentDocLst.get(objPlan.Id).isEmpty()){
            objPlan.Is_file_attached__c = False;
            lstPlanRecord.add(objPlan);
        }
        
    }
    if(!lstPlanRecord.isEmpty()){
        List<Database.SaveResult> lstSaveErrorsPlan = Database.update(lstPlanRecord, false); 
            ApexExceptions.emitSaveErrors(lstSaveErrorsPlan, SOURCE+' Plan '); 
    }
}
}