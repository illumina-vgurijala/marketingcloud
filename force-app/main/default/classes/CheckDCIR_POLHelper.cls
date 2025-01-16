/**
* @author Shivani Jain
* @date 29 Nov 2021
*
* @description DCP-42926 Helper Class for Parts Order Line Trigger to run DCIR logic 
*/ 
public class CheckDCIR_POLHelper {
    
    /*******************************************************************************************************
    * @description Check if the Part Order is Submitted for Approval and if any related POL faling a DCIR check
    * @param isChannelPartner True if logged in user is CP
    * @param records List <SVMXC__RMA_Shipment_Line__c>
    * @return
    */
    public static void checkDCIR(Boolean isChannelPartner, List <SVMXC__RMA_Shipment_Line__c> records) {

        for(SVMXC__RMA_Shipment_Line__c objPartOrderLine: (List <SVMXC__RMA_Shipment_Line__c>) records) {
            if(isChannelPartner && objPartOrderLine.Parts_Order_Type__c == 'Return' 
                    && objPartOrderLine.Decontamination_Required__c && !objPartOrderLine.Is_DCIR_Filled__c) {
                if(PartsOrderLines.partsOrderIdToPartsOrder != null 
                        && PartsOrderLines.partsOrderIdToPartsOrder.containsKey(objPartOrderLine.SVMXC__RMA_Shipment_Order__c) 
                        && PartsOrderLines.partsOrderIdToPartsOrder.get(objPartOrderLine.SVMXC__RMA_Shipment_Order__c).Submit_for_Approval_CP__c) {
                    objPartOrderLine.addError(Label.PODCIRCheckErrorCP);
                }
            }
        }
    }
}