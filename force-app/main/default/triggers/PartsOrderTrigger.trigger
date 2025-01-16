/***************************************************************************************************************************************
 * NAME   : PartsOrderTrigger
 * DESCRIPTION  : Trigger for Parts Order
 *                    
 * @AUTHOR : Ritika Maheshwari
 * @DATE   : 20-May-2018  
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Ritika               20-May-2018          Initial Version. Events handled after insert and before udpate
 * Veerendra            06-Jun-2018          Populate Is Billable flag when the Parts Order is created.
  ****************************************************************************************************************************************/ 

trigger PartsOrderTrigger on SVMXC__RMA_Shipment_Order__c (before insert, after insert, before update, after update, before delete) {
    
        ilib_SObjectDomain.triggerHandler(PartsOrders.class);
}