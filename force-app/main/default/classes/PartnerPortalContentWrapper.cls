/***************************************************************************************************************************************
* NAME   : PartnerPortalContentWrapper 
* --------------------------------------------------------------------------------------------------------------------------------------
*/
Global class PartnerPortalContentWrapper{
        @AuraEnabled public List<Partner_Portal_Content__c> lstCopySlides;
        @AuraEnabled public String strErrorMsg;
 
		/*
         * Constructor
         */ 
        global PartnerPortalContentWrapper(List<Partner_Portal_Content__c> lstCopySlides,String strErrorMsg){
            this.lstCopySlides=lstCopySlides;
            this.strErrorMsg=strErrorMsg;
        }
    }