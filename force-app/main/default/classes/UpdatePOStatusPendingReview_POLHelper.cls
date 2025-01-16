/**
* @author Shivani Jain
* @date 29 Nov 2021
*
* @description DCP-42926 Helper Class for Parts Order Line Trigger to 
*                       update Status to Pending Review
*/ 
public with sharing class UpdatePOStatusPendingReview_POLHelper {
   
    /*******************************************************************************************************
    * @description update Parts order Status to PR
    * @param isChannelPartner True if logged in user is CP
    * @return
    */
    public static void updatePartsOrderStatus(Boolean isChannelPartner) {
        Map<Id,Set<SVMXC__RMA_Shipment_Line__c>> mapPOtoPOLIdneedingDCIRCheck = new Map<Id,Set<SVMXC__RMA_Shipment_Line__c>>();

        if(PartsOrderLines.partsOrderIdToPartsOrder == NULL 
            || PartsOrderLines.partsOrderIdToPartsOrder.size() == 0) {return;}

        for(SVMXC__RMA_Shipment_Line__c obj:new PartsOrderLineSelector().selectPartsOrderLinesOnPartsOrders(PartsOrderLines.partsOrderIdToPartsOrder.keySet())) {
            if(isChannelPartner && obj.Parts_Order_Type__c == 'Return'
                    && obj.Decontamination_Required__c==true 
                    && !obj.Is_DCIR_Filled__c) {
                if(!mapPOtoPOLIdneedingDCIRCheck.containskey(obj.SVMXC__RMA_Shipment_Order__c)) {
                    mapPOtoPOLIdneedingDCIRCheck.put(obj.SVMXC__RMA_Shipment_Order__c,new set<SVMXC__RMA_Shipment_Line__c>());
                }
                mapPOtoPOLIdneedingDCIRCheck.get(obj.SVMXC__RMA_Shipment_Order__c).add(obj);
            }
        }
        populateUpdateMap(mapPOtoPOLIdneedingDCIRCheck);
        
    }

    /*******************************************************************************************************
    * @description populate PO Update Map
    * @param mapPOtoPOLIdneedingDCIRCheck Map<Id,Set<SVMXC__RMA_Shipment_Line__c>>
    * @return void
    */
    private static void populateUpdateMap(Map<Id,Set<SVMXC__RMA_Shipment_Line__c>> mapPOtoPOLIdneedingDCIRCheck) {
        for(Id partsOrderId: PartsOrderLines.partsOrderIdToPartsOrder.keyset()) {
                
            if(PartsOrderLines.partsOrderIdToPartsOrder.get(partsOrderId).Submit_to_SAP__c) {
                if(!PartsOrderLines.mapPartsOrderToUpdateAfterInsert.containsKey(partsOrderId)) {
                    PartsOrderLines.mapPartsOrderToUpdateAfterInsert.put(partsOrderId, PartsOrderLines.partsOrderIdToPartsOrder.get(partsOrderId));
                }
                PartsOrderLines.mapPartsOrderToUpdateAfterInsert.get(partsOrderId).Request_All_Part_Order_Lines__c = true;
            }
            if (mapPOtoPOLIdneedingDCIRCheck!= NULL 
                    && !mapPOtoPOLIdneedingDCIRCheck.containsKey(partsOrderId) 
                    && PartsOrderLines.partsOrderIdToPartsOrder.get(partsOrderId).Submit_for_Approval_CP__c 
                    && PartsOrderLines.partsOrderIdToPartsOrder.get(partsOrderId).SVMXC__Order_Status__c != PartsOrderLines.STRING_PART_ORDER_STATUS_PENDING_REVIEW) {
                if(!PartsOrderLines.mapPartsOrderToUpdateAfterInsert.containsKey(partsOrderId)) {
                    PartsOrderLines.mapPartsOrderToUpdateAfterInsert.put(partsOrderId, PartsOrderLines.partsOrderIdToPartsOrder.get(partsOrderId));
                }
                PartsOrderLines.mapPartsOrderToUpdateAfterInsert.get(partsOrderId).SVMXC__Order_Status__c = PartsOrderLines.STRING_PART_ORDER_STATUS_PENDING_REVIEW;
            }
        }

    }
}
