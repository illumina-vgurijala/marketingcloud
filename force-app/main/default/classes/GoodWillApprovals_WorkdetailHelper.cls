/*****************************************************************************************************************
 * Class Name: GoodWillApprovals_WorkdetailHelper
 * 
 * Description: Helper class for goodwill approvals.
 * 
 * Author: Prashanth
 * 
 * Date: 06-Dec-2021
 * 
 * Notification Log:
 * -------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -------------------------------------------------------------------------------------------------------------
 * Prashanth                  06-12-2021                       Helper class for goodwill approvals.
 ******************************************************************************************************************/
public with sharing class GoodWillApprovals_WorkdetailHelper {
    public static Channel_Partner_Profile_Settings__c cpProfileSettings = Channel_Partner_Profile_Settings__c.getInstance(Userinfo.getProfileID());
    public static final String STRING_WORK_DETAIL_NON_BILLABLE_REASON_GOODWILL = 'Goodwill';
    public static final String WD_APPROVALSTATUS_PENDINGAPPROVAL = 'Pending Approval';
    public static final String STRING_WORK_DETAIL_LINE_STATUS_CANCELED = 'Canceled';
    public static Map<Id,SVMXC__Service_Order_Line__c> idWDToWDGoodwillApproval;
    public static final String WD_APPROVALSTATUS_APPROVED = 'Approved';
    public static final String WD_APPROVALSTATUS_REJECTED = 'Rejected';
    public static final String WD_APPROVALSTATUS_NOTREQUIRED = 'Not Required';
   

    /*  @author - Tapas
    *  @description - DCP-43634, submit for goodwill approval via code
    */    
    public static void submitGoodwillApproval(List<SVMXC__Service_Order_Line__c> lstWDs, Map<Id,SVMXC__Service_Order_Line__c> oldRecords){
        List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
        for(SVMXC__Service_Order_Line__c objWD : lstWDs){
            SVMXC__Service_Order_Line__c objOldWD = Trigger.isUpdate ? oldRecords.get(objWD.id) : null;
            if(!cpProfileSettings.Is_Channel_Partner__c && objWD.Non_Billable_Reason__c == STRING_WORK_DETAIL_NON_BILLABLE_REASON_GOODWILL && 
            objWD.Approval_Status__c != WD_APPROVALSTATUS_PENDINGAPPROVAL && objWD.SVMXC__Line_Status__c != STRING_WORK_DETAIL_LINE_STATUS_CANCELED){
               if(!(goodwillApprovals(objWD, objOldWD)).isEmpty())
                     requests.addAll(goodwillApprovals(objWD, objOldWD));
            }   
        } 
        if(requests.isEmpty()){
            return;
        }
        Approval.ProcessResult[] processResults = Approval.process(requests, true);
        if(idWDToWDGoodwillApproval != null && !idWDToWDGoodwillApproval.isEmpty()){
            new WorkDetailsWithoutSharingInner().unlockWorkDetails(idWDToWDGoodwillApproval.values());
        }
    }
    /*  @author - Tapas
    *  @description - DCP-43634, submit for goodwill approval via code
    */  
    public static List<Approval.ProcessSubmitRequest> goodwillApprovals(SVMXC__Service_Order_Line__c objWD, SVMXC__Service_Order_Line__c objOldWD){
        List<Approval.ProcessSubmitRequest>  requests = new List<Approval.ProcessSubmitRequest>();
        if(((Trigger.isInsert && !objWD.Is_Auto_Created__c) || 
            (Trigger.isUpdate && (objWD.SVMXC__Actual_Quantity2__c != objOldWD.SVMXC__Actual_Quantity2__c || objWD.Non_Billable_Reason__c != objOldWD.Non_Billable_Reason__c))) && objWD.Owner_s_Manager__c != null){
            //if(){
                Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                req1.setComments('Submitting request for approval');
                req1.setObjectId(objWD.Id);
                if(idWDToWDGoodwillApproval == null){
                    idWDToWDGoodwillApproval = new Map<Id,SVMXC__Service_Order_Line__c>();
                }
                    
                idWDToWDGoodwillApproval.put(objWD.Id,objWD);           
                    
                requests.add(req1);
            //}    
        }
        return requests;
    }
    /*
    *  @author - Tapas
    *  @Description : DCP-43634, unlocking requires access to SFDC internal lock records, so using without sharing class
    * 
    */    
    public without sharing class WorkDetailsWithoutSharingInner{
        /**
         * Method:unlockWorkDetails
         */
        public void unlockWorkDetails(List<SVMXC__Service_Order_Line__c> lstWDs){
            if(!lstWDs.isEmpty()){
                Approval.UnlockResult[] unlockResults = Approval.Unlock(lstWDs);
            }
        }
    }
    /*@author - Tapas
    * @Description - DCP-43634, post comments to approval submitter when goodwill approval is approved/denied
    */      
    public static void postCommentsIfGoodwillApprovedOrDenied(List<SVMXC__Service_Order_Line__c> records,Map<Id,SVMXC__Service_Order_Line__c> oldRecords,Map < Id, SVMXC__Service_Order__c > idToworkOrder){
        List<SVMXC__Service_Order_Line__c> lstApprovedRejectedWDs = new List<SVMXC__Service_Order_Line__c>();
        Set<String> setApprovedOrRejectedStatuses = new Set<String>{WD_APPROVALSTATUS_APPROVED,WD_APPROVALSTATUS_REJECTED};

        for(SVMXC__Service_Order_Line__c objWD : records){
            SVMXC__Service_Order_Line__c objOldWD = oldRecords.get(objWD.Id);
            if(objOldWD.Approval_Status__c != objWD.Approval_Status__c && setApprovedOrRejectedStatuses.contains(objWD.Approval_Status__c)){
                lstApprovedRejectedWDs.add(objWD);
            }
        }

        if(lstApprovedRejectedWDs.isEmpty()){
            return;
        }

        Boolean isApproved = false;
        List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();

        for(SVMXC__Service_Order_Line__c objWD : lstApprovedRejectedWDs){
            SVMXC__Service_Order__c objWO = idToworkOrder.get(objWD.SVMXC__Service_Order__c);
            isApproved = objWD.Approval_Status__c == WD_APPROVALSTATUS_APPROVED ? true:false;

            ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
            ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
            ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
            ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();

            messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

            mentionSegmentInput.id = objWO.OwnerId;
            messageBodyInput.messageSegments.add(mentionSegmentInput);

            textSegmentInput.text = '\n Work Detail '+objWD.Name+' on Work Order '+objWO.Name+' has been '+ (isApproved ? 'Approved':'Denied') +' for use of Goodwill.' + (isApproved ? '':' Please work with your manager on how to proceed further.');
            messageBodyInput.messageSegments.add(textSegmentInput);

            feedItemInput.body = messageBodyInput;
            feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
            feedItemInput.subjectId = objWO.OwnerId;

            ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(feedItemInput);
            batchInputs.add(batchInput);
        }

        ConnectApi.ChatterFeeds.postFeedElementBatch(null, batchInputs);
    }
    /*
    *  @AUTHOR:  Ritika 
    *  @DESCRIPTION: Method to send notification to nobillable contacts of work details. Method has been updated as a part of DCP-38817
    *  @PARAM : set<Id> SetNonBillableWorkDetails
    *  @RETURN:  void
    */  
    public static void sendNotificationToNonBillableContacts(set<Id> setNonBillableWorkDetailsId){  
        if(!setNonBillableWorkDetailsId.isEmpty()){
            List<SVMXC__Service_Order_Line__c> lstBillableWorkOrderLine  = new WorkDetailsSelector().selectNonBillableWorkDetailsById(setNonBillableWorkDetailsId);
            //DCP-28205 update to send mail to WO owner's salesforce manager rather than FSM on account
            if(!lstBillableWorkOrderLine.isEmpty()){
                SendEmailNotification.getSendEmailParamaters(AfterUpdate_WorkDetailHelper.BILLABLE_WORK_DETAIL_META_DATA, lstBillableWorkOrderLine ,null ,AfterUpdate_WorkDetailHelper.WORK_ORDER_ACCOUNT);
            }
        }
        
    }
}
