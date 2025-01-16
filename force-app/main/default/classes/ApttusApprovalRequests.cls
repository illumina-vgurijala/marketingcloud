/**
*  @author Todd Newman
*  @date   2020-03-24
*  @description    domain class for Apttus Approval Request
*   @Test Class for above 90% coverage.
*   @Test Class for atleast 75% coverage.
      -TestApttusProposals
      -TestSharingConsole
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------------
*      Developer          Date          Description
*      Todd Newman/                      Initial Version
*      Roopal             2020-03-24    Modified After update and created generateAndAttachPDF and createContentDocumentAndLink for DCP-34075
*      Roopal             2020-02-04    broken if condition in two parts for snarqube fix
*      Satya Swain        2020-03-31    INC0253701: Added logic to Share Parent Proposal with Approver_Share_Service__e
*      Satya Swain        2020-09-24    TASK0644781 : Added logic to create shares only for active approvers
*      Satya Swain        2021-10-04    DCP-48131 : Added logic to cache map of id to active approvers to prevent recursive SOQL
*      Nesar              2022-06-21    DCP-53207 : transfer generateAndAttachPDF and createContentDocumentAndLink logic from future to queueable, added comments population logic
*      Avina              2022-06-29    CMSI-91 Added Instrumentation
*      Nishan Shetty      24-Aug-2022   DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
*      Kumar Gaurav       14-Jun-2024   DGP-31  Added invoke the instance of ApttusApprovalRequestReapprovalHandler class
*  ---------------------------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class ApttusApprovalRequests extends ilib_SObjectDomain {

    private static final String LOG_TITLE = 'ApttusApprovalRequests';//CMSI-91
    public static Boolean hasRunTaps = false;
    public static final String OBJECT_TYPE_QUOTATION = 'Apttus_Proposal__Proposal__c';
    public static final String OBJECT_TYPE_AGREEMENT = 'Apttus__APTS_Agreement__c';
    public static final String ASSIGNED_TO_TYPE_USER = 'User';
    public static final String ASSIGNED_TO_TYPE_QUEUE = 'Queue';
    public static final String ACCESS_LEVEL_EDIT = 'Edit';
    public static final String SOURCE_CLASS_NAME_APTTUSAPPROVALREQUESTS = 'ApttusApprovalRequests';
    private static Map<Id, User> mapIdToActiveUsers;
    public static final String EXECUTE = 'execute';
    public static final String INVOKECOMMENTPOPULATIONLOGIC = 'populateCommentsOnQuote';
    public static final String GENERATEANDATTACHPDF = 'generateAndAttachPDF';

    /**
    * @description Parameterized Constructor called
    * @params List<Apttus_Approval__Approval_Request__c> sObjectList
    * @return void
    **/
    public ApttusApprovalRequests(List<Apttus_Approval__Approval_Request__c> sObjectList)
    {
        super(sObjectList);
    }
    /**
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
            return new ApttusApprovalRequests(sObjectList);
        }
    }

    /**
    * @description Overriding the onAfterInsert base class method
    * @params NA
    * @return void
    **/
    public override void onAfterInsert()
    {
        TAPS_OrchestratorInterface tapsOrchestrator = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
        tapsOrchestrator.recalculateRecordChanges(UtilsCollection.getSetOfIds(records, 'Id'), getSObjectType());//DCP-44091
        // Added for INC0253701
        createSharesForApprovers((List<Apttus_Approval__Approval_Request__c>) records);
    }
    /**
    * @description Overriding the onAfterUpdate base class method
    * @params Map<Id, sObject> existingRecords
    * @return void
    **/
    public override void onAfterUpdate(Map<Id, sObject> existingRecords)
    {
        ilib_Queueablethread queueableThreadAfterUpdate = new ilib_Queueablethread('ApttusApprovalRequestsAfterUpdate'); //DCP-53207
        Map<Id,Id> mapProposalRequestIdtoQuoteId = new Map<Id,Id>();    //DCP-53207

        if (!hasRunTaps && !isInsertOperationForObject(getSObjectType()))
        {
            List<String> fieldsThatTriggerRecalculation = new List<String> { 'OwnerId' };
            TAPS_OrchestratorInterface tapsOrchestratorInst = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
            Set<Id> idsThatNeedRecalculation = tapsOrchestratorInst.updateRequiresRecalculation(records, existingRecords, fieldsThatTriggerRecalculation);//DCP-44091
            ilib_LogEvent.info('idsThatNeedRecalculation'+idsThatNeedRecalculation);
            if (idsThatNeedRecalculation.size() > 0)
            {
                ilib_LogEvent.info('inside Record Change Loop');//CMSI-91
                tapsOrchestratorInst.recalculateRecordChanges(idsThatNeedRecalculation, getSObjectType());//DCP-44091
                hasRunTaps = true;
            }
        }
		
		List<Apttus_Approval__Approval_Request__c> lstApprovalrequest = (List<Apttus_Approval__Approval_Request__c>)records;           //DCP-34075 Added logic for attaching content document to Approval request
        List<Apttus_Approval__Approval_Request__c> quoteLstApprovalrequest =new List<Apttus_Approval__Approval_Request__c>(); 
        Map<Id, Apttus_Approval__Approval_Request__c> idToApprovalReq = (Map<Id, Apttus_Approval__Approval_Request__c>)existingRecords;
        Set<Id> setAppApprovalReqId = new Set<Id>();
        
        for(Apttus_Approval__Approval_Request__c objApprovalReq : lstApprovalrequest)
        {
            Apttus_Approval__Approval_Request__c objOldApprovalRequest = (Apttus_Approval__Approval_Request__c) existingRecords.get(objApprovalReq.Id);
            if(string.isNotBlank(objApprovalReq.Apttus_Approval__Object_Type__c) && 
            objApprovalReq.Apttus_Approval__Object_Type__c != 'Apttus__APTS_Agreement__c' ){
              
                if((objApprovalReq.Apttus_Approval__Approval_Status__c == Label.ApprovalRequestApprovalStatusAssigned || objApprovalReq.Apttus_Approval__Approval_Status__c == Label.ApprovalRequestApprovalStatusReassigned )&& (idToApprovalReq.get(objApprovalReq.Id).Apttus_Approval__Approval_Status__c != objApprovalReq.Apttus_Approval__Approval_Status__c)){
                    setAppApprovalReqId.add(objApprovalReq.Id);
                }
                else {
                    if((objApprovalReq.Apttus_Approval__Approval_Status__c == Label.ApprovalRequestApprovalStatusReassigned && (idToApprovalReq.get(objApprovalReq.Id).Apttus_Approval__Assigned_To_Id__c != objApprovalReq.Apttus_Approval__Assigned_To_Id__c))){
                        setAppApprovalReqId.add(objApprovalReq.Id);
                    }
                }
            }
            if(string.isNotBlank(objApprovalReq.Apttus_Approval__Object_Type__c) && 
            objApprovalReq.Apttus_Approval__Object_Type__c == OBJECT_TYPE_QUOTATION )
            {
                quoteLstApprovalrequest.add(objApprovalReq);
            }
            Boolean boolStatusCriteriaSatisfied = objOldApprovalRequest.Apttus_Approval__Approval_Status__c == Label.ApprovalRequestApprovalStatusAssigned || objOldApprovalRequest.Apttus_Approval__Approval_Status__c == Label.ApprovalRequestApprovalStatusReassigned;
            ilib_LogEvent.info('boolStatusCriteriaSatisfied ::: '+boolStatusCriteriaSatisfied+' & Name ::: '+objApprovalReq.Name);
            if(boolStatusCriteriaSatisfied && objApprovalReq.Apttus_Approval__Assigned_To_Type__c != NULL && objApprovalReq.Apttus_Approval__Assigned_To_Id__c != NULL && objApprovalReq.Apttus_Approval__Step_Name__c == System.Label.Open_Offer_Review && objApprovalReq.Apttus_Approval__Object_Type__c == OBJECT_TYPE_QUOTATION) {  //DCP-53207
                mapProposalRequestIdtoQuoteId.put(objApprovalReq.id,objApprovalReq.Apttus_QPApprov__ProposalId__c);
            }
        }

        if(setAppApprovalReqId != null && !setAppApprovalReqId.isEmpty()) { //DCP-53207 
            ApprovalRequestAfterUpdateQueueable queueableClassInstance = new ApprovalRequestAfterUpdateQueueable(GENERATEANDATTACHPDF,null,setAppApprovalReqId);
            queueableThreadAfterUpdate.logAndQueue(queueableClassInstance, GENERATEANDATTACHPDF, EXECUTE);
            //Recalculate Approver record access after re-assignment
            List<Apttus_Approval__Approval_Request__c> lstApprovalReq = new ApttusApprovalRequestsSelector().selectByApprovalRequestId(setAppApprovalReqId);
            createSharesForApprovers(lstApprovalReq);
        }
 
        if(!mapProposalRequestIdtoQuoteId.isEmpty()) { //DCP-53207
            ilib_LogEvent.info('Invoking Open Offer Approval Comment Copy Logic');
            ApprovalRequestAfterUpdateQueueable queueableClassInstance = new ApprovalRequestAfterUpdateQueueable(INVOKECOMMENTPOPULATIONLOGIC,mapProposalRequestIdtoQuoteId,null);
            queueableThreadAfterUpdate.logAndQueue(queueableClassInstance, INVOKECOMMENTPOPULATIONLOGIC, EXECUTE);
        }
 
        if(!queueableThreadAfterUpdate.lstQueueableJobs.isEmpty() && queueableThreadAfterUpdate != null) { //DCP-53207
            ilib_LogEvent.info('Invoking ApprovalRequestAfterUpdateQueueable');
            ilib_QueueableManager.enqueueJob(queueableThreadAfterUpdate);
        }

        if (!quoteLstApprovalrequest.isEmpty() &&  quoteLstApprovalrequest != null)
        ApttusApprovalRequestReapprovalHandler.evaluateLinesForReapproval(quoteLstApprovalrequest);
    }
    /**
    * @description Overriding the onAfterDelete base class method
    * @params NA
    * @return void
    **/
    public override void onAfterDelete()
    {
        List<Apttus_Approval__Approval_Request__c> lstApprovalRequest = (List<Apttus_Approval__Approval_Request__c>) records;
        // Added for INC0253701
        deleteSharesForDeletedApprovalRequests(lstApprovalRequest);
    }

    /*CMSI-51
    * method will return the workstream
    */
    public override string getWorkstream(){
        return ilib_LogEvent.SALES;
    }

    /**
    *  @author Satya Swain
    *  @description Share Parent Proposal with Approver as part of INC0253701
    *  @param List<Apttus__AgreementLineItem__c> lstAgreementLineItem
    *  @return void
    **/
    private void createSharesForApprovers(List<Apttus_Approval__Approval_Request__c> lstApprovalRequest)
    {
        ilib_LogEvent.push(LOG_TITLE + '.createSharesForApprovers()');//CMSI-91
        if(lstApprovalRequest.isEmpty()) { 
            ilib_LogEvent.pop();//CMSI-91
            return; 
        }

        Set<Id> setApproverId = new Set<Id>();
        Set<Id> setObjectId = new Set<Id>();
        Set<Id> setGroupId = new Set<Id>();
        List<Apttus_Proposal__Proposal__Share> lstQuotationShare = null;
        List<Apttus__APTS_Agreement__Share> lstAgreementShare = null;
        List<Approver_Share_Service__e> lstApproverShareService = new List<Approver_Share_Service__e>();
        Map<Id, List<Id>> groupIdToListGroupMembers = new Map<Id, List<Id>>();
        
        for(Apttus_Approval__Approval_Request__c objRequest : lstApprovalRequest)
        {
            setApproverId.add(objRequest.Apttus_Approval__Assigned_To_Id__c);
            setObjectId.add(objRequest.Apttus_Approval__ObjectRefId__c);
            if(objRequest.Apttus_Approval__Assigned_To_Type__c == ASSIGNED_TO_TYPE_QUEUE)
            {
                setGroupId.add(objRequest.Apttus_Approval__Assigned_To_Id__c);
            }
        }
        ilib_LogEvent.info('setApproverId-->: '+setApproverId);//CMSI-91
        if(!setApproverId.isEmpty() && !setObjectId.isEmpty())
        {
            lstQuotationShare = [Select Id, ParentId, UserOrGroupId from Apttus_Proposal__Proposal__Share where UserOrGroupId IN :setApproverId AND ParentId IN :setObjectId];
            lstAgreementShare = [Select Id, ParentId, UserOrGroupId from Apttus__APTS_Agreement__Share where UserOrGroupId IN :setApproverId AND ParentId IN :setObjectId];
        }

        groupIdToListGroupMembers = getMapOfGroupIdToListGroupMembers(setGroupId,getMapOfIdToActiveUsers());

        Map<Id, Set<Id>> existingQuotationRecordIdToUserIds = UtilsCollection.getMapOfIdToIds(lstQuotationShare, 'ParentId', 'UserOrGroupId');
        Map<Id, Set<Id>> existingAgreementRecordIdToUserIds = UtilsCollection.getMapOfIdToIds(lstAgreementShare, 'ParentId', 'UserOrGroupId');

        for(Apttus_Approval__Approval_Request__c objApprovalRequest : lstApprovalRequest)
        {
            Boolean boolIsShareForQuotationExisting = existingQuotationRecordIdToUserIds.containskey(objApprovalRequest.Apttus_Approval__ObjectRefId__c) ?
                                                      existingQuotationRecordIdToUserIds.get(objApprovalRequest.Apttus_Approval__ObjectRefId__c).contains(objApprovalRequest.Apttus_Approval__Assigned_To_Id__c)  : false;
            Boolean boolIsShareForAgreementExisting = existingAgreementRecordIdToUserIds.containskey(objApprovalRequest.Apttus_Approval__ObjectRefId__c) ?
                                                      existingAgreementRecordIdToUserIds.get(objApprovalRequest.Apttus_Approval__ObjectRefId__c).contains(objApprovalRequest.Apttus_Approval__Assigned_To_Id__c)  : false;
            if(objApprovalRequest.Apttus_Approval__Assigned_To_Id__c != NULL
            && objApprovalRequest.Apttus_Approval__ObjectRefId__c != NULL
            && !boolIsShareForQuotationExisting
            && !boolIsShareForAgreementExisting)
            {
                // Added for TASK0644781
                if(objApprovalRequest.Apttus_Approval__Assigned_To_Type__c == ASSIGNED_TO_TYPE_USER  && !getMapOfIdToActiveUsers().containsKey(objApprovalRequest.Apttus_Approval__Assigned_To_Id__c)) { continue; }
                Approver_Share_Service__e objApproverShareService = getApproverShareServiceInstance(objApprovalRequest,groupIdToListGroupMembers,true,false);  // isInsert = true
                if(objApproverShareService != NULL) { lstApproverShareService.add(objApproverShareService); }  
            }
        }
        if(!lstApproverShareService.isEmpty())
        {
            List<Database.SaveResult> res = EventBus.publish(lstApproverShareService);
            ilib_LogEvent.info('@@@ res of publish in insert : '+res);
        }
        ilib_LogEvent.pop();//CMSI-91
    }
    /**
    *  @author Satya Swain
    *  @description delete Shares for corresponding Agreement and Quotation if Approval Request is deleted
    *  @param List<Apttus_Approval__Approval_Request__c> lstApprovalRequest
    *  @return void
    **/
    private void deleteSharesForDeletedApprovalRequests(List<Apttus_Approval__Approval_Request__c> lstApprovalRequest)
    {
        ilib_LogEvent.push(LOG_TITLE + '.deleteSharesForDeletedApprovalRequests()');//CMSI-91
        if(lstApprovalRequest.isEmpty()) {
            ilib_LogEvent.pop();//CMSI-91
             return; 
        }
            

        Set<Id> setGroupId = new Set<Id>();
        List<Approver_Share_Service__e> lstApproverShareService = new List<Approver_Share_Service__e>();
        Map<Id, List<Id>> groupIdToListGroupMembers;

        for(Apttus_Approval__Approval_Request__c objApprovalRequest : lstApprovalRequest)
        {
            if(objApprovalRequest.Apttus_Approval__Assigned_To_Type__c == ASSIGNED_TO_TYPE_QUEUE)
            {
                setGroupId.add(objApprovalRequest.Apttus_Approval__Assigned_To_Id__c);
            }
        }
        ilib_LogEvent.info('setGroupId-->: '+setGroupId);//CMSI-91
        groupIdToListGroupMembers = getMapOfGroupIdToListGroupMembers(setGroupId, null);

        for(Apttus_Approval__Approval_Request__c objApprovalRequest : lstApprovalRequest)
        {
            Approver_Share_Service__e objApproverShareService = getApproverShareServiceInstance(objApprovalRequest,groupIdToListGroupMembers,false,true); // isDelete = true
            if(objApproverShareService != NULL) { lstApproverShareService.add(objApproverShareService); }
                
        }
        if(!lstApproverShareService.isEmpty())
        {
            List<Database.SaveResult> res = EventBus.publish(lstApproverShareService);
            ilib_LogEvent.info('@@@ res of publish in delete : '+res);
        }
        ilib_LogEvent.pop();//CMSI-91
    }
    /**
    *  @author Satya Swain
    *  @description create map of Group Id to List of Group Members
    *  @param Set<Id> setGroupId
    *  @return Map<Id, List<Id>>
    **/
    private Map<Id, List<Id>> getMapOfGroupIdToListGroupMembers(Set<Id> setGroupId, Map<Id,User> mapIdToActiveUsers)
    {
        ilib_LogEvent.push(LOG_TITLE + '.getMapOfGroupIdToListGroupMembers()');//CMSI-91

        ilib_LogEvent.info('setGroupId-->: '+setGroupId);//CMSI-91
        ilib_LogEvent.info('mapIdToActiveUsers-->: '+mapIdToActiveUsers);//CMSI-91

        Map<Id, List<Id>> groupIdToListGroupMembers = new Map<Id, List<Id>>();
        List<GroupMember> lstGroupMember = new List<GroupMember>();

        if(!setGroupId.isEmpty())
        {
            lstGroupMember = [Select Id, GroupId, UserOrGroupId from GroupMember where GroupId IN :setGroupId];
        }
        if(!lstGroupMember.isEmpty())
        {
            for(GroupMember objGroupMember : lstGroupMember)
            {
                Boolean boolCriteriaSatisfied = false;
                if(!groupIdToListGroupMembers.containsKey(objGroupMember.GroupId)) { groupIdToListGroupMembers.put(objGroupMember.GroupId, new List<Id>()); }

                String strUserOrGroupId = String.valueOf(objGroupMember.UserOrGroupId);
                Boolean isGroupMemberAUser = strUserOrGroupId.substring(0,3) == '005';

                // Adding only those members to the list which are users and not groups
                if(isGroupMemberAUser)
                {
                    // Added for TASK0644781
                    if(mapIdToActiveUsers == null)
                    {
                        boolCriteriaSatisfied = true;  
                    }
                    else if(mapIdToActiveUsers.containsKey(objGroupMember.UserOrGroupId))
                    {
                        boolCriteriaSatisfied = true;
                    }
                    // End of TASK0644781
                }
                if(boolCriteriaSatisfied)
                {
                    groupIdToListGroupMembers.get(objGroupMember.GroupId).add(objGroupMember.UserOrGroupId);
                }
            }
        }
        ilib_LogEvent.pop();//CMSI-91
        return groupIdToListGroupMembers;
    }
    /**
    *  @author Satya Swain
    *  @description create instance of Platform event Approver Share Service
    *  @param Apttus_Approval__Approval_Request__c objApprovalRequest,Map<Id, List<Id>> groupIdToListGroupMembers,Boolean isInsert,Boolean isDelete
    *  @return Approver_Share_Service__e
    **/
    private Approver_Share_Service__e getApproverShareServiceInstance(Apttus_Approval__Approval_Request__c objApprovalRequest,Map<Id, List<Id>> groupIdToListGroupMembers,Boolean isInsert,Boolean isDelete)
    {
        ilib_LogEvent.message('objApprovalRequest-->: '+objApprovalRequest);//CMSI-91
        ilib_LogEvent.message('isInsert-->: '+isInsert);//CMSI-91
        ilib_LogEvent.message('isDelete-->: '+isDelete);//CMSI-91

        if (isInsert && isDelete || !isInsert && !isDelete) { 
            return null; 
        }
            

        if (objApprovalRequest.Apttus_Approval__Assigned_To_Type__c != ASSIGNED_TO_TYPE_USER && objApprovalRequest.Apttus_Approval__Assigned_To_Type__c != ASSIGNED_TO_TYPE_QUEUE) { 
            return null; 
        }
            

        Approver_Share_Service__e objShareService = new Approver_Share_Service__e();

        objShareService.Parent_Record_Id__c = objApprovalRequest.Apttus_Approval__ObjectRefId__c;
        objShareService.Parent_Object_Type__c = objApprovalRequest.Apttus_Approval__Object_Type__c;

        objShareService.Is_Insert__c = isInsert;
        objShareService.Is_Delete__c = isDelete;

        if (objApprovalRequest.Apttus_Approval__Assigned_To_Type__c == ASSIGNED_TO_TYPE_USER)
        {
            objShareService.User_Ids__c = objApprovalRequest.Apttus_Approval__Assigned_To_Id__c;
        }
        else
        {
            String serializedUserIds = getUserIdsForSharing(objApprovalRequest,groupIdToListGroupMembers);
            objShareService.User_Ids__c = serializedUserIds;
        }
        ilib_LogEvent.message('objShareService-->: '+objShareService);//CMSI-91
        return objShareService;
    }

    /**
    *  @author Satya Swain
    *  @description create serialized user Ids
    *  @param Apttus_Approval__Approval_Request__c objApprovalRequest, Map<Id, List<Id>> groupIdToListGroupMembers
    *  @return String
    **/
    private String getUserIdsForSharing(Apttus_Approval__Approval_Request__c objApprovalRequest, Map<Id, List<Id>> groupIdToListGroupMembers)
    {
        ilib_LogEvent.push(LOG_TITLE + '.getUserIdsForSharing()');//CMSI-91
        List<Id> userIds = groupIdToListGroupMembers.get(objApprovalRequest.Apttus_Approval__Assigned_To_Id__c);
        if (userIds == null) { 
            ilib_LogEvent.pop();//CMSI-91
            return ''; 
        }

        String serializedUserIds = String.join(userIds, '|');
        ilib_LogEvent.info('serializedUserIds-->: '+serializedUserIds);//CMSI-91
        ilib_LogEvent.pop();//CMSI-91
        return serializedUserIds;
    }

    /**
    *  @author Satya Swain
    *  @description create serialized user Ids
    *  @param none
    *  @return Map<Id, User>
    **/
    public static Map<Id, User> getMapOfIdToActiveUsers()
    {
        if(mapIdToActiveUsers == null || mapIdToActiveUsers.isEmpty())
        {
            mapIdToActiveUsers = new Map<Id, User>(new UsersSelector().selectUsersByActiveStatus(true));
        }
        return mapIdToActiveUsers;
    }
}