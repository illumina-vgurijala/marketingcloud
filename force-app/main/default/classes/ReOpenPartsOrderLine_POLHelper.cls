/**
* @author Shivani Jain
* @date 29 Nov 2021
*
* @description DCP-42926 Helper Class for Parts Order Line Trigger to reOpen POL
*/ 
public class ReOpenPartsOrderLine_POLHelper {

    /*******************************************************************************************************
    * @description Reopen POL records
    * @param objPartOrderLine new record
    * @param objOldPartsOrderLine old record
    * @return void
    */
    public static void reOpenPOL(SVMXC__RMA_Shipment_Line__c objPartOrderLine, SVMXC__RMA_Shipment_Line__c objOldPartsOrderLine) {
        if((objPartOrderLine.Service_Product_Type_Instrument__c 
                || objPartOrderLine.Reason__c == PartsOrderLines.STRING_PARTSORDERLINE_NON_BILLABLE_REASON_GOODWILL/* DCP-43634, Goodwill check */) 
            && (objOldPartsOrderLine.SVMXC__Product__c != objPartOrderLine.SVMXC__Product__c 
                || objOldPartsOrderLine.SVMXC__Actual_Quantity2__c != objPartOrderLine.SVMXC__Actual_Quantity2__c)) {
            SVMXC__RMA_Shipment_Order__c partsOrder = new SVMXC__RMA_Shipment_Order__c(Id = objPartOrderLine.SVMXC__RMA_Shipment_Order__c);
            if(!PartsOrderLines.mapPartsOrderToUpdate.containsKey(partsOrder.Id)) {
                PartsOrderLines.mapPartsOrderToUpdate.put(partsOrder.Id, partsOrder);
            }
            PartsOrderLines.mapPartsOrderToUpdate.get(partsOrder.Id).SVMXC__Order_Status__c = 'Open';
            PartsOrderLines.mapPartsOrderToUpdate.get(partsOrder.Id).Submit_POL_For_Approval__c = true;
        }
    }
}