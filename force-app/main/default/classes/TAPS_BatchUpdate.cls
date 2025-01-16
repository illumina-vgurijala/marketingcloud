/*
*    @author: Todd Newman
*    @description: Class used for batch update
*    Modification Log:
*   ----------------------------------------------------------------------------------------
*    Developer                      Date                    Description
*    Todd Newman                                            Initial Version
*    Ashwin Kumar                   29-June-2021            TASK0608051 - Query & Defer Child Territories
*    Nesar Mohan                    01-April-2022           CodeScan Fix - Add code comments
*    Rajbabu Boopalan               2023-12-20              CMCM-4122 Fix - SOQL 201 error
*    ---------------------------------------------------------------------------------------                  
*/
public without sharing class TAPS_BatchUpdate implements Database.Batchable<Id> {

    // records that need sharing recalculation
    private Set<Id> affectedRecordIds;

    // implementation for this specific object
    private TAPS_IBatch handler;

    private static final String AGREEMENT_SHARE = 'Apttus__APTS_Agreement__Share';
    private static final String DOCUMENT_VERSION_SHARE = 'Apttus__DocumentVersion__Share';
    
    /*
    *  @Author      : Todd Newman
    *  @Description : Parameterized constructor to initialize the variables
    *  @Param       : Set<Id>, TAPS_IBatch
    */

    public TAPS_BatchUpdate(Set<Id> affectedRecordIds, TAPS_IBatch handler)
    {
        this.affectedRecordIds = affectedRecordIds;
        this.handler = handler;
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : start method to collect the id of the scope records
    *  @Param       : Database.BatchableContext
    *  @Return      : Iterable<Id>
    */

    public Iterable<Id> start(Database.BatchableContext bc)
    {
        return new List<Id>(affectedRecordIds);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : execute method for the business logic
    *  @Param       : Database.BatchableContext, List<Id>
    *  @Return      : Void
    */

    public void execute(Database.BatchableContext bc, List<Id> recordIds)
    {
        ilib_LogEvent.rootTitle = 'TAPS Batch Run (' + handler.getShareObjectType().getDescribe().getName() + ')';
        ilib_LogEvent.push('TAPS_BatchUpdate.execute');
        ilib_LogEvent.push('TAPS_BatchUpdate.execute for ' + recordIds.size() + ' records');
        Set<Id> setRecordIds = new Set<Id>(recordIds);
        string handlerSobjectName = handler.getShareObjectType().getDescribe().getName();

        try
        {
            // see if the records have been persisted yet
            if (!areRecordsPersisted(recordIds))
                return;

            // determine the users who will have shares by the end of this
            Map<Id, Set<Id>> recordIdToUserIds = handler.mapRecordIdToUserIds(setRecordIds);
            ilib_LogEvent.message('in batch; recordIdToUserIds ' + recordIdToUserIds);

            // query existing shares
            List<SObject> extantShares = handler.getExtantShares(setRecordIds);

            // map record -> user from existing share records
            Map<Id, Set<Id>> existingRecordIdToUserIds = UtilsCollection.getMapOfIdToIds(extantShares, handler.getShareParentFieldName(), 'UserorGroupId');

            // maps for shares to create/delete
            Map<Id, Set<Id>> recordIdToNewShares = new Map<Id, Set<Id>>();
            Map<Id, Set<Id>> recordIdToObsoleteShares = new Map<Id, Set<Id>>();

            // compare (incoming) recordIdToUserIds with existingRecordIdToUserIds
            for (Id recordId : recordIdToUserIds.keySet())
            {
                if (!recordIdToUserIds.containsKey(recordId) && !existingRecordIdToUserIds.containsKey(recordId)) continue;

                // start with existing records
                Set<Id> usersWhoWillHaveShares = (recordIdToUserIds.containsKey(recordId) ? recordIdToUserIds.get(recordId) : new Set<Id>());
                Set<Id> usersWhoAlreadyHaveShares = (existingRecordIdToUserIds.containsKey(recordId) ? existingRecordIdToUserIds.get(recordId) : new Set<Id>());

                // Remove the existing users from the to-be users
                // what remains will be added
                Set<Id> usersToGiveSharesTo = new Set<Id>(usersWhoWillHaveShares);
                usersToGiveSharesTo.removeAll(usersWhoAlreadyHaveShares);
                recordIdToNewShares.put(recordId, usersToGiveSharesTo);

                // Remove the to-be users from the old set
                // what remains will be deleted
                Set<Id> usersToTakeSharesFrom = new Set<Id>(usersWhoAlreadyHaveShares);
                usersToTakeSharesFrom.removeAll(usersWhoWillHaveShares);
                recordIdToObsoleteShares.put(recordId, usersToTakeSharesFrom);
                ilib_LogEvent.message('TTN: for rec ' + recordId + ': willhave/alreadyhas/newshares/goneshares counts ' + usersWhoWillHaveShares.size() + '/' + usersWhoAlreadyHaveShares.size() + '/' + recordIdToNewShares.size() + '/' + recordIdToObsoleteShares.size());
            }

            ilib_LogEvent.message('removing ' + recordIdToObsoleteShares.size() + ' shares: ' + recordIdToObsoleteShares);
            ilib_LogEvent.message('adding ' + recordIdToNewShares.size() + ' shares: ' + recordIdToNewShares);

            handler.removeSharingRecords(recordIdToObsoleteShares);
            if(AGREEMENT_SHARE == handlerSobjectName) {
                TAPS_ApttusAgreements tapsAgreementsClass = new TAPS_ApttusAgreements();
                tapsAgreementsClass.createSharingRecord(recordIdToNewShares);
            }else if(DOCUMENT_VERSION_SHARE == handlerSobjectName) {
                TAPS_ApttusDocumentVersion tapsDocVersionClass = new TAPS_ApttusDocumentVersion();
                tapsDocVersionClass.createSharingRecord(recordIdToNewShares);
            }else {
                handler.createSharingRecords(recordIdToNewShares);
            }

            ilib_LogEvent.message('batch run complete');
        }
        catch (Exception e)
        {
            ApexExceptions.emit('TAPS Batch Update', e);

            ilib_LogEvent.push('EXCEPTION');
            ilib_LogEvent.message(e.getMessage().abbreviate(4000));
            ilib_LogEvent.pop();
        }
        finally
        {
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
        }
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Finish method for post execution logic
    *  @Param       : Database.BatchableContext
    *  @Return      : Void
    */

    public void finish(Database.BatchableContext bc)
    {
        /*ilib_LogEvent.quickEmit('TAPS Batch Finished', new Map<String, String> {
            'Share Record Type' => handler.getShareObjectType().getDescribe().getName(),
            'Record IDs' => String.join(new List<Id>(affectedRecordIds), ',')
        });*/
        ilib_LogEvent.setTitle('TAPS Batch Finished');
        ilib_LogEvent.push('TAPS_BatchUpdate.finish');
        ilib_LogEvent.info('Share Record Type =>'+handler.getShareObjectType().getDescribe().getName());
        ilib_LogEvent.info('Record IDs =>'+String.join(new List<Id>(affectedRecordIds),','));
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to check if the records are persisted
    *  NOTE: with the move to after commit platform event this method is obsolete, remove it sometime
    *  @Param       : List<Id>
    *  @Return      : Boolean
    */
    
    private Boolean areRecordsPersisted(List<Id> recordIds)
    {
        if (recordIds == null || recordIds.size() == 0) return true;

        SObjectType objectType = recordIds.get(0).getSobjectType();
        TAPS_ComposedBase impl = TAPS_ObjectSupport.sharingFactory(objectType);

        Map<Id, Set<Id>> recordIdToAccountIds = impl.getRecordIdToAccountIds(new Set<Id>(recordIds));

        Boolean alreadyPersisted = !recordIdToAccountIds.isEmpty();

        if (!alreadyPersisted)
        {
            ilib_LogEvent.message('recordIdToAccountIds were not found, deferring calc');
            //TASK0608051 - When recordIds is set of Territory Ids, Query Child Territories & add, if any, to same set and defer.
            String strObjectName = objectType.getDescribe().getName();
            Set<Id> setRecordIds = new Set<Id>(recordIds);
            setRecordIds = TAPS_DeferredRun.TERRITORY_JOB_OBJECT_NAME == strObjectName ? TAPS_DeferredRun.selectAndAddChildTerritoriesByTerritoryId(setRecordIds) : setRecordIds;
            TAPS_DeferredRun.deferSharing(strObjectName, setRecordIds);
        }

        return alreadyPersisted;
    }

}