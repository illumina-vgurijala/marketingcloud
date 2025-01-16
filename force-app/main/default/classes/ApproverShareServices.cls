/**
* @author Satya Swain
* @description  Domain Class for Platform event Approver_Share_Service__e
* Modification Log:
* ------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                Description                                                 
*   Satya Swain           14-April-2020          INC0253701/DCP-37473: Added logic to Share Parent Proposal or Agreement with Approver
*   Prabhsimran Singh     15-Jan-2021            INC0304142: Added logic to not delete the quotation/agreement share record if aproval request inserted again.
* ------------------------------------------------------------------------------------------------------------------------------------          
*/
public with sharing class ApproverShareServices extends ilib_SObjectDomain
{
    /**
    * @description Parameterized Constructor called
    * @params List<Approver_Share_Service__e> sObjectList
    * @return void
    **/
    public ApproverShareServices(List<Approver_Share_Service__e> sObjectList)
    {
        super(sObjectList);
    }
    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /**
        * @description  Constructor of base class
        * @params List<SObjects> sObjectList
        * @return sObjectList
        **/
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new ApproverShareServices(sObjectList);
        }
    }
    /**
    * @description Overriding the onAfterInsert base class method
    * @params NA
    * @return void
    **/
    public override void onAfterInsert()
    {
        List<Approver_Share_Service__e> lstApproverShareService = (List<Approver_Share_Service__e>) records;
        List<Approver_Share_Service__e> lstRecordsForInsertion = new List<Approver_Share_Service__e>();
        List<Approver_Share_Service__e> lstRecordsForDeletion = new List<Approver_Share_Service__e>();
        
        for(Approver_Share_Service__e  objApproverShareService : lstApproverShareService){
            System.debug('objApproverShareService+'+objApproverShareService);
            if(objApproverShareService.Is_Insert__c && !objApproverShareService.Is_Delete__c)
            {
                lstRecordsForInsertion.add(objApproverShareService);
            }
            else 
            {
                if(objApproverShareService.Is_Delete__c && !objApproverShareService.Is_Insert__c)
                {
                    lstRecordsForDeletion.add(objApproverShareService);
                }
            }
        }
        
        deleteSharesForDeletedApprovalRequests(lstRecordsForDeletion);
        createSharesForApprovers(lstRecordsForInsertion);
    }

    /**
    *  @author Satya Swain
    *  @description create share records of parent for approvers upon insertion of approval request
    *  @param List<Approver_Share_Service__e> lstApproverShareService
    *  @return void
    **/
    private void createSharesForApprovers(List<Approver_Share_Service__e> lstApproverShareService)
    {
        if(lstApproverShareService.isEmpty())
            return;

        List<Apttus_Proposal__Proposal__Share> lstQuotationSharesToInsert = new List<Apttus_Proposal__Proposal__Share>();
        List<Apttus__APTS_Agreement__Share> lstAgreementSharesToInsert = new List<Apttus__APTS_Agreement__Share>();

        for(Approver_Share_Service__e objApproverShareService : lstApproverShareService)
        {
            Set<Id> setUserIds = deserializeUserIds(objApproverShareService.User_Ids__c);
            if(objApproverShareService.Parent_Object_Type__c == ApttusApprovalRequests.OBJECT_TYPE_QUOTATION)
            {
                List<Apttus_Proposal__Proposal__Share> lstQuotationShare = getShareRecordsForQuotation(objApproverShareService.Parent_Record_Id__c,setUserIds);
                lstQuotationSharesToInsert.addAll(lstQuotationShare);
            }
            else
            {
                if(objApproverShareService.Parent_Object_Type__c == ApttusApprovalRequests.OBJECT_TYPE_AGREEMENT)
                {
                    List<Apttus__APTS_Agreement__Share> lstAgreementShare = getShareRecordsForAgreement(objApproverShareService.Parent_Record_Id__c,setUserIds);
                    lstAgreementSharesToInsert.addAll(lstAgreementShare);
                }
            }
        }
        if(!lstQuotationSharesToInsert.isEmpty())
        {
            List<Database.SaveResult> srListQuotationShared = Database.insert(lstQuotationSharesToInsert, false);
            ApexExceptions.emitSaveErrors(srListQuotationShared, ApttusApprovalRequests.SOURCE_CLASS_NAME_APTTUSAPPROVALREQUESTS);
        }
        if(!lstAgreementSharesToInsert.isEmpty())
        {
            List<Database.SaveResult> srListAgreementShared = Database.insert(lstAgreementSharesToInsert, false);
            ApexExceptions.emitSaveErrors(srListAgreementShared, ApttusApprovalRequests.SOURCE_CLASS_NAME_APTTUSAPPROVALREQUESTS);
        }
    }

    /**
    *  @author Satya Swain
    *  @description delete share records of parent for approvers upon deletion of approval request
    *  @param List<Approver_Share_Service__e> lstApproverShareService
    *  @return void
    **/
    private void deleteSharesForDeletedApprovalRequests(List<Approver_Share_Service__e> lstApproverShareService)
    {
        // validate the input rows contain enough criteria to identify shares
        // NOTE: necessary critiera hereafer means a) user to share with and b) quote/agreement parent
        Set<Id> setUserIds = new Set<Id>();
        Set<Id> setParentIds = new Set<Id>();
        for(Approver_Share_Service__e objApproverShareService : lstApproverShareService)
        {
            setUserIds.addAll(deserializeUserIds(objApproverShareService.User_Ids__c));
            setParentIds.add(objApproverShareService.Parent_Record_Id__c);
        }
        // if no criteria, done here
        if (setUserIds.isEmpty() || setParentIds.isEmpty()) return;

        // query for existing shares that match input row criteria
        List<Apttus_Proposal__Proposal__Share> lstQuoteShareDeleteCandidates = [Select Id,parentid,userorgroupid from Apttus_Proposal__Proposal__Share where ParentId IN :setParentIds AND UserOrGroupId IN :setUserIds AND RowCause = :Schema.Apttus_Proposal__Proposal__Share.RowCause.Approver__c];
        List<Apttus__APTS_Agreement__Share> lstAgreementShareDeleteCandidates = [Select Id,parentid,userorgroupid from Apttus__APTS_Agreement__Share where ParentId IN :setParentIds AND UserOrGroupId IN :setUserIds AND RowCause = :Schema.Apttus__APTS_Agreement__Share.RowCause.Approver__c];

        // INC0304142: parse the necessary criteria values from shares that actually exist
        Set<Id> setShareParentId = new Set<Id>();
        Set<Id> setShareUserId = new Set<Id>();
        if (!lstQuoteShareDeleteCandidates.isEmpty()) // first from quote shares
        {
            for (Apttus_Proposal__Proposal__Share quoteShare : lstQuoteShareDeleteCandidates) {                
                setShareParentId.add(quoteShare.parentid);
                setShareUserId.add(quoteShare.userorgroupid);
            }
        }
        if (!lstAgreementShareDeleteCandidates.isEmpty()) // then agreement shares
        {
            for (Apttus__APTS_Agreement__Share agreementShare : lstAgreementShareDeleteCandidates) {                
                setShareParentId.add(agreementShare.parentid);
                setShareUserId.add(agreementShare.userorgroupid);
            }
        }

        // INC0304142 - figure out which approval requests actually exist
        // if the request exists we don't want to delete the share to the requested approver - even if we got input rows saying we should
        // input rows like that sometimes get sent here because of Apttus' internal workings
        Map<String, Id> mapApprovalKeyToApprover = new Map<String, Id>();
        if (!setShareParentId.isEmpty())
        {
            List<Apttus_Approval__Approval_Request__c> lstApprovalReq = 
                new ApttusApprovalRequestsSelector().selectByParentandUserId(setShareParentId, setShareUserId);

            for (Apttus_Approval__Approval_Request__c appReq : lstApprovalReq)
            {
                mapApprovalKeyToApprover.put(buildApprovalKey(appReq), appReq.Apttus_Approval__Assigned_To_Id__c);
            }
        }

        // INC0304142 - compare the delete candidates with the keys built from the approval requests
        // if the approval request key matches the share key it should not be deleted
        // but if no match, the share will be added to the "to delete" list
        List<Apttus_Proposal__Proposal__Share> lstQuoteSharesToDelete = new List<Apttus_Proposal__Proposal__Share>();
        if (!lstQuoteShareDeleteCandidates.isEmpty())
        {
            for (Apttus_Proposal__Proposal__Share quoteShare : lstQuoteShareDeleteCandidates)
            {
                if (mapApprovalKeyToApprover.isEmpty() || !mapApprovalKeyToApprover.containsKey(buildApprovalKey(quoteShare)))
                    lstQuoteSharesToDelete.add(quoteShare);
            }
        }
        // quote processing done, now agreements
        List<Apttus__APTS_Agreement__Share> lstAgreementSharesToDelete = new List<Apttus__APTS_Agreement__Share>();
        if (!lstAgreementShareDeleteCandidates.isEmpty())
        {
            for (Apttus__APTS_Agreement__Share agreementShare : lstAgreementShareDeleteCandidates)
            {
                if (mapApprovalKeyToApprover.isEmpty() || !mapApprovalKeyToApprover.containsKey(buildApprovalKey(agreementShare)))
                    lstAgreementSharesToDelete.add(agreementShare);
            }
        }

        // delete the shares which were found not to match approval requests
        if (!lstQuoteSharesToDelete.isEmpty())
        {
            List<Database.DeleteResult> srListQuotationShareDeleted = Database.delete(lstQuoteSharesToDelete, false);
            ApexExceptions.emitDeleteErrors(srListQuotationShareDeleted,ApttusApprovalRequests.SOURCE_CLASS_NAME_APTTUSAPPROVALREQUESTS);
        }
        if (!lstAgreementSharesToDelete.isEmpty())
        {
            List<Database.DeleteResult> srListAgreementShareDeleted = Database.delete(lstAgreementSharesToDelete, false);
            ApexExceptions.emitDeleteErrors(srListAgreementShareDeleted,ApttusApprovalRequests.SOURCE_CLASS_NAME_APTTUSAPPROVALREQUESTS);
        }
    }

    private String buildApprovalKey(Apttus_Proposal__Proposal__Share share)
    {
        return buildApprovalKey(share.ParentId, share.UserOrGroupId);
    }
    private String buildApprovalKey(Apttus__APTS_Agreement__Share share)
    {
        return buildApprovalKey(share.ParentId, share.UserOrGroupId);
    }
    private String buildApprovalKey(Apttus_Approval__Approval_Request__c req)
    {
        if (req.Apttus_QPApprov__ProposalId__c != null)
            return buildApprovalKey(req.Apttus_QPApprov__ProposalId__c, req.Apttus_Approval__Assigned_To_Id__c);
        else
            return buildApprovalKey(req.Apttus_Approval__Related_Agreement__c, req.Apttus_Approval__Assigned_To_Id__c);
    }
    private String buildApprovalKey(Id parentId, Id userId)
    {
        return parentId + '-' + userId;
    }

    /**
    *  @author Satya Swain
    *  @description return list of Set<Id> from the provided serialized string
    *  @param String serialized
    *  @return Set<Id>
    **/
    private Set<Id> deserializeUserIds(String serialized)
    {
        List<String> splitUp = serialized.split('\\|');
        Set<Id> setUserIds = new Set<Id>();
        for (String str : splitUp)
        {
            Id i = (Id)str;
            setUserIds.add(i);
        }
        return setUserIds;
    }
    /**
    *  @author Satya Swain
    *  @description get share record for Quotations
    *  @param Id quoteId, Set<Id> userIds
    *  @return List<Apttus_Proposal__Proposal__Share>
    **/
    private List<Apttus_Proposal__Proposal__Share> getShareRecordsForQuotation(Id quoteId, Set<Id> userIds){
        List<Apttus_Proposal__Proposal__Share> lstQuotationShare = new List<Apttus_Proposal__Proposal__Share>();
        for(Id userId : userIds)
        {
            Apttus_Proposal__Proposal__Share objQuotationShare = new Apttus_Proposal__Proposal__Share();
            objQuotationShare.UserOrGroupId = userId;
            objQuotationShare.ParentId = quoteId;
            objQuotationShare.AccessLevel = ApttusApprovalRequests.ACCESS_LEVEL_EDIT;
            objQuotationShare.RowCause = Schema.Apttus_Proposal__Proposal__Share.RowCause.Approver__c;
            lstQuotationShare.add(objQuotationShare);
        }
        return lstQuotationShare;
    }
    /**
    *  @author Satya Swain
    *  @description get share record for Agreements
    *  @param Id agreementId, Set<Id> userIds
    *  @return List<Apttus__APTS_Agreement__Share>
    **/
    private List<Apttus__APTS_Agreement__Share> getShareRecordsForAgreement(Id agreementId, Set<Id> userIds){
        List<Apttus__APTS_Agreement__Share> lstAgreementShare = new List<Apttus__APTS_Agreement__Share>();
        for(Id userId : userIds)
        {
            Apttus__APTS_Agreement__Share objAgreementShare = new Apttus__APTS_Agreement__Share();
            objAgreementShare.UserOrGroupId = userId;
            objAgreementShare.ParentId = agreementId;
            objAgreementShare.AccessLevel = ApttusApprovalRequests.ACCESS_LEVEL_EDIT;
            objAgreementShare.RowCause = Schema.Apttus__APTS_Agreement__Share.RowCause.Approver__c;
            lstAgreementShare.add(objAgreementShare);
        }
        return lstAgreementShare;
    }

}