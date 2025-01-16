/***************************************************************************************************************************************
 * NAME   : ContentDocumentLinkDomain
 * DESCRIPTION  : Domain class for ContentDocumentLink.
 *				  Added logic for DCP-804  
 * @AUTHOR : Debalina
 * @DATE   : 08-Jun-2018  
 *  
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Debalina            	08-Jun-2018             Initial Version. 
 * Soumya				05-Jun-2018				Added before insert.
  ****************************************************************************************************************************************/ 

trigger ContentDocumentLinkTrigger on ContentDocumentLink (before insert,after insert, after update, after delete) {
	
    ilib_SObjectDomain.triggerHandler(ContentDocumentLinks.class);
}