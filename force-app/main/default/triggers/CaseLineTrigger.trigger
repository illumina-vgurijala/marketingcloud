/***************************************************************************************************************************************
 * NAME         : CaseLineTrigger
 * DESCRIPTION  : Trigger for Case Line
 *
 * @Author : Nitin Sood
 * @DATE   : 13-Dec02018
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Nitin Sood             13-December-2018    Initial Creation. Create Related product on Work Order linked with parent case
  ****************************************************************************************************************************************/ 
  
trigger CaseLineTrigger on SVMXC__Case_Line__c(after Insert, after Update, before insert, before update) {
    
    ilib_SObjectDomain.triggerHandler(CaseLines.class);
}