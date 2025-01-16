/***************************************************************************************************************************************
 * NAME   : CoveredProductTrigger
 * DESCRIPTION  : Trigger for Covered Product
 *                    
 * @AUTHOR : Shashank Singhal
 * @DATE   : 10-Oct-2018   
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Shashank Singhal        10-Oct-2018          Initial Version. Events handled after insert, after delete, after undelete and after udpate
 *****************************************************************************************************************************************/ 

trigger CoveredProductTrigger on SVMXC__Service_Contract_Products__c (after insert, after update, after delete, after undelete) {
	ilib_SObjectDomain.triggerHandler(CoveredProducts.class);
}