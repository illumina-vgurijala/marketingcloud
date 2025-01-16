/**
* @author Shivani Jain
* @date 8th Nov 2022
*
* @description DCP-54018 Queueable Class for Work Order trigger to Update Sold To
*/ 
public class RecalculateOperabilityQueueable_WOHelper implements Queueable {

    Set<Id> setChildWorkOrderIds = new Set<Id>();

    /*******************************************************************************************************
    * @description Constructor
    * @param setChildWorkOrderIds Set<Id>
    * @return
    */
    public RecalculateOperabilityQueueable_WOHelper(Set<Id> setChildWorkOrderIds) {
        this.setChildWorkOrderIds = setChildWorkOrderIds;
    }

    /*******************************************************************************************************
    * @description Execute method
    * @param QueueableContext qc
    * @return
    */
    public void execute(QueueableContext qc) { 
        try {
            reCalculateConfirmOperabilityWO(setChildWorkOrderIds);
        } catch(Exception ex) {
            ApexExceptions.emit('RecalculateOperabilityQueueable_WOHelper.'+ 'reCalculateConfirmOperabilityWO', ex);
            throw ex;
        }
    }

    /*
    *  @author: Rucha Dalvi
    *  @description: DCP-46273 To recalculate confirmed operability for child Work Orders where Confirm Operability is changed
    *  @param : Set of child work orders
    *  @param : List of Child work orders 
    *  @return:  void
    *  @example
    */ 
    public static void reCalculateConfirmOperabilityWO(Set<Id> setChildWorkOrderIds) {
        if(!setChildWorkOrderIds.isEmpty()) {
            Map<Id,String> workOrderIdToConfirmOpStringMap = new Map<Id,String>();
            List<SVMXC__Service_Order__c> lstWOToUpdate = new List<SVMXC__Service_Order__c>();
            ilib_LogEvent.push(WorkOrders.LOG_TITLE + '.reCalculateConfirmOperabilityWO()');
            workOrderIdToConfirmOpStringMap = UpdateConfirmOperability_WDHelper.calculateConfirmOperabilityWO(setChildWorkOrderIds);

            for(Id objWOId : workOrderIdToConfirmOpStringMap.keyset()){
                SVMXC__Service_Order__c workOrder = new SVMXC__Service_Order__c(Id = objWOId , Confirmed_Operability__c = workOrderIdToConfirmOpStringMap.get(objWOId));
                lstWOToUpdate.add(workOrder);
                ilib_LogEvent.message('46273 Recalculate Confirm Operability '+workOrder.Confirmed_Operability__c);
            }  

            if(!lstWOToUpdate.isEmpty()) {
                update lstWOToUpdate;
            }     
        }
        ilib_LogEvent.pop();
    }


}

