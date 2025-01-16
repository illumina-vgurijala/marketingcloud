/**
*    @author Prabhsimran Singh
*    @date   31 July 2020
*    @description    DCP-39587 Trigger helper class to invoke batch if related agreement record is created as part of amend functionality.
*    @Test Class for above 90% coverage.
*    -TestTAPS_ApttusRelatedAgreement
*    @Test Class for atleast 75% coverage.
      -TestTAPS_ApttusRelatedAgreement
*    Modification Log:
*    ------------------------------------------------------------------------------------
*        Developer                  Date              Description
*        Rahul Bishnoi              13-May-2021       INC0320773 - fetching parent agreement number from new field created on amended agreement.
*        Bharath Varma              25-Mar-2022       TASK0718153 - Adding sharing when record is inserted
*        Aman Tyagi                 31-Mar-2022       Codescan fixes
*        Nishan Shetty              23-May-2022       DCP-50962 [Ilib Batch Manager Implementation]
*        Nishan Shetty              24-Aug-2022       DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
*    ------------------------------------------------------------------------------------
*
*/
public without sharing class ApttusRelatedAgreements extends ilib_SObjectDomain{
    public final static String LOG_TITLE = 'ApttusRelatedAgreements';
    /* constructor */
    public ApttusRelatedAgreements(List<Apttus__APTS_Related_Agreement__c> sObjectList)
    {        
        super(sObjectList);        
    }
    /**
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /*
        * @Author: Rahul Bishnoi
        * @Description : parameterized constructor of the base class
        * @param : List<SObject> sObjectList  
        */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new ApttusRelatedAgreements(sObjectList);
        }
    }
    /*
    * @Author: Rahul Bishnoi
    * @Description : this method has logic for after insert
    * @param : null
    * @return: void
    */
    public override void onAfterInsert()
    {   
        ilib_LogEvent.setTitle(LOG_TITLE,ilib_LogEvent.SALES);
        ilib_LogEvent.push(LOG_TITLE);
        try{
        // there will be only one such agreement in a single insert
        Apttus__APTS_Related_Agreement__c amendedOrRenewalAgreement = findAmendedOrRenewalAgreement((List<Apttus__APTS_Related_Agreement__c>)records);
        if(amendedOrRenewalAgreement != null){
			callBatchJobALI(amendedOrRenewalAgreement);
		}
        //Populate Parent agreement number if agreement is ameneded.
        populateParentAgreementNumber();
        // TASK0718153 - Calculate sharing when the related agr record is inserted
        TAPS_OrchestratorInterface tapsOrchestrator = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
        tapsOrchestrator.recalculateRecordChanges(UtilsCollection.getSetOfIds(records, 'Id'), getSObjectType());//DCP-44091
    
        ilib_LogEvent.pop();
        } catch(Exception e){
        System.debug('Error Message is  '+e.getMessage());
        ApexExceptions.emit(LOG_TITLE,e,ilib_LogEvent.SALES );
    }
     

    }

    /*
    * Method to Populate Parent agreement number if agreement is ameneded.
    */
    private void populateParentAgreementNumber()
    {
        ilib_LogEvent.push(LOG_TITLE+'.populateParentAgreementNumber');
        ilib_LogEvent.message('Updating Parent Agreement Number');
        List<Apttus__APTS_Agreement__c> updateAgreements = new List<Apttus__APTS_Agreement__c>();
        Set<id> idAgreements = new Set<id>();
        for(Apttus__APTS_Related_Agreement__c agreementRel : (List<Apttus__APTS_Related_Agreement__c>)records){
            idAgreements.add(agreementRel.Apttus__APTS_Contract_To__c);
            idAgreements.add(agreementRel.Apttus__APTS_Contract_From__c);
        }
        Map<Id,Apttus__APTS_Agreement__c> idToAgreement = new Map<Id,Apttus__APTS_Agreement__c>(new ApttusAgreementSelectors().selectAgreements(idAgreements));
        for(Apttus__APTS_Related_Agreement__c agreementRel : (List<Apttus__APTS_Related_Agreement__c>)records)
        {
            if(!idToAgreement.get(agreementRel.Apttus__APTS_Contract_To__c).Agreement_Not_Amended__c){
                ilib_LogEvent.message('Parent Agreement Number -->> '+ idToAgreement.get(agreementRel.Apttus__APTS_Contract_From__c).Apttus__FF_Agreement_Number__c);
                idToAgreement.get(agreementRel.Apttus__APTS_Contract_To__c).Parent_Agreement_Number__c = idToAgreement.get(agreementRel.Apttus__APTS_Contract_From__c).Apttus__FF_Agreement_Number__c;
                updateAgreements.add(idToAgreement.get(agreementRel.Apttus__APTS_Contract_To__c));
            }
        }
        if (!updateAgreements.isEmpty()){
            update updateAgreements;
        }

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
    private Apttus__APTS_Related_Agreement__c findAmendedOrRenewalAgreement(List<Apttus__APTS_Related_Agreement__c> agreements)
    {
        Apttus__APTS_Related_Agreement__c amendedOrRenewalAgreement;

        Set<String> setTypes = new Set<String>{
            Label.RelatedAgreementRelationshipFromTypeAmend,
            Label.RelatedAgreementRelationshipFromTypeRenew
        };

        for (Apttus__APTS_Related_Agreement__c agreement : agreements)
        {
            if (setTypes.contains(agreement.Apttus__Relationship_From_Type__c)) {
                amendedOrRenewalAgreement = agreement;
            }
        }

        return amendedOrRenewalAgreement;
    }

    /**
    *  @author Prabhsimran Singh
    *  @description To Call batch job for line item insertion in case of amend/renew.
    *  @param lstRecords- List of related agreement
    *  @return void
    **/
    public void callBatchJobALI(Apttus__APTS_Related_Agreement__c amendedOrRenewalAgreement)
    {
        if (
            String.isNotBlank(amendedOrRenewalAgreement.Apttus__APTS_Contract_From__c)
            && String.isNotBlank(amendedOrRenewalAgreement.Apttus__APTS_Contract_To__c)
        ) { 
            List<Code_Parameter__mdt> lstCodeParameter = new CodeParametersSelector().selectCodeParameterByDeveloperName(
                new Set<String> { 'Batch_Agreement_Amend_Renew_Process' }
            );
            Integer batchSize = Integer.valueOf(lstCodeParameter[0].Value__c);

            BatchAgreementLineItemsInsertion batALIInsertion = new BatchAgreementLineItemsInsertion(amendedOrRenewalAgreement);
            ilib_BatchManager.executeBatch(batALIInsertion,batchSize);//DCP-50962
        }
    }

    
}