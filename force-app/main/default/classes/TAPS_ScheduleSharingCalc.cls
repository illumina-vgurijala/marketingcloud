@isTest
/**
*    @author Todd Newman
*    @date   
*    @description  class for sharing calc 
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                  Date                   Description
*     Todd Newman                                      Initial Version
*     Aman Tyagi             31st March 2022           CodeScan Fixes
*    ------------------------------------------------------------------------------------                    
*/
global without sharing class TAPS_ScheduleSharingCalc extends ilib_ScheduleAndBatch {

    /*public static final Integer MIN_RECORD_AGE_MINUTES = 5;
    public static final Integer MAX_RECORD_AGE_MINUTES = 90;
    public static final Integer ID_BATCH_SIZE = 100;

    private List<SObjectType> objectTypes = new List<SObjectType> {
        Apttus_Config2__TempObject__c.sObjectType,
        Apttus_Config2__ProductConfiguration__c.sObjectType
    };

    global override void execute(SchedulableContext sc)
    {
        ilib_LogEvent.rootTitle = 'TAPS Deferred Run Gen Data';
        ilib_LogEvent.push('TAPS_ScheduleSharingCalc.execute');

        Datetime maxCreatedDate = Datetime.now().addMinutes(-1 * MIN_RECORD_AGE_MINUTES);
        Datetime minCreatedDate = Datetime.now().addMinutes(-1 * MAX_RECORD_AGE_MINUTES);

        for (SObjectType objType : objectTypes)
        {
            // query for records created in the last hour or so
            String tableName = objType.getDescribe().getName();
            String soql = 'SELECT Id FROM ' + tableName + ' WHERE CreatedDate < :maxCreatedDate AND CreatedDate > :minCreatedDate';
            List<SObject> records = Database.query(soql);
            ilib_LogEvent.message('Found ' + records.size() + ' qualifying records in ' + tableName);
            if (records.size() == 0) continue;

            // reduce records to IDs
            Set<Id> recordIds = UtilsCollection.getSetOfIds(records, 'Id');

            // remove IDs already queries and deferred in the last run
            Set<Id> alreadyDeferredIds = retrieveDeferredIds(tableName);
            ilib_LogEvent.message('Found ' + alreadyDeferredIds.size() + ' existing IDs');
            recordIds.removeAll(alreadyDeferredIds);
            ilib_LogEvent.message('Found ' + recordIds.size() + ' non-duplicate qualifying records in ' + tableName);
            if (recordIds.size() == 0) continue;

            List<Set<Id>> recordIdBatches = splitIdsToBatches(recordIds);

            persistIdsReadyForCalculations(tableName, recordIdBatches);
        }

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    private Set<Id> retrieveDeferredIds(String tableName)
    {
        Set<Id> alreadyDeferredIds = new Set<Id>();

        Datetime minCreatedDate = Datetime.now().addMinutes(-1 * MAX_RECORD_AGE_MINUTES);

        try
        {
            List<TAPS_IDs_Already_Deferred__c> processed = [SELECT Id, Object_Type__c, Record_IDs__c
                FROM TAPS_IDs_Already_Deferred__c
                WHERE Object_Type__c = :tableName
                AND CreatedDate > :minCreatedDate];

            for (TAPS_IDs_Already_Deferred__c processedRow : processed)
            {
                Set<Id> thisRowIds = (Set<Id>)JSON.deserialize(processedRow.Record_IDs__c, Set<Id>.class);
                alreadyDeferredIds.addAll(thisRowIds);
            }
        }
        catch (Exception e)
        {
            ilib_LogEvent.push('EXCEPTION');
            ilib_LogEvent.message(e.getMessage().abbreviate(4000));
            ilib_LogEvent.pop();
        }

        return alreadyDeferredIds;
    }

    @TestVisible
    private List<Set<Id>> splitIdsToBatches(Set<Id> recordIds)
    {
        Integer batchCount = ((recordIds.size() - 1) / ID_BATCH_SIZE) + 1;
        List<Id> lstRecordIds = new List<Id>(recordIds);
        List<Set<Id>> recordIdBatches = new List<Set<Id>>();
        for (Integer i = 0; i < batchCount; i++)
        {
            Integer startIndex = i * ID_BATCH_SIZE;
            Integer endIndex = ((i + 1) * ID_BATCH_SIZE) - 1;
            if (endIndex > (lstRecordIds.size() - 1)) endIndex = lstRecordIds.size() - 1;
            List<Id> batchOfIds = new List<Id>();
            for (Integer j = startIndex; j <= endIndex; j++)
                batchOfIds.add(lstRecordIds.get(j));
            recordIdBatches.add(new Set<Id>(batchOfIds));
        }

        return recordIdBatches;
    }

    private void persistIdsReadyForCalculations(String tableName, List<Set<Id>> recordIdBatches)
    {
        try
        {
            // for these IDs
            // we will save them in Deferred Run so they will be picked up and processed
            // also in already deferred so we don't pick them up in the next run of this job
            List<TAPS_Deferred_Run__c> deferredRuns = new List<TAPS_Deferred_Run__c>();
            List<TAPS_IDs_Already_Deferred__c> processedIDs = new List<TAPS_IDs_Already_Deferred__c>();

            for (Set<Id> ids : recordIdBatches)
            {
                deferredRuns.addAll(TAPS_DeferredRun.getDeferredList(tableName, ids)) ;

                String serializedIds = JSON.serialize(ids);

                processedIDs.add(new TAPS_IDs_Already_Deferred__c(
                    Object_Type__c = tableName,
                    Record_IDs__c = serializedIds
                ));
            }

            if (deferredRuns.size() > 0)
            {
                upsert deferredRuns;
                insert processedIDs;
            }
        }
        catch (Exception e)
        {
            ilib_LogEvent.push('EXCEPTION');
            ilib_LogEvent.message(e.getMessage().abbreviate(4000));
            ilib_LogEvent.pop();
        }
    }*/

}