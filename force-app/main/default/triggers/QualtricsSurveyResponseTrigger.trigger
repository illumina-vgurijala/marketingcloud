/***************************************************************************************************************************************
 * NAME   : QualtricsSurveyResponseTrigger
 * DESCRIPTION  : Trigger for Qualtrics Survey Response
 *                    
 * @AUTHOR : Digvijay
 * @DATE   : 14-Feb-2020  
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Digvijay              14-Feb-2020          Initial Version. Events handled after insert and before udpate
 
  ****************************************************************************************************************************************/ 

trigger QualtricsSurveyResponseTrigger on Qualtrics_Survey_Response__c(before insert, before update,after insert,after update) {
    
    ilib_SObjectDomain.triggerHandler(QualtricsSurveyResponses.class);
}