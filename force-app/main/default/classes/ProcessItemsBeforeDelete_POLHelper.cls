/**
* @author Shivani Jain
* @date 29 Nov 2021
*
* @description DCP-42926 Helper Class for Parts Order Line Trigger to validate 
*                        records on delete
*/ 
public with sharing class ProcessItemsBeforeDelete_POLHelper {
    
    /*
     *  @AUTHOR:  Vaibhav
     *  @DESCRIPTION: DCP-27270 Parts Order Lines created from SFM can only be deleted from SFM only.
     *  @PARAM :  List<SVMXC__RMA_Shipment_Line__c> lstCurrentPartsOrderLines
     *  @RETURN:  void
     */
    public static void processLineItemsBeforeDelete(List<SVMXC__RMA_Shipment_Line__c> lstCurrentPartsOrderLines) {
        //restrict deletion
        for(SVMXC__RMA_Shipment_Line__c objPartsOrderLine: lstCurrentPartsOrderLines){
            if (!PartsOrders.allowDeletion 
                    && objPartsOrderLine.SVMXC__Line_Status__c != PartsOrderLines.STRING_STATUS_OPEN) { 
                objPartsOrderLine.addError(Label.PartsOrderLinesDeletionError);
            }
        }
        
    }
}
