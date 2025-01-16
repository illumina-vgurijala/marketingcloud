/***************************************************************************************************************************************
 * NAME         : FieldSupportTrigger
 * DESCRIPTION  : Trigger for Field Support
 *                    
 * @AUTHOR : Ritika
 * @DATE   : 18-Jan-2023  
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Ritika               18-Jan-2023          Initial Version. 
  ****************************************************************************************************************************************/ 

trigger FieldSupportTrigger on SVMXC__Service_Group_Members__c(before insert, before update) {
    
		ilib_SObjectDomain.triggerHandler(FieldSupports.class);
}