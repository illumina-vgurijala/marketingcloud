/**
*    @author Todd Newman
*    @date   
*    @description  To calculate availability of queues for running batch class and then execution of batch class for TAPS
*    Modification Log:
*    -------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*           Todd Newman                                          Initial Version
*           Satya Swain                    01-Aug-2019           PRB0042764: Added retrigger of platform event if batch size is exceeded
*                                                                and removal of insert statement inside for loop as per SFDC guidelines
*           Joshith K                      01-Apr-2020          PRB0043528 -update Taps Deffered Run Creation logic.
*           Joshith K                      01-June-2020         PRB0043714 -flexJobCount changed as local variable in runOrDeferBatch() method.
*           Akshay Mohan                   18-June-2021        DCP-38968 Remove OpportunitiesService.shareOpportunites
*           Ashwin Kumar                   11-Mar-2022           DCP-52339: Insert deferred records by using TAPS_DeferredRun.insertDeferredRecs()
*           Prem Ranjan                    25-April-2022         CodeScan Fix:Avoid Literals in If condition
*           Aman Tyagi                     30-Mar-2022          CodeScan Fixes
*    -------------------------------------------------------------------------------------------------------------------------------------
**/
public without sharing class TAPSBatches extends ilib_SObjectDomain {

    public static final String LOG_TITLE = 'TAPS Batch Subscription';
    public static final String BRACES = '{\'\'}';
    /*
    * @Author: Todd Newman
    * @Description: parameterized constructor of class TAPSBatches
    * @param : List<TAPS_Batch__e> sObjectList
    * @return: none
    */
    public TAPSBatches(List<TAPS_Batch__e> sObjectList) {
        super(sObjectList);
    }
    /*
    * Boilerplate which is required for base class instantiation logic
    */

    public class Constructor implements ilib_SObjectDomain.IConstructable {
        /*
        * @Author: Todd Newman
        * @Description: 
        * @param : List<TAPS_Batch__e> sObjectList
        * @return: TAPSBatches(sObjectList)
        */
        public ilib_SObjectDomain construct(List<TAPS_Batch__e> sObjectList) {
            return new TAPSBatches(sObjectList);
        }
    }

    private static Integer mbufferedSimultaneousJobsMax;
    private static Integer getBufferedSimultaneousJobsMax()
    {
        if (mbufferedSimultaneousJobsMax == null)
            mbufferedSimultaneousJobsMax = TAPS_Config.getBufferedSimultaneousJobsMax();

            return mbufferedSimultaneousJobsMax;
    }

    /*
    * @Author: Todd Newman
    * @Description:  moved code back in trigger
    * Apex triggers on platform events run as Automated Process user
    * this user now has permission to create sharing records
    * @param : none
    * @return: void
    */
    public override void onAfterInsert()
    {
        asyncRecalculateChanges((List<TAPS_Batch__e>)records);
    }

    @InvocableMethod(Label='TAPS Recalculate')
    /*
    * @Author: Todd Newman
    * @Description: it is dummy method with recordId as parameter
    * @param : List<String> recordIds
    * @return: void
    */
    public static void dummyMethod(List<String> recordIds)
    {
        /// noop
    }

    /*
    * @Author: Todd Newman
    * @Description: asynchronous method to recalculate the changes
    * @InvocableMethod(Label='TAPS Recalculate') -- also was static
    * @param : List<TAPS_Batch__e> tapsBatches
    * @return: void
    */
    public void asyncRecalculateChanges(List<TAPS_Batch__e> tapsBatches)
    {
        ilib_LogEvent.rootTitle = LOG_TITLE;
        ilib_LogEvent.push('asyncRecalculateChanges');

        if (TAPS_Config.getBooleanValue(TAPS_Config.DISABLE_TAPS) && !System.Test.isRunningTest())
        {
            notifyDisabled(tapsBatches);
            ilib_LogEvent.emit();
            return;
        }

        try
        {
            Integer maxSubscriptionsProcessed = TAPS_Config.getIntValue(TAPS_Config.KEY_MAX_PUBLISHED_RECORDS);
            Integer actualSubscriptionsProcessed = 0;

            // NOTE: moved this query out of loop which has caused issues when multiple threads run, will move back in
            //Integer flexJobCount = getHoldingFlexJobCount();

            List<TAPS_Deferred_Record__c> lstTapsDeferredRecord = new List<TAPS_Deferred_Record__c>();
            for (TAPS_Batch__e tapsBatch : tapsBatches)
            {
                String recordIds = tapsBatch.Record_IDs__c;
                if (String.isBlank(recordIds)) { continue; }
                if (recordIds == BRACES) { continue; }

                Set<Id> deserializedRecordIds = customIdDeserialization(recordIds);
                SObjectType objType = UtilsCollection.getFirstIdFromSet(deserializedRecordIds).getSObjectType();
                ilib_LogEvent.push('Object Type: ' + objType.getDescribe().getName());
                ilib_LogEvent.message('deserializedRecordIds ' + deserializedRecordIds);

                try
                {
                    lstTapsDeferredRecord = runOrDeferBatch(deserializedRecordIds,lstTapsDeferredRecord);
                }
                catch (Exception e)
                {
                    ApexExceptions.emit('TAPSBatches for ' + objType, e);
                    ilib_LogEvent.push('EXCEPTION');
                    ilib_LogEvent.message(e.getMessage().abbreviate(4000));
                    ilib_LogEvent.pop();
                }

                ilib_LogEvent.pop();

                EventBus.TriggerContext.currentContext().setResumeCheckpoint(tapsBatch.replayId);
                actualSubscriptionsProcessed = actualSubscriptionsProcessed + 1;
                if (actualSubscriptionsProcessed >= maxSubscriptionsProcessed)
                {
                    break;
                }
            }

            ilib_LogEvent.message('events in this subscription ' + tapsBatches.size());
            ilib_LogEvent.message('events processed actualSubscriptionsProcessed ' + actualSubscriptionsProcessed);

            // Added for PRB0042764   
            if (!lstTapsDeferredRecord.isEmpty())
            {
                //lstTapsDeferredRun = removeDeferredDuplicates(lstTapsDeferredRun);
                ilib_LogEvent.message('deferred job count ' + lstTapsDeferredRecord.size());
                TAPS_DeferredRun.insertDeferredRecs(lstTapsDeferredRecord);         //DCP-52339
            }   

            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
        }
        catch (Exception e)
        {
            ApexExceptions.emit('TAPSBatches fail', e);
        }
    }
    /*
    * @Author: Todd Newman
    * @Description:
    * @param : Set<Id> ids
    * @return: List<Database.SaveResult>
    */
    public static List<Database.SaveResult> publish(Set<Id> ids)
    {
        String customSerialized = customIdSerialization(ids);
        return publish(customSerialized);
    }

    /*
    * @Author: Todd Newman
    * @Description:
    * @param : String serializedIds
    * @return: List<Database.SaveResult>
    */
    public static List<Database.SaveResult> publish(String serializedIds)
    {
        return publish(new List<String> {serializedIds});
    }

    /*
    * @Author: Todd Newman
    * @Description: static method to publish the events
    * @param : List<String> lstSerializedIds
    * @return: List<Database.SaveResult>
    */
    public static List<Database.SaveResult> publish(List<String> lstSerializedIds)
    {
        List<TAPS_Batch__e> lstTapsEvents = buildEvents(lstSerializedIds);

        if (TAPS_Config.getBooleanValue(TAPS_Config.DISABLE_TAPS) && !System.Test.isRunningTest())
        {
            notifyDisabled(lstSerializedIds);
            return null;
        }
        else
        {
            return EventBus.publish(lstTapsEvents);
        }
    }

    @TestVisible
    private static void notifyDisabled(List<TAPS_Batch__e> tapsBatches)
    {
        ilib_LogEvent.message('TAPS IS DISABLED');
        for (TAPS_Batch__e tb : tapsBatches) {
            ilib_LogEvent.message('Would have published ' + tb.Record_IDs__c);
        }
    }

    @TestVisible
    private static void notifyDisabled(List<String> lstSerializedIds)
    {
        ilib_LogEvent.message('TAPS IS DISABLED');
        ilib_LogEvent.message('Would have published ' + lstSerializedIds);
    }

    /*
    * @Author: Todd Newman
    * @Description: method to build events 
    * @param : List<String> lstSerializedIds
    * @return: List<TAPS_Batch__e>
    */
    public static List<TAPS_Batch__e> buildEvents(List<String> lstSerializedIds)
    {
        List<TAPS_Batch__e> lstTapsEvents = new List<TAPS_Batch__e>();
        for (String serializedIds : lstSerializedIds) {
            lstTapsEvents.add(new TAPS_Batch__e(Record_IDs__c = serializedIds));
        }

        return lstTapsEvents;
    }

    /*
    * @Author: Todd Newman
    * @Description: static method to run the batch based on deserializedRecordIds and list of lstTapsDeferredRecord
    * @param : Set<Id> deserializedRecordIds, List<TAPS_Deferred_Record__c> lstTapsDeferredRecord
    * @return: List<TAPS_Deferred_Record__c>
    */
    public static List<TAPS_Deferred_Record__c> runOrDeferBatch(Set<Id> deserializedRecordIds, List<TAPS_Deferred_Record__c> lstTapsDeferredRecord)
    {
        ilib_LogEvent.push('TAPSBatches.runOrDeferBatch');

        SObjectType objType = UtilsCollection.getFirstIdFromSet(deserializedRecordIds).getSobjectType();
        String objTypeName = objType.getDescribe().getName();

        TAPS_ComposedBase objectSpecificImpl = TAPS_ObjectSupport.sharingFactory(objType);

        // if there are already too many batches running, this one will be deferred
        Integer bufferedSimultaneousJobsMax = getBufferedSimultaneousJobsMax();
        Integer flexJobCount = getHoldingFlexJobCount();
        Boolean flexQueueTooFull = (flexJobCount > bufferedSimultaneousJobsMax);
        ilib_LogEvent.message('flexQueueTooFull ' + flexQueueTooFull);

        if (flexQueueTooFull)
        {
            ilib_LogEvent.message('deferring calculations');
            // if the queue is too full defer this calculation run (improved for PRB0042764)
            lstTapsDeferredRecord = TAPS_DeferredRun.getDeferredList(objTypeName, deserializedRecordIds);
            ilib_LogEvent.pop();
            return lstTapsDeferredRecord;
        }

        // in a unit test context we can only run so much batch code
        // objectBeingTested is used TAPSBatches to specify which batch we should run
        // for the test to succeed
        Boolean testContextRunBatchForThisObject = (TestTAPS.objectBeingTested == null || TestTAPS.objectBeingTested == objType);
        ilib_LogEvent.message('testContextRunBatchForThisObject: ' + testContextRunBatchForThisObject + ', ' + objTypeName);
        if (System.Test.isRunningTest()) { ilib_LogEvent.message('will run batch if this type ' + objType + ' = the unit test-specified type of ' + TestTAPS.objectBeingTested); }

        if (!System.Test.isRunningTest() || testContextRunBatchForThisObject)
        {
            
            // CRF are doubly special
            // the logic to combine territory and account-based sharing was not written
            // so we have to run both batches
            if (objType == Customer_Readiness_Form__c.SObjectType)
            {
                List<Customer_Readiness_Form__c> crfs = new CustomerReadinessFormSelector().getCRFsByIds(deserializedRecordIds);
                CustomerReadinessFormsService.shareWithFieldUsers(crfs, null);
            }

            // execute the batch recalculation (CRF and everything else)
            TAPS_BatchUpdate batchUpdater = new TAPS_BatchUpdate(new Set<Id>(deserializedRecordIds), objectSpecificImpl);
            Integer batchSize = TAPS_Config.getBatchSize(objectSpecificImpl.getObjectType());

            ilib_LogEvent.message('starting batch for ' + deserializedRecordIds.size() + ' ' + objType + ' records with batch size ' + batchSize);
            Database.executeBatch(batchUpdater, batchSize);
            //flexJobCount = flexJobCount + 1;
            
        }

        ilib_LogEvent.pop();
        return lstTapsDeferredRecord;
    }
    
    /*
    * @Author: Todd Newman
    * @Description: static method for getting flex job count
    * @param : none
    * @return: Integer
    */
    public static Integer getHoldingFlexJobCount()
    {
        Integer flexHoldingCount = [SELECT count() FROM AsyncApexJob WHERE Status = 'Holding'];
        ilib_LogEvent.message('flexHoldingCount ' + flexHoldingCount);
        return flexHoldingCount;
    }
    /*
    * @Author: Todd Newman
    * @Description: static method for serialization based on Ids
    * @param : Set<Id> ids
    * @return: String
    */
    public static String customIdSerialization(Set<Id> ids)
    {
        if (ids == null || ids.size() == 0) return '';

        return '{\'' + String.join(new List<Id>(ids), '|') + '\'}';
    }

    /*
    * @Author: Todd Newman
    * @Description: static method for deserialization
    * @param : String serialized
    * @return: Set<Id>
    */
    public static Set<Id> customIdDeserialization(String serialized)
    {
        serialized = serialized.replace('{', '').replace('}', '').replaceAll('\'', '');

        List<String> splitUp = serialized.split('\\|');
        Set<Id> ids = new Set<Id>();
        for (String s : splitUp)
        {
            try
            {
                Id i = (Id)s;
                ids.add(i);
            }
            catch (Exception e)
            {
                ApexExceptions.emit('TAPSBatches deserialization for value ' + s, null, e);
                ilib_LogEvent.push('EXCEPTION');
                ilib_LogEvent.message(e.getMessage().abbreviate(4000));
                ilib_LogEvent.pop();
            }
        }
        return ids;
    }

}