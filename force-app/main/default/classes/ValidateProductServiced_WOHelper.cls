/*
*    @author Romi Taskar
*    @date   15-06-2022
*    @description    Class to restrict Dispatcher if the Product Serviced's Product and WO's Product doesnt match
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer              Date                    Description
*    Romi                 15-June-2022             Initial Version
*    Nancy                13-Feb-2024               CMCM-5307 Work Order Trigger Query Optimization
*    ------------------------------------------------------------------------------------
*/
public with sharing class ValidateProductServiced_WOHelper {

    public static final String DISPATCHER_PERMISSION_SET = 'SS_Service_Dispatch_Console';
    public static Boolean hasPermission = false;
    private static Boolean hasConfirmAssigneeLogicRun = false;

    public static List<SVMXC__Service_Group_Product__c> productServicedRecs = new List<SVMXC__Service_Group_Product__c>(); //CMCM-5307

    /**
    *  @author Romi Taskar 
    *  @description - 53211 - To restrict Dispatcher if the Product Serviced's Product and WO's Product doesnt match
    *  @return: Void              
    **/
    public static void populateWorkOrdersToValidate(List<Sobject> records, Map<Id, SObject> oldRecords) {

        ilib_LogEvent.push(WorkOrders.LOG_TITLE + '.populateWorkOrdersToValidate()');

        Map<Id, SVMXC__Service_Order__c> workOrderMap = new Map<Id, SVMXC__Service_Order__c>(); 
        Set<Id> technicianIds = new Set<Id>();
        Set<Id> productIds = new Set<Id>();
        hasPermission = FeatureManagement.checkPermission(DISPATCHER_PERMISSION_SET);

        if(!hasPermission || hasConfirmAssigneeLogicRun) {
            ilib_LogEvent.pop();
            return;
        }

        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            SVMXC__Service_Order__c objOldWorkOrder = (SVMXC__Service_Order__c)(oldRecords.get(objWorkOrder.Id));

            if(!objWorkOrder.Confirm_Assignee__c && objWorkOrder.SVMXC__Group_Member__c != objOldWorkOrder.SVMXC__Group_Member__c 
            && objWorkOrder.SVMXC__Group_Member__c != null && !objOldWorkOrder.SVMXC__Locked_By_DC__c && objWorkOrder.SVMXC__Locked_By_DC__c) {
                workOrderMap.put(objWorkOrder.Id, objWorkOrder);
                technicianIds.add(objWorkOrder.SVMXC__Group_Member__c);
                productIds.add(objWorkOrder.SVMXC__Product__c);
            }

            if(objWorkOrder.Confirm_Assignee__c) {
                objWorkOrder.Confirm_Assignee__c = false;
                hasConfirmAssigneeLogicRun = true;
            }
            
        }

        throwErrorOnDC(workOrderMap, technicianIds, productIds);

        ilib_LogEvent.pop();
    } 

    /*******************************************************************************************************
    * @param workOrderMap Work Order Record
    * @param technicianIds Field Support record
    * @param productIds product set
    * @return void 
    */
    public static void throwErrorOnDC(Map<Id, SVMXC__Service_Order__c> workOrderMap,set<Id> technicianIds, Set<Id> productIds) {
        if(!workOrderMap.isEmpty()) {
            //CMCM-5307 - Add empty check for WO trigger Optimization
            if (productServicedRecs.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
                productServicedRecs = new ProductServicedSelector().selectProductServicedRecs(technicianIds, productIds);
            }
            Map<String, Boolean> productTechnicianMap = new Map<String, Boolean>();

            for(SVMXC__Service_Group_Product__c psRecord : productServicedRecs) {
                productTechnicianMap.put(psRecord.SVMXC__Group_Member__c + '_' + psRecord.SVMXC__Product__c,true);
            }
            
            for(SVMXC__Service_Order__c woRec : workOrderMap.values()) {
                if(!productTechnicianMap.containsKey(woRec.SVMXC__Group_Member__c + '_' + woRec.SVMXC__Product__c )) {
                    woRec.addError(Label.Check_Confirm_Assignee_ErrorMsg);
                }
            }

        }         
    }  

}