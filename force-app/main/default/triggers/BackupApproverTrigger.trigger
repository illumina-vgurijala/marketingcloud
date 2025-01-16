/**
*    @author Govind Dubey
*    @date   1 Oct 2018  
*    @description Approver Experience - Delegation of Approval   
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Govind Dubey                 1 Oct 2018            To show error if any field value is modified which is not allowed to change
*    ------------------------------------------------------------------------------------ 
*                    
*/
trigger BackupApproverTrigger on Apttus_Approval__Backup_Approver__c (before insert,after update) {
    ilib_SObjectDomain.triggerHandler(ApttusBackupApprovers.class);
}