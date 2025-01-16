/**
*    @author Todd Newman
*    @date   
*    @description  : Class contains deferred run implementations for TAPS
*    @Test Class for above 90% coverage.
*    @Test Class for atleast 75% coverage.
     -TestTAPS_DeferredRun
*    Modification Log:
*    --------------------------------------------------------------------------------------------------------------------------------------------
*           Developer                      Date                Description
*           Todd Newman                                        Initial Version
*           Joshith K                      01-Apr-2020         PRB0043528 -update Taps Deffered Run Creation logic.getDeferredList method.
*           Joshith K                      01-June-2020        PRB0043714- update MAX_IDS_PER_ROW value
*           Satya Swain                    10-Dec-2020         DCP-43261/TASK0548217: Parent and Child Relationship for Deferring Sharing Logic
*           Ashwin Kumar                   16-Apr-2021         INC0316527 - Updated Territory Sharing rule run logic - executeDeferredJobs()
*           Ashwin Kumar                   07-June-2020        INC0316527 - Updated getScheduledJobCount method's query to fetch Jobs that are scheduled Next
*           Akshay Mohan                   18-June-2021        DCP-38968 Remove OpportunitiesService.shareOpportunites
*           Ashwin Kumar                   29-June-2021        TASK0608051 - Added method selectAndAddChildTerritoriesByTerritoryId to fetch child territories and add in same set
*           Ashwin Kumar                   24-Mar-2022         DCP-52339: Remove references of TAPS Deferred Object and remove parent-child relationship with TAPS Deferred Records
*           Nesar Mohan                    01-Apr-2022         Codescan Fix - Add code comments
*           Ashwin Kumar                   11-July-2021        INC0407615 - Prevent unprocessed records from deletion & update isProcessing flag to false
*          Nishan Shetty                   24-Aug-2022         DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
*           Nishan Shetty                  02-Sept-2022        DCP-53823 Calling the Batch Class to update Opportunity's Is_Updated_By_System Flag to false.
*    --------------------------------------------------------------------------------------------------------------------------------------------
**/

global without sharing class TAPS_DeferredRun extends ilib_ScheduleAndBatch {

    public static final String ACCOUNT_JOB_OBJECT_NAME = 'Account';
    //DCP-27435: Make Account To Field Support sharing generic
    public static final String ACCOUNT_TO_FIELD_SUPPORT_OBJECT_NAME = 'Account_to_Field_Support__c';
    public static final String ACCOUNT_RELATED_JOB_OBJECT_PREFIX = 'AccountIDs:';
    public static final String TERRITORY_JOB_OBJECT_NAME = 'Territory2';        
    public static final String OPPORTUNITY_JOB_OBJECT_NAME = 'Opportunity';
    public static final String CRF_JOB_OBJECT_NAME = 'Customer_Readiness_Form__c';
    private static final String SCHEDULED_JOB_NAME_PREFIX = 'TAPSRun-';
    public static final Integer INTEGER_BATCH_SIZE = 5000;
    public static final Integer MAX_TERRITORY_ID_TO_ORCHESTRATOR = TAPS_Config.getMaxTerritory2ToOrchestrator();    //INC0316527
    private static final String LOG_TITLE = 'TAPS_DeferredRun';                                                 //DCP-52339
    private static final Integer MAX_DEFERRED_RECS_TO_EXECUTE = TAPS_Config.getMaxDeferredRecordsToExecute();   //DCP-52339
    private static final Integer MAX_ACCOUNT_ID_TO_ORCHESTRATOR = TAPS_Config.getMaxAccountToOrchestrator();    //DCP-52339
    private static Boolean boolKillSubsequentJobScheduling = false;                                             //DCP-52339
    private static final Set<String> SKIP_ERROR_INSERT_DEFERRED_REC = TAPS_Config.getErrorsToSkipForDeferredRecInsert(); //DCP-52339
    private static final Set<String> SKIP_ERROR_UPDATE_DEFERRED_REC = TAPS_Config.getErrorsToSkipForDeferredRecUpdate(); //DCP-52339
    private static final Set<String> SKIP_ERROR_DELETE_DEFERRED_REC = TAPS_Config.getErrorsToSkipForDeferredRecDelete(); //DCP-52339
    private static final Set<String> SKIP_ERROR_UPSERT_DEFERRED_REC = TAPS_Config.getErrorsToSkipForDeferredRecUpsert(); //INC0407615

    /*
    * @author Satya Swain
    * @description  execute method for Scheduler 
    * @parameter SchedulableContext
    * @Return void
    */

    global override void execute(SchedulableContext sc)
    {
        ilib_LogEvent.setTitle(LOG_TITLE);
        ilib_LogEvent.push(LOG_TITLE+'.execute');

        // currently 100 - 25 = 75 jobs that I'd allow to be scheduled at the end of this job
        Integer maxScheduledJobs = TAPS_Config.getSimultaneousJobsMax() - TAPS_Config.getSimultaneousJobsBuffer();

        // subtract the number scheduled already by other processes
        // ex: if there are 15, maxNewJobsFromThisExecution = 75 - 15 = 60 (can't be less than 0)
        Integer currentlyHoldingFlexJobs = TAPSBatches.getHoldingFlexJobCount();
        Integer maxNewJobsFromThisExecution = maxScheduledJobs - currentlyHoldingFlexJobs;
        if (maxNewJobsFromThisExecution < 0) { maxNewJobsFromThisExecution = 0; }

        // regardless of the above numbers, this is the actual max jobs this code will schedule, currently 25
        // continuing the example, maxNewJobsFromThisExecution = the cap of 25
        Integer maxWillingToSchedule = TAPS_Config.getBufferedSimultaneousDeferredJobsMax();
        if (maxNewJobsFromThisExecution > maxWillingToSchedule) { maxNewJobsFromThisExecution = maxWillingToSchedule; }
        ilib_LogEvent.message('maxNewJobsFromThisExecution = ' + maxNewJobsFromThisExecution);

        // how many jobs need to be scheduled and how often should we try it?
        List<AggregateResult> lstAggrResult = getPendingJobsAggrResult();
        //Gives number of unique object names where deferred records are yet to be processed
        Integer pendingJobCount = lstAggrResult.size();
        Integer nextJobDelayMinutes = TAPS_Config.getNextJobDelayMinutes();

        Map<String, Map<Id, TAPS_Deferred_Record__c>> mapObjTypesToMapRecIdToDeferredRec = getRunsToProcess(maxNewJobsFromThisExecution, lstAggrResult);
        Integer thisExecutionScheduleCount = maxNewJobsFromThisExecution;
        Integer objectTypesCount = mapObjTypesToMapRecIdToDeferredRec.size();
        if (objectTypesCount < maxNewJobsFromThisExecution) { thisExecutionScheduleCount = objectTypesCount; }

        ilib_LogEvent.message('thisExecutionScheduleCount = ' + thisExecutionScheduleCount);

        if (thisExecutionScheduleCount > 0) {
            executeDeferredJobs(mapObjTypesToMapRecIdToDeferredRec);
        }

        if (pendingJobCount > thisExecutionScheduleCount && !boolKillSubsequentJobScheduling) {
            runJobAgain(nextJobDelayMinutes);
        }
        //START DCP-53823
        Code_Parameter__mdt objCodeParameter= Code_Parameter__mdt.getInstance(BatchUpdateIsUpdatedBySystemFlag.STRING_BATCH_SIZE_PARAMETER);
        ilib_BatchManager.executeBatch(new BatchUpdateIsUpdatedBySystemFlag(BatchUpdateIsUpdatedBySystemFlag.STRING_OPPORTUNITY,Integer.valueOf(objCodeParameter.Value__c)));
        //END DCP-53823
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    /**
     *  @author Ashwin Kumar
     *  @description deferSharing to insert deferred records - called from other classes
     *  @Param: String, Set<Id>
     *  @Return: void
    **/
    public static void deferSharing(String objectName, Set<Id> recordIds) {
        insertDeferredRecs(getDeferredList(objectName, recordIds));
    }

    /**
     *  @author Ashwin Kumar
     *  @description insert Deferred records and log specific exceptions
    **/
    public static void insertDeferredRecs(List<TAPS_Deferred_Record__c> lstDeferredRecords) {
        List<Database.SaveResult> insertResults = Database.insert(lstDeferredRecords, false);
        ApexExceptions.emitSpecificExceptions(
            insertResults, LOG_TITLE+'.insertDeferredRecs', lstDeferredRecords, SKIP_ERROR_INSERT_DEFERRED_REC, 'Record_ID__c'
        );
    }

    /**
     *  @author Ashwin Kumar
     *  @description create Taps defered run record/merge ids to existing record-PRB0043528
    **/
    public static List<TAPS_Deferred_Record__c> getDeferredList(String objectName, Set<Id> recordIds) {
        ilib_LogEvent.push('getDeferredList');
        ilib_LogEvent.message('recordIds: '+recordIds);
        List<TAPS_Deferred_Record__c> lstDeferredRecord = new List<TAPS_Deferred_Record__c>();

        for(Id recordId : recordIds) {
            TAPS_Deferred_Record__c deferredRecord = new TAPS_Deferred_Record__c();
            deferredRecord.Record_ID__c = recordId;
            deferredRecord.Object_Name__c = objectName;         //DCP-52339
            lstDeferredRecord.add(deferredRecord);
        }
        ilib_LogEvent.message('size of lstDeferredRecord to be inserted: ' + lstDeferredRecord.size());
        ilib_LogEvent.pop();

        return lstDeferredRecord;
    }

    /*
    *  @Author: Todd Newman
    *  @Description: Method to defer the sharing for object list
    *  @Param: Set<Id>, List<String>
    *  @Return: void
    */
    public static void deferSharingForObjectList(Set<Id> recordIds, List<String> objectNames) {
        ilib_LogEvent.message('@@@ inside TAPS_DeferredRun.deferSharingForObjectList ');
        throw new TAPS_OrchestrationImpl.ApexSharingException(TAPS_ComposedBase.ETM_FUNCTIONALITY_NOT_SUPPORTED);
    }
    

    /**
     *  @author Ashwin Kumar
     *  @description aggregateResult of unprocessed deferred ids > 0  grouped by Object name - DCP-52339
    **/
    private static List<AggregateResult> getPendingJobsAggrResult() {
        return new TAPSDeferredRecordSelector().getAggregateOfUnprocessedDeferredRecords();
    }

    /**
     *  @author Ashwin Kumar
     *  @description - To prepare Map of Object Types to Map of RecordID to Deferred Record for processing - DCP-52339
    **/
    private static Map<String, Map<Id, TAPS_Deferred_Record__c>> getRunsToProcess(Integer canScheduleJobCount, 
                                                                                  List<AggregateResult> lstAggrResult) {
        ilib_LogEvent.push(LOG_TITLE+'.getRunsToProcess');
        Set<String> setObjectName = new Set<String>();
        for(AggregateResult aggr : lstAggrResult) {
            if(canScheduleJobCount == setObjectName.size()) { break; }
            setObjectName.add( (String)aggr.get('Object_Name__c') );
        }
        
        Map<String, Map<Id, TAPS_Deferred_Record__c>> mapAccountTypeToMapRecIdToDeferredRec = new Map<String, Map<Id, TAPS_Deferred_Record__c>>();
        Map<String, Map<Id, TAPS_Deferred_Record__c>> mapOtherObjTypeToMapRecIdToDeferredRec = new Map<String, Map<Id, TAPS_Deferred_Record__c>>();
        List<TAPS_Deferred_Record__c> lstAccountTypeProcessingRecords = new List<TAPS_Deferred_Record__c>();
        List<TAPS_Deferred_Record__c> lstOtherObjTypeProcessingRecords = new List<TAPS_Deferred_Record__c>();
        Integer territoriesAdded = 0;
        //Limit for Account since 4800 records schedules more than 50+ queueables in few cases. Limit used now is 750
        Integer maxDeferredRecordsToExecute = setObjectName.size() == 1 && setObjectName.contains(ACCOUNT_JOB_OBJECT_NAME) 
                                                ? MAX_ACCOUNT_ID_TO_ORCHESTRATOR : MAX_DEFERRED_RECS_TO_EXECUTE;
        ilib_LogEvent.message('Incoming Object Types: ' + setObjectName);
        ilib_LogEvent.message('Limit Used: ' + maxDeferredRecordsToExecute);

        for(TAPS_Deferred_Record__c deferredRec : new TAPSDeferredRecordSelector().getUnprocessedDeferredRecsByObjectNames(setObjectName, maxDeferredRecordsToExecute)) {
            deferredRec.Is_Processing__c = true;
            if (ACCOUNT_JOB_OBJECT_NAME == deferredRec.Object_Name__c) {
                if (!mapAccountTypeToMapRecIdToDeferredRec.containsKey(ACCOUNT_JOB_OBJECT_NAME)) {
                    mapAccountTypeToMapRecIdToDeferredRec.put(deferredRec.Object_Name__c, new Map<Id, TAPS_Deferred_Record__c>());
                }
                mapAccountTypeToMapRecIdToDeferredRec.get(deferredRec.Object_Name__c).put(deferredRec.Record_ID__c, deferredRec);
                lstAccountTypeProcessingRecords.add(deferredRec);
            } else {
                if (!mapOtherObjTypeToMapRecIdToDeferredRec.containsKey(deferredRec.Object_Name__c)) {
                    mapOtherObjTypeToMapRecIdToDeferredRec.put(deferredRec.Object_Name__c, new Map<Id, TAPS_Deferred_Record__c>());
                }
                //INC0316527 - Control size of Territory records passed to recalculateTerritoryChanges() in executeDeferredJobs()
                if (TERRITORY_JOB_OBJECT_NAME == deferredRec.Object_Name__c && territoriesAdded < MAX_TERRITORY_ID_TO_ORCHESTRATOR) {
                    territoriesAdded++;
                    mapOtherObjTypeToMapRecIdToDeferredRec.get(deferredRec.Object_Name__c).put(deferredRec.Record_ID__c, deferredRec);
                    lstOtherObjTypeProcessingRecords.add(deferredRec);
                } else if (TERRITORY_JOB_OBJECT_NAME != deferredRec.Object_Name__c) { 
                    mapOtherObjTypeToMapRecIdToDeferredRec.get(deferredRec.Object_Name__c).put(deferredRec.Record_ID__c, deferredRec);
                    lstOtherObjTypeProcessingRecords.add(deferredRec);
                }
            }
        }

        Map<String, Map<Id, TAPS_Deferred_Record__c>> mapObjTypesToMapRecIdToDeferredRec = new Map<String, Map<Id, TAPS_Deferred_Record__c>>();

        //Prioritize all other object types of deferred records for processing and only when all others are empty, process deferred records of Account object type.
        if (!mapOtherObjTypeToMapRecIdToDeferredRec.isEmpty()) { 
            mapObjTypesToMapRecIdToDeferredRec =  mapOtherObjTypeToMapRecIdToDeferredRec;
            updateIsProcessingFlag(lstOtherObjTypeProcessingRecords);
            
        } else if (!mapAccountTypeToMapRecIdToDeferredRec.isEmpty()) { 
            mapObjTypesToMapRecIdToDeferredRec =  mapAccountTypeToMapRecIdToDeferredRec;
            updateIsProcessingFlag(lstAccountTypeProcessingRecords);
        }

        ilib_LogEvent.message('ObjectTypes picked: ' + mapObjTypesToMapRecIdToDeferredRec.keyset());
        ilib_LogEvent.pop();
        return mapObjTypesToMapRecIdToDeferredRec;
    }

    /**
     *  @author Ashwin Kumar
     *  @description - Updates Is Processing? field to true on Deferred Record - DCP-52339
    **/
    private static void updateIsProcessingFlag(List<TAPS_Deferred_Record__c> lstProcessingRecords) {
        //To update isProcessing flag to true, so that subsequent jobs do not pick up the same records
        List<Database.SaveResult> results = Database.update(lstProcessingRecords, false);
        if(lstProcessingRecords.size() == getLockRowErrorCount(results)) {
            boolKillSubsequentJobScheduling = true;
        }
    }

    /**
     *  @author Ashwin Kumar
     *  @description - To get count of errors that are due to lock row - DCP-52339
    **/
    private static Integer getLockRowErrorCount(List<Database.SaveResult> results) {
        Integer lockRowFailureCount = 0;
        for (Database.SaveResult eachResult : results) {

            if (eachResult.isSuccess()) { continue; }
            
            Set<String> allErrorMessages = new Set<String>();
            String errorMsg;
            for (Database.Error e : eachResult.getErrors()) {
                errorMsg  = e.getMessage();
                if(String.isBlank(errorMsg)) { continue; }
                allErrorMessages.addAll(UtilsCollection.addKnownErrors(errorMsg, SKIP_ERROR_UPDATE_DEFERRED_REC));
            }

            if (allErrorMessages.size() == SKIP_ERROR_UPDATE_DEFERRED_REC.size()) { lockRowFailureCount++; }

        }
        return lockRowFailureCount;
    }

    /*
    *  @Author: Todd Newman
    *  @Description: Method to schedule the list of TAPS_Deferred_Object__c
    *  @Param: List<TAPS_Deferred_Object__c>
    *  @Return: void
    */

    @TestVisible
    private void executeDeferredJobs(Map<String, Map<Id, TAPS_Deferred_Record__c>> mapObjTypesToMapRecIdToDeferredRec) {
        
        if (mapObjTypesToMapRecIdToDeferredRec.isEmpty()) {
            ilib_LogEvent.message('No records to process');
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return;
        }

        ilib_LogEvent.message('@@@@ inside executeDeferredJobs');

        for(String objectName : mapObjTypesToMapRecIdToDeferredRec.keyset()) {   
            
            Set<Id> setRecordId = new Set<Id>();
            List<TAPS_Deferred_Record__c> lstDeferredRecords = new List<TAPS_Deferred_Record__c>();
            try{
                //Map TAPS_Deferred_Record__c.Record_ID__c => TAPS_Deferred_Record__c.Id
                Map<Id, TAPS_Deferred_Record__c> mapDeferredObjRecordIDToDeferredRec = mapObjTypesToMapRecIdToDeferredRec.get(objectName);
                ilib_LogEvent.message('@@@@ deferred records size: '+mapDeferredObjRecordIDToDeferredRec.size());
                setRecordId = mapDeferredObjRecordIDToDeferredRec.keyset();
                lstDeferredRecords = mapDeferredObjRecordIDToDeferredRec.values();

                // CRF are doubly special
                // the logic to combine territory and account-based sharing was not written
                // so we have to run both batches
                if (objectName == CRF_JOB_OBJECT_NAME) {
                    processCRFDeferredRecs(setRecordId);
                    shareDeferredObjRecords(objectName, setRecordId);
                } else if (objectName == TERRITORY_JOB_OBJECT_NAME) {   // territories are a special case - pass to orchestrator
                    processTerritoryDeferredRecs(mapDeferredObjRecordIDToDeferredRec);
                } else if (objectName == ACCOUNT_JOB_OBJECT_NAME) {     // accounts are a special case - pass to orchestrator
                    processAccountDeferredRecs(mapDeferredObjRecordIDToDeferredRec);
                } else if (objectName == ACCOUNT_TO_FIELD_SUPPORT_OBJECT_NAME) {   // DCP-27435: Make Account To Field Support sharing generic
                    TAPS_OrchestratorInterface tapsOrchestrator = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
                    // only if true mark as processed. if not true means lot of jobs in system.
                    if (tapsOrchestrator.recalculateATFSChanges(setRecordId)) {//DCP-44091
                        asyncDeleteProcessedRecords(lstDeferredRecords);
                    } else {
                        revertIsProcessingFlag(lstDeferredRecords);     //INC0407615
                    }
                    continue;
                } else {
                    shareDeferredObjRecords(objectName, setRecordId);
                }

                asyncDeleteProcessedRecords(lstDeferredRecords);
            } catch (Exception e) {
                ilib_LogEvent.push('EXCEPTION');
                ilib_LogEvent.message(e.getMessage().abbreviate(4000));
                if(System.Label.TAPS_Custom_Msg_Resource_Unavailable_To_Process != e.getMessage()) {//DCP-44091
                    asyncRevertIsProcessingFlag(lstDeferredRecords);
                    ApexExceptions.emit(e, LOG_TITLE+'.executeDeferredJobs', UtilsCollection.concatenateToStringWithDelimiter(setRecordId, ';'));
                }
                ilib_LogEvent.pop();
            }
        }
    }

    /**
     *  @author Ashwin Kumar
     *  @description - Logic to share records based on appropriate object type - DCP-52339
    **/
    private void shareDeferredObjRecords(String objectName, Set<Id> records) {
        ilib_LogEvent.push(LOG_TITLE+'.shareDeferredObjRecords');
        // determine the implementation type and instantiate
        SObjectType objectType = ((SObject)Type.forName(objectName).newInstance()).getSObjectType();
        ilib_LogEvent.message('objectType = ' + objectType);
        TAPS_ComposedBase apexSharing = TAPS_ObjectSupport.sharingFactory(objectType);

        Boolean recordsCommitedToDatabase = false;
        Map<Id, Set<Id>> recordIdToAccountIds = apexSharing.getRecordIdToAccountIds(records);
        recordsCommitedToDatabase = !recordIdToAccountIds.isEmpty();

        if (recordsCommitedToDatabase) {
            // trigger the recalculation
            ilib_LogEvent.message('scheduling batch');
            apexSharing.batchRecalculateShares(records);
        } else {
            ilib_LogEvent.message('record ids not found, assuming they have been deleted: ' + records);
        }
        ilib_LogEvent.pop();
    }

    /**
     *  @author Ashwin Kumar
     *  @description - Launch Queueable to delete processed records - DCP-52339
    **/
    private void asyncDeleteProcessedRecords(List<TAPS_Deferred_Record__c> lstProcessedDeferredRecords) {
        TAPS_DeferredRunQueueable tapsQueueable = new TAPS_DeferredRunQueueable(
            TAPS_DeferredRunQueueable.METHOD_NAME_DELETE_DEFERRED_RECORDS, lstProcessedDeferredRecords
        );
        enqueueJob(tapsQueueable);
    }

    /**
     *  @author Ashwin Kumar
     *  @description - Updates Is Processing? field to false on Deferred Record - DCP-52339
    **/
    private void asyncRevertIsProcessingFlag(List<TAPS_Deferred_Record__c> lstUnprocessedRecords) {
        TAPS_DeferredRunQueueable tapsQueueable = new TAPS_DeferredRunQueueable(
            TAPS_DeferredRunQueueable.METHOD_NAME_REVERT_IS_PROCESSING_FLAG, lstUnprocessedRecords
        );
        enqueueJob(tapsQueueable);
    }

    /**
     *  @author Ashwin Kumar
     *  @description - To enqueue Queueable Job
    **/
    private void enqueueJob(TAPS_DeferredRunQueueable tapsQueueable) {
        ilib_Queueablethread queueableThread = new ilib_Queueablethread('TAPS_DeferredRun_TAPS_DeferredRunQueueable');
        queueableThread.logAndQueue(tapsQueueable, 'TAPS_DeferredRunQueueable', 'execute');
        ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SALES);
    }

    /**
     *  @author Ashwin Kumar
     *  @description - Updates Is Processing? field to false on Deferred Record - DCP-52339
    **/
    public static void revertIsProcessingFlag(List<TAPS_Deferred_Record__c> lstUnprocessedRecords) {
        //To update isProcessing flag to false, so that subsequent jobs pick up unprocessed records
        for(TAPS_Deferred_Record__c objDeferredRec : lstUnprocessedRecords) {
            objDeferredRec.Is_Processing__c = false;
        }
        List<Database.SaveResult> updateResults = Database.update(lstUnprocessedRecords, false);
        ApexExceptions.emitSaveErrors(updateResults, LOG_TITLE+'.revertIsProcessingFlag(List)');
    }

    /**
     *  @author Ashwin Kumar
     *  @description - Updates Is Processing? field to false on Deferred Record - DCP-52339
     *                 Called from TAPS_Orchestrator when Accounts cannot be processed due to limited resource
    **/
    public static void revertIsProcessingFlag(Set<Id> setUnprocessedIds) {
        if(setUnprocessedIds.isEmpty()) { return; }
        //To update isProcessing flag to false, so that subsequent jobs pick up unprocessed records
        List<TAPS_Deferred_Record__c> lstUnprocessedRecords = new List<TAPS_Deferred_Record__c>();
        for(String recordId : setUnprocessedIds) {
            lstUnprocessedRecords.add(new TAPS_Deferred_Record__c(
                Record_ID__c = recordId, Is_Processing__c = false, Object_Name__c = ACCOUNT_JOB_OBJECT_NAME
            ));
        }
        Schema.SObjectField externalField = TAPS_Deferred_Record__c.Fields.Record_ID__c;
        List<Database.UpsertResult> upsertResults = Database.upsert(lstUnprocessedRecords, externalField, false);
        //INC0407615
        ApexExceptions.emitSpecificExceptions(
            upsertResults, LOG_TITLE+'.revertIsProcessingFlag(Set)', lstUnprocessedRecords, SKIP_ERROR_UPSERT_DEFERRED_REC, 'Record_ID__c'
        );
    }

    /**
     *  @author Ashwin Kumar
     *  @description - Process Customer Readiness Form records - DCP-52339
    **/
    private void processCRFDeferredRecs(Set<Id> recordIds) {
        List<Customer_Readiness_Form__c> crfs = new CustomerReadinessFormSelector().getCRFsByIds(recordIds);
        CustomerReadinessFormsService.shareWithFieldUsers(crfs, null);
    }

    /**
     *  @author Ashwin Kumar
     *  @description - process Territory2 records - DCP-52339
    **/
    private void processTerritoryDeferredRecs(Map<Id, TAPS_Deferred_Record__c> mapDeferredObjRecordIDToDeferredRec) {
        ilib_LogEvent.message('objectType = Territory2, passing back to Orchestrator');
        TAPS_OrchestratorInterface tapsOrchestratorInst = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
        tapsOrchestratorInst.recalculateTerritoryChanges(mapDeferredObjRecordIDToDeferredRec.keySet());//DCP-44091           
    }

    /**
     *  @author Ashwin Kumar
     *  @description - process Account records - DCP-52339
    **/
    private void processAccountDeferredRecs(Map<Id, TAPS_Deferred_Record__c> mapDeferredObjRecordIDToDeferredRec) {
        ilib_LogEvent.message('objectType = Account, passing back to Orchestrator');
        TAPS_OrchestratorInterface tapsOrchestratorInstance = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
        tapsOrchestratorInstance.recalculateAccountChanges(mapDeferredObjRecordIDToDeferredRec.keyset());//DCP-44091
        //PRB0043303 - Added Logic  as part of Incident
        InstalledProductsService.shareWithDistibutorUsersByUC(mapDeferredObjRecordIDToDeferredRec.keyset());
    }

    /**
     *  @author Ashwin Kumar
     *  @description - Delete processed Deferred records - called from queueable - DCP-52339
    **/
    public static void deleteDeferredRecords(List<TAPS_Deferred_Record__c> lstDeferredRecsToDelete) {
        
        //INC0407615 - Filter to remove unprocessed record from deletion
        for (Integer index = lstDeferredRecsToDelete.size() - 1; index >= 0; index--) {
            if (!lstDeferredRecsToDelete[index].Is_Processing__c) {
                lstDeferredRecsToDelete.remove(index);
            }
        }

        if(lstDeferredRecsToDelete.isEmpty()) { return; }
        ilib_LogEvent.message('lstDeferredRecsToDelete size: ' + lstDeferredRecsToDelete.size());
        List<Database.DeleteResult> deleteResults = Database.delete(lstDeferredRecsToDelete, false);
        ApexExceptions.emitSpecificExceptions(
            deleteResults, LOG_TITLE+'.deleteDeferredRecords', lstDeferredRecsToDelete, SKIP_ERROR_DELETE_DEFERRED_REC, 'Id'
        );
    }

    /**
     *  @author Ashwin Kumar
     *  @description - Schedule DeferredRun in 2 minutes if there still records to process - DCP-52339
    **/
    @TestVisible
    private Id runJobAgain(Integer nextJobDelayMinutes) {
        
        ilib_LogEvent.message('Records remain to process, scheduling another job');

        Integer futureDeferredProcessingJobsMax = TAPS_Config.getFutureDeferredProcessingJobsMax();
        Integer deferredProcessingJobCount = getDeferredProcessingJobCount();
        if (deferredProcessingJobCount > futureDeferredProcessingJobsMax) {
            ilib_LogEvent.message('Already found ' + deferredProcessingJobCount + ' jobs waiting to process deferred records. Enough for now.');
            return null;
        }

        Integer totalScheduledJobCount = getScheduledJobCount();
        if (totalScheduledJobCount >= TAPS_Config.LIMIT_MAX_SCHEDULED_JOBS) {
            ilib_LogEvent.message('Max scheduled jobs already scheduled - ' + totalScheduledJobCount + ' - will not try to schedule another');
            return null;
        }
        String strJobName;
        try {
            Datetime scheduleIn = Datetime.now().addMinutes(nextJobDelayMinutes);

            String year = String.valueOf(scheduleIn.year());
            String month = String.valueOf(scheduleIn.month());
            String day = String.valueOf(scheduleIn.day());
            String hour = String.valueOf(scheduleIn.hour());
            String minute = String.valueOf(scheduleIn.minute());
            String second = String.valueOf(scheduleIn.second());

            strJobName = SCHEDULED_JOB_NAME_PREFIX + second + '_' + minute + '_' + hour + '_' + day + '_' + month + '_' + year;
            String strSchedule = '0 ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
            Id jobId = System.schedule(strJobName, strSchedule, new TAPS_DeferredRun());
            ilib_LogEvent.message('scheduled ' + strJobName + ', ID is ' + jobId);
            return jobId;
        } catch (Exception e) {
            ilib_LogEvent.push('EXCEPTION');
            ilib_LogEvent.message(e.getMessage().abbreviate(4000));
            ApexExceptions.emit(e, LOG_TITLE+'.runJobAgain', strJobName);
            ilib_LogEvent.pop();
            return null;
        }
    }

    /**
     *  @author Ashwin Kumar
     *  @description - To get already scheduled Apex job count - DCP-52339
    **/
    private Integer getScheduledJobCount() {
        return new CronTriggerSelector().getJobsByJobType(new Set<String>{'7'}).size();      //DCP-52339
    }

    /**
     *  @author Ashwin Kumar
     *  @description - To get TAPS Apex jobs count - DCP-52339
    **/
    private Integer getDeferredProcessingJobCount() {
        String nameLikeValue = SCHEDULED_JOB_NAME_PREFIX + '%';
        return new CronTriggerSelector().getJobsByNameAndJobType(nameLikeValue, '7').size();  //DCP-52339
    }

    /**
     *  @author Ashwin Kumar
     *  @description TASK0608051
    **/
    public static Set<Id> selectAndAddChildTerritoriesByTerritoryId(Set<Id> territoryIds) {
        // query for associated territories and any territories below those in the hierarchy
        Map<Id, Territory2> mapIdToTerritory = new Map<Id, Territory2>(new TerritoriesSelector().selectChildrenByTerritoryId(territoryIds));
        //Add all child territories, if any, to the same set and return
        if(!mapIdToTerritory.isEmpty()){
            territoryIds.addAll(mapIdToTerritory.keyset());
        }
        return territoryIds;
    }

}