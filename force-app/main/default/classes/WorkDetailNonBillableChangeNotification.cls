/***************************************************************************************************************************************
* NAME   : WorkDetailNonBillableChangeNotification
* DESCRIPTION  : Controller class for WorkDetailNonBillableChangeNotification VF Component.
*                    
* @AUTHOR : Vaibhav
* @DATE   : 10-Aug-2020  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Vaibhav                10-Aug-2020          Initial Version. Added logic to Fetch Work Details Records for WorkDetailNonBillableChangeNotification VF Component.

****************************************************************************************************************************************/
public class WorkDetailNonBillableChangeNotification {
  public Id workOrderId {
    get;
    set;
  }


  /**
   *  @author Vaibhav
   *  @description - Fetches the Work Detail records for the work Order. 
   *               
   **/
  public List < SVMXC__Service_Order_Line__c > getListWorkDetails() {
    return new WorkDetailsSelector().selectWorkDetailRecordsWithNonBillableReason(workOrderId);
  }
}