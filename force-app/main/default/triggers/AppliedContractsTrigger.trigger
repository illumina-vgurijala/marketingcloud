/***************************************************************************************************************************************
 * NAME   : AppliedContractsTrigger 
 * DESCRIPTION  : Trigger for Entitlement
 *                    
 * @AUTHOR : Mandeep Singh
 * @DATE   : 13-Sep-2018  
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Mandeep               13-Sep-2018          Initial Version. Events handled after insert
 * Abhishek Yadav        04-June-2024         Added The. Events handled after update & delete
  ****************************************************************************************************************************************/ 
trigger AppliedContractsTrigger on Applied_Contract__c (after insert , after update , after delete) {

    ilib_SObjectDomain.triggerHandler(AppliedContracts.class);    
}