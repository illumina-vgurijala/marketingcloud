/**
* @author Shivani Jain
* @date 29 Nov 2021
*
* @description DCP-42926 Queueable Class for Parts Order Line Trigger to create return Parts Order with lines 
*/ 
public class CreateReturnPOWithLines_POLHelper implements Queueable {

    List<SVMXC__RMA_Shipment_Line__c> lstShippedPOL = new List<SVMXC__RMA_Shipment_Line__c>();

    /*******************************************************************************************************
    * @description Constructor
    * @param lstShippedPOL List<SVMXC__RMA_Shipment_Line__c>
    * @return
    */
    public CreateReturnPOWithLines_POLHelper(List<SVMXC__RMA_Shipment_Line__c> lstShippedPOL) {
        this.lstShippedPOL = lstShippedPOL;
    }
    
    /*******************************************************************************************************
    * @description Execute method
    * @param QueueableContext qc
    * @return
    */
    public void execute(QueueableContext qc) { 
        Map<Id, SVMXC__RMA_Shipment_Order__c> mapIdToPartsOrdersToBeInserted = new Map<Id, SVMXC__RMA_Shipment_Order__c>();
        List<SVMXC__RMA_Shipment_Line__c> lstReturnPOLToBeInserted = new List<SVMXC__RMA_Shipment_Line__c>();
        
        Set<Id> setPartsOrderId = UtilsCollection.getSetOfIds(lstShippedPOL,'SVMXC__RMA_Shipment_Order__c');

        if(setPartsOrderId.isEmpty()) return;

        List<SVMXC__RMA_Shipment_Order__c> lstPartsOrdersExisting = new PartsOrdersSelector().selectPartsOrders(setPartsOrderId);
        try {
            for(SVMXC__RMA_Shipment_Order__c objPartsOrder : lstPartsOrdersExisting) {
                SVMXC__RMA_Shipment_Order__c objPartsOrderNew = new SVMXC__RMA_Shipment_Order__c();
                objPartsOrderNew.SVMXC__Order_Type__c = PartsOrderLines.STRING_PARTS_ORDER_TYPE_RETURN;
                if(objPartsOrder.SVMXC__Service_Order__c != NULL)
                {
                    objPartsOrderNew.SVMXC__Service_Order__c = objPartsOrder.SVMXC__Service_Order__c;
                    objPartsOrderNew.SVMXC__Company__c = objPartsOrder.SVMXC__Service_Order__r.SVMXC__Company__c;
                    objPartsOrderNew.SVMXC__Source_Location__c = objPartsOrder.SVMXC__Service_Order__r.SVMXC__Site__c;
                    objPartsOrderNew.SVMXC__Contact__c = objPartsOrder.SVMXC__Service_Order__r.SVMXC__Contact__c; 
                    objPartsOrderNew.Contact_Name__c = objPartsOrder.SVMXC__Service_Order__r.Contact_Name__c;
                    objPartsOrderNew.SVMXC__Case__c = objPartsOrder.SVMXC__Case__c;
                }
                objPartsOrderNew.SVMXC__Shipment_Reference__c = objPartsOrder.Id;
                mapIdToPartsOrdersToBeInserted.put(objPartsOrder.Id, objPartsOrderNew);
            }

            if(!mapIdToPartsOrdersToBeInserted.isEmpty()) {
                insert mapIdToPartsOrdersToBeInserted.values();
            }

            for(SVMXC__RMA_Shipment_Line__c objShippedPOL : lstShippedPOL) {
                if(!mapIdToPartsOrdersToBeInserted.containsKey(objShippedPOL.SVMXC__RMA_Shipment_Order__c))
                    continue;

                SVMXC__RMA_Shipment_Line__c objPOL = new SVMXC__RMA_Shipment_Line__c();
                objPOL.SVMXC__Product__c = objShippedPOL.SVMXC__Serial_Number__c != NULL ? objShippedPOL.SVMXC__Serial_Number__r.SVMXC__Product__c : NULL;
                objPOL.SVMXC__Serial_Number__c = objShippedPOL.SVMXC__Serial_Number__c;
                objPOL.SVMXC__Actual_Quantity2__c = 1;
                objPOL.Return_Reason__c = PartsOrderLines.STRING_RETURN_REASON;
                objPOL.Controlling_Return_Reason__c = PartsOrderLines.STRING_PRODUCT_TYPE_INSTRUMENT;
                objPOL.Requested_Delivery_Date__c = NULL;
                objPOL.SVMXC__RMA_Shipment_Order__c = mapIdToPartsOrdersToBeInserted.get(objShippedPOL.SVMXC__RMA_Shipment_Order__c).Id;
                lstReturnPOLToBeInserted.add(objPOL);
            }   
            if(!lstReturnPOLToBeInserted.isEmpty()) {
                insert lstReturnPOLToBeInserted;
            }
        } catch(Exception e){
            system.debug('Exception occured in: PartsOrderLineQueueable ' +e);
            ApexExceptions.emit(PartsOrderLines.STRING_PARTSORDERLINEQUEUEABLE, e);
            throw e;
        }
        
    }
}