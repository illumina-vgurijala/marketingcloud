/*****************************************************************************************************************
 * Class Name: UpdateConfirmOperability_WDHelper
 * 
 * Description: Queueable class to update confirm operability.
 * 
 * Author: Prashanth
 * 
 * Date: 07-Dec-2021
 * 
 * Notification Log:
 * -----------------------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -----------------------------------------------------------------------------------------------------------------------------
 * Prashanth                  07-12-2021                       Queueable class to update confirm operability.
 * 
 ********************************************************************************************************************************/
public with sharing class UpdateConfirmOperability_WDHelper implements Queueable{
    List < SVMXC__Service_Order_Line__c > records = new List<SVMXC__Service_Order_Line__c>();
    Map < Id, SObject > mapOld = new Map<Id, sObject>(); 
    Map < Id, SObject > mapNew = new Map<Id, sObject>();
	public static Boolean catchException = false;
    /**
     * constructor
     */
    public UpdateConfirmOperability_WDHelper(List < SVMXC__Service_Order_Line__c > records, Map < Id, SObject > mapOld, Map < Id, SObject > mapNew) {
        this.records = records;
        this.mapOld = mapOld;
        this.mapNew = mapNew;
    }
    /* 
     * @author : Rucha Dalvi
     * @description : DCP-46273 - Method to update Confirm Operability on WO for relocation work order type
     * @param : List of Work Details
     * @param : oldMap records
     * @return : 
     * @example :
     */
    public void execute(QueueableContext qc){
        try{
        updateConfirmOperabilityForRelocationWO(records, mapOld, mapNew);
		if(catchException == true){
			throw new AuraHandledException('Throwing Custom Exception');
		}
        }catch(Exception e){
            ApexExceptions.emit('UpdateConfirmOperability_WDHelper',e,ilib_LogEvent.getWorkstream());
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            throw e;
        }
        
    }
     /* 
     * @author : Rucha Dalvi
     * @description : DCP-46273 - Method to update Confirm Operability on WO for relocation work order type
     * @param : List of Work Details
     * @param : oldMap records
     * @return : 
     * @example :
     */
    public static void updateConfirmOperabilityForRelocationWO(List < SVMXC__Service_Order_Line__c > records, Map < Id, SObject > mapOld, Map < Id, SObject > mapNew) {

        Map < Id, String > serviceOrderIdToStringMap = new Map < Id, String > ();
        Set < Id > setWorkOrderIds = new Set < Id > ();

        for (SVMXC__Service_Order_Line__c objWorkDetail: records) {
            //creating instance of Old and New Work Detail
            SVMXC__Service_Order_Line__c objOldWorkDetail = null;
            SVMXC__Service_Order_Line__c objNewWorkDetail = null;
            if (mapOld != null ) {
                objOldWorkDetail = (SVMXC__Service_Order_Line__c)(mapOld.get(objWorkDetail.Id));
                objNewWorkDetail = (SVMXC__Service_Order_Line__c)(mapNew.get(objWorkDetail.Id));
            }
            //DCP-50079 Removing logic for Activity Type Check
            //DCP-50157 Added check for work Order Status
            if (objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR && !Workdetails.SET_WORK_ORDER_STATUS.contains(objWorkDetail.SVMXC__Service_Order__r.SVMXC__Order_Status__c)) {

                if ((mapOld == null && objWorkDetail.SVMXC__Line_Status__c != Workdetails.STRING_WORK_DETAIL_LINE_STATUS_CANCELED) || (mapOld != null && ((objNewWorkDetail.SVMXC__Line_Status__c != objOldWorkDetail.SVMXC__Line_Status__c && objNewWorkDetail.SVMXC__Line_Status__c == Workdetails.STRING_WORK_DETAIL_LINE_STATUS_CANCELED) || objNewWorkDetail.SVMXC__Activity_Type__c != objOldWorkDetail.SVMXC__Activity_Type__c))) {
                    setWorkOrderIds.add(objWorkDetail.SVMXC__Service_Order__c);
                }

            }
        }
        system.debug('46273 setWorkOrderIds :' + setWorkOrderIds);
        serviceOrderIdToStringMap = calculateConfirmOperabilityWO(setWorkOrderIds);
        //Update the Work Orders fetched.
        if (!serviceOrderIdToStringMap.isEmpty()) {
            updateWorkOrderForOperability(serviceOrderIdToStringMap);
        }

    }
    /*
     * @author : Rucha Dalvi
     * @description : DCP-46273 To update confirm operability on Work Orders
     * @param : Map of work order id and final confirm operability string to update
     * @return : void
     * @example : 
     */
    public static void updateWorkOrderForOperability(Map < Id, String > serviceOrderIdToStringMap) {
        List < SVMXC__Service_Order__c > lstUpdateSO = new List < SVMXC__Service_Order__c > ();
        for (SVMXC__Service_Order__c so: new WorkOrdersSelector().selectWorkOrders(serviceOrderIdToStringMap.keyset())) {
            //Adding work order to update only if confirmed operability is changed
            if (serviceOrderIdToStringMap.containsKey(so.Id) && so.Confirmed_Operability__c != serviceOrderIdToStringMap.get(so.Id)) {
                so.Confirmed_Operability__c = serviceOrderIdToStringMap.get(so.Id);
                //DCP-50421 Fix
                if (so.Customer_Requested_Not_To_Re_Install__c == true && so.Total_Labor_Lines_For_Operability__c > 0) {
                    so.Customer_Requested_Not_To_Re_Install__c = false;
                }
                lstUpdateSO.add(so);
            }
        }
        if (!lstUpdateSO.isEmpty()) {
            update lstUpdateSO;
        }
    }
    /*
     * @author : Rucha Dalvi
     * @description : DCP-46273 - Method to calculate Confirm Operability on WO
     * @param : setWorkOrderIds
     * @return : Map of Work Order and Confirm Operability String value
     * @example :
     */
    public static Map < Id, String > calculateConfirmOperabilityWO(Set < Id > setWorkOrderIds) {

        Map < Id, String > serviceOrderIdToStringMap = new Map < Id, String > ();
        Map < Id, Set < String >> woIdtoSetConfirmOperabilityMap = new Map < Id, Set < String >> ();

        woIdtoSetConfirmOperabilityMap = calculateDirectOperability(setWorkOrderIds);

        system.debug('46273 : woIdtoSetConfirmOperabilityMap' + woIdtoSetConfirmOperabilityMap);
        for (SVMXC__Service_Order__c objWO: new WorkOrdersSelector().selectWorkOrders(setWorkOrderIds)) {
            String strWOConfirmOperability = '';
            Set < String > woOperability = new Set < String > ();
            if (woIdtoSetConfirmOperabilityMap.containsKey(objWO.Id)) {
                woOperability = woIdtoSetConfirmOperabilityMap.get(objWo.Id);
            }
            if (objWO.Related_WO_to_Confirm_Operability__c != null && String.isNotBlank(objWO.Related_WO_to_Confirm_Operability__r.Confirmed_Operability__c)) {
                woOperability.addAll(objWO.Related_WO_to_Confirm_Operability__r.Confirmed_Operability__c.split(';'));
            }
            if (!woOperability.isEmpty()) {
                strWOConfirmOperability = String.join(new List < String > (woOperability), ';');
            }
            serviceOrderIdToStringMap.put(objWO.Id, strWOConfirmOperability);
        }
        system.debug('46273 Calculated serviceOrderIdToStringMap :' + serviceOrderIdToStringMap);
        return serviceOrderIdToStringMap;
    }
    /*
     * @author : Rucha Dalvi
     * @description : DCP-46273 - Method to calculate Confirm Operability on WO
     * @param : setWorkOrderIds
     * @return : Map of Work Order and Confirm Operability String value
     * @example :
     */
    public static Map < Id, set < String >> calculateDirectOperability(Set < Id > setWorkOrderIds) {
        Map < Id, Set < String >> woIdtoSetConfirmOperabilityMap = new Map < Id, Set < String >> ();
        for (SVMXC__Service_Order_Line__c objWD: new WorkDetailsSelector().selectWorkDetailsForWorkOrderId(setWorkOrderIds)) {
            if (objWD.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR && Workdetails.SET_WORKDETAIL_ACTIVITY_TYPES.contains(objWD.SVMXC__Activity_Type__c) && objWD.SVMXC__Line_Status__c != Workdetails.STRING_WORK_DETAIL_LINE_STATUS_CANCELED) {

                if (!woIdtoSetConfirmOperabilityMap.containsKey(objWD.SVMXC__Service_Order__c)) {
                    woIdtoSetConfirmOperabilityMap.put(objWD.SVMXC__Service_Order__c, new Set < String > ());
                }
                woIdtoSetConfirmOperabilityMap.get(objWD.SVMXC__Service_Order__c).add(objWD.SVMXC__Activity_Type__c);
            }
        }
        return woIdtoSetConfirmOperabilityMap;
    }
}
