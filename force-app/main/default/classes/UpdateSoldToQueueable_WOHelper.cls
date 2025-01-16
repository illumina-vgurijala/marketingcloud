/**
* @author Shivani Jain
* @date 8th Nov 2022
*
* @description DCP-54018 Queueable Class for Work Order trigger to Update Sold To
* MODIFICATION LOG: 
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Shivani               05-Sep-2022          DCP-43629 moved getSoldToAccFromAccHierarchy method to Utility class
*/ 
public class UpdateSoldToQueueable_WOHelper implements Queueable {

    Map<Id,Id> woIdToAccId = new Map<Id, Id>();
    Map<Id,Id> woIdToSoldAccId = new Map<Id, Id>();
    Set<Id> setWOIDToUpdate = new Set<Id>();

    /*******************************************************************************************************
    * @description Constructor
    * @param mapPOLIdToInstalledProductId Map<Id, Id>
    * @return
    */
    public UpdateSoldToQueueable_WOHelper(Map<Id,Id> woIdToAccId, Map<Id,Id> woIdToSoldAccId, set<Id> setWOIDToUpdate) {
        this.woIdToAccId = woIdToAccId;
        this.woIdToSoldAccId = woIdToSoldAccId;
        this.setWOIDToUpdate = setWOIDToUpdate;
    }

    /*******************************************************************************************************
    * @description Execute method
    * @param QueueableContext qc
    * @return
    */
    public void execute(QueueableContext qc) { 
        try {
            updateSoldToOnWO(woIdToAccId, woIdToSoldAccId, setWOIDToUpdate);
        } catch(Exception ex) {
            ApexExceptions.emit('UpdateSoldToQueueable_WOHelper.'+ 'updateSoldToOnWO', ex);
            throw ex;
        }
    }

    /*
    * method : updateSoldToOnWO
    * params : Map<Id,Id> woIdToAccId, Map<Id,Id> woIdToSoldAccId,set<Id> setWOIDToUpdate
    * description: update sold to on wo
    * return: void
    */
    public static void updateSoldToOnWO(Map<Id,Id> woIdToAccId, Map<Id,Id> woIdToSoldAccId,set<Id> setWOIDToUpdate) {
        // list to hold the work orders which has sold to field updated.
        List<SVMXC__Service_Order__c> lstWOToUpdatedSoldTo = new List<SVMXC__Service_Order__c>();
        // Map to hold the work orders id and sold Account id field.
         Map<Id,Id> woIdToSoldAccountId = ServiceUtility.getSoldToAccFromAccHierarchy(woIdToAccId,woIdToSoldAccId); //DCP-43629 [moved method to Utility class]
        if(woIdToSoldAccountId!=null &&!woIdToSoldAccountId.isEmpty()) {
           for(SVMXC__Service_Order__c objWo :new WorkOrdersSelector().selectWorkOrders(setWOIDToUpdate)) {
                if(objWo.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED || objWo.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_CLOSED)
                   continue;
                objWo.Sold_To_Account__c= woIdToSoldAccountId.containskey(objWo.id)?woIdToSoldAccountId.get(objWo.id): null;
                system.debug('$$$$$objWo.Sold_To_Account__c'+objWo.Sold_To_Account__c);
                lstWOToUpdatedSoldTo.add(objWo);
            }
        }
         WorkOrders.stopRecurssiveUpdateSoldToOnWO= true;
        if(lstWOToUpdatedSoldTo!=null && !lstWOToUpdatedSoldTo.isEmpty()) {
            update lstWOToUpdatedSoldTo;
        }
    }
}
