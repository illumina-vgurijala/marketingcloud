/**
*    @author Todd Newman
*    @description  domain class for Apttus_Config2__TempObject__c
*    @Test Class for above 90% coverage.
*    -TestTAPS_ApttusTempObject
*    @Test Class for atleast 75% coverage.
     -TestTAPS_ApttusTempObject
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------------
*    Developer                      Date                Description
*    Todd Newman                                        Intital Version
*    Himanshu                   31-March-2022           Code Scan Fixes
*    Nishan Shetty              24-August-2022          DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*
*
*/
public with sharing class ApttusTempObjects extends ilib_SObjectDomain {

    public static Boolean hasRunTaps = false;
    /**
    * @description Parameterized Constructor called
    * @params List<Apttus_Config2__TempObject__c> sObjectList
    * @return void
    **/
    public ApttusTempObjects(List<Apttus_Config2__TempObject__c> sObjectList)
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
            return new ApttusTempObjects(sObjectList);
        }
    }
    /**
    * @description Overriding the onAfterInsert base class method
    * @params NA
    * @return void
    **/
    public override void onAfterInsert()
    {
        //Added by Satya as part of DCP-43261/TASK0548217
        TAPS_OrchestratorInterface tapsOrchestrator = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
        tapsOrchestrator.recalculateRecordChanges(UtilsCollection.getSetOfIds(records, 'Id'), getSObjectType());
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
            Set<Id> idsThatNeedRecalculation = tapsOrchestratorInst.updateRequiresRecalculation(records, existingRecords, fieldsThatTriggerRecalculation);
            if (idsThatNeedRecalculation.size() > 0)
            {
                tapsOrchestratorInst.recalculateRecordChanges(idsThatNeedRecalculation, getSObjectType());
                hasRunTaps = true;
            }
        }
    }

}