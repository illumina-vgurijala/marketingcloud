/**
*    @author: Illumina
*    @description:  Product Configuration Domain class
*    @Test Class for above 90% coverage.
*     -TestApprovalsQuoteLineMaterialNumber
      -TestApttusApprovals
      -TestApttusAssetLineItems
*    @Test Class for atleast 75% coverage.
      -TestApprovalsQuoteLineMaterialNumber
      -TestApttusApprovals
      -TestApttusAssetLineItems
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                 Date                Description
*             Ashwin Kumar              4-Mar-2022          INC0378550: Add Logic to populate today's date to Pricing Date when Quote is cloned     
*             Jitesh Lakhwani           8-July-2022         Code Scan fixes of Comments
*             Nishan Shetty             24-Aug-2022         DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
*    ------------------------------------------------------------------------------------                   
*/
public with sharing class ApttusProductConfigurations extends ilib_SObjectDomain {

    public static Boolean hasRunTaps = false;

    /**
    * @description Parameterized Constructor called
    * @params List<Apttus_Config2__ProductConfiguration__c> sObjectList
    * @return void
    **/
    public ApttusProductConfigurations(List<Apttus_Config2__ProductConfiguration__c> sObjectList)
    {
        super(sObjectList);
    }
    /**
     * Boilerplate which is required for base class instantiation logic
     */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /**
        * @description  Constructor of base class
        * @params List<SObjects> sObjectList
        * @return sObjectList
        **/
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new ApttusProductConfigurations(sObjectList);
        }
    }

    /**
     *  @author  Joshith K
     *  @description Before Insert Logic (to clear fields for cloned Product Configurations)
     **/
    public override void onBeforeInsert()
    {
        for (Apttus_Config2__ProductConfiguration__c objLineItem : (List<Apttus_Config2__ProductConfiguration__c>) records)
        {
            System.debug('objLineItem' + objLineItem.id);
            if (objLineItem.isclone())
            {
                objLineItem.Apttus_Config2__BusinessObjectRefId__c = null;
                objLineItem.Apttus_CQApprov__BusinessObjectRefId__c = null;
                objLineItem.Apttus_Config2__PricingDate__c = Datetime.now();        //INC0378550
            }
        }
    }
    
    
    /**
    * @description Overriding the onAfterInsert base class method
    * @params NA
    * @return void
    **/ 
    public override void onAfterInsert()
    {    
        TAPS_OrchestratorInterface tapsOrchestrator = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
        tapsOrchestrator.recalculateRecordChanges(UtilsCollection.getSetOfIds(records, 'Id'), getSObjectType());//DCP-44091

        //CMCM-9986
        ApttusProductConfigurationService.updateDatesIfProposalIsClone((List<Apttus_Config2__ProductConfiguration__c>) records);
        //END CMCM-9986
    }

    /**
    * @description Overriding the onAfterUpdate base class method
    * @params NA
    * @return void
    **/
    public override void onAfterUpdate(Map<Id, sObject> existingRecords)
    {
        if (!hasRunTaps && !isInsertOperationForObject(getSObjectType()))
        {
            List<String> fieldsThatTriggerRecalculation = new List<String>{'OwnerId'};
            TAPS_OrchestratorInterface tapsOrchestratorInst = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
            Set<Id> idsThatNeedRecalculation = tapsOrchestratorInst.updateRequiresRecalculation(records, existingRecords, fieldsThatTriggerRecalculation);//DCP-44091
            if (idsThatNeedRecalculation.size() > 0) {
                tapsOrchestratorInst.recalculateRecordChanges(idsThatNeedRecalculation, getSObjectType());//DCP-44091
                hasRunTaps = true;
            }
            // CMCM-9986
            ApttusProductConfigurationService.updateByPassSyncToOpportunity((List<Apttus_Config2__ProductConfiguration__c>) records, existingRecords);
            // END 9986
        }
    }

}