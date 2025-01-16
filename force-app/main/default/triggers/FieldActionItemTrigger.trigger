/***************************************************************************************************************************************
 * NAME   : FieldActionItemTrigger
 * DESCRIPTION  : Trigger for FieldActionItem
 *                    
 * @AUTHOR : Debanka Chakraborty
 * @DATE   : 8-Sept-2018  
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Debanka            	8-Sept-2018         Initial Version. Events handled before insert and before update
  ****************************************************************************************************************************************/ 

trigger FieldActionItemTrigger on Field_Action_Item__c (after insert,after update,before insert) {
    ilib_SObjectDomain.triggerHandler(FieldActionItems.class);
}