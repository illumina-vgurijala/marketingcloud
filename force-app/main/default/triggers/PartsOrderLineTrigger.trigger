/***************************************************************************************************************************************
 * NAME   : PartsOrderLineTrigger
 * DESCRIPTION  : Trigger for Parts Order Line
 *                    
 * @AUTHOR : Veerendra
 * @DATE   : 15-Jun-2018  
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
  ****************************************************************************************************************************************/ 

trigger PartsOrderLineTrigger on SVMXC__RMA_Shipment_Line__c (before insert,before update, after insert, after update,before delete, after delete, after undelete) {
    
    if(PartsOrderLines.appliedContractsTriggerRanOnce == false){
        ilib_SObjectDomain.triggerHandler(PartsOrderLines.class);
    }
}