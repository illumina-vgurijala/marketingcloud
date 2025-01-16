/**
*	@author Milan Savaliya
*	@date   2018-05-27
*	@description	DCP-11786: Create Quote - Clone Products from Opportunity
*	Modification Log:
*	------------------------------------------------------------------------------------ 
*			Developer					Date				Description
*			Miilan						23 Oct 2018			
*	------------------------------------------------------------------------------------ 
*
*/
trigger ApttusDocumentCollateInfoTrigger on Apttus_Proposal__DocumentCollateInfo__c(after update) {
	ilib_SObjectDomain.triggerHandler(ApttusDocumentCollateInfos.class); 
}