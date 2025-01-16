/*
*  @Author:
*  @Date: 
*  @Description:
*  @Test Class for above 90% coverage.
*  -TestTAPS_ApttusTempRenewAssetGroup
*  @Test Class for atleast 75% coverage.
   -TestTAPS_ApttusTempRenewAssetGroup
*  Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                    Description
*  Nishan Shetty                 24-Aug-2022            DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
*  Saddam                 10-oct-22           Codescan Fix Added Comments for methods.

*    ------------------------------------------------------------------------------------                  
*/
public with sharing class ApttusTempRenewAssetGroups extends ilib_SObjectDomain {

    public static Boolean hasRunTaps = false;

    /*
    *  @description  : Constructor Method 
    */
    public ApttusTempRenewAssetGroups(List<Apttus_Config2__TempRenewAssetGroup__c> sObjectList)
    {
        super(sObjectList);
    }
    /**
     * Boilerplate which is required for base class instantiation logic
     */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /*
        * Constructor method
        * params: List<sobject>
        */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new ApttusTempRenewAssetGroups(sObjectList);
        }
    }

    /* Method Afterinsert trigger event */
    public override void onAfterInsert()
    {
        TAPS_OrchestratorInterface tapsOrchestrator = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
        tapsOrchestrator.recalculateRecordChanges(UtilsCollection.getSetOfIds(records, 'Id'), getSObjectType());//DCP-44091
    }

    /* Method AfterUpdate trigger event */
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