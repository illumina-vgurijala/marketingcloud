/***************************************************************************************************************************************
 * NAME         : WorkDetailTrigger
 * DESCRIPTION  : Trigger for Work Detail
 *
 * @Author : Veerendra                    
 * @DATE   : 31-May-2018  
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Veerendra            31-May-2018             Initial Creation. Update whether work detail line is Billable for each line type
  ****************************************************************************************************************************************/ 

trigger WorkDetailTrigger on SVMXC__Service_Order_Line__c(before insert,before update, after insert,after Update, before delete) {
    
  	if(WorkDetails.appliedContractsTriggerRanOnce == false){
		ilib_SObjectDomain.triggerHandler(WorkDetails.class);
	}
}