/***************************************************************************************************************************************
 * NAME   : AccountToFieldSupportTrigger
 * DESCRIPTION  : Trigger for Account to Field support
 *                    
 * @AUTHOR : Sandeep Ram Ch.
 * @DATE   : 4-July-2018 
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Sandeep Ram Ch.        4-July-2018          Initial Version. Events handled after insert and before udpate
 
  ****************************************************************************************************************************************/ 

trigger AccountToFieldSupportTrigger on Account_to_Field_Support__c  (before insert, after insert, before update, after update, after delete)
{
    ilib_SObjectDomain.triggerHandler(AccountToFieldSupports.class);
}