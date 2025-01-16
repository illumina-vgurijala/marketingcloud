/*****************************************************************************************************************
 * Class Name: AfterUpdate_WorkDetailHelper
 * 
 * Description: Helper class for before update of Work details.
 * 
 * Author: Prashanth
 * 
 * Date: 29-Nov-2021
 * 
 * Notification Log:
 * -------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -------------------------------------------------------------------------------------------------------------
 * Prashanth                  29-11-2021                       Helper class for before update of Work details.
 * 
 ******************************************************************************************************************/
public with sharing class AfterUpdate_WorkDetailHelper {
    
    //DCP-33466 --- START
    public static Channel_Partner_Profile_Settings__c cp = Channel_Partner_Profile_Settings__c.getInstance(Userinfo.getProfileID());
    //DCP-33466
    public static Set < Id > setBatchQualifiedWorkOrderIds = new Set < Id > ();
    //DCP-37399
    public static Set < Id > setPartConsumptionWorkOrderIds = new Set < Id > ();
    public static Id idWorkDetailRelProdRecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get(Workdetails.STRING_WORK_DETAIL_RECORD_TYPE_RELATED_PRODUCT).getRecordTypeId();
    public static final String BILLABLE_WORK_DETAIL_META_DATA = 'Billable_Work_Detail';
    public static final String WORK_ORDER_ACCOUNT = 'SVMXC__Service_Order__r.SVMXC__Company__c';
    
    //DCP-33467
    public static Set < SVMXC__Service_Order_Line__c > setWorkDetailsParts = new Set < SVMXC__Service_Order_Line__c > ();
    public static Set < Id > setWorkDetailsPartsIds = new Set < Id > ();
    public static Set < Id > setCanceledWDPartsIds = new Set < Id > ();
    public static Set < Id > setWDProductSTockUpdatedIds = new Set < Id > ();
    public static Set < String > setBatchNumber = new Set < String > ();
    public static Set < Id > setFromLocationId = new Set < Id > ();
    public static Set < Id > setStockSerialId = new Set < Id > ();
    public static Set < Id > setProductStockId = new Set < Id > ();
    // DCP-33467
    public static Map < Id, Id > laborWorkDetailToParentWorkOrder = new Map < Id, Id > ();
    public static Map < Id, String > laborParentWorkOrderToActivityType = new Map < Id, String > ();
    public static Set < Id > setBillableServiceOrderIds  = new Set<Id>();
    public static set<Id> setWorkOrderIds = new set<Id>(); //DCP-44981 
    public static final String STRING_WORK_DETAIL_ACTIVITY_TYPE_FIELD_COMPLIANCE_REVIEW = System.Label.WorkDetailActivityFieldComplianceReview;
    public static final String STRING_WORK_DETAIL_ACTIVITY_TYPE_CUSTOMER_SERVICE_REVIEW = System.Label.WorkDetailActivityCustomerServiceReview;
    public static final String STRING_WORK_DETAIL_ACTIVITY_TYPE_QS_REVIEW = 'Qualification Service Review';
    public static final Set < String > SET_ACTIVITY_TYPES = new Set < String > {
        STRING_WORK_DETAIL_ACTIVITY_TYPE_CUSTOMER_SERVICE_REVIEW,
        STRING_WORK_DETAIL_ACTIVITY_TYPE_QS_REVIEW,
        STRING_WORK_DETAIL_ACTIVITY_TYPE_FIELD_COMPLIANCE_REVIEW
    };
    public static final String WD_APPROVALSTATUS_PENDINGAPPROVAL = 'Pending Approval';
    //Added by Shruti Karn for populating product group on Work Order for ICE integration
    public static set < Id > setWOIdforICEPrdGrp = new set < Id > ();
    /**
     * Method: processWorkdetailsAfterUpdate
     * Description: Method to process the work detail after update.
     * params: new map, old map
     * return: void
     */
    public static void processWorkdetailsAfterUpdate(Map < Id, SObject > mapOld){
        Map<Id, SVMXC__Service_Order__c> idParentWOToWO = Workdetails.idParentWOToWO;
        for(SVMXC__Service_Order_Line__c objOldWorkDetail: (List < SVMXC__Service_Order_Line__c > ) mapOld.values()){
            SVMXC__Service_Order_Line__c objNewWorkDetail = (SVMXC__Service_Order_Line__c) Trigger.newMap.get(objOldWorkDetail.id);
            
            //DCP-44981
            setWorkOrderIds = AutoRMA_WorkdetailHelper.getReversalRequestedWorkorders(objOldWorkDetail, objNewWorkDetail,setWorkOrderIds);
            populateSetQualifiedWorkordersForBatch(objOldWorkDetail, objNewWorkDetail);
            populateRequiredSets(objOldWorkDetail, objNewWorkDetail,idParentWOToWO);
            setBillableServiceOrderIds = AutoRMA_WorkdetailHelper.populateBillableServiceOrders(objOldWorkDetail, objNewWorkDetail,idParentWOToWO,setBillableServiceOrderIds);
            populatePartsReservationSets(objOldWorkDetail, objNewWorkDetail);
        }
        //DCP-44981
        if (!setWorkOrderIds.isEmpty() && !system.Test.isRunningTest()) {
            WorkOrders.sendWorkOrderToSAP(setWorkOrderIds); //make callout to SAP
        }
        // DCP-33467: Delete allocated stock records for the canceled/product stock updated work details 
        AllocatedStocks_WorkdetailHelper.deleteAllocatedStockRecords(setCanceledWDPartsIds);
        
        // DCP-33467: Create new allocated stock record for WD which has product stock change
        ProcessWDAfterInsert_WorkdetailHelper.createAllocatedStockRecords(setWDProductSTockUpdatedIds);
        
        // DCP-33467: Update allocated stock record related to updated work detail
        AllocatedStocks_WorkdetailHelper.updateAllocatedStocks(setWorkDetailsParts, setWorkDetailsPartsIds);
        
        //DCP-33467: Validate Parts Reservation
        if (!setWorkDetailsParts.isEmpty()){
            PartsReservation_WorkDetailHelper.validateBatchOrStockSerial(setWorkDetailsParts, setBatchNumber, setFromLocationId, new Set<Id>(), setProductStockId, false);
        }
        // DCP-33467
        //DCP-38817
        GoodWillApprovals_WorkdetailHelper.sendNotificationToNonBillableContacts(setBillableServiceOrderIds);
        
    }
    /**
     * Method:populateWorkdetailMap
     * Description: Method to populate the work detail map.
     * Params: old record & new record.
     * return: void
     */
    public static Map < Id, SVMXC__Service_Order_Line__c > populateWorkdetailMap(SVMXC__Service_Order_Line__c objOldWorkDetail, SVMXC__Service_Order_Line__c objNewWorkDetail){
        //Map < Id, SVMXC__Service_Order_Line__c > workDetailIdToWorkDetailMap = new Map < Id, SVMXC__Service_Order_Line__c >();
        //DCP-44981 - If Part_Consumption_Reversal_External_ID__c is different from original external id, start reversal in sfdc.
        if ((objOldWorkDetail.Part_Consumption_Reversal_External_ID__c != objNewWorkDetail.Part_Consumption_Reversal_External_ID__c &&
                objNewWorkDetail.Part_Consumption_Reversal_External_ID__c != objNewWorkDetail.SVMX_PS_External_ID__c &&
                objNewWorkDetail.Integration_Status__c == Workdetails.STRING_INTEGRATION_SUCCESS &&
                objNewWorkDetail.SVMXC__Line_Status__c == Workdetails.STRING_REVERSAL_REQUESTED) ||
            (String.isNotBlank(objNewWorkDetail.SVMXC__Consumed_From_Location__c) &&
            Workdetails.consumedFromLocationIdToLocationMap != null && !Workdetails.consumedFromLocationIdToLocationMap.isEmpty() &&
            Workdetails.consumedFromLocationIdToLocationMap.get(objNewWorkDetail.SVMXC__Consumed_From_Location__c).Type__c == 'Partner Stock' &&
                objOldWorkDetail.SVMXC__Line_Status__c != objNewWorkDetail.SVMXC__Line_Status__c &&
                objNewWorkDetail.SVMXC__Line_Status__c == Workdetails.STRING_REVERSAL_REQUESTED)) {
                AsyncAfterUpdate_WorkdetailHelper.workDetailIdToWorkDetailMap.put(objNewWorkDetail.Id, objNewWorkDetail); // all these work details will go for consumption reversal in sfdc.
        }
        return AsyncAfterUpdate_WorkdetailHelper.workDetailIdToWorkDetailMap;
    }
    /**
     * Method:populateSetQualifiedWorkordersForBatch
     * Description: Method to populate the set for qualified work orders for the batch processing.
     * Params: old record & new record.
     * return: void
     */
    public static void populateSetQualifiedWorkordersForBatch(SVMXC__Service_Order_Line__c objOldWorkDetail, SVMXC__Service_Order_Line__c objNewWorkDetail){
        if (objNewWorkDetail.Approval_Status__c != WD_APPROVALSTATUS_PENDINGAPPROVAL) { //DCP-43634 - prevent weekly batch run if WD is pending approval
            //conditions: a) Line Type = Labor AND channel partner = false 
            if (objNewWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR && !cp.Is_Channel_Partner__c == true && Userinfo.getUserId() != NULL) {

                /*conditions - [12 May 2020] - added "canceled" condition for DCP-37747
                            : a) (Activity Type has changed AND Activity Type is not present in "SET_ACTIVITY_TYPES") 
                                OR (Change in Travel time "OR" Change in Labor Hours "OR" When Status = canceled)
                            */
                if ((objOldWorkDetail.SVMXC__Activity_Type__c != objNewWorkDetail.SVMXC__Activity_Type__c &&
                            !SET_ACTIVITY_TYPES.contains(objNewWorkDetail.SVMXC__Activity_Type__c)) ||
                        objOldWorkDetail.Travel_Time_in_hours__c != objNewWorkDetail.Travel_Time_in_hours__c ||
                        objOldWorkDetail.Labor_Hours__c != objNewWorkDetail.Labor_Hours__c ||
                        (objOldWorkDetail.SVMXC__Line_Status__c != objNewWorkDetail.SVMXC__Line_Status__c && objNewWorkDetail.SVMXC__Line_Status__c == Workdetails.STRING_WORK_DETAIL_LINE_STATUS_CANCELED)
                    ) {
                    setBatchQualifiedWorkOrderIds.add(objNewWorkDetail.SVMXC__Service_Order__c);
                }
            } else if (objOldWorkDetail.Consumption_Confirmed__c != objNewWorkDetail.Consumption_Confirmed__c && objNewWorkDetail.Consumption_Confirmed__c) { //added for DCP-37399
                setBatchQualifiedWorkOrderIds.add(objNewWorkDetail.SVMXC__Service_Order__c);
            }
        }
        //DCP-33466 ---- END
        
    }
    /**
     * Method:populateRequiredSets
     * Description: Method to populate the required sets.
     * Params: old record & new record.
     * return: void
     */
    public static void populateRequiredSets(SVMXC__Service_Order_Line__c objOldWorkDetail, SVMXC__Service_Order_Line__c objNewWorkDetail,Map<Id, SVMXC__Service_Order__c> idParentWOToWO){
        //DCP-37399
        /*
        a) For Internal - if consumption connfirmed is true, and external id is not blank, qualify the work order for consumption.
        b) For CP - If external Id is blank and the Work Detail is of a partner stock 
        */
        if (objNewWorkDetail.Consumption_Confirmed__c && ((objOldWorkDetail.SVMX_PS_External_ID__c != objNewWorkDetail.SVMX_PS_External_ID__c && String.isNotBlank(objNewWorkDetail.SVMX_PS_External_ID__c)) || (idParentWOToWO.get(objNewWorkDetail.SVMXC__Service_Order__c).Partner_Work_Order__c))) {
            setPartConsumptionWorkOrderIds.add(objNewWorkDetail.SVMXC__Service_Order__c);
        }
        
        // DCP-33467 : Prepare canceled work detail set
        if (objNewWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS && objNewWorkDetail.SVMXC__Line_Status__c == Workdetails.STRING_WORK_DETAIL_LINE_STATUS_CANCELED) {
            setCanceledWDPartsIds.add(objNewWorkDetail.Id);
        } // DCP-33467

        // DCP-37399 : Prepare consumption contains success work detail set
        if (objNewWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS && objNewWorkDetail.SVMX_PS_VS_Consumed_Status__c != objOldWorkDetail.SVMX_PS_VS_Consumed_Status__c && objNewWorkDetail.SVMX_PS_VS_Consumed_Status__c.contains(Workdetails.STRING_INTEGRATION_SUCCESS)) {
            setCanceledWDPartsIds.add(objNewWorkDetail.Id);
        } // DCP-37399
        //DCP-37399
        //Added by shruti Karn to populate Product group on work order for ICE integration               
        if (objNewWorkDetail.RecordTypeID == idWorkDetailRelProdRecordTypeId && objNewWorkDetail.SVMXC__Product__c != objOldWorkDetail.SVMXC__Product__c) {
            setWOIdforICEPrdGrp.add(objNewWorkDetail.SVMXC__Service_Order__c);
        }
    }
    
    /**
     * Method:populatePartsReservationSets
     * Description: Method to populate the sets related to parts reservation.
     * Params: old record & new record.
     * return: void
     */
    public static void populatePartsReservationSets(SVMXC__Service_Order_Line__c objOldWorkDetail, SVMXC__Service_Order_Line__c objNewWorkDetail){
        //DCP-33467 : Parts Reservation update          
        if (objNewWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS && objNewWorkDetail.SVMXC__Line_Status__c != Workdetails.STRING_WORK_DETAIL_LINE_STATUS_CANCELED) {
            if (objNewWorkDetail.Batch_Number__c != objOldWorkDetail.Batch_Number__c || objNewWorkDetail.SVMXC__Actual_Quantity2__c != objOldWorkDetail.SVMXC__Actual_Quantity2__c || objNewWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c != objOldWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c || objNewWorkDetail.SVMX_PS_VS_Consumed_Stocked_Serial__c != objOldWorkDetail.SVMX_PS_VS_Consumed_Stocked_Serial__c) {
                if (objNewWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c != objOldWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c) {
                    setCanceledWDPartsIds.add(objNewWorkDetail.Id);
                    setWDProductSTockUpdatedIds.add(objNewWorkDetail.Id);
                }
                if (objNewWorkDetail.Batch_Number__c != objOldWorkDetail.Batch_Number__c && objNewWorkDetail.Batch_Number__c != null || objNewWorkDetail.SVMXC__Actual_Quantity2__c != objOldWorkDetail.SVMXC__Actual_Quantity2__c && objNewWorkDetail.Batch_Number__c != null) {
                    setBatchNumber.add(objNewWorkDetail.Batch_Number__c);
                    setFromLocationId.add(objNewWorkDetail.SVMXC__Consumed_From_Location__c);
                }
                setWorkDetailsParts.add(objNewWorkDetail);
                setProductStockId.add(objNewWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c);
                setWorkDetailsPartsIds.add(objNewWorkDetail.Id);
            }
        } // DCP-33467
        
    }
}