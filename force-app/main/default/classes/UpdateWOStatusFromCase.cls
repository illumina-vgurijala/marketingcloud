/***************************************************************************************************************************************
 * NAME   : UpdateWOStatusFromCase 
 * DESCRIPTION  : Update All Related workorder on rejection of case
 *           DCP-12485  : Work Order and Case Reopening Process 
 *    
 * @AUTHOR : Dipika Gupta
 * @DATE   : 3-Oct-2018  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Dipika             3-Oct-2018             Initial Version
  ****************************************************************************************************************************************/ 
public class UpdateWOStatusFromCase {
    //@InvocableMethod
    /*******************************************************************************************************
    * @description Method to update Work Orders Status value based upon Case
    * @param listCase List<Case>
    * @return void
    */
    public static void updateWorkOrdersStatus(List<Case> listCase) {
      set<Id> setCaseIds = new Set<Id>();
      for(Case cs: listCase){
          setCaseIds.add(cs.Id);
      }
      
      List<SVMXC__Service_Order__c> lstUpdateWorkOrder = new List<SVMXC__Service_Order__c>();
      List<SVMXC__Service_Order__c>lstWorkOrders = new WorkOrdersSelector().selectReopenRequestedWOForCases(setCaseIds);
          
      for (SVMXC__Service_Order__c order : lstWorkOrders){
              if(order.SVMXC__Case__r.Status == Label.CaseStatusInProgress){
                  order.SVMXC__Order_Status__c = Label.WorkOrderStatusAssigned;
                  order.Reason_for_Approval_Denial_of_Reopen__c = order.SVMXC__Case__r.Reason_for_Approval_Denial_of_Reopen__c;
				  order.Approver_Rejector__c= UserInfo.getUserId();
                  lstUpdateWorkOrder.add(order);
              }
              else{
                  if(order.Order_Previous_Status__c != order.SVMXC__Order_Status__c){
                      order.SVMXC__Order_Status__c = order.Order_Previous_Status__c;
					  order.Approver_Rejector__c= UserInfo.getUserId();
                      order.Reason_for_Approval_Denial_of_Reopen__c = order.SVMXC__Case__r.Reason_for_Approval_Denial_of_Reopen__c;
                      lstUpdateWorkOrder.add(order);
                  }
              }
              
      }
       
      
      if(lstUpdateWorkOrder.size() > 0){
          update lstUpdateWorkOrder;
      }   
   }
}