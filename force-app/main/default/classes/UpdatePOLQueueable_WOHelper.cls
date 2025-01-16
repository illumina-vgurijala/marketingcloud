/**
* @author Shivani Jain
* @date 8th June 2022
*
* @description DCP-54018 Queueable Class for Work Order trigger to update Billable on POL when IP is changed
*/ 
public class UpdatePOLQueueable_WOHelper implements Queueable {

    Set<Id> setworkorders = new Set<Id>();

    /*******************************************************************************************************
    * @description Constructor
    * @param setworkorders Set<Id> 
    * @return
    */
    public UpdatePOLQueueable_WOHelper(Set<Id> setworkorders) {
        this.setworkorders = setworkorders;
    }

    /*******************************************************************************************************
    * @description Execute method
    * @param QueueableContext qc
    * @return
    */
    public void execute(QueueableContext qc) { 
        try {
            updateIsBillabeOnPartsOrderLines(setworkorders);
        } catch(Exception ex) {
            ApexExceptions.emit('UpdatePOLQueueable_WOHelper.'+ 'updateIsBillabeOnPartsOrderLines', ex);
            throw ex;
        }
        
    }

    /**
     *  @author KD
     *  @description To update the is billable flag on POL when installed product is changed on Work Order
     *  @param Map : <id,SVMXC__Service_Order__c> 
     *  @return void
     *  DCP-43163
     **/
    public static void updateIsBillabeOnPartsOrderLines(Set<Id> setworkorders) {
        Set<String> setPOLStatuses = new Set<String>{Label.PartsOrderLineCanceled,Label.PartsOrderLineShipped,Label.PartsOrderLineRequested};
        Set<String> setPOStatuses = new Set<String>{Label.WorkOrderStatusClosed};
        Set<String> setPOType = new Set<String>{Label.PartOrderTypeShipment};
        List<SVMXC__RMA_Shipment_Line__c> lstPOL = new List<SVMXC__RMA_Shipment_Line__c>();
        Map<Id,Boolean> mapoldFlagValue=new Map<Id,Boolean>();
        List<SVMXC__RMA_Shipment_Line__c> lstPOLlstoupdate = new List<SVMXC__RMA_Shipment_Line__c>();
        for(SVMXC__RMA_Shipment_Line__c objPOL : new PartsOrderLineSelector().selectPartsOrderLinesByWONotInStatues(setworkorders,setPOLStatuses,setPOStatuses,setPOType)){
            lstPOL.add(objPOL);
            mapoldFlagValue.put(objPOL.Id,objPOL.Is_Billable__c);
        }

        if(lstPOL.isEmpty()) {
            return;
        }
        //START DCP-42926
        //List<Sobject> lstpolUp = PartsOrderLines.executeIsBillableRules(lstPOL);
        List<Sobject> lstpolUp = BillableRules_POLHelper.executeIsBillableRules(lstPOL);
        //END DCP-42926

        if(lstpolUp!=null && !lstpolUp.IsEmpty()) {
            for(SVMXC__RMA_Shipment_Line__c objPOL:(List<SVMXC__RMA_Shipment_Line__c>)lstpolUp) {
                if(mapoldFlagValue.get(objPOL.Id)!=null && mapoldFlagValue.get(objPOL.Id) != objPOL.Is_Billable__c) {
                    objPOL.Billable_AutoUpdated__c = !objPOL.Is_Billable__c ? true : objPOL.Billable_AutoUpdated__c;
                    lstPOLlstoupdate.add(objPOL);
                }
            }
            if(!lstPOLlstoupdate.IsEmpty()) {
                update lstPOLlstoupdate;
            }
        }
    }

 
}
