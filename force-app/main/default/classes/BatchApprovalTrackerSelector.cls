/**
 *    @author Rishab Wali
 *    @date   2020-08-14
 *    @description   DCP-39772 Selector Class for Batch Approval Tracker Object 
 *    Modification Log:
 *   ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Rishab Wali                    2020-08-14          Initial Version
 *    ------------------------------------------------------------------------------------                  
 */
public with sharing class BatchApprovalTrackerSelector extends ilib_SObjectSelector{

    /*
    * @author Rishab Wali
    * @date   03-Sep-2020
    * @description  describe the object
    *
    */
    public Schema.SObjectType getSObjectType()
    {
        return Batch_Approval_Tracker__c.sObjectType;
    }
    
    /*
    * @author Rishab Wali
    * @date   03-Sep-2020   
    * @description  set select fields
    */
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Batch_Approval_Tracker__c.Name,
            Batch_Approval_Tracker__c.Approval_Related_To__c,
            Batch_Approval_Tracker__c.Status__c,
            Batch_Approval_Tracker__c.Submitted_At__c,
            Batch_Approval_Tracker__c.Submitted_By__c,
            Batch_Approval_Tracker__c.Failed_Records__c,
            Batch_Approval_Tracker__c.Process_Type__c,
            Batch_Approval_Tracker__c.Records_Processed_Successfully__c,
            Batch_Approval_Tracker__c.Total_Number_of_Records_Requested__c    
        };
    }
    
        /*
    * @author Rishab Wali
    * @date   03-Sep-2020
    * @description Fetch Batch Approval Records for a user
    * @param Id UserId, String ObjectType , Set<String> Status 
    *
    */
    public List<Batch_Approval_Tracker__c> getBatchApprovals(String userId , String objectType , Set<String> setStatus) 
    {
        return (List<Batch_Approval_Tracker__c>) Database.query(
         newQueryFactory()
        .setCondition('Submitted_By__c = :userId AND Approval_Related_To__c =: objectType AND Status__c In : setStatus').toSOQL());
    }  
    
}