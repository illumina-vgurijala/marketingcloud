/**
*  @author Unknown
*  @date   NA
*  @description    ApttusApprovalRequestHistories class
*  @Test Class for above 90% coverage.
*    -TestTAPS_ApttusApprovalRequestHistory
*  @Test Class for atleast 75% coverage.
    -TestTAPS_ApttusApprovalRequestHistory
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------------
*      Developer          Date          Description
*      Jitesh Lakhwani    8-July-2022   Code Scan fixes of Comments
*      Nishan Shetty      24-Aug-2022   DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
*  ---------------------------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class ApttusApprovalRequestHistories extends ilib_SObjectDomain {

    public static Boolean hasRunTaps = false;

    /**
    * @description Parameterized Constructor called
    * @params List<Apttus_Approval__Approval_Request_History__c> sObjectList
    * @return void
    **/
    public ApttusApprovalRequestHistories(List<Apttus_Approval__Approval_Request_History__c> sObjectList)
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
            return new ApttusApprovalRequestHistories(sObjectList);
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
    }

    /**
    * @description Overriding the onAfterUpdate base class method
    * @params Map<Id, sObject> existingRecords
    * @return void
    **/
    public override void onAfterUpdate(Map<Id, sObject> existingRecords)
    {
        if (!hasRunTaps && !isInsertOperationForObject(getSObjectType()))
        {
            List<String> fieldsThatTriggerRecalculation = new List<String> { 'OwnerId' };
            TAPS_OrchestratorInterface tapsOrchestratorInst = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
            Set<Id> idsThatNeedRecalculation = tapsOrchestratorInst.updateRequiresRecalculation(records, existingRecords, fieldsThatTriggerRecalculation);//DCP-44091
            if (idsThatNeedRecalculation.size() > 0)
            {
                tapsOrchestratorInst.recalculateRecordChanges(idsThatNeedRecalculation, getSObjectType());//DCP-44091
                hasRunTaps = true;
            }
        }
    }

}