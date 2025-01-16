/**
*    @author KD
*    @description  domain class for Apttus__DocumentVersion__c
*    @Test Class for above 90% coverage.
*    -TestTAPS_ApttusDocumentVersion
*    @Test Class for atleast 75% coverage.
      -TestTAPS_ApttusDocumentVersion
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------------
*    Developer                      Date                Description
*    Todd Newman                                        Intital Version
*    Himanshu                   31-March-2022           Code Scan Fixes
*    Nishan Shetty               24-Aug-2022            DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*
*
 */
public with sharing class ApttusDocumentVersions  extends ilib_SObjectDomain {
    /**
    * @author  KD
    * @description Parameterized Constructor called
    * @params List<Apttus__DocumentVersion__c> sObjectList
    * @return void
    **/
    public ApttusDocumentVersions(List<Apttus__DocumentVersion__c> sObjectList)
    {
        super(sObjectList);
    }
    /*
    * Boilerplate which is required for base class instantiation logic
    */
    
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /**
        * @author  KD
        * @description  Constructor of base class
        * @params List<SObjects> sObjectList
        * @return sObjectList
        **/
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new ApttusDocumentVersions(sObjectList);
        }
    }
    /**
    * @author  KD
    * @description Overriding the onBeforeInsert base class method
    * @params NA
    * @return void
    **/
    public override void onBeforeInsert()
    {
        stampAgreementRecordTypeName();
    }
    /**
    * @author  KD
    * @description Overriding the onAfterInsert base class method
    * @params NA
    * @return void
    **/
    public override void onAfterInsert()
    {
        TAPS_OrchestratorInterface tapsOrchestrator = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
        tapsOrchestrator.recalculateRecordChanges(UtilsCollection.getSetOfIds(records), getSObjectType());//DCP-44091
    }

    private void stampAgreementRecordTypeName()
    {
        Set<Id> agreementIds = UtilsCollection.getSetOfIds(records, 'Apttus__AgreementId__c');
        Map<Id, Apttus__APTS_Agreement__c> idToAgreement = new Map<Id, Apttus__APTS_Agreement__c>(new ApttusAgreementSelectors().selectAgreements(agreementIds));

        for (Apttus__DocumentVersion__c dv : (List<Apttus__DocumentVersion__c>)records)
        {
            if (idToAgreement.containsKey(dv.Apttus__AgreementId__c))
                dv.Agreement_Record_Type__c = idToAgreement.get(dv.Apttus__AgreementId__c).RecordType.DeveloperName;
        }
    }

}