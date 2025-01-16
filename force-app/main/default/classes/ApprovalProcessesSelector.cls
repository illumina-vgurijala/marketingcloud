/**
*    @author Govind Dubey
*    @date   03 Aug 2018
*    @description  DCP-5311: To fetch Apttus Approval Processes for Quotation
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                      Date                Description
*    Govind Dubey                   03 Aug 2018         Initial Version
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class ApprovalProcessesSelector extends ilib_SObjectSelector{
	/**
    *  @author Govind Dubey 
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the proposal
    **/
    public Schema.SObjectType getSObjectType()
    {
        return Apttus_Approval__Approval_Process__c.sObjectType;
    }
    
    /**
    *  @author  Govind Dubey
    *  @description Retrieve list of fields for Apttus_Approval__Approval_Process__c sObject 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Apttus_Approval__Approval_Process__c.id,
            Apttus_Approval__Approval_Process__c.Name,
            Apttus_Approval__Approval_Process__c.Apttus_Approval__Reassignment_Email_Template__c,
            Apttus_Approval__Approval_Process__c.Apttus_Approval__Process_Name__c,
            Apttus_Approval__Approval_Process__c.Apttus_Approval__Object_Type__c,
            Apttus_Approval__Approval_Process__c.Apttus_Approval__Object_Name__c,
            Apttus_Approval__Approval_Process__c.Apttus_Approval__Object_Label__c,
            Apttus_Approval__Approval_Process__c.Apttus_Approval__NotifyOnly_Email_Template__c,
            Apttus_Approval__Approval_Process__c.Apttus_Approval__Escalation_Email_Template__c,
            Apttus_Approval__Approval_Process__c.Apttus_Approval__Cancellation_Email_Template__c,
            Apttus_Approval__Approval_Process__c.Apttus_Approval__Assignment_Email_Template__c
    	};
    }
    
    /**
     *  @author Govind Dubey 
     *  @description fetch Apttus_Approval__Approval_Process__c for the ids passed in the argument
     *  @param idSet set of Attachment ids
     *  @return lstAttachment list of Attachment records
     **/
    public List<Apttus_Approval__Approval_Process__c> selectById(Set<ID> idSet) 
    {
        return (List<Apttus_Approval__Approval_Process__c>) selectSObjectsById(idSet);
    }
	
}