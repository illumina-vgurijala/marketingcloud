/*****************************************************************************************************************
 * Class Name: WOBatchQualification_WorkdetailHelper
 * 
 * Description: Queueable class to update work orders which are confirmed for batch.
 * 
 * Author: Prashanth
 * 
 * Date: 07-Dec-2021
 * 
 * Notification Log:
 * -----------------------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -----------------------------------------------------------------------------------------------------------------------------
 * Prashanth                  07-12-2021                       Queueable class to update work orders which are confirmed for batch
 * 
 ********************************************************************************************************************************/
public with sharing class WOBatchQualification_WorkdetailHelper implements Queueable{
    set < Id > setQualifiedWorkOrdersId = new Set<Id>();
	public static Boolean catchException = false;
    /**
     * constructor
     */
    public WOBatchQualification_WorkdetailHelper(set < Id > setQualifiedWorkOrdersId) {
        this.setQualifiedWorkOrdersId = setQualifiedWorkOrdersId;
    }
    /*
     *  @AUTHOR:  Vaibhav 
     *  @DESCRIPTION: DCP-33466 - Method to update Work Orders to qualify for batch processing.
     *  @MODIFICATION : CMSI-38 Added Try Catch mechanism Emitting exception to ApexExceptions class with Workstream.
     *  @PARAM : set<Id> setWorkOrdersIds
     *  @RETURN:  void
     */
    public void execute(QueueableContext qc){ 
        try{
        if(!setQualifiedWorkOrdersId.isEmpty()){
            updateWorkOrdersForBatchQualification(setQualifiedWorkOrdersId);
			if(catchException == true){
			throw new AuraHandledException('Throwing Custom Exception');
			}
        }
        }catch(Exception e){ 
            //CMSI-38 Emitting exception to ApexExceptions class with Workstream.
            ApexExceptions.emit('WOBatchQualification_WorkdetailHelper',e,ilib_LogEvent.getWorkstream());
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            throw e;
        }
    }
    /*
     *  @AUTHOR:  Vaibhav 
     *  @DESCRIPTION: DCP-33466 - Method to update Work Orders to qualify for batch processing.
     *  @PARAM : set<Id> setWorkOrdersIds
     *  @RETURN:  void
     */
    public static void updateWorkOrdersForBatchQualification(set < Id > setQualifiedWorkOrdersId) {

        Map < Id, SVMXC__Service_Order__c > workOrderIdToWorkOrder = new Map < Id, SVMXC__Service_Order__c > (new WorkOrdersSelector().selectWorkOrders(setQualifiedWorkOrdersId));
        Map < Id, SVMXC__Service_Order_Line__c > mapworkdetailId = new Map < Id, SVMXC__Service_Order_Line__c > (new WorkDetailsSelector().selectNonCanceledWorkDetailsForWorkOrderId(setQualifiedWorkOrdersId));
        List < SVMXC__Service_Order__c > lstWorkOrders = new List < SVMXC__Service_Order__c > ();
        if (!workOrderIdToWorkOrder.isEmpty() && !mapworkdetailId.isEmpty()) {
            for (Id workOrderId: workOrderIdToWorkOrder.keyset()) {
                if (!workOrderIdToWorkOrder.get(workOrderId).Qualified_for_Batched_Sync_to_ERP__c) {
                    lstWorkOrders.add(new SVMXC__Service_Order__c(Id = workOrderId, Qualified_for_Batched_Sync_to_ERP__c = true));
                }
            }
        }
        if (mapworkdetailId.isEmpty() && !system.Test.isRunningTest()) {
            for (id workOrderId: setQualifiedWorkOrdersId) {
                lstWorkOrders.add(new SVMXC__Service_Order__c(Id = workOrderId, Qualified_for_Batched_Sync_to_ERP__c = false));
            }
        }
        if (lstWorkOrders != null && !lstWorkOrders.isEmpty()) {
            update lstWorkOrders;
        }
    }
}
