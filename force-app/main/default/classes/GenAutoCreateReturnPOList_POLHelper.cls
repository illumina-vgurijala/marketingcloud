/**
* @author Shivani Jain
* @date 29 Nov 2021
*
* @description DCP-42926 Helper Class for Parts Order Line Trigger to return list of Shipped POL
*/ 
public class GenAutoCreateReturnPOList_POLHelper {

    
    /*******************************************************************************************************
    * @description return list of Shipped POL
    * @return List<SVMXC__RMA_Shipment_Line__c>
    */
    public static List<SVMXC__RMA_Shipment_Line__c> autoCreateReturnPartsOrder(Map < Id, sObject > oldRecords) {
        List<SVMXC__RMA_Shipment_Line__c> lstShippedPOL = new List<SVMXC__RMA_Shipment_Line__c>();
        
        for(SVMXC__RMA_Shipment_Line__c objPartsOrderLine : PartsOrderLines.mapCurrentPartsOrderLines.values()) {  
            SVMXC__RMA_Shipment_Line__c objOldPartsOrderLine = null;
            if(oldRecords != null){
                objOldPartsOrderLine = (SVMXC__RMA_Shipment_Line__c) oldRecords.get(objPartsOrderLine.Id);
            }
            Boolean boolPartsOrderIsShipment = objPartsOrderLine.Parts_Order_Type__c == PartsOrderLines.STRING_PARTS_ORDER_TYPE_SHIPMENT 
                                                && objPartsOrderLine.Service_Product_Type__c == PartsOrderLines.STRING_PRODUCT_TYPE_INSTRUMENT;
            Boolean boolPartsOrderLineIsShipped = objPartsOrderLine.SVMXC__Product__c != NULL 
                                                  ? objPartsOrderLine.SVMXC__Product__r.Condition_Type__c == PartsOrderLines.STRING_CONDITION_TYPE_LOANER 
                                                  && objPartsOrderLine.SVMXC__Product__r.Serial_Number_Profile__c == PartsOrderLines.STRING_SERIAL_NUMBER_PROFILE_IL02 
                                                  && objPartsOrderLine.SVMXC__Line_Status__c == PartsOrderLines.STRING_PART_ORDER_LINE_STATUS_SHIPPED 
                                                  && (objOldPartsOrderLine == null || objOldPartsOrderLine.SVMXC__Line_Status__c != objPartsOrderLine.SVMXC__Line_Status__c)
                                                  && String.isNotBlank(objPartsOrderLine.SVMXC__Serial_Number_List__c) 
                                                  : false;
           
            if(boolPartsOrderIsShipment && boolPartsOrderLineIsShipped) {
                lstShippedPOL.add(objPartsOrderLine);
            }
        }
        return lstShippedPOL;
    }
}