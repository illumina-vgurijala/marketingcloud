/***************************************************************************************************************************************
 * NAME   : WorkOrderTrigger
 * DESCRIPTION  : Trigger for Work Order
 *				      
 * @AUTHOR : Ritika Maheshwari
 * @DATE   : 20-May-2018  
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Ritika             	20-May-2018          Initial Version. Events handled after insert and before udpate
 * Debalina             04-June-2018         DCP-803 Send Email for Cancelled WO.
  ****************************************************************************************************************************************/ 

trigger WorkOrderTrigger on SVMXC__Service_Order__c (before insert,after insert, before update, after update, before delete, after delete) {   
	ilib_SObjectDomain.triggerHandler(WorkOrders.class);
}