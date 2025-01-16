/**
*    @author Prem Ranjan
*    @date   16 Aug 2021
*    @description    DCP-47729 Ability to add PPM to Agreement header 
*    Modification Log:
*   ------------------------------------------------------------------------------------------------
*    Developer                      Date                		Description
*    Prem Ranjan                    16 Aug 2021               Initial Version
*    -----------------------------------------------------------------------------------------------
*/
public with sharing class PPMAgreementQuickActionController{
    public static final string SUCCESSFULLY_UPDATED = 'Successfully updated';
    public static final string ERROR = 'Error';
    public static final String EXCEPTION_LOG_TITLE = 'PPMAgreementQuickActionController.saveRecord';
    public static boolean isTest = false;
    public static final String TESTING_EXCEPTION = 'Testing Exception';
    
    /**
      *  @description Return Agreement Object
      *  @param recordId
      **/
    @AuraEnabled(Cacheable = true)
    public static Apttus__APTS_Agreement__c getAgreementRecord(Id aggRecordId){
        try {
        ApttusAgreementSelectors agreementSelector = new ApttusAgreementSelectors();
        return agreementSelector.selectAgreements(new Set<Id>{aggRecordId})[0];
        }catch (Exception e) { throw new AuraHandledException(e.getMessage()); }  
    }

     /**
      *  @description Update Post Pricing Message 
      *  @param recordId and String
      **/
    @AuraEnabled
    public static String saveRecord(String aggRecordId,String ppmValue){
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c();
        ApttusAgreementSelectors agreementSelector = new ApttusAgreementSelectors();
        
        agreement = agreementSelector.selectAgreements(new Set<Id>{aggRecordId})[0];
                if(agreement == NULL){return ERROR;}
            agreement.Post_Pricing_Message__c = ppmValue;
                 try {   
                    Update agreement;
                    if(test.isRunningTest() && isTest){
                        AuraHandledException e = new AuraHandledException(TESTING_EXCEPTION);
                        e.setMessage(TESTING_EXCEPTION);
                        system.debug(e);
                        throw e;
                    } 
                    return SUCCESSFULLY_UPDATED;
                }
                catch(Exception e) {
                    throw new AuraHandledException(e.getMessage());
                }  
    }
}