/**
* @author Shivani Jain
* @date 30th May 2022
*
* @description DCP-54018 Helper Class for Work Order Trigger to run logic related to Field Stock WO 
*/ 
public with sharing class FieldStockFSOwner_WOHelper {
    /*
    *  @AUTHOR:  Soumya
    *  @DESCRIPTION: To Populate the Field Support and Owner of Work Order (Cycle Count)
    *                with Inventory Authority of Location DCP-24618
    *  @PARAM :  Set of Location Id, Map of Work Order Ids and Location Ids  
    *  return : void
    */ 
    public static void populateFieldSupportAndOwnerFromLocation(List<Sobject> records) {
        
        Map<id,id> idWOToIdLocation=new Map<id,id>();
        Map<id,SVMXC__Site__c> idToLocationMap = new Map<id,SVMXC__Site__c>(WorkOrders.mapLocationrecords);
        set<id> setServiceEnggUser = new set<id>();
        Map<id,id> idOwnerToFieldSupportMap = new Map<id,id>();

        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            //DCP-24618
            if(objWorkOrder.RecordTypeId == ServiceUtilityCollection.getRecordTypeId(WorkOrders.STRING_WORK_ORDER_API_NAME, WorkOrders.STRING_WORK_ORDER_FIELD_STOCK_RECORDTYPE_NAME) 
                    && objWorkOrder.SVMXC__Site__c != NULL) {
                IdWOToIdLocation.put(objWorkOrder.Id,objWorkOrder.SVMXC__Site__c);
            }
        }   
    
        
        if(!WorkOrders.mapLocationrecords.isEmpty()) {
            for(SVMXC__Site__c objLocation :WorkOrders.mapLocationrecords.values()) {
                if(objLocation.SVMXC__Service_Engineer__c != NULL ) {
                    setServiceEnggUser.add(objLocation.SVMXC__Service_Engineer__c);
                }
            }
            //To get the associated field support from service engineer of location
            if(!setServiceEnggUser.isEmpty()) {
                idOwnerToFieldSupportMap = ServiceUtilityCollection.FieldSupportFromUser(setServiceEnggUser);
            }
            populateInventoryAuthorityFromLocation(records, idToLocationMap, idOwnerToFieldSupportMap, IdWOToIdLocation);
        }
    }

    /*
    *  @DESCRIPTION: 
    */ 
    private static void populateInventoryAuthorityFromLocation(List<Sobject> records,  Map<id,SVMXC__Site__c> idToLocationMap, Map<id,id> idOwnerToFieldSupportMap, Map<id,id> idWOToIdLocation) {
        //To populate the inventory authority from location
        for(SVMXC__Service_Order__c objWorkOrder :(List<SVMXC__Service_Order__c>)records) {
            if(objWorkOrder.RecordTypeId == ServiceUtilityCollection.getRecordTypeId(WorkOrders.STRING_WORK_ORDER_API_NAME, WorkOrders.STRING_WORK_ORDER_FIELD_STOCK_RECORDTYPE_NAME) 
                    && objWorkOrder.SVMXC__Site__c != NULL && IdWOToIdLocation.containsKey(objWorkOrder.id) 
                    && idToLocationMap.containskey(IdWOToIdLocation.get(objWorkOrder.id))) {
                //To check if Service Engineer is associated on the Loaction
                if(idToLocationMap.get(IdWOToIdLocation.get(objWorkOrder.id)).SVMXC__Service_Engineer__c != NULL) {
                    objWorkOrder.OwnerId =idToLocationMap.get(IdWOToIdLocation.get(objWorkOrder.id)).SVMXC__Service_Engineer__c;
                    objWorkOrder.SVMXC__Group_Member__c = idOwnerToFieldSupportMap.containskey(objWorkOrder.OwnerId) ? idOwnerToFieldSupportMap.get(objWorkOrder.OwnerId) : objWorkOrder.SVMXC__Group_Member__c;
                } else if(idToLocationMap.get(IdWOToIdLocation.get(objWorkOrder.id)).SVMX_PS_Preferred_Technician__c != NULL) {
                    objWorkOrder.SVMXC__Group_Member__c = idToLocationMap.get(IdWOToIdLocation.get(objWorkOrder.id)).SVMX_PS_Preferred_Technician__c;
                    objWorkOrder.OwnerId = idToLocationMap.get(IdWOToIdLocation.get(objWorkOrder.id)).SVMX_PS_Preferred_Technician__r.SVMXC__Salesforce_User__c;
                }
            }   
        }
    }
}
