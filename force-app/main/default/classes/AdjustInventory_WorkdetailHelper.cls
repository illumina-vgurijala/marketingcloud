/*****************************************************************************************************************
 * Class Name: AdjustInventory_WorkdetailHelper
 * Description: Adjust the inventory for serialized, batch & non tracked products.
 * Author: Prashanth
 * 
 * Date: 06-Dec-2021
 * 
 * Notification Log:
 * -------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -------------------------------------------------------------------------------------------------------------
 * Prashanth               06-12-2021        Adjust the inventory for serialized, batch & non tracked products.
 ******************************************************************************************************************/
public with sharing class AdjustInventory_WorkdetailHelper {
    //DCP-44981
    public static final String STRING_CONSUMED_PRODUCT_STOCK = 'Consumed';
    public static final String STRING_AVAILABLE_PRODUCT_STOCK = 'Available';

    /*
    *  @DESCRIPTION: DCP-44981 - Parts Consumption Reversal Process for Serialized Work Detail
    *  @RETURN:  void
    */
    public static void adjustSerializedOrNonTrackedInventory(Map < Id, SVMXC__Service_Order_Line__c > serializedWorkDetailIdToWorkDetailMap, String serializedOrNonTracked) {

        Map < String, Id > partNumberToConsumedLocationIdMap = new Map < String, Id > ();
        Map < String, SVMXC__Service_Order_Line__c > partNumberToWorkDetailMap = new Map < String, SVMXC__Service_Order_Line__c > ();
        Map < String, List < SVMXC__Product_Stock__c >> partNumberToListProductStocks = new Map < String, List < SVMXC__Product_Stock__c >> ();
        List < SVMXC__Product_Serial__c > listReparentedStockedSerialInternal = new List < SVMXC__Product_Serial__c > ();
        List < SVMXC__Product_Stock__c > listProductStockInternal = new List < SVMXC__Product_Stock__c > ();

        for (Id workDetailId: serializedWorkDetailIdToWorkDetailMap.keyset()) {
            if (String.isNotBlank(serializedWorkDetailIdToWorkDetailMap.get(workDetailId).Consumed_Part_Number__c)) {
                partNumberToConsumedLocationIdMap.put(serializedWorkDetailIdToWorkDetailMap.get(workDetailId).Consumed_Part_Number__c, serializedWorkDetailIdToWorkDetailMap.get(workDetailId).SVMXC__Consumed_From_Location__c);
                partNumberToWorkDetailMap.put(serializedWorkDetailIdToWorkDetailMap.get(workDetailId).Consumed_Part_Number__c, serializedWorkDetailIdToWorkDetailMap.get(workDetailId));
            }
        }

        //get available and consumed product stocks based on part number
        Map < Id, SVMXC__Product_Stock__c > productStockIdToProductStockMap = new Map < Id, SVMXC__Product_Stock__c > ([Select Id, SVMXC__Status__c,SVMXC__Location__c, Product_Code__c, SVMXC__Quantity2__c from SVMXC__Product_Stock__c Where Product_Code__c IN :partNumberToConsumedLocationIdMap.keyset() AND SVMXC__Location__c IN :partNumberToConsumedLocationIdMap.values()]);

        //part number with list of product stocks
        for (Id productStockId: productStockIdToProductStockMap.keyset()) {
            if (partNumberToListProductStocks!=NULL && !partNumberToListProductStocks.IsEmpty() && partNumberToListProductStocks.containskey(productStockIdToProductStockMap.get(productStockId).Product_Code__c)) {
                partNumberToListProductStocks.get(productStockIdToProductStockMap.get(productStockId).Product_Code__c).add(productStockIdToProductStockMap.get(productStockId));
            } else {
                partNumberToListProductStocks.put(productStockIdToProductStockMap.get(productStockId).Product_Code__c, new List < SVMXC__Product_Stock__c > ());
                partNumberToListProductStocks.get(productStockIdToProductStockMap.get(productStockId).Product_Code__c).add(productStockIdToProductStockMap.get(productStockId));
            }
        }
        populateProductStockMap(partNumberToListProductStocks, partNumberToWorkDetailMap, listReparentedStockedSerialInternal, listProductStockInternal, serializedOrNonTracked);
        //update product stock
        if (!listProductStockInternal.isEmpty()){
            PartsConsumptionReversal_WDHelper.listProductStockFinalUpdate.addAll(listProductStockInternal);
        }

        //reparent stocked serial update
        if ( !listReparentedStockedSerialInternal.isEmpty()){
            PartsConsumptionReversal_WDHelper.listStockedSerialFinalUpdate.addAll(listReparentedStockedSerialInternal);
        }   

    }
    /*
    *  Method:populateProductStockMap
    *  @DESCRIPTION: DCP-44981 - Parts Consumption Reversal Process for Serialized Work Detail
    *  @RETURN:  void
    */
    public static void populateProductStockMap(Map < String, List < SVMXC__Product_Stock__c >> partNumberToListProductStocks, Map < String, SVMXC__Service_Order_Line__c > partNumberToWorkDetailMap,List < SVMXC__Product_Serial__c > listReparentedStockedSerialInternal, List<SVMXC__Product_Stock__c> listProductStockInternal, String serializedOrNonTracked){
        for (string partNumber: partNumberToListProductStocks.keyset()) {

            for (SVMXC__Product_Stock__c productStock: partNumberToListProductStocks.get(partNumber)) {
                if (productStock.SVMXC__Status__c == STRING_CONSUMED_PRODUCT_STOCK) {
                    productStock.SVMXC__Quantity2__c -= partNumberToWorkDetailMap.get(partNumber).SVMXC__Actual_Quantity2__c;
                } else if (productStock.SVMXC__Status__c == STRING_AVAILABLE_PRODUCT_STOCK) {
                    productStock.SVMXC__Quantity2__c += partNumberToWorkDetailMap.get(partNumber).SVMXC__Actual_Quantity2__c;

                    if (serializedOrNonTracked == Workdetails.PRODUCT_TRACKING_SERIALIZED){
                        listReparentedStockedSerialInternal.add(new SVMXC__Product_Serial__c(Id = partNumberToWorkDetailMap.get(partNumber).SVMX_PS_VS_Consumed_Stocked_Serial__c, SVMXC__Product_Stock__c = productStock.id, SVMX_PS_VS_Linked_Installed_Product__c = partNumberToWorkDetailMap.get(partNumber).SVMXC__Serial_Number__c,SVMXC__Active__c = true));
                    }

                }
                listProductStockInternal.add(productStock);
            }
        }
    }

    /*
    *  @DESCRIPTION: DCP-44981 - Parts Consumption Reversal Process for Batch Work Detail
    *  @RETURN:  void
    */
    public static void adjustBatchInventory(Map < Id, SVMXC__Service_Order_Line__c > batchWorkDetailIdToWorkDetailMap) {

        Map < String, Id > partNumberToConsumedLocationIdMap = new Map < String, Id > ();
        Map < String, SVMXC__Service_Order_Line__c > partNumberToWorkDetailMap = new Map < String, SVMXC__Service_Order_Line__c > ();
        Map < String, List < SVMXC__Product_Stock__c >> partNumberToListProductStocks = new Map < String, List < SVMXC__Product_Stock__c >> ();
        List < SVMXC__Product_Serial__c > listStockSerialInternal = new List < SVMXC__Product_Serial__c > ();
        List < SVMXC__Product_Stock__c > listProductStockInternal = new List < SVMXC__Product_Stock__c > ();

        for (Id workDetailId: batchWorkDetailIdToWorkDetailMap.keyset()) {
            if (String.isNotBlank(batchWorkDetailIdToWorkDetailMap.get(workDetailId).Consumed_Part_Number__c)) {
                partNumberToConsumedLocationIdMap.put(batchWorkDetailIdToWorkDetailMap.get(workDetailId).Consumed_Part_Number__c, batchWorkDetailIdToWorkDetailMap.get(workDetailId).SVMXC__Consumed_From_Location__c);
                partNumberToWorkDetailMap.put(batchWorkDetailIdToWorkDetailMap.get(workDetailId).Consumed_Part_Number__c, batchWorkDetailIdToWorkDetailMap.get(workDetailId));
            }
        }

        //get available and consumed product stocks based on part number
        Map < Id, SVMXC__Product_Stock__c > productStockIdToProductStockMap = new Map < Id, SVMXC__Product_Stock__c > ([Select Id, SVMXC__Status__c, Product_Code__c, SVMXC__Quantity2__c, (Select Id, Quantity__c, Batch_Number__c, Product_Stock_Status__c from SVMXC__Product_Serial__r) from SVMXC__Product_Stock__c Where Product_Code__c IN: partNumberToConsumedLocationIdMap.keyset() AND SVMXC__Location__c IN: partNumberToConsumedLocationIdMap.values()]);

        //part number with list of product stocks
        for (Id productStockId: productStockIdToProductStockMap.keyset()) {
            if (partNumberToListProductStocks!=NULL && !partNumberToListProductStocks.IsEmpty() && partNumberToListProductStocks.containskey(productStockIdToProductStockMap.get(productStockId).Product_Code__c)) {
                partNumberToListProductStocks.get(productStockIdToProductStockMap.get(productStockId).Product_Code__c).add(productStockIdToProductStockMap.get(productStockId));
            } else {
                partNumberToListProductStocks.put(productStockIdToProductStockMap.get(productStockId).Product_Code__c, new List < SVMXC__Product_Stock__c > ());
                partNumberToListProductStocks.get(productStockIdToProductStockMap.get(productStockId).Product_Code__c).add(productStockIdToProductStockMap.get(productStockId));
            }
        }

        for (string partNumber: partNumberToListProductStocks.keyset()) {
            adjustBatchQuantity(partNumberToListProductStocks, partNumberToWorkDetailMap, listStockSerialInternal, listProductStockInternal,partNumber);
        }

        //update product stock
        if ( !listProductStockInternal.isEmpty()){
            PartsConsumptionReversal_WDHelper.listProductStockFinalUpdate.addAll(listProductStockInternal);
        }

        //reparent stocked serial update
        if ( !listStockSerialInternal.isEmpty()){
            PartsConsumptionReversal_WDHelper.listStockedSerialFinalUpdate.addAll(listStockSerialInternal);
        }     

    }
     
    
    /*
    * Method:adjustBatchQuantity
    *  @DESCRIPTION: DCP-44981 - Parts Consumption Reversal Process for Serialized Work Detail, update on IP
    *  @RETURN:  void
    */
    public static void adjustBatchQuantity(Map < String, List < SVMXC__Product_Stock__c >> partNumberToListProductStocks, Map < String, SVMXC__Service_Order_Line__c > partNumberToWorkDetailMap, List < SVMXC__Product_Serial__c > listStockSerialInternal, List < SVMXC__Product_Stock__c > listProductStockInternal, String partNumber){
        //adjust the quantity
        for (SVMXC__Product_Stock__c productStock: partNumberToListProductStocks.get(partNumber)) {
            if (productStock.SVMXC__Status__c == STRING_CONSUMED_PRODUCT_STOCK) {
                productStock.SVMXC__Quantity2__c -= partNumberToWorkDetailMap.get(partNumber).SVMXC__Actual_Quantity2__c;
            } else if (productStock.SVMXC__Status__c == STRING_AVAILABLE_PRODUCT_STOCK) {
                productStock.SVMXC__Quantity2__c += partNumberToWorkDetailMap.get(partNumber).SVMXC__Actual_Quantity2__c;
            }

            for (SVMXC__Product_Serial__c stockedSerial: productStock.SVMXC__Product_Serial__r) {

                if (stockedSerial.Product_Stock_Status__c == STRING_CONSUMED_PRODUCT_STOCK && stockedSerial.Batch_Number__c == partNumberToWorkDetailMap.get(partNumber).Batch_Number__c) {
                    stockedSerial.Quantity__c -= partNumberToWorkDetailMap.get(partNumber).SVMXC__Actual_Quantity2__c;
                } else if (stockedSerial.Product_Stock_Status__c == STRING_AVAILABLE_PRODUCT_STOCK && stockedSerial.Batch_Number__c == partNumberToWorkDetailMap.get(partNumber).Batch_Number__c) {
                    stockedSerial.Quantity__c += partNumberToWorkDetailMap.get(partNumber).SVMXC__Actual_Quantity2__c;
                }

                listStockSerialInternal.add(stockedSerial);
            }
            listProductStockInternal.add(productStock);

        }
        
    }

}