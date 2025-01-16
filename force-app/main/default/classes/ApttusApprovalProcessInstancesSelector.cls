/**
*    @author Dushyant Srivastava
*    @date   09 March 2021
*    @description  DCP-52265: To fetch Apttus Approval Instance for Quotation
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                      Date                  Description
*    Dushyant Srivastava            09 March 2022         Initial Version
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class ApttusApprovalProcessInstancesSelector extends ilib_SObjectSelector{
    /**
    *  @author Dushyant Srivastava
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the proposal
    **/
    public Schema.SObjectType getSObjectType()
    {
        return Apttus_Approval__ApprovalProcessInstance__c.sObjectType;
    }
    
    /**
    *  @author  Dushyant Srivastava
    *  @description Retrieve list of fields for Apttus_Approval__ApprovalProcessInstance__c sObject 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Apttus_Approval__ApprovalProcessInstance__c.id,
            Apttus_Approval__ApprovalProcessInstance__c.Name,
            Apttus_Approval__ApprovalProcessInstance__c.LastModifiedDate,
            Apttus_Approval__ApprovalProcessInstance__c.LastModifiedById,
            Apttus_Approval__ApprovalProcessInstance__c.LastActivityDate,
            Apttus_Approval__ApprovalProcessInstance__c.CreatedDate,
            Apttus_Approval__ApprovalProcessInstance__c.Apttus_Approval__Status__c,
            Apttus_Approval__ApprovalProcessInstance__c.Apttus_Approval__StartTime__c,
            Apttus_Approval__ApprovalProcessInstance__c.Apttus_Approval__PrevProcessInstanceId__c,
            Apttus_Approval__ApprovalProcessInstance__c.Apttus_Approval__InstanceNumber__c,
            Apttus_Approval__ApprovalProcessInstance__c.Apttus_Approval__EndTime__c,
            Apttus_Approval__ApprovalProcessInstance__c.Apttus_Approval__Data__c,
            Apttus_Approval__ApprovalProcessInstance__c.Apttus_Approval__ConsolidationVersionNumber__c,
            Apttus_Approval__ApprovalProcessInstance__c.Apttus_Approval__BusinessObjectType__c,
            Apttus_Approval__ApprovalProcessInstance__c.Apttus_Approval__BusinessObjectLink__c,
            Apttus_Approval__ApprovalProcessInstance__c.Apttus_Approval__BusinessObjectId__c,
            Apttus_Approval__ApprovalProcessInstance__c.Apttus_Approval__ApprovalProcessId__c,
            Apttus_Approval__ApprovalProcessInstance__c.Apttus_Approval__AssignmentEmailTemplate__c, 
            Apttus_Approval__ApprovalProcessInstance__c.Apttus_Approval__ReassignmentEmailTemplate__c, 
            Apttus_Approval__ApprovalProcessInstance__c.Apttus_Approval__EscalationEmailTemplate__c, 
            Apttus_Approval__ApprovalProcessInstance__c.Apttus_Approval__NotifyOnlyEmailTemplate__c, 
            Apttus_Approval__ApprovalProcessInstance__c.Apttus_Approval__CancellationEmailTemplate__c
        };
    }
    
    /**
    *  @author Dushyant Srivastava
    *  @description fetch Apttus_Approval__ApprovalProcessInstance__c for the ids passed in the argument
    *  @param idSet set of Apttus_Approval__ApprovalProcessInstance__c ids
    *  @return lstApprovalProcessInstance__c list of EmailTemplate records
    **/
    public List<Apttus_Approval__ApprovalProcessInstance__c> selectById(List<ID> lstIds) 
    {
        return (List<Apttus_Approval__ApprovalProcessInstance__c>) Database.query(
            newQueryFactory(false,false,true).setCondition('id IN :lstIds').toSOQL()
        );
    }

    /**
    *  @author Kumar Gaurav
    *  @description fetch Apttus_Approval__ApprovalProcessInstance__c for the proposal id passed in the argument
    *  @param proposalid set of Apttus_Approval__ApprovalProcessInstance__c ids
    *  @return lstApprovalProcessInstance__c list records
    **/
    public list<Apttus_Approval__ApprovalProcessInstance__c> selectbyApprovalBusinessObjectId(Set<ID> proposalId)
    {
        return (List <Apttus_Approval__ApprovalProcessInstance__c>) Database.query(
            newQueryFactory()
            .setCondition('Apttus_Approval__BusinessObjectId__c IN :proposalId')
            .addOrdering('CreatedDate', ilib_QueryFactory.SortOrder.DESCENDING)
            .toSOQL()
        );
    }


}