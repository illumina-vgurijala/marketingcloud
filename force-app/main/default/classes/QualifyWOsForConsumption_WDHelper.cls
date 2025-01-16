/*****************************************************************************************************************
 * Class Name: QualifyWOsForConsumption_WDHelper
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
public with sharing class QualifyWOsForConsumption_WDHelper implements Queueable{
    set < Id > setQualifiedWorkOrdersId = new Set<Id>();
	public static Boolean catchException = false;
    /**
     * Constructor
     */
    public QualifyWOsForConsumption_WDHelper(set < Id > setQualifiedWorkOrdersId) {
        this.setQualifiedWorkOrdersId = setQualifiedWorkOrdersId;
    }
    /*
     *  @AUTHOR:  Vaibhav 
     *  @DESCRIPTION: DCP-33466 - Method to update Work Orders to qualify for batch processing.
     *  @PARAM : set<Id> setWorkOrdersIds
     *  @MODIFICATIONS : CMSI-38 Added try catch mechanism and emitting exception to ApexExceptions class with Workstream.
     *  @RETURN:  void
     */
    public void execute(QueueableContext qc){
        try{
        if(!setQualifiedWorkOrdersId.isEmpty()){
            qualifyWorkOrdersForConsumptionThroughVanstock(setQualifiedWorkOrdersId);
        }
		if(catchException == true){
			throw new AuraHandledException('Throwing Custom Exception');
			}
        }catch(Exception e){
            //CMSI-38 emitting exceptions to ApexExceptions class with Workstream.
            ApexExceptions.emit('QualifyWOsForConsumption_WDHelper',e,ilib_LogEvent.getWorkstream());
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            throw e;
        }
    }
    /*
     *  @DESCRIPTION: DCP-37399 - Qualify Work Order For Part Consumtion using vanstock code.
     *  @PARAM : set<Id> setWorkOrdersIds
     *  @RETURN:  void
     */
    public static void qualifyWorkOrdersForConsumptionThroughVanstock(set < Id > setQualifiedWorkOrdersId) {

        Map < Id, SVMXC__Service_Order__c > workOrderIdToWorkOrder = new Map < Id, SVMXC__Service_Order__c > (new WorkOrdersSelector().selectWorkOrders(setQualifiedWorkOrdersId));
        List < SVMXC__Service_Order__c > lstWorkOrders = new List < SVMXC__Service_Order__c > ();
        if (workOrderIdToWorkOrder != null && !workOrderIdToWorkOrder.isEmpty()) {
            for (Id workOrderId: workOrderIdToWorkOrder.keyset()) {
                if (!workOrderIdToWorkOrder.get(workOrderId).Parts_Consumed_By_SAP__c) {
                    lstWorkOrders.add(new SVMXC__Service_Order__c(Id = workOrderId, Parts_Consumed_By_SAP__c = true));
                }
            }
        }

        if (lstWorkOrders != null && !lstWorkOrders.isEmpty()) {
            update lstWorkOrders;
        }
    }
}
