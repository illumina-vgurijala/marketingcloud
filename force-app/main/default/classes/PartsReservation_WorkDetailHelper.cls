/*****************************************************************************************************************
 * Class Name: PartsReservation_WorkDetailHelper
 * 
 * Description: Helper class for Parts Reservation functionality.
 * 
 * Author: Prashanth
 * 
 * Date: 29-Nov-2021
 * 
 * Notification Log:
 * -------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -------------------------------------------------------------------------------------------------------------
 * Prashanth                  29-11-2021                       Helper class for parts Reservation functionality.
 * 
 ******************************************************************************************************************/
public with sharing class PartsReservation_WorkDetailHelper {
    public static Map < Id, SVMXC__Product_Serial__c > mapBatchSerialRecords = new Map < Id, SVMXC__Product_Serial__c > ();
    /*******************************************************************************************************
     * Method: checkPartsReservation
     * @description DCP-33467: populate the sets and validate if batch or serial.
     * @param Datetime startDate, String duration
     * @return: DateTime
     * @author Sravan Kumar
     */
    public static void checkPartsReservation(List<SVMXC__Service_Order_Line__c> lstWorkDetails){
        //DCP-33467
        Set < SVMXC__Service_Order_Line__c > setWorkDetailsParts = new Set < SVMXC__Service_Order_Line__c > ();
        Set < String > setBatchNumber = new Set < String > ();
        Set < Id > setStockSerialId = new Set < Id > ();
        Set < Id > setFromLocationId = new Set < Id > ();
        Set < Id > setProductStockId = new Set < Id > ();
        //DCP-33467
        // DCP-33467 - Parts reservation
        for(SVMXC__Service_Order_Line__c objWorkDetail : lstWorkDetails){
            if (objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS && objWorkDetail.SVMXC__Line_Status__c != Workdetails.STRING_WORK_DETAIL_LINE_STATUS_CANCELED) {
                if (objWorkDetail.Batch_Number__c != null && objWorkDetail.SVMXC__Consumed_From_Location__c != null && objWorkDetail.SVMXC__Actual_Quantity2__c > 0) {
                    setBatchNumber.add(objWorkDetail.Batch_Number__c);
                    setFromLocationId.add(objWorkDetail.SVMXC__Consumed_From_Location__c);
                    setWorkDetailsParts.add(objWorkDetail);
                }
                if (objWorkDetail.SVMX_PS_VS_Consumed_Stocked_Serial__c != null) {
                    setStockSerialId.add(objWorkDetail.SVMX_PS_VS_Consumed_Stocked_Serial__c);
                    setWorkDetailsParts.add(objWorkDetail);
                }
                populateRequiredSets(setProductStockId, setWorkDetailsParts, objWorkDetail);
            } // DCP-33467
        }
        // DCP-33467: Validate Parts Reservation
        if(!setWorkDetailsParts.isEmpty()){
            validateBatchOrStockSerial(setWorkDetailsParts, setBatchNumber, setFromLocationId, setStockSerialId, setProductStockId, true);
        }
        // DCP-33467

    }
    /**
     * method: populateRequiredSets
     * Description: Method is to populate the sets
     * return: void
     */
    public static void populateRequiredSets(Set<Id> setProductStockId, Set < SVMXC__Service_Order_Line__c > setWorkDetailsParts, SVMXC__Service_Order_Line__c objWorkDetail){
        if (objWorkDetail.SVMX_PS_VS_Consumed_Stocked_Serial__c == null && objWorkDetail.Batch_Number__c == null) {
            setProductStockId.add(objWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c);
            setWorkDetailsParts.add(objWorkDetail);
        }
    }
    /*
     *  @AUTHOR:  Sravan
     *  @DESCRIPTION: 33467 - Validate the batched or serilized part while creating or updating the debrief line
     *  @PARAM :  WorkDetail Id set, BatchNumber set, Location Id set and StockSerial Id set
     *  @RETURN:  void
     */
    public static void validateBatchOrStockSerial(set < SVMXC__Service_Order_Line__c > setWorkDetailsParts, Set < String > setBatchNumber, Set < Id > setFromLocationId, Set < Id > setStockSerialId, set < Id > setProductStockId, Boolean isInsert) {
        Map < String, List < SVMXC__Allocated_Stock__c >> mapAllocaatedStockList = new Map < String, List < SVMXC__Allocated_Stock__c >> ();
        List < string > lstWoNumber = new list < string > ();
        Set < SVMXC__Service_Order_Line__c > setErrorWDs = new Set < SVMXC__Service_Order_Line__c > ();
        Map < Id, String > mapStockSerialNumbers = new Map < Id, String > ();
        List < string > lstWDErrors = new list < string > ();
        populateStockSerialMap(setWorkDetailsParts, mapStockSerialNumbers);
        // Prepare POL map and Allocated Stock Map to get the batch QTY(Available and Allocated) per batch
        if(setBatchNumber != null && !setBatchNumber.isEmpty() && setFromLocationId != null && !setFromLocationId.isEmpty()) {
            for (SVMXC__Allocated_Stock__c allocatedStock: new AllocatedStocksSelector().selectAllocatedStocksByBatchAndLocation(setFromLocationId, setBatchNumber)) {
                String batchUniqueKey = allocatedStock.Location__r.ERP_Customer_ID__c + allocatedStock.Product_Code__c + allocatedStock.Batch_Number__c;
                if (!mapAllocaatedStockList.containsKey(batchUniqueKey)) {
                    mapAllocaatedStockList.put(batchUniqueKey, new List < SVMXC__Allocated_Stock__c > ());
                }
                mapAllocaatedStockList.get(batchUniqueKey).add(allocatedStock);
            }
        }
        //Batched Parts
        setErrorWDs.addAll(VerifyBatchedParts_WorkDetailHelper.verifyBatchedParts(setWorkDetailsParts, mapStockSerialNumbers, mapBatchSerialRecords, mapAllocaatedStockList, isInsert));
        //Serialized Parts
        setErrorWDs.addAll(VerifySerializedParts_WorkDetailHelper.verifySerializedParts(setWorkDetailsParts, setStockSerialId, mapStockSerialNumbers));
        //Non Serialized Parts
        setErrorWDs.addAll(VerifyNonSerialized_WorkdetailHelper.verifyNonSerializedParts(setWorkDetailsParts, mapStockSerialNumbers, setProductStockId, isInsert));

        if (!WorkDetails.setWDErrors.isEmpty() && !WorkDetails.setWorkOrderNumber.isEmpty() && !setErrorWDs.isEmpty()) {
            for (SVMXC__Service_Order_Line__c wd: setErrorWDs) {
                lstWoNumber.addAll(WorkDetails.setWorkOrderNumber);
                lstWDErrors.addAll(WorkDetails.setWDErrors);
                wd.addError(Label.DebriefPartsReservationError + String.join(lstWoNumber, '#') + Label.DebriefPartsReservationErrorPart2 + '\n' + '[*' + String.join(lstWDErrors, '*') + ']', false);
                //break;
            }
        }

    } // DCP-33467
    /*
     *  @AUTHOR:  Sravan
     *  @DESCRIPTION: 33467 - Validate the batched or serilized part while creating or updating the debrief line
     *  @PARAM :  WorkDetail Id set, BatchNumber set, Location Id set and StockSerial Id set
     *  @RETURN:  void
     */
    public static void populateStockSerialMap(Set<SVMXC__Service_Order_Line__c> setWorkDetailsParts, Map < Id, String > mapStockSerialNumbers){
        Set < Id > setStockedSerialIds = new Set < Id > ();
        // Prepare Srocked Serial id set
        if (!setWorkDetailsParts.isEmpty()) {
            for (SVMXC__Service_Order_Line__c wd: setWorkDetailsParts) {
                if (wd.SVMX_PS_VS_Consumed_Stocked_Serial__c != null) {
                    setStockedSerialIds.add(wd.SVMX_PS_VS_Consumed_Stocked_Serial__c);
                } else if (wd.Batch_Lookup__c != null) {
                    setStockedSerialIds.add(wd.Batch_Lookup__c);
                }
            }
        }

        // Prepare a map with Stock Serial number by passing stock serial set
        if (!setStockedSerialIds.isEmpty()) {
            for (SVMXC__Product_Serial__c stockedSerial: new StockedSerialSelector().selectStockedSerialById(setStockedSerialIds)) {
                if (stockedSerial.SVMX_PS_VS_Product_Tracking__c == Workdetails.PRODUCT_TRACKING_SERIALIZED) {
                    mapStockSerialNumbers.put(stockedSerial.id, stockedSerial.Name);
                } else if (stockedSerial.SVMX_PS_VS_Product_Tracking__c == Workdetails.PRODUCT_TRACKING_LOT_BATCH_TRACKED) {
                    mapBatchSerialRecords.put(stockedSerial.id, stockedSerial);
                }
            }
        }
    }
    
}
