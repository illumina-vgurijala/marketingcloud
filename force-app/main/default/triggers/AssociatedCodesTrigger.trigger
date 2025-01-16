/***************************************************************************************************************************************
 * NAME   : AssociatedCodeTrigger
 * DESCRIPTION  : Trigger for Associated Code
 *                    
 * @AUTHOR : Shashank Singhal
 * @DATE   : 12-July-2018   
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Shashank Singhal        12-July-2018          Initial Version. Events handled after insert, after delete, after undelete and after udpate
 *****************************************************************************************************************************************/ 

trigger AssociatedCodesTrigger on Associated_Codes__c (before update, before insert, after insert, after update, after delete, after undelete) {
    ilib_SObjectDomain.triggerHandler(AssociatedCodes.class);
}