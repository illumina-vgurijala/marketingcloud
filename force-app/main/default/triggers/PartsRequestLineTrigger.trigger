/***************************************************************************************************************************************
 * NAME   : PartsRequestLineTrigger
 * DESCRIPTION  : Trigger for Parts Request Line
 *                    
 * @AUTHOR : Vaibhav
 * @DATE   : 21 Oct 2018  
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 
  ****************************************************************************************************************************************/ 

trigger PartsRequestLineTrigger on SVMXC__Parts_Request_Line__c (after insert, after update,before insert ) {
     
    ilib_SObjectDomain.triggerHandler(PartsRequestLines.class);
    
}