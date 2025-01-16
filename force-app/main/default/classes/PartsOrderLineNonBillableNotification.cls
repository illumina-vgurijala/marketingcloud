/***************************************************************************************************************************************
* NAME   : PartsOrderLineNonBillableNotification
* DESCRIPTION  : Controller class for PartsOrderLineNonBillableNotification VF Component.
*                    
* @AUTHOR : Vaibhav
* @DATE   : 10-Aug-2020  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Vaibhav                10-Aug-2020          Initial Version. Added logic to Fetch POL Records for PartsOrderLineNonBillableNotification VF Component.

****************************************************************************************************************************************/
public class PartsOrderLineNonBillableNotification {
  public Id partsOrderId {
    get;
    set;
  }


  /**
   *  @author Vaibhav
   *  @description - Fetches the POL records for the PO. 
   *               
   **/
  public List < SVMXC__RMA_Shipment_Line__c > getListPartsOrderLines() {
    return new PartsOrderLineSelector().selectPartsOrderLinesWithReasonOnPartsOrders(new set<Id>{partsOrderId});
  }
}