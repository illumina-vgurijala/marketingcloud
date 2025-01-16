/**
*    @author Prabhsimran Singh
*    @date   31-July-2020
*    @description    DCP-39587 Trigger to call handler class when record is inserted.
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    ------------------------------------------------------------------------------------ 
*                    
*/
trigger ApttusRelatedAgreementTrigger on Apttus__APTS_Related_Agreement__c (after insert) {
	ilib_SObjectDomain.triggerHandler(ApttusRelatedAgreements.class);	
}