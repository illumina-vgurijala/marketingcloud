/***************************************************************************************************************************************
 * NAME   : AttachmentTrigger
 * DESCRIPTION  : Trigger for Attachments
 *                    
 * @AUTHOR : Ritika Maheshwari
 * @DATE   : 6-June-2018  
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Ritika               06-June-2018          Initial Version. Events handled before insert
 * Soumya				10-Sept-2018			Added After Insert.
  ****************************************************************************************************************************************/ 
trigger AttachmentTrigger on Attachment (before insert, after insert) {
   ilib_SObjectDomain.triggerHandler(Attachments.class);
}