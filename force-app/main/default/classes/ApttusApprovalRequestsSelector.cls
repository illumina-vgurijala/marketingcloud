/**
 *    @author Rohan Chandarana
 *    @date   2018-06-07
 *    @description    Class to get the Proposal Line Items records based on different conditions 
 *    Modification Log:
 *   ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Govind Dubey                   2018-07-25           Initial Version
 *    Rahul Sharma                   2019-07-03           DCP-25384 Added selectByAccounts
 *    Roopal Verma                   2019-07-05           DCP-25340 Added Promo_Approval_Seq__c
 *    Roopal Verma                   2020-03-20           DCP-34075 Added selectByApprovalRequestId
 *    Umesh Mor                      2020-01-15           DCP-31142 Added selectByAgreementId(Set<Id> setAgreementIds)  
 *    Roopal Verma                   2020-06-12           DCP-37652 Added selectAppReqByAgreementId
 *    Rishab Wali                    2020-08-07           DCP-40087 Adding method to get Request for Agreements only
 *    Prabhsimran Singh              2021-01-15           INC0304142: Added selectByParentandUserId() to query approval requests based on parent id's and user id's.
 *    ------------------------------------------------------------------------------------                  
 */

public with sharing class ApttusApprovalRequestsSelector extends ilib_SObjectSelector 
{
    /**
    *  @author Govind Dubey 
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the Proposal Line Item
    **/
   public Schema.SObjectType getSObjectType()
   {
      return Apttus_Approval__Approval_Request__c.sObjectType;
   }
    
    /**
     *  @author  Govind Dubey
     *  @description Retrieve list of fields for Approval Request
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
           Apttus_Approval__Approval_Request__c.Id,
           Apttus_Approval__Approval_Request__c.Name,
           Apttus_Approval__Approval_Request__c.Apttus_Approval__Assigned_To_Id__c,
           Apttus_Approval__Approval_Request__c.Apttus_QPApprov__ProposalId__c,
           Apttus_Approval__Approval_Request__c.Apttus_Approval__Status_Link__c,
           Apttus_Approval__Approval_Request__c.Apttus_Approval__Assigned_To_Name__c,
           Apttus_Approval__Approval_Request__c.Apttus_Approval__Sequence__c,
           Apttus_Approval__Approval_Request__c.Apttus_Approval__Step_Name__c,
           Apttus_Approval__Approval_Request__c.Apttus_Approval__Approval_Status__c,
           Apttus_Approval__Approval_Request__c.Apttus_Approval__Approver_Comments__c,
           Apttus_Approval__Approval_Request__c.Apttus_Approval__StepLabel__c,
           Apttus_Approval__Approval_Request__c.Apttus_Approval__StepSequenceString__c,
           Apttus_Approval__Approval_Request__c.Apttus_Approval__ChildObjectId__c,
           Apttus_Approval__Approval_Request__c.Promo_Approval_Seq__c, //DCP-25340
           Apttus_Approval__Approval_Request__c.Apttus_Approval__SubstepSequence__c,
           Apttus_Approval__Approval_Request__c.Apttus_Approval__Related_Agreement__c,
           Apttus_Approval__Approval_Request__c.CreatedById,             //DCP-37652
           Apttus_Approval__Approval_Request__c.Formula_Sub_Sequence__c
       };
    }

    /**
     *  @author Govind Dubey
     *  @description fetch Approval Requests for the ids passed in the argument
     *  @param idSet set of proposal line ids
     *  @return list of Approval Request records
     **/
    public List<Apttus_Approval__Approval_Request__c> selectByQuoteId(Set<Id> setQuoteIds) 
    { 
        return (List<Apttus_Approval__Approval_Request__c>) Database.query(
                      newQueryFactory()
                      .selectField('Apttus_Approval__Initial_Submitter__c')
                      .selectField('Apttus_QPApprov__ProposalId__r.Region_Sold_To__c')
                      .selectField('Apttus_QPApprov__ProposalId__r.Region_Ultimate_Consignee__c')
                      .selectField('Apttus_QPApprov__ProposalId__r.Region_Distributor__c')
                      .selectField('Apttus_QPApprov__ProposalId__r.Apttus_Proposal__Opportunity__r.RecordType.DeveloperName')
                      .setCondition('Apttus_QPApprov__ProposalId__c IN :setQuoteIds AND Apttus_Approval__Assigned_To_Type__c != NULL AND Apttus_Approval__Assigned_To_Id__c != NULL')
                      //.addOrdering('Apttus_Approval__Sequence__c', ilib_QueryFactory.SortOrder.ASCENDING)
                      .addOrdering('Formula_Sub_Sequence__c', ilib_QueryFactory.SortOrder.ASCENDING) 
                      .addOrdering('Apttus_Approval__StepLabel__c', ilib_QueryFactory.SortOrder.ASCENDING)
                      .toSOQL());
                     
    }
    
    /**
     *  @author Govind Dubey
     *  @description Order By sequence 
     *  @retrun String
     */
    public override String getOrderBy(){
      return 'Apttus_Approval__StepSequenceString__c ASC';
    } 

    /**
     *  @author Rahul Sharma
     *  @description DCP-25384 fetch Approval Requests for the ids passed in the argument
     *  @param idSet set of proposal line ids
     *  @return list of Approval Request records
     **/
     
    public List<Apttus_Approval__Approval_Request__c> selectByAccounts(Set<Id> accountIds) 
    { 
        return (List<Apttus_Approval__Approval_Request__c>) Database.query(
                      newQueryFactory()
                      .setCondition('Apttus_QPApprov__ProposalId__r.Apttus_Proposal__Opportunity__r.AccountId IN :accountIds OR Apttus_QPApprov__ProposalId__r.Apttus_Proposal__Opportunity__r.Ultimate_Consignee__c IN :accountIds')
                      .toSOQL());                
    }
	
	/**
     *  @author Roopal Verma
     *  @description : DCP-34075
     *  @param idSet set of Approval Request ids
     *  @return list of Approval Request records
     **/
	public List<Apttus_Approval__Approval_Request__c> selectByApprovalRequestId(Set<Id> appReqIds) 
    { 
        return (List<Apttus_Approval__Approval_Request__c>) Database.query(
                      newQueryFactory()
                      .selectField('Apttus_QPApprov__ProposalId__r.Id')
                      .selectField('Apttus_Approval__Assigned_To_Id__c') //DCP-53207
                      .selectField('Apttus_Approval__Assigned_To_Type__c') //DCP-53207
                      .selectField('Apttus_Approval__ObjectRefId__c')
                      .selectField('Apttus_Approval__Object_Type__c')
                      .setCondition('Apttus_Approval__Approval_Request__c.Id IN :appReqIds')
                      .toSOQL());                

	}
	/**
     *  @author Umesh Mor
     *  @description : DCP-31142
     *  @param idSet set of Agreement ids
     *  @return list of Approval Request records
     **/
    public List<Apttus_Approval__Approval_Request__c> selectByAgreementId(Set<Id> setAgreementIds) 
    { 
        return (List<Apttus_Approval__Approval_Request__c>) Database.query(
                       newQueryFactory()
                      .selectField('Apttus_Approval__Initial_Submitter__c')
                      .selectField('Apttus_Approval__Related_Agreement__r.Region__c')
                      .selectField('Apttus_Approval__Related_Agreement__r.Ultimate_Consignee__c')
                      .selectField('Apttus_Approval__Related_Agreement__r.Discount_Justification__c')
                      .setCondition('Apttus_Approval__Related_Agreement__c IN :setAgreementIds AND Apttus_Approval__Assigned_To_Type__c != NULL AND Apttus_Approval__Assigned_To_Id__c != NULL')
                      .addOrdering('Apttus_Approval__Sequence__c', ilib_QueryFactory.SortOrder.ASCENDING)
                      .addOrdering('Apttus_Approval__StepLabel__c', ilib_QueryFactory.SortOrder.ASCENDING)
                      .toSOQL());
                     
    }

    /**
     *  @author Roopal Verma
     *  @description : DCP-37652
     *  @param idSet set of Agreement ids
     *  @return list of Approval Request records
     **/
    public List<Apttus_Approval__Approval_Request__c> selectAppReqByAgreementId(Set<Id> setAgreementIds){

        Set<String> statusNotInApproval = ApttusAgreements.STATUSES_NOT_IN_APPROVAL;
        return (List<Apttus_Approval__Approval_Request__c>) Database.query(
                      newQueryFactory()
                      .selectField('Apttus_Approval__Related_Agreement__r.Submitted_by__c')
                      .setCondition('Apttus_Approval__Related_Agreement__c IN :setAgreementIds AND Apttus_Approval__Related_Agreement__r.Apttus_Approval__Approval_Status__c NOT IN :statusNotInApproval AND Apttus_Approval__Related_Agreement__r.Approval_Request_Present__c = false')
                      .toSOQL());
    }
    
    /**
     *  @author Rishab Wali
     *  @description : DCP-40087 Method to get approval requests
     *  @param String,Id,Set<String>
     *  @return list of Approval Request records
     **/
    public List<Apttus_Approval__Approval_Request__c> getApprovalRequestByLoggedInUser(String objectName , Id userId , Set<String> setStatuses)
    {
        return (List<Apttus_Approval__Approval_Request__c>) Database.query(
                      newQueryFactory()
                      .selectField('Apttus_Approval__Related_Agreement__r.Name')
                      .selectField('Apttus_Approval__Related_Agreement__r.RecordType.Name')
                      .selectField('Apttus_Approval__Related_Agreement__r.Apttus__Account__r.Name')
                      .selectField('Apttus_Approval__Related_Agreement__r.Apttus__FF_Agreement_Number__c')
                      .selectField('Apttus_Approval__Related_Agreement__r.Discount_Justification__c')
                      .selectField('Apttus_Approval__Related_Agreement__r.Highest_Discount_Requested__c')
                      .selectField('Apttus_Approval__Related_Agreement__r.Approval_Hierarchy_Discount__c')
                      .selectField('Apttus_Approval__Approver_Comments__c')
                      .selectField('Apttus_Approval__Related_Agreement__r.Highest_Approver_Level_Discount__c')
                      .selectField('Apttus_Approval__Related_Agreement__r.Approval_Hierarchy_Discount__r.Approver_Level_1__r.Name')
                      .selectField('Apttus_Approval__Related_Agreement__r.Approval_Hierarchy_Discount__r.Approver_Level_2__r.Name')
                      .selectField('Apttus_Approval__Related_Agreement__r.Approval_Hierarchy_Discount__r.Approver_Level_3__r.Name')
                      .selectField('Apttus_Approval__Related_Agreement__r.Approval_Hierarchy_Discount__r.Approver_Level_4__r.Name')
                      .selectField('Apttus_Approval__Related_Agreement__r.Approval_Hierarchy_Discount__r.Approver_Level_5__r.Name')
                      .selectField('Apttus_Approval__Related_Agreement__r.Approval_Hierarchy_Discount__r.Approver_Level_6__r.Name')                      
                      .setCondition('Apttus_Approval__Approval_Status__c IN : setStatuses AND Apttus_Approval__Assigned_To_Type__c != NULL AND Apttus_Approval__Assigned_To_Id__c = :userId AND Apttus_Approval__Object_Type__c =: objectName')
                      .toSOQL());
    }
	
	/**
     *  @author Prabhsimran Singh
     *  @description : INC0304142 Method to get approval requests based on parent id and user id
     *  @param Set<Id> parent ids,Set<Id> user ids
     *  @return list of Approval Request records
     **/
    public List<Apttus_Approval__Approval_Request__c> selectByParentandUserId(Set<Id> setParentIds, Set<Id> setUserIds) 
    { 
        return (List<Apttus_Approval__Approval_Request__c>) Database.query(
                      newQueryFactory()
                      .setCondition('(Apttus_Approval__Related_Agreement__c IN :setParentIds OR Apttus_QPApprov__ProposalId__c IN :setParentIds) AND Apttus_Approval__Assigned_To_Id__c IN :setUserIds AND Apttus_Approval__Assigned_To_Type__c != NULL AND Apttus_Approval__Assigned_To_Id__c != NULL')
                      .toSOQL());
                     
    }
    
     /**
     *  @author Dushyant Srivastava
     *  @description : Method to get approval requests based on Request Status and user id
     *  @param List<User> User List,List<String> Status List
     *  @return list of Approval Request records
     **/
    public List<Apttus_Approval__Approval_Request__c> selectByParentandUserId(List<User> lstUsers, List<String> lstApprovalStatus,String approvalStage) 
    {
        
            return (List<Apttus_Approval__Approval_Request__c>) Database.query(
                    newQueryFactory()
                    .selectField('Apttus_Approval__Action__c')
                    .selectField('Approval_Email__c')
                    .selectField('Apttus_Approval__DateAssigned__c')
                    .selectField('Apttus_QPApprov__ProposalId__c')
                    .selectField('Apttus_QPApprov__ProposalId__r.Name')
                    .selectField('Apttus_QPApprov__ProposalId__r.Apttus_Proposal__Opportunity__r.Name')
                    .selectField('Apttus_QPApprov__ProposalId__r.Sold_To_Account_Name__c')
                    .selectField('Apttus_QPApprov__ProposalId__r.Total_Net__c')
                    .selectField('Apttus_QPApprov__ProposalId__r.Approval_Level__c')
                    .selectField('Apttus_QPApprov__ProposalId__r.CurrencyIsoCode')
                    .selectField('Apttus_QPApprov__ProposalId__r.Ultimate_Consignee__r.Subregion__c')
                    .selectField('OwnerId')
                    .selectField('Apttus_QPApprov__ProposalId__r.Apttus_Proposal__Approval_Stage__c')
                    .setCondition('OwnerId IN: lstUsers AND Apttus_Approval__Approval_Status__c IN:lstApprovalStatus AND Apttus_QPApprov__ProposalId__r.Apttus_Proposal__Approval_Stage__c = :approvalStage')
                    .toSOQL());
        
        
   }

	
}