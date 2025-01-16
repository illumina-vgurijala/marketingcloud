/**
* @author Shivani Jain
* @date 29 Nov 2021
*
* @description DCP-42926 Helper Class for Parts Order Line Trigger to Populate Collections 
*                          used on After Insert event 
*/ 
public class PopulateCollectionsAfterEvent_POLHelper {

    /*******************************************************************************************************
    * @description populate Set And Maps
    * @param objPartOrderLine True if logged in user is CP
    * @param objOldPartsOrderLine List <SVMXC__RMA_Shipment_Line__c>
    * @return
    */
    public static void populateSetAndMaps(SVMXC__RMA_Shipment_Line__c objPartOrderLine, SVMXC__RMA_Shipment_Line__c objOldPartsOrderLine, 
                                    Boolean isInsert, Boolean hasInsertOrUpdateRun) {
        if (objPartOrderLine.SVMXC__Line_Status__c == PartsOrderLines.STRING_PART_ORDER_LINE_STATUS_SHIPPED 
                && objPartOrderLine.SVMXC__Product__c != null
                && (objOldPartsOrderLine == NULL || (objOldPartsOrderLine != NULL && (objOldPartsOrderLine.SVMXC__Line_Status__c != objPartOrderLine.SVMXC__Line_Status__c 
                    || objOldPartsOrderLine.SVMXC__Product__c != objPartOrderLine.SVMXC__Product__c))) ) {
            PartsOrderLines.setPartsOrderLineId.add(objPartOrderLine.Id);
            System.debug(objPartOrderLine);
            System.debug(objOldPartsOrderLine);
            //DCP-43163
            if(objPartOrderLine.Parts_Order_Type__c == PartsOrderLines.STRING_PARTS_ORDER_TYPE_SHIPMENT) {
                PartsOrderLines.mapPOLIdToInstalledProductId.put(objPartOrderLine.id, objPartOrderLine.SVMXC__Serial_Number__c);
            }
            if(objPartOrderLine.Parts_Order_Type__c != 'Return' 
                    && objPartOrderLine.Parts_Order_Type__c != PartsOrderLines.STRING_PARTS_ORDER_STOCK_TRANSFER) {
                PartsOrderLines.nonReturnPartsOrderLineIdVSPOL.put(objPartOrderLine.Id, objPartOrderLine);
            }
        }
        //DCP-38817
        //conditions - Non Billable Reason is not blank and is not of type consumable warranty.
        if(String.isNotBlank(objPartOrderLine.Reason__c) 
                && objPartOrderLine.Reason__c != PartsOrderLines.STRING_WORK_DETAIL_NON_BILLABLE_REASON_CONSUMABLE_WARRANTY 
                && !hasInsertOrUpdateRun
                && (objOldPartsOrderLine == NULL 
                        || (objOldPartsOrderLine != NULL && objOldPartsOrderLine.Is_Billable__c && !objPartOrderLine.Is_Billable__c))) {
            PartsOrderLines.setBillablePartsOrderLinesIds.add(objPartOrderLine.Id);
            if(isInsert) {
                PartsOrderLines.hasInsertRun =  true;
            } else {
                PartsOrderLines.hasUpdateRun = true;
            }
        }
    }
}
