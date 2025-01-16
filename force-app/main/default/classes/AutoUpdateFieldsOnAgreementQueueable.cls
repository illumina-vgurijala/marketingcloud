/**
*    @author : Bharath Varma
*    @date   : 07-Apr-2022
*    @description : Queuable Class that updates CP Agreements.
*    Test Class 90%+ Coverage : TestApttusAgreements
*    Test Class 75%+ Coverage :TestAgrLinesFindDuplicatesController , TestOpenOfferAgreements.
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                      Date                Description
*    Bharath Varma               07-Apr-2022          Initial Version.
*    Saddam                      25-Aug-2022          Created one static  Boolean field  and added Added  field to updateCustomRollUpsOnAgreements() Dcp-54810.
*    ------------------------------------------------------------------------------------ 
*                    
*/
public class AutoUpdateFieldsOnAgreementQueueable implements Queueable {
    private static final String LOG_TITLE = 'AutoUpdateFieldsOnAgreementQueueable';
    Set<Id> setAgreementIds = new Set<Id>();
    public static Boolean boolIsOpenOfferAgreement = false; //DCP-54810
    private Boolean boolIsDeleteTrigger = false;

    /**
    * @description To assign setAgreementIds
    * @author Bharath Varma
    * @param setAgreementIds 
    **/
    public AutoUpdateFieldsOnAgreementQueueable(Set<Id> setAgreementIds) {
        this.setAgreementIds = setAgreementIds;
    }

    /**
    * @description Method to calculate the roll up updates to Agreements
    * @author Bharath Varma
    * @param qc 
    **/
    public static void updateCustomRollUpsOnAgreements(Set<Id> setAgreementIds, List<Apttus__AgreementLineItem__c> lstAgrLineItems,Boolean boolIsDeleteTrigger) {
        ilib_LogEvent.push(LOG_TITLE+'updateCustomRollUpsOnAgreements()');
        // Get all the line items on the Agreements
        List<Apttus__AgreementLineItem__c> lstAgreementLineItems = lstAgrLineItems == null ? 
                                                                   new ApttusAgreementLineItemSelectors().selectByAgreementId(setAgreementIds) : lstAgrLineItems;
        ilib_LogEvent.message('Size of AgreementLineItems: '+ lstAgreementLineItems.size());
        List<Apttus__APTS_Agreement__c> lstAgreements = new ApttusAgreementSelectors().selectAgreements(setAgreementIds);
        boolIsOpenOfferAgreement = true; //dcp-54810
        Map<Id, Apttus__APTS_Agreement__c> mapIdToAgreement = ApttusAgreementsHelper.getMapIdToAgreement(lstAgreements);

        // Calculate the roll up fields on the Agreement based on the line items data
        // Using the custom roll up as we are unable to compare the fields on line items with the fields on Agreements
        // And we are very close to hitting soft limit of number of roll ups on the object
        //pass boolean value to true for deletion trigger to helper method.
        ApttusAgreementsHelper.setFlagForAgreementlineDeletion(boolIsDeleteTrigger); 
        List<Apttus__APTS_Agreement__c> lstAgreementsToUpdate = ApttusAgreementsHelper.updateAgrFromLineItems(lstAgreementLineItems, mapIdToAgreement);
        ilib_LogEvent.message('Number of Agreements to update: '+ lstAgreementsToUpdate.size());

        if(!lstAgreementsToUpdate.isEmpty()){
            List<Database.SaveResult> lstSaveErrors = Database.update(lstAgreementsToUpdate, false);
            if(!lstSaveErrors.isEmpty()){ 
                ApexExceptions.emitSaveErrors(lstSaveErrors, LOG_TITLE);
            } 
        }
        boolIsOpenOfferAgreement = false;//dcp-54810
        ilib_LogEvent.pop();
    }

    /**
    * @description Execute method for QueueableContext
    * @author Bharath Varma
    * @param qc 
    **/
    public void execute(QueueableContext qc){
        ilib_LogEvent.setTitle(LOG_TITLE);
        ilib_LogEvent.push(LOG_TITLE + '.execute');
        try{
            updateCustomRollUpsOnAgreements(setAgreementIds, null,boolIsDeleteTrigger);
        }catch(Exception e){
            for(Id agreementId : setAgreementIds) {ApexExceptions.emit(LOG_TITLE, agreementId, e);}
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    /**
    * @author Saddam
    * @description: method to set Boolean Variable to true for Delete trigger.
    * @param Boolean 
    **/
    public void setBooleanForDeleteTrigger(Boolean value) {
        boolIsDeleteTrigger = value;
    }
}
