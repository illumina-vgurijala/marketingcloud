/*
*  @Author: Todd Newman
*  @Date: 
*  @Description: Class which contains methods, future methods which can be called from Triggers
*    @Test Class for above 90% coverage.
*    @Test Class for atleast 75% coverage.
*     TestTAPS
*     TestTAPSBatches
*     TestTAPS_DeferredRun
*   Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                    Description
*    Todd Newman                                            Initial Version
*    Ashwin Kumar                   29-June-2021            TASK0608051 - Removed Querying & Deferring of Child Territories
*    Ashwin Kumar                   22-Apr-2022             DCP-52339: Revert Is Processing? field to false when resources are unavailable
*    Nesar Mohan                    01-April-2022           Codescan Fix
*    Nishan Shetty                  24-Aug-2022             DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
*    Adyasha Satapathy              24-Nov-2022             POL-54: Update region references to AMEA and EUR 
*    Nishan Shetty                  05-Jan-2023             CodeScan Fix for Unused Local Variable.Removed maxIdsInDeferralRequest unused variable reference.
*    ------------------------------------------------------------------------------------                  
*/
public without sharing class TAPS_Orchestrator implements TAPS_OrchestratorInterface {

    private static Boolean useQueueableManager = true;

    // called from triggers on UserTerritory2Association and Territory2
    /*
    *  @Author      : Todd Newman
    *  @Description : Method used to called from triggers on UserTerritory2Association and Territory2
    *  @Param       : Set<Id>
    *  @Return      : void
    */
    public void recalculateTerritoryChanges(Set<Id> territoryIds) {
        // NOTE: will need to think about what to do if accounts reach 10s of thousands
        // counts as of early 2019
        // AMR = 9112, AMEA = 4070, China = 1567, EUR = 7127
        // POL-54

        Set<Id> accountIds = getAccountIdsFromTerritoryIds(territoryIds);
        ilib_LogEvent.message('TAPS_Orchestrator:recalculateTerritoryChanges found accounts ' + accountIds.size());

        // this code path comes from a setup object update
        // using the queueable manager will attempt a log insert which is non-setup
        // and will result in a mixed DML error
        useQueueableManager = false;

        //INC0316527 - Defer Sharing of Territories
        //accountIds size would not cross 10k since the territories(count reduced to ~15) that are getting processed in a single run will not have more than 10k accounts combined.
        TAPS_DeferredRun.deferSharing(TAPS_DeferredRun.ACCOUNT_JOB_OBJECT_NAME, accountIds);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method used to call from batch job ScheduledBatchAccountTerritorySync
    *  @Param       : Set<Id>
    *  @Return      : void
    */
    public void recalculateAccountChanges(Set<Id> accountIds) {
        recalculateAccountChanges(accountIds, null);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method used to call from batch job ScheduledBatchAccountTerritorySync
    *  @Param       : Set<Id> and List<SObjectType>
    *  @Return      : void
    */
    private void recalculateAccountChanges(Set<Id> accountIds, List<SObjectType> objectTypes) {//[DCP-44091] Changed the access modifier to Private. 
        if (accountIds.size() == 0) return;

        Integer maxAccountsInBatch = TAPS_Config.getMaxAccountsInBatch();
        TAPS_Config.getMaxIdsInDeferralRequest();//CodeScan Fix for Unused Local Variable.

        // orch logic
        Integer hodlingJobCount = TAPSBatches.getHoldingFlexJobCount();
        Integer bufferedSimultaneousJobsMax = TAPS_Config.getBufferedSimultaneousJobsMax();
        Integer availableJobSlots = bufferedSimultaneousJobsMax - hodlingJobCount;

        ilib_LogEvent.message(availableJobSlots + ' job slots');

        // if job slots < 0 we can't defer because that happens in a future method which will error
        // in order to prevent loss of data, will have to throw this back to the user
        // this method can also be called from deferred batch. An error there is ok, it will try again later
        if (availableJobSlots < 0)
        {
            TAPS_DeferredRun.revertIsProcessingFlag(accountIds);        //DCP-52339
            throw new TAPS_BatchImpl.ApexSharingException(System.Label.TAPS_Custom_Msg_Resource_Unavailable_To_Process);//DCP-44091
        }

        Integer accountIdCount = accountIds.size();
        ilib_LogEvent.message('Size of AccountIDs to TAPS_Orchestrator.recalculateAccountChanges: ' + accountIdCount);
        Integer canProcessNowCount = availableJobSlots * maxAccountsInBatch;

        if (canProcessNowCount >= accountIdCount)
        {
            ilib_LogEvent.message('plenty of jobs sending all records ' + accountIdCount);
            createJobsToRecalculateForAccountIds(accountIds, objectTypes);
        }
        else
        {
            // take the first n IDs that fit in the available job slots
            Set<Id> accountIdsToProcessNow = new Set<Id>();
            if (availableJobSlots <= 0)
            {
                ilib_LogEvent.message('no available slots right now, deferring everything');
            }
            else
            {
                ilib_LogEvent.message('will run ' + availableJobSlots + ' jobs which is ' + (availableJobSlots * maxAccountsInBatch) + ' records');
                accountIdsToProcessNow = UtilsCollection.take(accountIds, availableJobSlots * maxAccountsInBatch);
                createJobsToRecalculateForAccountIds(accountIdsToProcessNow, objectTypes);
            }

            // take the rest and defer them
            ilib_LogEvent.message('still need to defer ' + (accountIdCount - accountIdsToProcessNow.size()) + ' records');
            Set<Id> setUnprocessedAccountIds = UtilsCollection.takeRight(accountIds, accountIdCount - accountIdsToProcessNow.size());

            TAPS_DeferredRun.revertIsProcessingFlag(setUnprocessedAccountIds);      //DCP-52339
        }
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : DCP-27435: Make Account To Field Support sharing generic
    *  @Param       : Set<Id>
    *  @Return      : Boolean
    */
    public Boolean recalculateATFSChanges(Set<Id> accountIds) {
        if (accountIds.size() == 0) return true;

        // orch logic
        Integer hodlingJobCount = TAPSBatches.getHoldingFlexJobCount();
        Integer bufferedSimultaneousJobsMax = TAPS_Config.getBufferedSimultaneousJobsMax();
        Integer availableJobSlots = bufferedSimultaneousJobsMax - hodlingJobCount;

        ilib_LogEvent.message(availableJobSlots + ' job slots');

        if (availableJobSlots <= 0) return false; // don't process and try in next run

        //not checking account size since anticipation is size would be less as unique accounts come on Account to Field Support updates
        TAPS_OrchestrateQueued queueableClassInstance = new TAPS_OrchestrateQueued(accountIds, TAPS_ObjectSupport.allATFSSharedObjectTypes);
        ilib_Queueablethread queueableThread = new ilib_Queueablethread('TAPSOrchestrator.recalculateATFSChanges');
        queueableThread.logAndQueue(queueableClassInstance, 'TAPS_OrchestrateQueued', 'execute');
        ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SALES);

        return true;
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : made this future because if the update comes from the User-T2 trigger it will get a mixed DML error
    *  if we are out of queueable slots we are out of luck, I can't write to a table so...
    *  @Param       : Set<Id> and List<String>
    *  @Return      : void
    */
    @future
    public static void deferSharingFuture(Set<Id> accountIds, List<String> objectNames) {
        if (objectNames == null || objectNames.size() == 0)
            TAPS_DeferredRun.deferSharing('Account', accountIds);
        else
            TAPS_DeferredRun.deferSharingForObjectList(accountIds, objectNames);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to break the list of accounts into chunks of size maxAccountsInBatch and queue up calculations for each chunk of accounts
    *  @Param       : Set<Id> and List<SObjectType>
    *  @Return      : void
    */
    private void createJobsToRecalculateForAccountIds(Set<Id> accountIds, List<SObjectType> objectTypes) {
        // break the list of accounts into chunks of size maxAccountsInBatch
        ilib_LogEvent.message('Size of accountIds to TAPS_Orchestrator.createJobsToRecalculateForAccountIds: '+accountIds.size());
        Integer maxAccountsInBatch = TAPS_Config.getMaxAccountsInBatch();
        List<Set<Id>> accountIdChunks = UtilsCollection.sliding(accountIds, maxAccountsInBatch);
        ilib_LogEvent.message('Size of accountIdChunks to TAPS_Orchestrator.createJobsToRecalculateForAccountIds: '+accountIdChunks.size());

        // queue up calculations for each chunk of accounts
        for (Set<Id> accountIdChunk : accountIdChunks)
        {
            ilib_LogEvent.message('starting queueable with ' + accountIdChunk.size() + ' account Ids');

            TAPS_OrchestrateQueued queueableClassInstance;
            if (objectTypes == null)
            {
                queueableClassInstance = new TAPS_OrchestrateQueued(accountIdChunk);
            }
            else
            {
                queueableClassInstance = new TAPS_OrchestrateQueued(accountIdChunk, objectTypes);
            }

            if (useQueueableManager)
            {
                ilib_Queueablethread queueableThread = new ilib_Queueablethread('TAPSOrchestrator.createJobsToRecalculateForAccountIds');
                queueableThread.logAndQueue(queueableClassInstance, 'TAPS_OrchestrateQueued', 'execute');
                ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SALES);
            }
            else
            {
                System.enqueueJob(queueableClassInstance);
            }
        }
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to get sharing implementation for this object and 
    *  find records that need sharing recalculation
    *  @Param       : SObjectType and Set<Id>
    *  @Return      : void
    */
    public void recalculateAccountChangesForObject(SObjectType objectType, Set<Id> accountIds) {
        // get sharing implementation for this object
        TAPS_ComposedBase apexSharing = TAPS_ObjectSupport.sharingFactory(objectType);

        recalculateAccountChangesForObject(apexSharing, accountIds);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to find records that need sharing recalculation
    *  @Param       : TAPS_ComposedBase and Set<Id>
    *  @Return      : void
    */
    @TestVisible private void recalculateAccountChangesForObject(TAPS_ComposedBase apexSharing, Set<Id> accountIds) {
        // find records that need sharing recalculation
        Set<Id> recordIds = apexSharing.getRecordIdsFromAccountIds(accountIds);
        ilib_LogEvent.message('TAPS_Orchestrator:recalculateAccountChangesForObject ' + apexSharing.getObjectType() + ' records for recalculations ' + recordIds.size());

        apexSharing.batchRecalculateShares(recordIds);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method called from trigger when record insert/update causes a sharing recalculation
    *  NOTE: candidate for strategy pattern
    *  @Param       : Set<Id> and SObjectType
    *  @Return      : void
    */
    public void recalculateRecordChanges(Set<Id> recordIds, SObjectType objectType) {
        if (recordIds.size() == 0) return;

        // get sharing implementation for this object
        TAPS_ComposedBase apexSharing = TAPS_ObjectSupport.sharingFactory(objectType);
        String strObjectType = String.valueOf(objectType);

        // NOTE: this might need to be moved into two places if partner users don't have enough permissions
        Set<Id> recordIdsToShare = convertRecordsToRecordsToShare(recordIds, objectType, apexSharing);
        if (recordIdsToShare.size() == 0) return;

        // Removed deferring of Partner User Sharing as part of TASK0548217/DCP-43261
        // If records count is not too large, perform sharing in future or synchronous for some objects
        if (recordIdsToShare.size() < TAPS_Config.getMaxSynchronousRecords())
        {
            if (TAPS_Config.getObjectsThatShareInFuture().contains(strObjectType))
            {
                // object configured for future
                TAPS_SharingUsingFuture.recFutureSharing(recordIdsToShare, strObjectType);
            }
            else if (TAPS_Config.getObjectsThatShareSynchronously().contains(strObjectType))
            {
                // object configured for synchronous
                TAPS_SharingUsingFuture.recSyncSharing(recordIdsToShare, strObjectType);
            }
            else
            {
                // normal case for small number of records (not future or synchronous)
                apexSharing.batchRecalculateShares(recordIdsToShare);
            }
        }
        // normal sharing case, standard user and large number of records
        else
        {
            apexSharing.batchRecalculateShares(recordIdsToShare);
        }
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method called from trigger to fetch the recordIds
    *  NOTE: candidate for strategy pattern
    *  @Param       : Set<Id>, SObjectType and TAPS_ComposedBase 
    *  @Return      : Set<Id>
    */
    private Set<Id> convertRecordsToRecordsToShare(Set<Id> recordIds, SObjectType objectType, TAPS_ComposedBase tapsImpl) {
        if (UtilsCollection.getFirstIdFromSet(recordIds).getSobjectType() == objectType)
        {
            // likely came from an insert trigger or an update where the triggering object is the same records that will be shared
            return recordIds;
        }
        else
        {
            // likely came from an update trigger where the triggering change is on a parent object to the records to be shared
            return tapsImpl.getRecordIdsFromModifiedRecordIds(recordIds);
        }
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method called from trigger when record parent change causes a sharing recalculation
    *  NOTE: candidate for strategy pattern
    *  @Param       : List<SObject>, Map<Id, sObject> and List<String> 
    *  @Return      : Set<Id>
    */
    public Set<Id> updateRequiresRecalculation(List<SObject> records, Map<Id, sObject> oldRecords, List<String> parentFieldNames) {
        Set<Id> setReparentedRecordIds = new Set<Id>();
        for (SObject rec : records)
        {
            for (String parentFieldName: parentFieldNames)
            {
                Id newId = (Id)rec.get(parentFieldName);
                Id oldId = (Id)oldRecords.get(rec.Id).get(parentFieldName);
                if (newId != null && newId != oldId)
                    setReparentedRecordIds.add(rec.Id);
            }
        }

        return setReparentedRecordIds;
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method called from trigger when record parent change causes a sharing recalculation
    *  @Param       : List<SObject>, Map<Id, sObject>,  List<String> and SObjectType 
    *  @Return      : void
    */
    @TestVisible private void recalculateRecordChanges(List<SObject> records, Map<Id, sObject> oldRecords, List<String> parentFieldNames, SObjectType objectType) {
        Set<Id> setReparentedRecordIds = new Set<Id>();
        for (SObject rec : records)
        {
            for (String parentFieldName : parentFieldNames)
            {
                Id newId = (Id) rec.get(parentFieldName);
                Id oldId = (Id) oldRecords.get(rec.Id).get(parentFieldName);
                if (newId != null && newId != oldId)
                    setReparentedRecordIds.add(rec.Id);
            }
        }
        if (setReparentedRecordIds.size() > 0)
            recalculateRecordChanges(setReparentedRecordIds, objectType);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method created simply for test coverage, this method receives IDs of records that were modified
    *  which may need to be converted to IDs that need to be shared
    *  @Param       : TAPS_ComposedBase, Set<Id> 
    *  @Return      : void
    */
    @TestVisible private void recalculateRecordChangesForObject(TAPS_ComposedBase apexSharing, Set<Id> modifiedRecordIds) {
        // this method receives IDs of records that were modified
        // which may need to be converted to IDs that need to be shared
        Set<Id> recordIds = apexSharing.getRecordIdsFromModifiedRecordIds(modifiedRecordIds);

        apexSharing.batchRecalculateShares(recordIds);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : TASK0608051 - Retrieve the accounts associated to the territories
    *  @Param       : Set<Id>
    *  @Return      : Set<Id>
    */
    @TestVisible private Set<Id> getAccountIdsFromTerritoryIds(Set<Id> territoryIds) {
        //TASK0608051 - Retrieve the accounts associated to the territories
        List<ObjectTerritory2Association> associatedObjectterritories = new ObjectTerritory2AssociationsSelector().selectByTerritoryId(territoryIds);
        Set<Id> accountIds = UtilsCollection.getSetOfIds(associatedObjectterritories, 'ObjectId');

        return accountIds;
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to convert Object Types to Object Names
    *  @Param       : List<SObjectType>
    *  @Return      : List<String>
    */
    @TestVisible private List<String> objectTypesToObjectNames(List<SObjectType> objectTypes) {
        List<String> objectNames = new List<String>();
        if (objectTypes == null) return objectNames;

        for (SObjectType t : objectTypes)
            objectNames.add(t.getDescribe().getName());

        return objectNames;
    }

}