/**
* @author Shivani Jain
* @date 28 Sep 2021
* @description DCP-47698 Service Class to run logic related to Work Orders from Sales Objects
*/
public with sharing class WorkOrdersService {

    /*******************************************************************************************************
    * @description DCP-47698 Sync the acceptance code to the Install Work Order
    * @param oliNumberToMaterialGroup5Map Map of Order Line Item ERP Number to Material Group 5 from Order Line Item
    * @return
    * @example
    */
    public static void syncAcceptanceCodeInstallWO(Map<String, String> oliNumberToMaterialGroup5Map) {
        List<SVMXC__Service_Order__c> lstWOToUpdate = new WorkOrdersSelector()
            .selectWorkOrderSpecificOrderTypeOLI(oliNumberToMaterialGroup5Map.keyset(), Label.WorkOrderTypeInstallation);
        if(!lstWOToUpdate.isEmpty()) {
            for(SVMXC__Service_Order__c workOrder: lstWOToUpdate) {
                workOrder.Acceptance_Code__c = oliNumberToMaterialGroup5Map.get(workOrder.ERP_Order_Line_Number__c) ;
            }
            update lstWOToUpdate;
        }
    }

}
