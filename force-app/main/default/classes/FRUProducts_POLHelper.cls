/**
* @author Shivani Jain
* @date 29 Nov 2021
*
* @description DCP-42926 Helper Class for Parts Order Line Trigger to run FRU logic
*/ 
public class FRUProducts_POLHelper {

    /*******************************************************************************************************
    * @description populate Collections
    * @param partOrderLine new record
    * @param objOldPartOrderLine old record
    * @return
    */
    public static void generateCollections(SVMXC__RMA_Shipment_Line__c partOrderLine, SVMXC__RMA_Shipment_Line__c objOldPartOrderLine) {
        //If Product has been changed, validate that it is in the FRU list
        if (partOrderLine.SVMXC__Product__c != null && partOrderLine.Is_Part_Order_Line_for_Spare_Parts__c
                && (objOldPartOrderLine == NULL 
                    || (objOldPartOrderLine != NULL && objOldPartOrderLine.SVMXC__Product__c != partOrderLine.SVMXC__Product__c))) {
            PartsOrderLines.setPartOrderIds.add(partOrderLine.SVMXC__RMA_Shipment_Order__c);
            PartsOrderLines.setProductIdsSelected.add(partOrderLine.SVMXC__Product__c);
            PartsOrderLines.lstPOLForCompatibleProductCheck.add(partOrderLine);
            if(objOldPartOrderLine != NULL) {
                PartsOrderLines.setProductIdsSelected.add(objOldPartOrderLine.SVMXC__Product__c);
            }
        }
    }
    
    /*******************************************************************************************************
    * @description Check the list of products present in FruList object and restrict the user
    *               to update the part order line if the selected product is not present in FruList object.
    * @param setPartOrderIds Set<Id>
    * @param lstPOLForCompatibleProductCheck List<SVMXC__RMA_Shipment_Line__c>
    * @return void
    */
    public static void checkProductsOnFruList(Set<Id> setPartOrderIds, List <SVMXC__RMA_Shipment_Line__c> lstPOLForCompatibleProductCheck, Map <Id, sobject> oldRecord, Set <Id> setProductsIdsSelected, String strTypeCheck) {
        Map <Id, SVMXC__RMA_Shipment_Order__c> idToPartOrder = new Map <Id, SVMXC__RMA_Shipment_Order__c> (new PartsOrdersSelector().selectPartsOrders(setPartOrderIds));
        if (!idToPartOrder.isEmpty()) {
            ServiceUtilityCollection.checkCompatibleProductsInFRUList(lstPOLForCompatibleProductCheck, idToPartOrder, oldRecord, 'SVMXC__RMA_Shipment_Order__c', setProductsIdsSelected, new set<String>{strTypeCheck});
        }
    }
}