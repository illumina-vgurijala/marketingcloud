/***************************************************************************************************************************************
* NAME   : WorkOrderService 
* DESCRIPTION  : Service class for Work Order object.
*                    
* @AUTHOR : Arquimidez Mora
* @DATE   : 10-08-2024  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Arquimidez Mora         08-Aug-2024         CMCM-9644: Method to delete rejected Order Line Items releted
* --------------------------------------------------------------------------------------------------------------------------------------
*/
public without sharing class WorkOrderService {

    public static final String STRING_WORK_ORDER_STATUS_CLOSED_DUPLICATE = 'Closed-Duplicate';
    public static final String STRING_WORK_ORDER_STATUS_CLOSED = 'Closed';
    public static final String STRING_WORK_ORDER_STATUS_COMPLETED = 'Completed';
    public static final String STRING_WORK_ORDER_STATUS_REOPEN_REUQUESTED = 'Reopen Requested';
    public static final String STRING_WO_ORDER_STATUS_REOPENED = 'Reopened';
    
    /*
    *  @AUTHOR: Arquimidez Mora
    *  @DESCRIPTION: Delete rejected Order Line Items related. CMCM-9644
    *  @RETURN:  void
    */ 
    public static void deleteOrderLineItemsRelated(List<SVMXC__Service_Order__c> records, Map<Id, SVMXC__Service_Order__c> mapOldRecords) {
        Set<Id> setWorkOrderIds = new Set<Id>();
        for(SVMXC__Service_Order__c objWorkOrder : records){
            SVMXC__Service_Order__c objOldWorkOrder = (mapOldRecords.containsKey(objWorkOrder.Id) ? mapOldRecords.get(objWorkOrder.Id) : null);
            if(
                objOldWorkOrder != null && objWorkOrder.SVMXC__Order_Status__c != objOldWorkOrder.SVMXC__Order_Status__c && 
                objWorkOrder.SVMXC__Order_Status__c != null && objWorkOrder.SVMXC__Order_Status__c != STRING_WORK_ORDER_STATUS_CLOSED && 
                objWorkOrder.SVMXC__Order_Status__c != STRING_WORK_ORDER_STATUS_COMPLETED && 
                objWorkOrder.SVMXC__Order_Status__c != STRING_WORK_ORDER_STATUS_REOPEN_REUQUESTED && 
                objWorkOrder.SVMXC__Order_Status__c != STRING_WO_ORDER_STATUS_REOPENED && 
                objWorkOrder.SVMXC__Order_Status__c != STRING_WORK_ORDER_STATUS_CLOSED_DUPLICATE
            ){
                setWorkOrderIds.add(objWorkOrder.Id);
            }
        }
        if(setWorkOrderIds.size() > 0){
            OrderLineItemService.deleteWorkOrderRelatedOrderLineItems(setWorkOrderIds);
        }
    }
}