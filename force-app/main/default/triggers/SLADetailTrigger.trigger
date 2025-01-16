/***************************************************************************************************************************************
 * NAME   : SLADetailTrigger 
 * DESCRIPTION  : Trigger for SLA Detail
 *                    
 * @AUTHOR : Mandeep Singh
 * @DATE   : 20-May-2018  
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Mandeep              13-Sep-2018          Initial Version. Events handled after insert,after udpate
  ****************************************************************************************************************************************/ 
trigger SLADetailTrigger on SVMXC__SLA_Detail__c (after insert, after update) {

     ilib_SObjectDomain.triggerHandler(SLADetails.class);
}