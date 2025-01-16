/**
* @author Shivani Jain
* @date 31st August 2022
*
* @description DCP-43629 Helper Class for Parts Order Trigger to run queueable 
*                        logic on After Insert & After Update event on Work Order 
*/ 
public with sharing class AsyncCalls_POHelper {

    private static final String LOG_TITLE = 'AsyncCalls_POHelper';
    private static final String ORDER_TYPE_SHIPMENT = 'Shipment';
    
    /*******************************************************************************************************
    * @description  DCP-43629 used to call all async methods in afterupdate event
    * @param records Parts Order Lines List
    * @return void
    */
    public static void asyncCallsOnPOAfterUpdate(List<SVMXC__RMA_Shipment_Order__c> records, Map<Id, SVMXC__RMA_Shipment_Order__c> oldRecords,  ilib_Queueablethread queueableThreadAfterUpdate) {
        ilib_LogEvent.push(LOG_TITLE + 'asyncCallsOnPOAfterUpdate');
        ilib_LogEvent.message('records :'+records);

        Set<Id> setPOIds = new Set<Id>();
        Map<Id, Boolean> poIdToChangeMap = new Map<Id, Boolean>(); // map to store change if Part Order Account changed but Sold To is same
        
        for(SVMXC__RMA_Shipment_Order__c partsOrder : records) {
            SVMXC__RMA_Shipment_Order__c oldPartsOrder = (SVMXC__RMA_Shipment_Order__c) (oldRecords.get(partsOrder.Id));

            Boolean runAccHierarchyLogic = oldPartsOrder.Shipping_Location__c != partsOrder.Shipping_Location__c 
                || oldPartsOrder.Shipping_Country__c != partsOrder.Shipping_Country__c || oldPartsOrder.SVMXC__Company__c != partsOrder.SVMXC__Company__c;

            if((runAccHierarchyLogic || oldPartsOrder.Sold_To__c != partsOrder.Sold_To__c) && ORDER_TYPE_SHIPMENT.equalsIgnoreCase(partsOrder.SVMXC__Order_Type__c) 
                    && !SoldToQueueable_POHelper.ranOnce) {
                
                setPOIds.add(partsOrder.Id);   
                  
                if(runAccHierarchyLogic) {
                    poIdToChangeMap.put(partsOrder.Id, true);
                }       
            }
        }

        if(!setPOIds.isEmpty()) {
            SoldToQueueable_POHelper.ranOnce = true;
            queueableThreadAfterUpdate.logandQueue(new SoldToQueueable_POHelper(setPOIds, poIdToChangeMap),'SoldToQueueable_POHelper','execute');
        }

        ilib_LogEvent.pop();
        
    }

    /*******************************************************************************************************
    * @description  DCP-43629 used to call all async methods in afterinsert event
    * @param records Parts Order Lines List
    * @return void
    */
    public static void asyncCallsOnPOAfterInsert(List<Sobject> records, ilib_Queueablethread queueableThread) {
        ilib_LogEvent.push(LOG_TITLE + 'asyncCallsOnPOAfterInsert');
        ilib_LogEvent.message('records :'+records);
        
        Map<Id,String> workOrderIdToPOStatus = new Map<Id,String>();
        Set<Id> setPOIds = new Set<Id>();

        for(SVMXC__RMA_Shipment_Order__c objPartOrder : (List<SVMXC__RMA_Shipment_Order__c>)records) {
            if(objPartOrder.SVMXC__Service_Order__c != null) {
                workOrderIdToPOStatus.put(objPartOrder.SVMXC__Service_Order__c, PartsOrders.STRING_PART_ORDER_STATUS_INPROGRESS);
            }
            if(ORDER_TYPE_SHIPMENT.equalsIgnoreCase(objPartOrder.SVMXC__Order_Type__c)) {
                setPOIds.add(objPartOrder.Id);
            }
        }

        if(!workOrderIdToPOStatus.IsEmpty()) {
           queueableThread.logandQueue(new PartsOrderQueueable(workOrderIdToPOStatus, 'updateWorkOrderStatus',null),'PartsOrderQueueable','updateWorkOrderStatus');
        }
        
        if(!setPOIds.isEmpty()) {
            SoldToQueueable_POHelper.ranOnce = true;
            queueableThread.logandQueue(new SoldToQueueable_POHelper(setPOIds, null),'SoldToQueueable_POHelper','execute');
        }

        ilib_LogEvent.pop();

    }


}
