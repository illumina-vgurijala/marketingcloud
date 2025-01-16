/**
* @author Shivani Jain
* @date 7th May 2022
*
* @description DCP-54018 Helper Class for Work Order Trigger to run logic related to confirmed operability 
*/ 
public with sharing class ConfirmedOperability_WOHelper {

    public static Map<Id,SVMXC__Service_Order__c> mapParentWO = new Map<Id,SVMXC__Service_Order__c>(); //CMCM-5307

    /*
    *  @author: Rucha Dalvi
    *  @description: DCP-46273 To populate confirmed operability for Work Orders having Related WO to Confirm Operability
    *  @param : List of Sobjects
    *  @return:  void
    *  @example
    */ 
    public static void populateConfirmOperabilityForRelatedWO(List<SObject> records, Map<Id, SObject> oldRecords) {

        Map<Id,SVMXC__Service_Order__c> mapWorkOrderId = new Map<Id,SVMXC__Service_Order__c>();
        set<Id> setParentWOId = new set<Id>();
        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            SVMXC__Service_Order__c objOldWorkOrder = (SVMXC__Service_Order__c)(oldRecords.get(objWorkOrder.Id));
            ilib_LogEvent.message('46273 Customer Requested Not ReInstall'+objWorkOrder.Customer_Requested_Not_To_Re_Install__c);
            ilib_LogEvent.message('46273 Related WO'+objWorkOrder.Related_WO_to_Confirm_Operability__c);
            ilib_LogEvent.message(' 46273 Confirm Operability'+objWorkOrder.Confirmed_Operability__c);
            //DCP-50044 Fix to update Related WO to COnfirm Operability only when customer requested checkbox is blank
            //GIS Review Comment to add check for Relocation Orders
            if(objWorkOrder.SVMXC__Order_Type__c == WorkOrders.STRING_WORK_ORDER_ORDER_TYPE_RELOCATION) {
                //DCP-50399 : Added check for Total_Labor_Lines_For_Operability__c 
                if(objWorkOrder.Customer_Requested_Not_To_Re_Install__c == true && objWorkOrder.Total_Labor_Lines_For_Operability__c == 0) {
                    objWorkOrder.Related_WO_to_Confirm_Operability__c = null;
                    objWorkOrder.Confirmed_Operability__c = '';
                }
                else if(!objWorkOrder.Customer_Requested_Not_To_Re_Install__c && objWorkOrder.Related_WO_to_Confirm_Operability__c != objOldWorkOrder.Related_WO_to_Confirm_Operability__c ) {
                    mapWorkOrderId.put(objWorkOrder.Id , objWorkOrder);
                    setParentWOId.add(objWorkOrder.Related_WO_to_Confirm_Operability__c);
                }
            }
        }

        if(!mapWorkOrderId.isEmpty()) {
            Map<Id,set<String>> mapDirectOperability = UpdateConfirmOperability_WDHelper.calculateDirectOperability(mapWorkOrderId.keyset());
            //CMCM-5307 - Add empty check for WO trigger Optimization 
            if(mapParentWO.isEmpty()  || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
                mapParentWO = new Map<Id,SVMXC__Service_Order__c>(new WorkOrdersSelector().selectWorkOrders(setParentWOId));
            }

            for(SVMXC__Service_Order__c objWorkOrder : mapWorkOrderId.Values()) {
                set<String> setOperability = new set<String>();
                if(mapDirectOperability.containsKey(objWorkOrder.Id)) {
                    setOperability.addAll( mapDirectOperability.get(objWorkOrder.Id));
                }
                
                if(mapParentWO.containsKey(objWorkOrder.Related_WO_to_Confirm_Operability__c) && mapParentWO.get(objWorkOrder.Related_WO_to_Confirm_Operability__c).Confirmed_Operability__c != Null ) {
                    setOperability.addAll( mapParentWO.get(objWorkOrder.Related_WO_to_Confirm_Operability__c).Confirmed_Operability__c.split(';') );
                }
                objWorkOrder.Confirmed_Operability__c = String.join(new List<String>(setOperability),';');
                ilib_LogEvent.message('46273 Final Confirm Operability '+objWorkOrder.Confirmed_Operability__c);
            }
            
        }
    }  
}
