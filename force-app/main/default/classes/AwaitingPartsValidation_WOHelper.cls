/**
* @author Shivani Jain
* @date 7th May 2022
*
* @description DCP-54018 Helper Class for Work Order Trigger 
*              CMCP-16 Status check on PartsOrder on Before Update to throw error if no shipment PartsOrders found.
*/ 
public with sharing class AwaitingPartsValidation_WOHelper {
    public static List<SVMXC__Service_Order__c> lstWOWithShipmentPO = new List<SVMXC__Service_Order__c>(); //CMCM-5307

    /**
    *  @author Gladis 
    *  @description - CMCP-16 Status check on PartsOrder on Before Update to throw error if no shipment PartsOrders found. 
    *  @return: Void              
    **/
    public static void checkPartsOrderStatusChange(List<Sobject> records, Map<Id, SObject> oldRecords) {

        ilib_LogEvent.push(WorkOrders.LOG_TITLE + '.checkPartsOrderStatusChange()');

        Map<Id, SVMXC__Service_Order__c> objNewWorkOrder = new Map<Id, SVMXC__Service_Order__c>(); 
        Set<Id> setWorkOrderIds = new Set<Id>();
        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            SVMXC__Service_Order__c objOldWorkOrder = (SVMXC__Service_Order__c)(oldRecords.get(objWorkOrder.Id));
            objNewWorkOrder.put(objWorkOrder.Id,objWorkOrder);

            if(objWorkOrder.SVMXC__Order_Status__c != objOldWorkOrder.SVMXC__Order_Status__c && objWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_AWAITING_PARTS) {
                setWorkOrderIds.add(objWorkOrder.Id);
            }
        }
        if(!setWorkOrderIds.isEmpty()) {
            //CMCM-5307 - Add empty check for WO trigger Optimization 
            if(lstWOWithShipmentPO.isEmpty()  || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
                lstWOWithShipmentPO =  new WorkOrdersSelector().workOrdersWithShipmentPartsOrder(setWorkOrderIds);
            }
            for(SVMXC__Service_Order__c objWO : lstWOWithShipmentPO) {
                if(objWO.SVMXC__RMA_Shipment_Order__r.size() == 0) {
                    SVMXC__Service_Order__c record = (SVMXC__Service_Order__c)(objNewWorkOrder.get(objWO.Id));
                    record.addError(Label.WONoShipmentPartsOrders);
                }
            }
        }
        ilib_LogEvent.pop();
    }   
    
}
