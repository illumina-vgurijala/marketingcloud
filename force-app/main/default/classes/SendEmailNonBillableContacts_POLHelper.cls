/**
* @author Shivani Jain
* @date 29 Nov 2021
*
* @description DCP-42926 Helper Class for Parts Order Line Trigger to send Email 
*/ 
public class SendEmailNonBillableContacts_POLHelper {
    
    /*******************************************************************************************************
    * @description send Email to Non Billable Contacts
    * @param setNonBillablePartsOrderLinesId Set<Id>
    * @return void
    */
    public static void sendEmail(Set<Id> setNonBillablePartsOrderLinesId) {
        List<SVMXC__RMA_Shipment_Line__c> lstBillablePartsOrderLine = new List<SVMXC__RMA_Shipment_Line__c>();
        
        if(setNonBillablePartsOrderLinesId != null && !setNonBillablePartsOrderLinesId.isEmpty()) {
            for(SVMXC__RMA_Shipment_Line__c objPartsOrderLine: PartsOrderLines.mapCurrentPartsOrderLines.values()) {
                if(setNonBillablePartsOrderLinesId.contains(objPartsOrderLine.Id)) {
                    lstBillablePartsOrderLine.add(objPartsOrderLine);   
                }                                                   
            }
        }
        
        if(lstBillablePartsOrderLine != null && !lstBillablePartsOrderLine.isEmpty()) {
            SendEmailNotification.getSendEmailParamaters(PartsOrderLines.BILLABLE_PARTS_ORDER_LINE_META_DATA, 
                                                            lstBillablePartsOrderLine, null ,null);
        }
    }
}