/***************************************************************************************************************************************
 * NAME   : UpdateWOPreviousStatusFromCase
 * DESCRIPTION  : Update All Related workorder on reopen of case
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
public class UpdateWOPreviousStatusFromCase{
  //@InvocableMethod
  
  	/*******************************************************************************************************
    * @description Method to update Work Orders Previous Status value based upon Case
    * @param listCase List<Case>
    * @return void
    */	
    public static void updateWorkOrdersPreviousStatus(List<Case> listCase) {
      set<Id> setCaseIds = new Set<Id>();
      for(Case cs: listCase){
          setCaseIds.add(cs.Id);
      }
      List<SVMXC__Service_Order__c> lstWorkOrders = new WorkOrdersSelector().selectOpenWorkOrders(setCaseIds);

      List<SVMXC__Service_Order__c> lstUpdateWorkOrder = new List<SVMXC__Service_Order__c>();
      for (SVMXC__Service_Order__c order : lstWorkOrders){
            order.Order_Previous_Status__c = order.SVMXC__Order_Status__c;
            order.SVMXC__Order_Status__c = order.WO_Reopen_Status__c ;
            order.Reason_for_Reopen__c = order.SVMXC__Case__r.Reason_for_Reopen__c;
            order.Reopen_Requester__c = UserInfo.getUserId();
            lstUpdateWorkOrder.add(order);
         
       } 
      
      if(lstUpdateWorkOrder.size() > 0){
          update lstUpdateWorkOrder;
      } 
  }   
}