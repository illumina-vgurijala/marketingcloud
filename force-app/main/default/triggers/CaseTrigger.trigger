/***************************************************************************************************************************************
 * NAME         : CaseTrigger
 * DESCRIPTION  : Trigger for Case
 *                    
 * @AUTHOR : Veerendra
 * @DATE   : 06-Jun-2018  
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Veerendra               06-Jun-2018          Initial Version. Create Entitlement records when Case is created
  ****************************************************************************************************************************************/ 

trigger CaseTrigger on Case(after insert, after update, before insert, before update) {
    
		ilib_SObjectDomain.triggerHandler(Cases.class);
}