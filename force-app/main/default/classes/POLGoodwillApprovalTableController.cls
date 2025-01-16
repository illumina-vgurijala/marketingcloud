/**
*  @author Tapas
*  @description - Fetches the POL records for the PO baseed on Non-billable reason. 
*               
**/
public with sharing class POLGoodwillApprovalTableController {
    public Id partsOrderId {
        get;
        set;
    }
    
    
    /**
*  @author Tapas
*  @description - Fetches the POL records for the PO. 
*               
**/
    public List < SVMXC__RMA_Shipment_Line__c > getListPartsOrderLines() {
        List < SVMXC__RMA_Shipment_Line__c > lstPOLs = new List < SVMXC__RMA_Shipment_Line__c >();
        for(SVMXC__RMA_Shipment_Line__c objPOL : new PartsOrderLineSelector().selectPartsOrderLinesWithReasonOnPartsOrders(new set<Id>{partsOrderId})){
            if(objPOL.Reason__c == System.Label.PartsOrderLineReasonGoodwill)
                lstPOLs.add(objPOL);
        }
        return lstPOLs;
    }
}