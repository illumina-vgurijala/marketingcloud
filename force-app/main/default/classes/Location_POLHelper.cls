/**
* @author Shivani Jain
* @date 29 Nov 2021
*
* @description DCP-42926 Helper Class for Parts Order Line Trigger 
*               to check if the from location is one of the part locker or trunk of the technitian.
*/
public with sharing class Location_POLHelper {

    /*******************************************************************************************************
    * @description Generate Shipment Parts Order Map
    * @param partOrderLine new record
    * @param objOldPartOrderLine old record
    * @return
    */
    public static void generatePartsOrderMap(SVMXC__RMA_Shipment_Line__c partOrderLine, SVMXC__RMA_Shipment_Line__c objOldPartOrderLine) {
        if (partOrderLine.SVMXC__RMA_Shipment_Order__c != null && partOrderLine.From_Location__c != null 
                && partOrderLine.RecordTypeId == PartsOrderLines.shipmentRecordTypeId 
                && (objOldPartOrderLine == NULL || (objOldPartOrderLine.From_Location__c != partOrderLine.From_Location__c))) {
            PartsOrderLines.partsOrderLinesToPartsOrder.put(partOrderLine, partOrderLine.SVMXC__RMA_Shipment_Order__c);
        }
    }
   
    /*******************************************************************************************************
    * @description To check if the from location is one of the part locker or trunk of the technitian. 
    * @param partsOrderLinesToPartsOrder Map <SVMXC__RMA_Shipment_Line__c, Id>
    * @return void
    */
    public static void validateFromLocation(Map <SVMXC__RMA_Shipment_Line__c, Id> partsOrderLinesToPartsOrder) {
        if(partsOrderLinesToPartsOrder == null || partsOrderLinesToPartsOrder.isEmpty()) {
            return;
        }
    
        Map<Id, Set<Id>> fieldSupportIdTosetLocationId = new Map<Id, Set<Id>>();
        Map<Id, Id> partOrderIdToTechnitianId = new Map<Id, Id>();
        Set<Id> setFieldSupportId = new Set<Id>();

        partOrderIdToTechnitianId = populatePartOrderIdToTechnitianId(partsOrderLinesToPartsOrder.values());

        if (partOrderIdToTechnitianId != null && !partOrderIdToTechnitianId.isEmpty() ) {
            for (SVMXC__Service_Group_Site__c objLocationCovered: new LocationsCoveredSelector().selectRelatedLocationFieldSupport(partOrderIdToTechnitianId.values())) {

                if (fieldSupportIdTosetLocationId.containskey(objLocationCovered.SVMXC__Technician_Equipment__c)) {
                    fieldSupportIdTosetLocationId.get(objLocationCovered.SVMXC__Technician_Equipment__c).add(objLocationCovered.SVMXC__Site__c);
                } else {
                    fieldSupportIdTosetLocationId.put(objLocationCovered.SVMXC__Technician_Equipment__c, new set<Id>{
                        objLocationCovered.SVMXC__Site__c});
                }
            }
            setFieldSupportId.addAll(partOrderIdToTechnitianId.values());
        }

        if (setFieldSupportId != null && setFieldSupportId.size() > 0) {
            for(SVMXC__Service_Group_Members__c objFieldSupport: new TechniciansSelector().selectTechnicians(setFieldSupportId)) {
                if(fieldSupportIdTosetLocationId.containskey(objFieldSupport.Id)) {
                    fieldSupportIdTosetLocationId.get(objFieldSupport.Id).add(objFieldSupport.SVMXC__Inventory_Location__c);
                } else {
                    fieldSupportIdTosetLocationId.put(objFieldSupport.Id, new set < Id > {
                        objFieldSupport.SVMXC__Inventory_Location__c
                    });
                }
            }
        }

        throwErrorTrunkLocker(partsOrderLinesToPartsOrder, partOrderIdToTechnitianId, fieldSupportIdTosetLocationId);
    }

    /*******************************************************************************************************
    * @description populate partOrderIdToTechnitianId
    * @param polIds List<Id>
    * @return Map<id, Id>
    */
    private static Map<Id, Id> populatePartOrderIdToTechnitianId(List<Id> polIds) {
        Map<Id, Id> partOrderIdToTechnitianId = new Map<Id, Id>();

        for(Id poId: polIds) {
            if(PartsOrderLines.partsOrderIdToPartsOrder != NULL
                    && PartsOrderLines.partsOrderIdToPartsOrder.containsKey(poId) 
                    && PartsOrderLines.partsOrderIdToPartsOrder.get(poId).SVMXC__Service_Order__c != null 
                    && PartsOrderLines.partsOrderIdToPartsOrder.get(poId).SVMXC__Service_Order__r.SVMXC__Group_Member__c != null) {
                partOrderIdToTechnitianId.put(poId, PartsOrderLines.partsOrderIdToPartsOrder.get(poId).SVMXC__Service_Order__r.SVMXC__Group_Member__c);
            }
        }
        return partOrderIdToTechnitianId;
    }

    /*******************************************************************************************************
    * @description Throw Trunk Locker Error
    * @param partsOrderLinesToPartsOrder Map<SVMXC__RMA_Shipment_Line__c, Id>
    * @param partOrderIdToTechnitianId Map<Id, Id>
    * @param fieldSupportIdTosetLocationId Map<Id, Set<Id>>
    * @return
    */
    private static void throwErrorTrunkLocker(Map<SVMXC__RMA_Shipment_Line__c, Id> partsOrderLinesToPartsOrder, Map<Id, Id> partOrderIdToTechnitianId,
                    Map<Id, Set<Id>> fieldSupportIdTosetLocationId) {
        for (SVMXC__RMA_Shipment_Line__c objPartsOrderLine: partsOrderLinesToPartsOrder.keySet()) {
            Id idFieldsupport = null;

            if(partOrderIdToTechnitianId != null && partOrderIdToTechnitianId.get(partsOrderLinesToPartsOrder.get(objPartsOrderLine)) != null) {
                idFieldsupport = partOrderIdToTechnitianId.get(partsOrderLinesToPartsOrder.get(objPartsOrderLine));
            }

            if(idFieldsupport != NULL && fieldSupportIdTosetLocationId != null && fieldSupportIdTosetLocationId.containskey(idFieldsupport)) {
                set<Id> setLocationId = fieldSupportIdTosetLocationId.get(idFieldsupport);

                if (setLocationId != null && !setLocationId.contains(objPartsOrderLine.From_Location__c)) {
                    if (!UserInfo.getName().EqualsIgnoreCase(PartsOrderLines.STRING_SAP_INTEGRATION_USER) &&
                        !UserInfo.getName().EqualsIgnoreCase(PartsOrderLines.STRING_SNAP_INTEGRATION_USER)
                    ) {
                        objPartsOrderLine.addError(Label.Trunk_Locker_Error);
                    }
                }
            }
        }
    }

}
