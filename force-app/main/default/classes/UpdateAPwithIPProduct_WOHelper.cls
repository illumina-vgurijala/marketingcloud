/**
*    @author Vishal
*    @date   17 Dec 2024
*    @description    Helper class for updating Associated Products on Work Orders
*    @test class TestUpdateAPwithIPProduct_WOHelper
*/
public with sharing class UpdateAPwithIPProduct_WOHelper {
    
    public static final String LOG_TITLE = 'UpdateAPwithIPProduct_WOHelper';
    public static List<Associated_Product__c> associatedProductsOnWORecordsList = new List<Associated_Product__c>();
    
    /**
    * Method: isCaseIPProdchanged
    * Handles the scenario for Work Order updates and updates Associated Product records.
    * @param newWOList List of updated Work Orders (Trigger.new)
    * @param oldWOMap Map of old Work Orders (Trigger.oldMap)
    */
    public static void isCaseIPProdchanged(List<SVMXC__Service_Order__c> newWOList, Map<Id, SVMXC__Service_Order__c> oldWOMap) {
        ilib_LogEvent.push(LOG_TITLE + '.isCaseIPProdchanged()');
        Map<Id, SVMXC__Service_Order__c> woMap = new Map<Id, SVMXC__Service_Order__c>();
        
        try {
            // Collect Work Orders meeting the condition
            if(!newWOList.isEmpty() && WorkOrders.loggedInUserProfileName == System.Label.Integration_Service_SNAP_Profile){
                for (SVMXC__Service_Order__c newWO : newWOList) {
                    SVMXC__Service_Order__c oldWO = oldWOMap.get(newWO.Id);
                    if ((oldWO.SVMXC__Component__c == null || String.isBlank(oldWO.SVMXC__Component__c)) 
                    && newWO.SVMXC__Order_Type__c == System.Label.WorkOrderTypeInstallation) {
                        woMap.put(newWO.Id, newWO);
                    }
                }
            }       
            // Query Associated_Product__c records created by SNAP Sales Integration user
            if (associatedProductsOnWORecordsList.isEmpty() && !woMap.isEmpty()){
                associatedProductsOnWORecordsList = new AssociatedProductSelector().selectAPonWO(woMap.keySet());
            }           
            List<Associated_Product__c> apRecordsToUpdate = new List<Associated_Product__c>();
            for (Associated_Product__c ap : associatedProductsOnWORecordsList) {
                SVMXC__Service_Order__c wo = woMap.get(ap.Work_Order__c);
                ap.Installed_Product__c = wo.SVMXC__Component__c; // Update IP
                ap.Product__c = wo.SVMXC__Product__c;     // Update Product
                if (!String.isBlank(ap.Subscription__c)) {
                    ap.Subscription__c = null; // Set Subscription to null if not blank
                }
                apRecordsToUpdate.add(ap);
            }         
            // Perform DML update
            if (!apRecordsToUpdate.isEmpty()) {
                AssociatedProduct.skipWOUpdateOnAPUpdate = true;
                update apRecordsToUpdate;
            }
        } catch (Exception e) {
            // Log the exception
            ApexExceptions.emit(LOG_TITLE,e);
            ilib_LogEvent.message(LOG_TITLE+'.Exception: ' + e.getMessage());
        } finally {
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
        }
    }          
}