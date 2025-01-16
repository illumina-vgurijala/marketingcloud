/**
 *    @author Ritika
 *    @date   
 *    @description : Class for auto closing work orders
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                  Description
 *    Ritika                     26-09-2022           Moving the auto closure logic of work orders from queuable to platform event
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class AutoCloseWOHelper implements ilib_AdminOperationLogicInterface{
    private static final String LOG_TITLE = 'AutoCloseWOHelper';
    
     /**
     *  @author       : Ritika
     *  @description  : Auto close work orders using platform event (this is to ensure that any profile not )
     *  @return       : void
     */
    public static void doBusinessLogic(List<Id> lstWorkOrderIds){
        ilib_LogEvent.push(LOG_TITLE + '.execute()');
        try{
            Set<Id> setOfWorkOrderIds = new Set<Id>();
            for(Id woId: lstWorkOrderIds){
                setOfWorkOrderIds.add(woId);
            }
            Map<Id,SVMXC__Service_Order__c> workOrderIdToWorkOrderObjMap = new Map<Id,SVMXC__Service_Order__c>(new WorkOrdersSelector().selectWorkOrders(setOfWorkOrderIds)); //WO's received from PB
            List<SVMXC__Service_Order__c> lstWorkOrdersToBeUpdated = new List<SVMXC__Service_Order__c>(); //list of WO's to be closed.
            
            for(Id workOrderId : workOrderIdToWorkOrderObjMap.keyset()) {
            //INC0344951 - remove (new WorkDetailsSelector().selectOpenLaborWorkDetailsByWorkOrderId()).size() == 0 and use Total_Open_Work_Details__c == 0 to check not only open labor but also Parts line before closing a WO
                if(workOrderIdToWorkOrderObjMap.get(workOrderId).Total_Open_Work_Details__c == 0) {
                    //mark the status of that WO as closed when Integration status = "Success" Or "Not Required"
                    if(workOrderIdToWorkOrderObjMap.get(workOrderId).Integration_Status__c == WorkOrders.STRING_WORK_ORDER_INTEGRATION_STATUS_NOT_REQUIRED ||
                        workOrderIdToWorkOrderObjMap.get(workOrderId).Integration_Status__c == WorkOrders.STRING_WORK_ORDER_INTEGRATION_STATUS) {
                        //final list of WO's to be updated as closed.
                        lstWorkOrdersToBeUpdated.add(new SVMXC__Service_Order__c(Id = workOrderId, SVMXC__Order_Status__c = WorkOrders.STRING_WORK_ORDER_STATUS_CLOSED));    
                    }
                }    
            }
            
            if(!lstWorkOrdersToBeUpdated.isEmpty()) {
                update lstWorkOrdersToBeUpdated;
            }
        }catch(Exception e){
            ApexExceptions.emit(LOG_TITLE,e);
        }
        ilib_LogEvent.pop();
		ilib_LogEvent.emit();
    }
    
}