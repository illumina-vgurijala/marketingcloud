/***************************************************************************************************************************************
 * NAME   : ProactiveRunDetailTrigger
 * DESCRIPTION  : Trigger for Proactive Run Detail
 *				      
 * @AUTHOR : Raviteja Vakkalagadda
 * @DATE   : 08-11-2021  
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Raviteja             08-Nov-2021          Initial Version
 ****************************************************************************************************************************************/ 
trigger ProactiveRunDetailTrigger on Proactive_Run_Detail__c (before update,before delete) {
	ilib_SObjectDomain.triggerHandler(ProactiveRunDetails.class);
}