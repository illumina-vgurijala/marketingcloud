/***************************************************************************************************************************************
* NAME   : PartsOrderReturnNotificationController 
* DESCRIPTION  : DCP-37399 - Controller class for Parts Order: Return Parts Order Created Using Consumption Confirmed VF Template.
*                    
* @AUTHOR : Vaibhav
* @DATE   : 10-Aug-2020  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Vaibhav                16-Nov-2020          Initial Version. DCP-37399 - Added logic to Fetch Parts Order Line Records for PartsOrderCreationNotificationOnConsumptionConfirmed VF Component.

****************************************************************************************************************************************/
public class PartsOrderReturnNotificationController {
    public Id partsOrderId {
        get;
        set;
    }

    /**
     *  @author Vaibhav
     *  @description - DCP-37399 - Fetches the Parts Order Lines records for the Parts Order. 
     *               
     **/
    public List < SVMXC__RMA_Shipment_Line__c > getListPartsOrderLines() {
        return new PartsOrderLineSelector().selectPartsOrderLinesOnPartsOrders(new set < Id > {
            partsOrderId
        });
    }
}