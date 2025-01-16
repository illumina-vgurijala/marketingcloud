/***************************************************************************************************************************************
 * NAME   : ServiceContractTrigger
 * DESCRIPTION  : Trigger for Service Contract
 *                    
 * @AUTHOR : Shashank Singhal
 * @DATE   : 13-September-2018   
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Shashank Singhal        13-September-2018          Initial Version. Events handled before insert, before update
 *****************************************************************************************************************************************/ 

trigger ServiceContractTrigger on SVMXC__Service_Contract__c (before insert, before update, after update,after insert) {
	ilib_SObjectDomain.triggerHandler(ServiceContracts.class);
}