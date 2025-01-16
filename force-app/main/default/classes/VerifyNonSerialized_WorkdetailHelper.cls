/*****************************************************************************************************************
 * Class Name: VerifyNonSerialized_WorkdetailHelper
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
public with sharing class VerifyNonSerialized_WorkdetailHelper {
    // DCP-33467
    public static final String PRODUCT_CODE = 'Product Code:';
    public static final String SERIAL = ', Serial:';
    public static final String BATCH = ', Batch:';
    /*
     *  @AUTHOR:  Sravan
     *  @DESCRIPTION: 33467 - Verify non-serialized parts whether it has error
     */
    public static set < SVMXC__Service_Order_Line__c > verifyNonSerializedParts(set < SVMXC__Service_Order_Line__c > setWorkDetailsParts, Map < Id, String > mapStockSerialNumbers, set < Id > setProductStockId, Boolean isInsert) {
        Set < SVMXC__Service_Order_Line__c > setWDs = new Set < SVMXC__Service_Order_Line__c > ();
        Map < Id, List < SVMXC__Allocated_Stock__c >> mapProductStockAllocatedList = new Map < Id, List < SVMXC__Allocated_Stock__c >> ();
        Map < Id, Integer > mapProductStockAllocatedQTY = new Map < Id, Integer > ();
        Map < Id, Integer > mapProductStockAvailableQTY = new Map < Id, Integer > ();
        
        boolean isError;
        String batchNumberDisplay = '';
        String serialNumberDisplay = '';
        
        populateProductStockAllocatedMap(setProductStockId,mapProductStockAllocatedList,mapProductStockAvailableQTY);
            
        getAllocatedQtyforProductStock(mapProductStockAllocatedList, mapProductStockAllocatedQTY);
        for (SVMXC__Service_Order_Line__c objWorkDetail: setWorkDetailsParts) {
            isError = false;
            if (!isInsert && mapProductStockAllocatedQTY.containsKey(objWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c) && mapProductStockAvailableQTY.containsKey(objWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c) && (mapProductStockAvailableQTY.get(objWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c) - mapProductStockAllocatedQTY.get(objWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c)) < 0) {
                isError = true;
            } else if (isInsert && mapProductStockAllocatedQTY.containsKey(objWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c) && mapProductStockAvailableQTY.containsKey(objWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c) && objWorkDetail.SVMXC__Actual_Quantity2__c > (mapProductStockAvailableQTY.get(objWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c) - mapProductStockAllocatedQTY.get(objWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c))) {
                isError = true;
            }
            if (isError) {
                setWDs.add(objWorkDetail);
                batchNumberDisplay = objWorkDetail.Batch_Number__c != null ? objWorkDetail.Batch_Number__c : '';
                serialNumberDisplay = mapStockSerialNumbers.get(objWorkDetail.SVMX_PS_VS_Consumed_Stocked_Serial__c) != null ? mapStockSerialNumbers.get(objWorkDetail.SVMX_PS_VS_Consumed_Stocked_Serial__c) : '';
                Workdetails.setWDErrors.add(PRODUCT_CODE + objWorkDetail.Product_Code__c + SERIAL + serialNumberDisplay + BATCH + batchNumberDisplay + '\n');
            }
        }
        return setWDs;
    } // DCP-33467
    /**
     * Method: getAllocatedQtyforProductStock
     */
    public static void getAllocatedQtyforProductStock(Map < Id, List < SVMXC__Allocated_Stock__c >> mapProductStockAllocatedList, Map < Id, Integer > mapProductStockAllocatedQTY){
        Integer allocatedQty;
        // Get allocated/Reserved Qty for each product stock and prepare the WO Number list
        if(!mapProductStockAllocatedList.isEmpty()) {
            for (Id alsKey: mapProductStockAllocatedList.keySet()) {
                allocatedQty = 0;
                for (SVMXC__Allocated_Stock__c allocatedStock: mapProductStockAllocatedList.get(alsKey)) {
                    if(allocatedStock.SVMXC__Allocated_Qty__c!=null){ //RESOLVING ATTEMPT TO DEFERENCE NULL
                        allocatedQty = allocatedQty + integer.valueOf(allocatedStock.SVMXC__Allocated_Qty__c);
                    }
                    Workdetails.setWorkOrderNumber.add(allocatedStock.Work_Order__r.Name);
                }
                mapProductStockAllocatedQTY.put(alsKey, allocatedQty);
            }
        }
    }
    /**
     * Method: populateProductStockAllocatedMap
     */
    public static void populateProductStockAllocatedMap(set < Id > setProductStockId, Map < Id, List < SVMXC__Allocated_Stock__c >> mapProductStockAllocatedList, Map < Id, Integer > mapProductStockAvailableQTY){        
        if (setProductStockId!=NULL && !setProductStockId.isEmpty()) {
            for (SVMXC__Allocated_Stock__c als: new AllocatedStocksSelector().selectAllocatedStocksByProductStockIds(setProductStockId)) {
                if (mapProductStockAllocatedList.containsKey(als.SVMXC__Product_Stock__c)) {
                    mapProductStockAllocatedList.get(als.SVMXC__Product_Stock__c).add(als);
                } else {
                    mapProductStockAllocatedList.put(als.SVMXC__Product_Stock__c, new List < SVMXC__Allocated_Stock__c > {
                        als
                    });
                }
            }
            for (SVMXC__Product_Stock__c ps: new ProductStockSelector().selectProductStocksByIds(setProductStockId)) {
                mapProductStockAvailableQTY.put(ps.id, integer.valueOf(ps.SVMXC__Quantity2__c != null ? ps.SVMXC__Quantity2__c : 0));
            }
        }
        
    }
}
