/*****************************************************************************************************************
 * Class Name: BeforeUpdate_WorkdetailHelper
 * Description: Helper class for before update of work details.
 * 
 * Author: Prashanth
 * 
 * Date: 07-Dec-2021
 * 
 * Notification Log:
 * -------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -------------------------------------------------------------------------------------------------------------
 * Prashanth                  07-12-2021                       Helper class for before update of work details.
 ******************************************************************************************************************/
public with sharing class BeforeUpdate_WorkdetailHelper {
    public static Id idWorkDetailUsageRecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get(Workdetails.STRING_WORK_DETAIL_RECORD_TYPE_USAGE_CONSUMPTION).getRecordTypeId();
    public static Id idWorkDetailEstimatesRecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get(Workdetails.STRING_WORK_DETAIL_RECORD_TYPE_ESTIMATES).getRecordTypeId();

    public static set < SVMXC__Service_Order_Line__c > setWorkDetail = new set < SVMXC__Service_Order_Line__c > ();
    public static set < Id > setWorkOrderId = new set < Id > ();

    public static Map < Id, AggregateLineItems_WorkDetailHelper.WorkDetailLineQuantityWrapper > workOrderIdToQuantityWrapper = new Map < Id, AggregateLineItems_WorkDetailHelper.WorkDetailLineQuantityWrapper > ();
    public static set < Id > setWorkDetailsIdAggregated = new set < Id > ();
    public static List < SVMXC__Service_Order_Line__c > lstWorkDetailWithUpdatedIPs = new List < SVMXC__Service_Order_Line__c > ();

    public static Set < Id > setWorkOrderIds = new Set < Id > ();
    public static List < SVMXC__Service_Order_Line__c > lstWorkOrderLinesWithBillableChange = new List < SVMXC__Service_Order_Line__c > ();
    

    //DCP-46273:
    public static Set < Id > setWOWorkDetails = new Set < Id > ();

    public static User loggedInUser = [Select profile.Name from User where Id =: USerInfo.getUserId()];
    //37734 list to hold canceld wds.
    public static list < SVMXC__service_order_Line__c > lstCanceledWd = new list < SVMXC__service_order_Line__c > ();
    public static List < SVMXC__service_order_Line__c > lstWDWithBillingWoSetByCS = new List < SVMXC__service_order_Line__c > ();
    //Variables to check part / tool selected is in FRU list
    public static Map < Id, SVMXC__Service_Order_Line__c > mapProductIdToWorkDetails = new Map < Id, SVMXC__Service_Order_Line__c > ();
    public static final String STRING_WORK_DETAIL_LINE_TYPE_IS_TOOLS = 'Tool';
    public static Set < Id > setStockSerialId = new Set < Id > ();
    public static Set < SVMXC__Service_Order_Line__c > setWorkDetailsParts = new Set < SVMXC__Service_Order_Line__c > ();
    /*
    *  @author - Prashanth
    *  @Description : process before update of work details.
    * 
    */ 
    public static void processBeforeUpdate(Map<Id, SObject> oldRecords, List<sObject> records){
        //Added by Shruti Karn for RITM0356143
        Map < String, Schema.SObjectField > objWorkDetailFields = Schema.SObjectType.SVMXC__Service_Order_Line__c.fields.getMap();
        //DCP-44981
        Set < Id > setConsumedFromLocationForPartReversal = new Set < Id > ();
        List < SVMXC__Service_Order_Line__c > lstWDwithUpdatedLineType = new List < SVMXC__Service_Order_Line__c > ();

        for (SVMXC__Service_Order_Line__c objWorkDetail: (List < SVMXC__Service_Order_Line__c > ) records) {
            SVMXC__Service_Order_Line__c objOldWorkOrderLine = (SVMXC__Service_Order_Line__c)(oldRecords.get(objWorkDetail.Id));

            populateProductMap(objWorkDetail);
            if (objOldWorkOrderLine.SVMXC__Line_Type__c != objWorkDetail.SVMXC__Line_Type__c) {
                lstWDwithUpdatedLineType.add(objWorkDetail);
            }
            //DCP-50097
            BeforeInsert_WorkDetailHelper.makeBatchNumberNull(objWorkDetail);
            PartsReversalBeforeUpdate_WDHelper.svmxcRecUpdate(objWorkDetail,objOldWorkOrderLine,objWorkDetailFields, loggedInUser);
            PartsReversalBeforeUpdate_WDHelper.assignFieldValues(objWorkDetail,objOldWorkOrderLine);
            
            PartsReversalBeforeUpdate_WDHelper.partsReversalProcess(objOldWorkOrderLine,objWorkDetail,setConsumedFromLocationForPartReversal);
            populateCollections(objWorkDetail, objOldWorkOrderLine);
            
            //DCP-37747
            //creating list of wd which are canceled.
            if (objWorkDetail.SVMXC__Line_Status__c != objOldWorkOrderLine.SVMXC__Line_Status__c && objWorkDetail.SVMXC__Line_Status__c == Workdetails.STRING_WORK_DETAIL_LINE_STATUS_CANCELED) {
                lstCanceledWd.add(objWorkDetail);
            }
            //Shivani
            processEstimateLines(objWorkDetail, objOldWorkOrderLine);
            ApprovalsBeforeUpdate_WorkdetailHelper.updateSerialNumber(Workdetails.iPtoProduct, objWorkDetail, objOldWorkOrderLine);
        }


        if(!mapProductIdToWorkDetails.isEmpty()){
            AggregateLineItems_WorkDetailHelper.updateEstimateLineType(mapProductIdToWorkDetails);
        }
        PartsReversalBeforeUpdate_WDHelper.validateErrorsForCP(setConsumedFromLocationForPartReversal, records,oldRecords);
        callSynchronousMethods();
        //DCP-37747
        if (!lstCanceledWd.isEmpty()) {
            ProcessWDBeforeInsert_WorkDetailHelper.unCheckIncludeInSRforcanceledWd(lstCanceledWd);
        }
        if(!setWorkOrderIds.isEmpty()){
            ApprovalsBeforeUpdate_WorkdetailHelper.updateNonBillableReason((List<SVMXC__Service_Order_Line__c>)records);
        }
        //Tapas - INC0230587
        if (!lstWDwithUpdatedLineType.isEmpty()){
            UpdateContract_WorkDetailHelper.updateContractOnWD(lstWDwithUpdatedLineType, false, false, new List < Applied_Contract__c > ());
        }

    }
    
     /*
    *  method: updateWDOwnerManager
    *  @author - Gagan
    *  @Description : update OwnerManager field when Non billable reason is Goodwill.
    * 
    */
    public static void updateWDOwnerManager(List<sObject> records){
     Map<Id,Id> idWOToWOOwnerIds = new Map<Id,Id>();
        
            for(SVMXC__Service_Order__c obj : Workdetails.idParentWOToWO.values()){ 
                idWOToWOOwnerIds.put(obj.Id, obj.ownerId);
            }// user query
            List<User> lstUsers = new UsersSelector().selectByUserId(new set<Id>(idWOToWOOwnerIds.values()));
            Map<Id,Id> idUserToManager = new Map<Id,Id>();
            for(User objUser : lstUsers){
                idUserToManager.put(objUser.Id, objUser.ManagerId);
            }//

            for (SVMXC__Service_Order_Line__c objWorkDetail: (List < SVMXC__Service_Order_Line__c > ) records) {
            if(objWorkDetail.SVMXC__Line_Status__c != WorkDetails.STRING_WORK_DETAIL_LINE_STATUS_CANCELED && !(objWorkDetail.SVMXC__Line_Status__c == System.Label.WorkDetailLineStatusClosed && objWorkDetail.SVMXC__Line_Type__c == WorkDetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS) && !AfterUpdate_WorkDetailHelper.SET_ACTIVITY_TYPES.contains(objWorkDetail.SVMXC__Activity_Type__c) && objWorkDetail.Non_Billable_Reason__c == WorkDetails.STRING_WORK_DETAIL_NON_BILLABLE_REASON_GOODWILL){
                objWorkDetail.Owner_s_Manager__c = idUserToManager.get(idWOToWOOwnerIds.get(objWorkDetail.SVMXC__Service_Order__c));
            }
            }
    }


    /*
    *  method: populateCollections
    *  @author - Prashanth
    *  @Description : populate Collections required for processing before update.
    * 
    */
    public static void populateCollections(SVMXC__Service_Order_Line__c objWorkDetail, SVMXC__Service_Order_Line__c objOldWorkOrderLine){
        if ((objWorkDetail.SVMXC__Line_Type__c == STRING_WORK_DETAIL_LINE_TYPE_IS_TOOLS && objWorkDetail.SVMXC__From_Location__c != null ) || (objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS && objWorkDetail.SVMXC__Consumed_From_Location__c != null) && objWorkDetail.SVMXC__Service_Order__c != null) {
            setWorkOrderId.add(objWorkDetail.SVMXC__Service_Order__c);
            //INC0253675
            if ((objWorkDetail.SVMXC__Line_Type__c == STRING_WORK_DETAIL_LINE_TYPE_IS_TOOLS && (objWorkDetail.SVMXC__From_Location__c != objOldWorkOrderLine.SVMXC__From_Location__c || objWorkDetail.SVMXC__Serial_Number__c != objOldWorkOrderLine.SVMXC__Serial_Number__c)) ||
                (objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS && (objWorkDetail.SVMXC__Consumed_From_Location__c != objOldWorkOrderLine.SVMXC__Consumed_From_Location__c ||
                    objWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c != objOldWorkOrderLine.SVMX_PS_VS_Consumed_Product_Stock__c ||
                    objWorkDetail.SVMX_PS_VS_Consumed_Stocked_Serial__c != objOldWorkOrderLine.SVMX_PS_VS_Consumed_Stocked_Serial__c ||
                    objWorkDetail.SVMX_PS_VS_Return_Installed_Product__c != objOldWorkOrderLine.SVMX_PS_VS_Return_Installed_Product__c ||
                    objWorkDetail.SVMXC__Actual_Quantity2__c != objOldWorkOrderLine.SVMXC__Actual_Quantity2__c
                ))){
                    setWorkDetail.add(objWorkDetail);
                }
        }
        // DCP-33467
        if (objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS && objWorkDetail.SVMXC__Line_Status__c != Workdetails.STRING_WORK_DETAIL_LINE_STATUS_CANCELED && objWorkDetail.SVMX_PS_VS_Consumed_Stocked_Serial__c != objOldWorkOrderLine.SVMX_PS_VS_Consumed_Stocked_Serial__c && objWorkDetail.SVMX_PS_VS_Consumed_Stocked_Serial__c != null) {
            setStockSerialId.add(objWorkDetail.SVMX_PS_VS_Consumed_Stocked_Serial__c);
            setWorkDetailsParts.add(objWorkDetail);
        } // DCP-33467
    }
    /*
    *  method: processEstimateLines
    *  @author - Prashanth
    *  @Description : process the workdetails for Estimates.
    * 
    */
    public static void processEstimateLines(SVMXC__Service_Order_Line__c objWorkDetail, SVMXC__Service_Order_Line__c objOldWorkOrderLine){
        //If Estimates Work Detail Line is updated :
        // Check for corresponsing Debrief lines for any mismatch
        //This scenario would come when the Estimates are performed post Debrief.
        if (objWorkDetail.RecordTypeId == idWorkDetailEstimatesRecordTypeId &&
            (objOldWorkOrderLine.SVMXC__Product__c != objWorkDetail.SVMXC__Product__c ||
                objOldWorkOrderLine.SVMXC__Activity_Type__c != objWorkDetail.SVMXC__Activity_Type__c ||
                objOldWorkOrderLine.SVMXC__Estimated_Quantity2__c != objWorkDetail.SVMXC__Estimated_Quantity2__c)) {
            AggregateLineItems_WorkDetailHelper.aggregateEstimateLineItems(workOrderIdToQuantityWrapper, objWorkDetail);
            setWorkDetailsIdAggregated.add(objWorkDetail.Id);
        }
        //If Usage/Consumption Work Detail Line is updated :
        // Check for corresponsing Estimate lines for any mismatch
        if (objWorkDetail.RecordTypeId == idWorkDetailUsageRecordTypeId &&
            ((objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_MATERIALSCONSUMED || objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS) &&
                (objOldWorkOrderLine.SVMXC__Product__c != objWorkDetail.SVMXC__Product__c || objOldWorkOrderLine.SVMXC__Actual_Quantity2__c != objWorkDetail.SVMXC__Actual_Quantity2__c)) ||
            (objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR &&
                (objOldWorkOrderLine.SVMXC__Activity_Type__c != objWorkDetail.SVMXC__Activity_Type__c || objOldWorkOrderLine.Duration_in_hours__c != objWorkDetail.Duration_in_hours__c)) ||
            objWorkDetail.SVMXC__Is_Billable__c != objOldWorkOrderLine.SVMXC__Is_Billable__c) {
                AggregateLineItems_WorkDetailHelper.aggregateDebriefLineItems(workOrderIdToQuantityWrapper, objWorkDetail);
            setWorkDetailsIdAggregated.add(objWorkDetail.Id);
        }
        setWorkOrderIds.add(objWorkDetail.SVMXC__Service_Order__c);
        lstWorkOrderLinesWithBillableChange.add(objWorkDetail);
    }
    /*
    *  method: aggregateLineItems
    *  @author - Prashanth
    *  @Description : process the workdetails for Estimates.
    * 
    */
    public static void asyncCallsOnBeforeUpdate(){
        ilib_Queueablethread queueableThread = new ilib_Queueablethread('WorkDetailsBeforeUpdate');

        if (!workOrderIdToQuantityWrapper.isEmpty()) {
            for (SVMXC__Service_Order_Line__c objWorkDetail: new WorkDetailsSelector().selectBillableWorkDetailsByWorkOrderIdExcludingFew(workOrderIdToQuantityWrapper.keySet(), setWorkDetailsIdAggregated)) {
                if (objWorkDetail.RecordTypeId == idWorkDetailEstimatesRecordTypeId) {
                    AggregateLineItems_WorkDetailHelper.aggregateEstimateLineItems(workOrderIdToQuantityWrapper, objWorkDetail);
                }
                if (objWorkDetail.RecordTypeId == idWorkDetailUsageRecordTypeId &&
                    (objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_MATERIALSCONSUMED ||
                        objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS ||
                        objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR)) {
                    AggregateLineItems_WorkDetailHelper.aggregateDebriefLineItems(workOrderIdToQuantityWrapper, objWorkDetail);
                }
            }
    
            //DCP-33873
            queueableThread.logandQueue(new CompareWorkdetails_WorkdetailHelper( workOrderIdToQuantityWrapper), 'CompareWorkdetails_WorkdetailHelper', 'compareWorkDetailLineItems');
    
        }
        if (!queueableThread.lstQueueableJobs.isEmpty()){
            ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SERVICE);
        }
    }
    
    /*
    *  method: populateProductMap
    *  @author - Prashanth
    *  @Description : process the workdetails for Estimates.
    * 
    */
    public static void populateProductMap(SVMXC__Service_Order_Line__c objWorkDetail){
        //DCP-45873
        if(objWorkDetail.RecordTypeId == idWorkDetailEstimatesRecordTypeId){
            if(String.isBlank(objWorkDetail.SVMXC__Product__c)){
                objWorkDetail.SVMXC__Line_Type__c = '';
            }
            else{
                mapProductIdToWorkDetails.put(objWorkDetail.SVMXC__Product__c,objWorkDetail);
            }
        }
    }
    /*
    *  method: callSynchronousMethods
    *  @author - Prashanth
    *  @Description : call the methods in Befof=re update
    * 
    */
    public static void callSynchronousMethods(){
        //DCP-33467: Validate Parts Reservation
        if (!setWorkDetailsParts.isEmpty() && !setStockSerialId.isEmpty()){
            PartsReservation_WorkDetailHelper.validateBatchOrStockSerial(setWorkDetailsParts, null, null, setStockSerialId, null, false);
        }
        // DCP-33467

        if (!setWorkDetail.isEmpty() && !setWorkOrderId.isEmpty()) {
            ValidateFromLocation_WorkdetailHelper.validateFromLocation(setWorkDetail, setWorkOrderId);
        }
    }
}
