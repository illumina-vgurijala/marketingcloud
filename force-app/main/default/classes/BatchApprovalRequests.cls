/**
*    @author: Rishab Wali
*    @date:   3-Sep-2020
*    @description:  Batch class to approve/reject .
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*            Nishan Shetty                  03-Jun-2022         Implementing Batch Manager Framework DCP-50962
*            Nishan Shetty                  22-Aug-2022         [TASK0802266] Constructor added to fix ilib_BatchRunner runtime instantiation issue of no-arg constructor.
*    ------------------------------------------------------------------------------------ 
*                    
*/
global without sharing class BatchApprovalRequests extends ilib_BatchDeferrable {  
   global static final string STRINGAPPROVE = 'Approve'; 
   global integer successRecords = 0;
   global integer failedRecords = 0;
   global static final String STRINGBATCHAPPROVALSTATUSCOMPLETED = 'Completed';
   global Set<Id> appreqIdSet;

   private Inputs inputs;
   public final static String LOG_TITLE = 'BatchApprovalRequests';


    /*
    *  @Author      : Nishan Shetty
    *  @Description : Parameter wrapper for easy serialization[DCP-50962]
    */
    public class Inputs {
        public Map<Id,String> appreqIdToCommentMap;
        public String appOrRejString;
        public String batchApprovalRecId;

        /*Constructor*/
        public Inputs(Map<Id,String> appreqIdToCommentMap, String appOrRejString, String batchApprovalRecId) {
            this.appreqIdToCommentMap = appreqIdToCommentMap;
            this.appOrRejString = appOrRejString;
            this.batchApprovalRecId = batchApprovalRecId;
        }
    }

    /*
    * @Author : Nishan Shetty[TASK0802266]
    * @Description : Constructor added to fix ilib_BatchRunner runtime instantiation issue of no-arg constructor.
    */
    global BatchApprovalRequests() {
      super();
    }
    
   /*Constructor*/
   global BatchApprovalRequests(Map<Id,String> appreqIdToCommentMap , String appOrRejString , String batchApprovalRecId) {
       super();
       this.inputs = new Inputs(appreqIdToCommentMap,appOrRejString,batchApprovalRecId);
       appreqIdSet = inputs.appreqIdToCommentMap.keySet();
   } 
  
   /*START*/
   global override Database.QueryLocator start(Database.BatchableContext bc) {       
      return Database.getQueryLocator('SELECT Id,Apttus_Approval__Approver_Comments__c FROM Apttus_Approval__Approval_Request__c WHERE Id In : appreqIdSet');
   }
   
   /*EXECUTE*/
   global override void execute(Database.BatchableContext bc, List<sObject> appReqList) {
    ilib_LogEvent.setBatchTitle(LOG_TITLE, transactionId); 
    ilib_LogEvent.push(LOG_TITLE + '.execute()');
       try {
           for(Apttus_Approval__Approval_Request__c objAppReq : (List<Apttus_Approval__Approval_Request__c>)appReqList) {
               Boolean result = false;
               if(inputs.appOrRejString == STRINGAPPROVE) { 
                   if(!test.isRunningTest()) {
                       result = Apttus_Approval.ApprovalsWebService.approveRequest(objAppReq.Id,inputs.appreqIdToCommentMap.get(objAppReq.Id));
                   } 
                   ilib_LogEvent.message('Result' + result);
                   ilib_LogEvent.message('Approval Request Id' + objAppReq.Id);
                   if(result) { successRecords = successRecords + 1;}
                   else
                   {
                       failedRecords = failedRecords + 1; 
                   }
               }
           }        
       }
       Catch(Exception e){ ApexExceptions.emit('BatchApprovalRequests',appReqList[0].Id,e); }

    ilib_LogEvent.pop();
    ilib_LogEvent.emit();
    }
   
   /*FINISH*/
   global override void finish(Database.BatchableContext bc) {
       ilib_LogEvent.setBatchTitle(LOG_TITLE, transactionId);
       ilib_LogEvent.push(LOG_TITLE + '.finish()');
       Batch_Approval_Tracker__c objBatchApproval = new Batch_Approval_Tracker__c(Id = inputs.batchApprovalRecId);
       objBatchApproval.Status__c = STRINGBATCHAPPROVALSTATUSCOMPLETED;
       objBatchApproval.Failed_Records__c = failedRecords;
       objBatchApproval.Records_Processed_Successfully__c = successRecords;
       update objBatchApproval;
       ilib_LogEvent.message('objBatchApproval' + objBatchApproval);
       ilib_LogEvent.pop();
       ilib_LogEvent.emit();
    }

    // ************************************************************************************************
    // Deferrable implementation DCP-50962
    // ************************************************************************************************
    
    /*
    *  @Author      : Nishan Shetty
    *  @Description : Method to simple input serialization
    *  @Param       : None
    *  @Return      : String
    */
    public override String serializeInputs() {
        return JSON.serialize(inputs);
    }

    /*
    *  @Author      : Nishan Shetty
    *  @Description : Method to simple input deserialization
    *  @Param       : String
    *  @Return      : void
    */
    public override void restoreInputs(String serializedInputs) {
        this.inputs = (BatchApprovalRequests.Inputs)JSON.deserialize(serializedInputs, BatchApprovalRequests.Inputs.class);
    }
    
}