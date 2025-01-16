/**
* @author Shivani Jain
* @date 29 Nov 2021
*
* @description DCP-42926 Helper Class for Parts Order Line Trigger to 
*                        process Linked Return Parts Order Lines
*/ 
public class CheckLinkedrecord_POLHelper {

    /*******************************************************************************************************
    * @description [DCP-1578] Check if the POL in Linked Return Part Order Line field is already linked.
    * @param oldRecords - Map <Id,sObject>
    * @param records List <SVMXC__RMA_Shipment_Line__c>
    * @return
    */
    public static void checkLinkedPOL(List<sObject> records, Map<Id, SObject> oldRecords) {
        Set<Id> setLinkedPOLIds = new Set<Id>();
        Set<Id> setAlreadyLinkedPOLIds = new Set<Id>();

        for (SVMXC__RMA_Shipment_Line__c rmaLine: (List<SVMXC__RMA_Shipment_Line__c>) records) {
            if (oldRecords != null) {
                SVMXC__RMA_Shipment_Line__c objOldPartOrderLine = (SVMXC__RMA_Shipment_Line__c)(oldRecords.get(rmaLine.Id));
                if (rmaLine.SVMXC__Master_Order_Line__c != null 
                        && objOldPartOrderLine.SVMXC__Master_Order_Line__c != rmaLine.SVMXC__Master_Order_Line__c) {
                    setLinkedPOLIds.add(rmaLine.SVMXC__Master_Order_Line__c);
                }
            } else if (rmaLine.SVMXC__Master_Order_Line__c != null) {
                setLinkedPOLIds.add(rmaLine.SVMXC__Master_Order_Line__c);
            }
        }

        if (setLinkedPOLIds.size() > 0) {
            for(SVMXC__RMA_Shipment_Line__c rmaLine: new PartsOrderLineSelector().selectLinkedPartsOrderLine(setLinkedPOLIds)) {
                setAlreadyLinkedPOLIds.add(rmaLine.SVMXC__Master_Order_Line__c);
            }
        }
        
        if (setAlreadyLinkedPOLIds.size() > 0) {
            for (SVMXC__RMA_Shipment_Line__c rmaLine: (List <SVMXC__RMA_Shipment_Line__c> ) records) {
                if (setAlreadyLinkedPOLIds.contains(rmaLine.SVMXC__Master_Order_Line__c)) {
                    rmaLine.addError(Label.Linked_Return_PO_Error);
                }
            }
        }
    }

}
