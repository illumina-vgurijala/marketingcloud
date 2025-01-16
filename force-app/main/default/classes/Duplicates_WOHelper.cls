/**
* @author Shivani Jain
* @date 7th May 2022
*
* @description DCP-54018 Helper Class for Work Order Trigger to run logic related to Duplicate Work Order. 
*/ 
public with sharing class Duplicates_WOHelper {
    
           
    /*
    *  @AUTHOR: Digvijay Singh
    *  @DESCRIPTION: process Closed duplicate Work Orders
    *  @PARAM : Map<Id , Sobject> 
    *  @RETURN:  void
    */
    public static void processDuplicateWorkOrders(Map<Id, SObject> oldRecords, List<sObject> records) {

        Map<Id, SVMXC__Service_Order__c> mapClosedDuplicateWOIds = new Map<Id, SVMXC__Service_Order__c>();
        
        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            SVMXC__Service_Order__c objOldWorkOrder = (SVMXC__Service_Order__c)(oldRecords.get(objWorkOrder.Id)); 
            //DCP-16165
            //Check if the Work Order has been closed duplicate
            if(objWorkOrder.SVMXC__Order_Status__c != objOldWorkOrder.SVMXC__Order_Status__c 
                    && objWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_CLOSED_DUPLICATE) {
                mapClosedDuplicateWOIds.put(objWorkOrder.Id, objWorkOrder);
            }
        }
        //DCP-16165
        //If Scheduled duration has been changed then create event 
        if(!mapClosedDuplicateWOIds.isEmpty()) {
            Map<Id, Integer> mapWOIdToWorkDetailsSize = new Map<Id, Integer>();
            Map<Id, Integer> mapWOIdToPartsOrdersSize = new Map<Id, Integer>();
            Map<Id, Integer> mapWOIdToAssociatedCodesSize = new Map<Id, Integer>();

            //query Work Details related to Work Order
            mapWOIdToWorkDetailsSize = fetchMapWOIdToWorkDetailsSize();

            //query Parts Orders related to Work Orders             
            mapWOIdToPartsOrdersSize = fetchMapWOIdToPartsOrdersSize();

            //query Associated Codes related to Work Order
            mapWOIdToAssociatedCodesSize = fetchMapWOIdToAssociatedCodesSize();

            for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)mapClosedDuplicateWOIds.values()) {
                SVMXC__Service_Order__c objOldWorkOrder = (SVMXC__Service_Order__c)(oldRecords.get(objWorkOrder.Id));
                //check if WO has related Work details or Parts Orders
                if((mapWOIdToWorkDetailsSize.containsKey(objWorkOrder.Id) && mapWOIdToWorkDetailsSize.get(objWorkOrder.Id) > 0)
                        || (mapWOIdToPartsOrdersSize.containsKey(objWorkOrder.Id) && mapWOIdToPartsOrdersSize.get(objWorkOrder.Id) > 0)) {
                    objWorkOrder.addError(system.label.Work_Order_ClosedDuplicate_Error_1);
                }
                //check if Elevation, Work Performed, Verification result has some value                        
                else if(string.isNotBlank(objWorkOrder.Notes__c)
                        || string.isNotBlank(objWorkOrder.Additional_Detail__c)
                        || (mapWOIdToAssociatedCodesSize.containsKey(objWorkOrder.Id) && mapWOIdToAssociatedCodesSize.get(objWorkOrder.Id) > 0)) {
                    objWorkOrder.addError(system.label.Work_Order_ClosedDuplicate_Error_2);
                }
                //check if Work Order has not been moved to Closed Duplicate from Pre Completion Status               
                else if(!WorkOrders.SET_WORK_ORDER_PRE_COMPLETION_STATUS.contains(objOldWorkOrder.SVMXC__Order_Status__c)) {
                    objWorkOrder.addError(system.label.Work_Order_ClosedDuplicate_Error_3);
                }
            }
        }
        
    } 

    private static Map<Id, Integer> fetchMapWOIdToWorkDetailsSize() {
        Map<Id, Integer> mapWOIdToWorkDetailsSize = new Map<Id, Integer>();

        for(SVMXC__Service_Order_Line__c objWorkDetail: WorkOrders.lstworkDetails) {
            if(!mapWOIdToWorkDetailsSize.containsKey(objWorkDetail.SVMXC__Service_Order__c)) {
                mapWOIdToWorkDetailsSize.put(objWorkDetail.SVMXC__Service_Order__c, 0);
            }
            //INC0226959 bypass validation for workdetails created by adding additional products on case (related products record type)
            if(objWorkDetail.SVMXC__Line_Status__c != NULL && objWorkDetail.SVMXC__Line_Status__c != WorkOrders.STRING_WORK_DETAIL_LINE_STATUS_CANCELED 
                    && objWorkDetail.RecordTypeId != ServiceUtilityCollection.getRecordTypeId('SVMXC__Service_Order_Line__c', WorkOrders.STRING_WORK_DETAIL_RECORDTYPE_NAME)) {
                Integer intWorkDetailNumber = mapWOIdToWorkDetailsSize.get(objWorkDetail.SVMXC__Service_Order__c);
                mapWOIdToWorkDetailsSize.put(objWorkDetail.SVMXC__Service_Order__c, intWorkDetailNumber+1);
            }
        }

        return mapWOIdToWorkDetailsSize;
    }

    private static Map<Id, Integer> fetchMapWOIdToPartsOrdersSize() {
        Map<Id, Integer> mapWOIdToPartsOrdersSize = new Map<Id, Integer>();

        for(SVMXC__RMA_Shipment_Order__c objPartsOrder: WorkOrders.lstpartsOrders) {
            if(!mapWOIdToPartsOrdersSize.containsKey(objPartsOrder.SVMXC__Service_Order__c)) {
                mapWOIdToPartsOrdersSize.put(objPartsOrder.SVMXC__Service_Order__c, 0);
            }
            integer intPartsOrderNumber = mapWOIdToPartsOrdersSize.get(objPartsOrder.SVMXC__Service_Order__c);
            mapWOIdToPartsOrdersSize.put(objPartsOrder.SVMXC__Service_Order__c, intPartsOrderNumber+1);
        }

        return mapWOIdToPartsOrdersSize;
    }

    private static Map<Id, Integer> fetchMapWOIdToAssociatedCodesSize() {
        Map<Id, Integer> mapWOIdToAssociatedCodesSize = new Map<Id, Integer>();

        for(Associated_Codes__c objAssociatedCode:WorkOrders.lstAssociatedCodes) {
            if(!mapWOIdToAssociatedCodesSize.containsKey(objAssociatedCode.Work_Order__c)) {
                mapWOIdToAssociatedCodesSize.put(objAssociatedCode.Work_Order__c, 0);
            }
            integer intAssociatedCodeNumber = mapWOIdToAssociatedCodesSize.get(objAssociatedCode.Work_Order__c);
            mapWOIdToAssociatedCodesSize.put(objAssociatedCode.Work_Order__c, intAssociatedCodeNumber+1);
        }

        return mapWOIdToAssociatedCodesSize;
    }
        
    
}