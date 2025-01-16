/**
* @author Shivani Jain
* @date 29 Nov 2021
*
* @description DCP-42926 Helper Class for Parts Order Line Trigger to update Batch Number to null 
*/ 
public with sharing class BatchNumber_POLHelper {
    /*******************************************************************************************************
    * @description DCP-50097 method to make Batch Number NULL when Batch Lookup is null;
    * @param partsOrderLine New list of records
    * @return
    * @author Harsh Shukla
    */
    public static void makeBatchNumberNull(SVMXC__RMA_Shipment_Line__c partsOrderLine) {
        if((partsOrderLine.Parts_Order_Type__c == PartsOrderLines.STRING_PARTS_ORDER_TYPE_RETURN 
                  || partsOrderLine.Parts_Order_Type__c == PartsOrderLines.STRING_PARTS_ORDER_STOCK_TRANSFER) 
              && String.isBlank(partsOrderLine.Batch_Lookup__c) && !String.isBlank(partsOrderLine.Batch_Number__c)) {
            partsOrderLine.Batch_Number__c = null;
        }
    }

    /*******************************************************************************************************
    * @description method to make Batch Number NULL when Batch Lookup is null;
    * @param partsOrderLine New record
    * @param objOldPartOrderLine Old record
    * @return
    */
    public static void makeBatchNumberNullBeforeUpdate(SVMXC__RMA_Shipment_Line__c partsOrderLine, SVMXC__RMA_Shipment_Line__c objOldPartOrderLine) {
        if(String.isBlank(partsOrderLine.Batch_Lookup__c) && !String.isBlank(partsOrderLine.Batch_Number__c)) {
            if(String.isBlank(partsOrderLine.Stocked_Serial__c) && partsOrderLine.Batch_Lookup__c != objOldPartOrderLine.Batch_Lookup__c) {
                partsOrderLine.Batch_Number__c = Null;
            }
        }
    }

}