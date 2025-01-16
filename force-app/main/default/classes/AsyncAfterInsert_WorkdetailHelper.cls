/*****************************************************************************************************************
 * Class Name: AsyncAfterInsert_WorkdetailHelper
 * Description: Helper class for processing work detail on After insert assynchronusly.
 * 
 * Author: Prashanth
 * Date: 07-Dec-2021
 * 
 * Notification Log:
 * -------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -------------------------------------------------------------------------------------------------------------
 * Prashanth                  07-12-2021      Helper class for processing work detail on After insert assynchronusly.
 * 
 ******************************************************************************************************************/
public with sharing class AsyncAfterInsert_WorkdetailHelper {
    //Added for DCP-46273
    public static Set < Id > setWrkDetailsId = new Set < Id > ();
    //DCP-33466
    public static Set < Id > setBatchQualifiedWorkOrderIds = new Set < Id > ();
    public static Id idWorkDetailRelProdRecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get(Workdetails.STRING_WORK_DETAIL_RECORD_TYPE_RELATED_PRODUCT).getRecordTypeId();
    //Added by Shruti Karn for populating product group on Work Order for ICE integration
    public static set < Id > setWOIdforICEPrdGrp = new set < Id > ();
    public static Set<Id> setInsertedPartWorkDetailsIds = new Set<Id>();
    public static final String WD_APPROVALSTATUS_PENDINGAPPROVAL = 'Pending Approval';
    /**
     * Method:asynCallsOnAfterInsert
     * Description: Method to process the async calls.
     * params: new records, old records.
     * return: void
     */
    public static void asynCallsOnAfterInsert(List < SVMXC__Service_Order_Line__c >  records){
        ilib_Queueablethread queueableThread = new ilib_Queueablethread('WorkDetailsAfterInsert');
        List < SVMXC__Service_Order_Line__c > lstWorkDetailsRelocation = new List < SVMXC__Service_Order_Line__c > ();
        processRecords(records);
        if (!Workdetails.boolVanStockTestInProgress && !setInsertedPartWorkDetailsIds.isEmpty() && !PartsOrderLines.stopPartOrderLineInsertion) {
            //DCP-33873
            queueableThread.logandQueue(new InsertPOAndPOL_WorkdetailHelper(setInsertedPartWorkDetailsIds), 'InsertPOAndPOL_WorkdetailHelper', 'insertPOAndPOLForPartSwap');
        }
        //DCP-46273
        if (!setWrkDetailsId.isEmpty()) {
            lstWorkDetailsRelocation = new WorkDetailsSelector().selectWorkDetailsByWorkDetailId(setWrkDetailsId);
        }
        //DCP-46273 moving After Insert call to async
        if (!lstWorkDetailsRelocation.isEmpty()) {
            queueableThread.logandQueue(new UpdateConfirmOperability_WDHelper(lstWorkDetailsRelocation, null, null),'UpdateConfirmOperability_WDHelper','updateConfirmOperabilityForRelocationWO');
        }
        //Added by Shruti Karn for populating product group on Work Order for ICE integration
        if (!setWOIdforICEPrdGrp.isEmpty()){
            queueableThread.logandQueue(new UpdateProductGroup_WorkdetailHelper(setWOIdforICEPrdGrp),'UpdateProductGroup_WorkdetailHelper','updateProductGrponWorkOrder');
        }
        //DCP-33466
        if (!setBatchQualifiedWorkOrderIds.isEmpty()) {
            queueableThread.logandQueue(new WOBatchQualification_WorkdetailHelper(setBatchQualifiedWorkOrderIds),'WOBatchQualification_WorkdetailHelper','updateWorkOrdersForBatchQualification');
        }
        if (!queueableThread.lstQueueableJobs.isEmpty()){
            ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SERVICE);
        }
    }
    /**
     * Method:populateQualifiedBatchSet
     * Description: Method to populate the set of work orders which are qualified for sync to SAP.
     * params: new records
     * return: void
     */
    public static void populateQualifiedBatchSet(SVMXC__Service_Order_Line__c objWorkDetail){
        //DCP-33466 ---- START
        Channel_Partner_Profile_Settings__c cp = Channel_Partner_Profile_Settings__c.getInstance(Userinfo.getProfileID());
        if (objWorkDetail.Approval_Status__c != WD_APPROVALSTATUS_PENDINGAPPROVAL) { //DCP-43634 - prevent weekly batch run if WD is pending approval
            //conditions: a) Line Type = Labor AND channel partner = false 
            if (objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR &&
                !cp.Is_Channel_Partner__c == true &&
                Userinfo.getUserId() != NULL) {
                /*conditions - [12 May 2020] - added "canceled" condition for DCP-37747
                    : a) (Activity Type is not blank AND Activity Type is not present in "SET_ACTIVITY_TYPES" 
                        AND
                        (Labor hours OR Travel Time has values OR line status = Cancelled)
                    */
                if (String.isNotBlank(objWorkDetail.SVMXC__Activity_Type__c) &&
                    !AfterUpdate_WorkDetailHelper.SET_ACTIVITY_TYPES.contains(objWorkDetail.SVMXC__Activity_Type__c) &&
                    (String.isNotBlank(objWorkDetail.Travel_Time_in_hours__c) ||
                        String.isNotBlank(objWorkDetail.Labor_Hours__c) ||
                        (String.isNotBlank(objWorkDetail.SVMXC__Line_Status__c) && objWorkDetail.SVMXC__Line_Status__c == Workdetails.STRING_WORK_DETAIL_LINE_STATUS_CANCELED)
                    )
                ) {
                    setBatchQualifiedWorkOrderIds.add(objWorkDetail.SVMXC__Service_Order__c);
                }
            } else if (objWorkDetail.Consumption_Confirmed__c) { //added for DCP-37399
                setBatchQualifiedWorkOrderIds.add(objWorkDetail.SVMXC__Service_Order__c);
            }
        }
    }
     /**
     * Method:populateRequiredSets
     * Description: Method to populate the require sets.
     * params: new record
     * return: void
     */
    public static void populateRequiredSets(SVMXC__Service_Order_Line__c objWorkDetail){
        //DCP-46273 Adding check to labor lines
        if (objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR) {
            setWrkDetailsId.add(objWorkDetail.Id);
        }
        if ((objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_MATERIALSCONSUMED || (objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS && objWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c != NULL)) && objWorkDetail.Consumption_Confirmed__c == true) {
            setInsertedPartWorkDetailsIds.add(objWorkDetail.Id);
        }
        if (objWorkDetail.RecordTypeID == Workdetails.idWorkDetailRelProdRecordTypeId) {
            //Added by Shruti Karn for populating product group on Work Order for ICE integration
            setWOIdforICEPrdGrp.add(objWorkDetail.SVMXC__Service_Order__c);
        }
    }
    /**
     * Method:processRecords
     * Description: Method to populate the require sets.
     * params: new records
     * return: void
     */
    public static void processRecords(List<SVMXC__Service_Order_Line__c> records){
        for (SVMXC__Service_Order_Line__c objWorkDetail:  records) {
            populateRequiredSets(objWorkDetail);
            populateQualifiedBatchSet(objWorkDetail);
        }
    }
}
