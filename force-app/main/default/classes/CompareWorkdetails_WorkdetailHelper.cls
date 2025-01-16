/**
 * Class: CompareWorkdetails_WorkdetailHelper
 * Description: Queueable Class to compare work details.
 * Modification Log:
 *    ------------------------------------------------------------------------------------
 *    Developer                      Date                Description
 *    Nitin                          7 june 2022         CMSI-36 try catch in execute method 
 *    ------------------------------------------------------------------------------------ 
 */
public with sharing class CompareWorkdetails_WorkdetailHelper implements Queueable{
    //List < SVMXC__Service_Order_Line__c > lstWorkDetails = new List < SVMXC__Service_Order_Line__c >();
    Map<Id, AggregateLineItems_WorkDetailHelper.WorkDetailLineQuantityWrapper> workOrderIdToQuantityWrapper = new Map<Id, AggregateLineItems_WorkDetailHelper.WorkDetailLineQuantityWrapper>();
    public static Boolean catchException = false;
    /**
     * Constructor
     */
    public CompareWorkdetails_WorkdetailHelper(Map<Id, AggregateLineItems_WorkDetailHelper.WorkDetailLineQuantityWrapper> workOrderIdToQuantityWrapper){
        //this.lstWorkDetails = lstWorkDetails;
        this.workOrderIdToQuantityWrapper = workOrderIdToQuantityWrapper;
    }
    /*
     *  @AUTHOR:  Ritika Maheshwari
     *  @DESCRIPTION: Method to compare Estimate Line items and Debrief Line items for the work order. Accordingly set the flag on work order
     *  @PARAM :  Map<Id,WorkDetailLineQuantityWrapper>  - Map of Work Order versus a wrapper which would store quantity details
     *  @RETURN:  void
     */
    public void execute(QueueableContext qc){
        try{
        //DCP-37662 to Bypass for Account Maintainence and Presales Work Orders
        List < SVMXC__Service_Order__c > lstWorkOrders = new List < SVMXC__Service_Order__c > ();
        Map < id, SVMXC__Service_Order__c > idtoOldWorkOrder = new Map < id, SVMXC__Service_Order__c > ();
        if (workOrderIdToQuantityWrapper.size() > 0) {
            lstWorkOrders = new workordersSelector().selectWorkOrderId(workOrderIdToQuantityWrapper.keySet());
            if (!lstWorkOrders.isEmpty()) {
                IdtoOldWorkOrder.putall(lstWorkOrders);
            }
        }
        //End of DCP-37662 to Bypass for Account Maintainence and Presales Work Orders
        List < SVMXC__Service_Order__c > lstWorkOrdersToBeUpdated = new List < SVMXC__Service_Order__c > ();
        for (Id idWorkOrder: workOrderIdToQuantityWrapper.keySet()) {
            AggregateLineItems_WorkDetailHelper.WorkDetailLineQuantityWrapper workOrderQuantityWrapper = workOrderIdToQuantityWrapper.get(idWorkOrder);
            SVMXC__Service_Order__c objWorkOrder = new SVMXC__Service_Order__c(Id = idWorkOrder);
            compareEstimateDebriefProducts(workOrderQuantityWrapper, objWorkOrder);
            
            //Next check if there are any parts which are in debrief but not in estimates
            for (Id idProduct: workOrderQuantityWrapper.debriefProductIdToQuantity.keySet()) {
                if (!workOrderQuantityWrapper.estimateProductIdToQuantity.containskey(idProduct)) {
                    objWorkOrder.Estimate_Debrief_Mismatch__c = true;
                    break;
                }
            }
            compareEstimateDebriefActivities(workOrderQuantityWrapper, objWorkOrder);

            //DCP-37662 to Bypass for Account Maintainence and Presales Work Orders
            if (IdtoOldWorkOrder.containskey(idWorkOrder) && IdtoOldWorkOrder.get(idWorkOrder).Estimate_Debrief_Mismatch__c != objWorkOrder.Estimate_Debrief_Mismatch__c) {
                lstWorkOrdersToBeUpdated.add(objWorkOrder);
            }
        }

        if (!lstWorkOrdersToBeUpdated.isEmpty()) {
            update lstWorkOrdersToBeUpdated;
        }
        if(catchException == true){
            throw new AuraHandledException('throwing custom exceptions');
          }
    }
    catch(Exception e){
        ApexExceptions.emit('CompareWorkdetails_WorkdetailHelper',e,ilib_LogEvent.getWorkstream());
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        throw e;
    }
    }
    /**
     * Method:compareEstimateDebriefProducts
     * Description: Method to update estimate debrief mismatch.
     * Return: void
     */
    public static void compareEstimateDebriefProducts(AggregateLineItems_WorkDetailHelper.WorkDetailLineQuantityWrapper workOrderQuantityWrapper, SVMXC__Service_Order__c objWorkOrder){
        //Compare the products and thier respective quantity for a work order in estimate and debrief line items
        //First loop through the estimate line items and find mismatch in the debrief line items
        for (Id idProduct: workOrderQuantityWrapper.estimateProductIdToQuantity.keySet()) {
            if (workOrderQuantityWrapper.debriefProductIdToQuantity.containskey(idProduct)) {
                Decimal estiamteProductQuantity = workOrderQuantityWrapper.estimateProductIdToQuantity.get(idProduct);
                Decimal debriefProductQuantity = workOrderQuantityWrapper.debriefProductIdToQuantity.get(idProduct);
                if (debriefProductQuantity != estiamteProductQuantity) {
                    objWorkOrder.Estimate_Debrief_Mismatch__c = true;
                    break;
                } else {
                    objWorkOrder.Estimate_Debrief_Mismatch__c = false;
                }
            } else {
                objWorkOrder.Estimate_Debrief_Mismatch__c = true;
                break;
            }
        }
    }
    /**
     * Method:compareEstimateDebriefProducts
     * Description: Method to update estimate debrief mismatch.
     * Return: void
     */
    public static void compareEstimateDebriefActivities(AggregateLineItems_WorkDetailHelper.WorkDetailLineQuantityWrapper workOrderQuantityWrapper, SVMXC__Service_Order__c objWorkOrder){
        //Compare the activity and thier respective quantity for a work order in estimate and debrief line items
        //First loop through the estimate line items and find mismatch in the debrief line items
        for (String strActivityName: workOrderQuantityWrapper.estimateActivityTypeToQuantity.keySet()) {
            if (workOrderQuantityWrapper.debriefActivityTypeToQuantity.containskey(strActivityName)) {
                Decimal debriefEstiamtQuantity = workOrderQuantityWrapper.estimateActivityTypeToQuantity.get(strActivityName);
                Decimal debriefProductQuantity = workOrderQuantityWrapper.debriefActivityTypeToQuantity.get(strActivityName);
                if (debriefProductQuantity != debriefEstiamtQuantity) {
                    objWorkOrder.Estimate_Debrief_Mismatch__c = true;
                    break;
                } else {
                    objWorkOrder.Estimate_Debrief_Mismatch__c = false;
                }
            } else {
                objWorkOrder.Estimate_Debrief_Mismatch__c = true;
                break;
            }
        }
        //Next check if there is any activity which are in debrief but not in estimates
        for (String strActivityName: workOrderQuantityWrapper.debriefActivityTypeToQuantity.keySet()) {
            if (!workOrderQuantityWrapper.estimateActivityTypeToQuantity.containskey(strActivityName)) {
                objWorkOrder.Estimate_Debrief_Mismatch__c = true;
                break;
            }
        }
    }
}
