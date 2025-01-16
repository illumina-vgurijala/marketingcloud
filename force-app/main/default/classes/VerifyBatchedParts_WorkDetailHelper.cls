/*****************************************************************************************************************
 * Class Name: VerifyBatchedParts_WorkDetailHelper
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
public with sharing class VerifyBatchedParts_WorkDetailHelper {
    // DCP-33467
    public static final String PRODUCT_CODE = 'Product Code:';
    public static final String SERIAL = ', Serial:';
    public static final String BATCH = ', Batch:';
    
    // DCP-33467
    /*
     *  @AUTHOR:  Sravan
     *  @DESCRIPTION: 33467 - Verify the batched parts whether it has error
     */
    public static set < SVMXC__Service_Order_Line__c > verifyBatchedParts(set < SVMXC__Service_Order_Line__c > setWorkDetailsParts, Map < Id, String > mapStockSerialNumbers, Map < Id, SVMXC__Product_Serial__c > mapBatchSerialRecords, Map < String, List < SVMXC__Allocated_Stock__c >> mapAllocaatedStockList, Boolean isInsert) {
        Set < SVMXC__Service_Order_Line__c > setWDs = new Set < SVMXC__Service_Order_Line__c > ();
        Map < String, Integer > mapAllocatedStockQTY = new Map < String, Integer > ();
        Integer allocatedQty;

        // Get allocated/Reserved Qty for each batch number and prepare the WOs list it was used
        if(!mapAllocaatedStockList.isEmpty()) {
            for (string alsKey: mapAllocaatedStockList.keySet()) {
                allocatedQty = 0;
                for (SVMXC__Allocated_Stock__c allocatedStock: mapAllocaatedStockList.get(alsKey)) {
                    allocatedQty = allocatedQty + integer.valueOf(allocatedStock.SVMXC__Allocated_Qty__c);
                    WorkDetails.setWorkOrderNumber.add(allocatedStock.Work_Order__r.Name);
                }
                mapAllocatedStockQTY.put(alsKey, allocatedQty);
            }
        }
        if (!setWorkDetailsParts.isEmpty() && !mapBatchSerialRecords.isEmpty() && !mapAllocatedStockQTY.isEmpty()) {
            setWDs = compareAvailableQtyForBatch(setWorkDetailsParts, mapBatchSerialRecords, mapAllocatedStockQTY,mapStockSerialNumbers, isInsert);
        }
        
        return setWDs;
    }
    /**
     * Method Name: compareAvailableQtyForBatch
     * Description: To compare available qty with allocated qty for batch products
     */
    public static Set < SVMXC__Service_Order_Line__c > compareAvailableQtyForBatch(set < SVMXC__Service_Order_Line__c > setWorkDetailsParts, Map < Id, SVMXC__Product_Serial__c > mapBatchSerialRecords, Map < String, Integer > mapAllocatedStockQTY, Map < Id, String > mapStockSerialNumbers, Boolean isInsert){
        Set < SVMXC__Service_Order_Line__c > setWDs = new Set < SVMXC__Service_Order_Line__c > ();
        boolean isError;
        String batchNumberDisplay = '';
        String serialNumberDisplay = '';
        // Compare the Available - Reserved/Allocated QTY for bacth and through error
        
        for (SVMXC__Service_Order_Line__c objWorkDetail: setWorkDetailsParts) {
            isError = false;
            SVMXC__Product_Serial__c batchSerialRec = mapBatchSerialRecords.get(objWorkDetail.Batch_Lookup__c);
            if (batchSerialRec != null) {
                isError = returnIsError(isInsert, mapAllocatedStockQTY, batchSerialRec, objWorkDetail);
                if (isError) {
                    setWDs.add(objWorkDetail);
                    batchNumberDisplay = objWorkDetail.Batch_Number__c;
                    serialNumberDisplay = mapStockSerialNumbers.get(objWorkDetail.SVMX_PS_VS_Consumed_Stocked_Serial__c) != null ? mapStockSerialNumbers.get(objWorkDetail.SVMX_PS_VS_Consumed_Stocked_Serial__c) : '';
                    WorkDetails.setWDErrors.add(PRODUCT_CODE + objWorkDetail.Product_Code__c + SERIAL + serialNumberDisplay + BATCH + batchNumberDisplay + '\n');
                }
                
            }
        }
        return setWDs;
        
    }
    /**
     * Method: returnIsError
     * Description: method to return the Boolean if error occured.
     */
    public static Boolean returnIsError(Boolean isInsert, Map < String, Integer > mapAllocatedStockQTY, SVMXC__Product_Serial__c batchSerialRec,SVMXC__Service_Order_Line__c objWorkDetail){
        Boolean isError = false;
        if (!isInsert && mapAllocatedStockQTY.containskey(batchSerialRec.SVMX_PS_External_ID__c) && batchSerialRec.Quantity__c - mapAllocatedStockQTY.get(batchSerialRec.SVMX_PS_External_ID__c) < 0) {
            isError = true;
        } else if (isInsert && mapAllocatedStockQTY.containsKey(batchSerialRec.SVMX_PS_External_ID__c) && objWorkDetail.SVMXC__Actual_Quantity2__c > (batchSerialRec.Quantity__c - mapAllocatedStockQTY.get(batchSerialRec.SVMX_PS_External_ID__c))) {
            isError = true;
        }
        return isError;
    }
}
