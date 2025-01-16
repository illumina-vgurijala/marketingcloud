/**
*    @author Rahul Sharma
*    @date   2019-06-21
*    @description    DCP-25384 UC Apex Sharing
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Rahul Sharma                21 Jun 2019            DCP-25384 UC Apex Sharing
*             Akshay Mohan                20 Sep 2019            DCP-27435 Account Plan Sharing for Account To Field Support changes.
*    ---------------------------------------------------------------------------------------------------------
*                    
*/
 
global class OpportunitiesBatchSharing extends ilib_ScheduleAndBatch{
 
    // records that need sharing recalculation
    private Set<Id> affectedRecordIds;
    public String strQuery;
    private Set<Id> setAccountIds;
 
    public OpportunitiesBatchSharing(Set<Id> affectedRecordIds)
    {
        this.affectedRecordIds = affectedRecordIds;
    }
 
    global override Database.QueryLocator start(Database.BatchableContext BC){
        this.strQuery = 'SELECT Id, Name,Ultimate_Consignee__c,AccountId,Primary_Field_Service_Engineer__c,Primary_Field_Application_Scientist__c,Field_Service_Manager__c,Field_Application_Manager__c '
                        +'FROM Opportunity '
                        +'WHERE Id IN :affectedRecordIds';
        return Database.getQueryLocator(strQuery);
    }
 
    global override void execute(Database.BatchableContext bc, List<SObject> recordIds)
    {
        TAPS_Opportunity opportunityImpl = new TAPS_Opportunity();
        TAPS_BatchImpl batchImpl = new TAPS_BatchImpl(opportunityImpl);
        List<Opportunity> oppList = (List<Opportunity>) recordIds;
        Set<Id> setRecordIds = UtilsCollection.getSetOfIds(oppList,'Id');

        ilib_LogEvent.push('OpportunitiesBatchSharing.execute');
        ilib_LogEvent.push('OpportunitiesBatchSharing.execute for ' + recordIds.size() + 'records');
        
        try
        {
            Map<Id, Set<Id>> oppIdToFieldUserIds = new Map<Id, Set<Id>>();
            Map<Id, Set<Id>> oppToUCUserIds = new Map<Id, Set<Id>>();// used as recordtouserIds

            for(Opportunity opp : oppList)
            {
                   oppIdToFieldUserIds.put(opp.Id, new Set<Id> {
                                            opp.Primary_Field_Service_Engineer__c,
                                            opp.Primary_Field_Application_Scientist__c,
                                            opp.Field_Service_Manager__c,
                                            opp.Field_Application_Manager__c
                   });
                   oppIdToFieldUserIds.get(opp.Id).remove(null);
            }
            System.debug('oppIdToFieldUserIds:'+oppIdToFieldUserIds);

            // map related ID -> Account IDs and ID -> UC IDs
            Map<Id, Set<Id>> recordIdToAccountIds = new Map<Id, Set<Id>>();
            Map<Id, Set<Id>> recordIdToUCIds = new Map<Id, Set<Id>>();
            for (Opportunity opp : oppList)
            {
                recordIdToAccountIds.put(opp.Id, new Set<Id> {opp.AccountId} );
                recordIdToUCIds.put(opp.Id, new Set<Id> {opp.Ultimate_Consignee__c} );
            }
            System.debug('recordIdToAccountIds:' + recordIdToAccountIds);
            System.debug('recordIdToUCIds:' + recordIdToUCIds);

            Set<Id> accountIds = UtilsCollection.flattenMapValueSets(recordIdToAccountIds);
            Set<Id> uCIds = UtilsCollection.flattenMapValueSets(recordIdToUCIds);
            Set<Id> setAccounts = new Set<Id>();
            setAccounts.addAll(accountIds);
            setAccounts.addAll(uCIds);

            Map<Id, Set<Id>> soldToIdToTerritoryIds = new Map<Id, Set<Id>>();
            Map<Id, Set<Id>> ucIdToTerritoryIds = new Map<Id, Set<Id>>();
            Map<Id, Set<Id>> accountIdToTerritoryIds = batchImpl.getAccountIdToTerritoryIds(setAccounts);
            System.debug('accountIdToTerritoryIds:' + accountIdToTerritoryIds);

            for (Id i: accountIdToTerritoryIds.keySet())
            {
                if (accountIds.contains(i))
                    soldToIdToTerritoryIds.put(i, new Set<Id>(accountIdToTerritoryIds.get(i)));   
                if (uCIds.contains(i))
                    ucIdToTerritoryIds.put(i, new Set<Id>(accountIdToTerritoryIds.get(i))); 
            }
            System.debug('soldToIdToTerritoryIds:' + soldToIdToTerritoryIds);
            System.debug('ucIdToTerritoryIds:' + ucIdToTerritoryIds);

            Set<Id> ucTerritories = new Set<Id>();
            // compare any territories in UC map that are not in sold to map, keep the territories in UC map only (not in sold to map)
            for (Opportunity opp : oppList)
            {
                Set<Id> setSoldToId = recordIdToAccountIds.get(opp.Id);
                Id soldToId = UtilsCollection.getFirstIdFromSet(setSoldToId);
                Set<Id> setUcId = recordIdToUCIds.get(opp.Id);
                Id ucId = UtilsCollection.getFirstIdFromSet(setUcId);

                Set<Id> oppSoldToTerritories = soldToIdToTerritoryIds.get(soldToId);
                Set<Id> oppUcTerritories = ucIdToTerritoryIds.get(ucId);

                if (oppUcTerritories == null) oppUcTerritories = new Set<Id>();
                if (oppSoldToTerritories != null) oppUcTerritories.removeAll(oppSoldToTerritories);

                ucTerritories.addAll(oppUcTerritories);
            }
            System.debug('ucTerritories'+ucTerritories);
            System.debug('ucIdToTerritoryIds'+ucIdToTerritoryIds);

            // map Territory ID -> User IDs
            Map<Id, Set<Id>> territoryIdToUserIds = batchImpl.getTerritoryIdToUserIds(ucTerritories);
            System.debug('territoryIdToUserIds:' + territoryIdToUserIds);

            // filter on role or some combination of role and record information
            Map<Id, Set<Id>> territoryIdToShareToUserIds = opportunityImpl.filterTerritoryIdToUserIds(territoryIdToUserIds, null, null);
            System.debug('filtered territoryIdToUserIds:' + territoryIdToShareToUserIds);

            // combine maps to go from related ID -> User ID

            //DCP-27435 Account Plan Sharing for Account To Field Support changes
            Map<Id, Set<Id>> recordIdToUserIds = batchImpl.buildMapOfRecordIdToUserIds(recordIdToUCIds, ucIdToTerritoryIds, territoryIdToShareToUserIds,new Map<Id, Set<Id>>()); 

            System.debug('recordIdToUserIds' + recordIdToUserIds);


            //Merge Maps from Account Field Support and UC Sharing
            Map<Id,Set<Id>> finalSharedUsers = UtilsCollection.getMergeMap(oppIdToFieldUserIds,recordIdToUserIds);
            System.debug('finalSharedUsers:'+finalSharedUsers);

            // query existing shares
            //List<OpportunityShare> extantShares = [SELECT Id, OpportunityId,UserOrGroupId,RowCause FROM OpportunityShare WHERE OpportunityId IN: setRecordIds AND RowCause = 'Manual'];
            List<OpportunityShare> extantShares = batchImpl.getExtantShares(setRecordIds);
            System.debug('extantShares'+extantShares);

            // map record -> user from existing share records
            Map<Id, Set<Id>> existingRecordIdToUserIds = UtilsCollection.getMapOfIdToIds(extantShares, 'OpportunityId', 'UserorGroupId');
            System.debug('existingRecordIdToUserIds'+existingRecordIdToUserIds);

            // maps for shares to create/delete
            Map<Id, Set<Id>> recordIdToNewShares = new Map<Id, Set<Id>>();
            Map<Id, Set<Id>> recordIdToObsoleteShares = new Map<Id, Set<Id>>();

            // compare (incoming) recordIdToUserIds with existingRecordIdToUserIds
            for (Id recordId : finalSharedUsers.keySet())
            {
                if (!finalSharedUsers.containsKey(recordId) && !existingRecordIdToUserIds.containsKey(recordId)) continue;
    
                // start with existing records
                Set<Id> usersWhoWillHaveShares = (finalSharedUsers.containsKey(recordId) ? finalSharedUsers.get(recordId) : new Set<Id>());
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

            batchImpl.removeSharingRecords(recordIdToObsoleteShares);
            batchImpl.createSharingRecords(recordIdToNewShares);

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
 
    global override void finish(Database.BatchableContext bc)
    {
        ilib_LogEvent.quickEmit('TAPS Batch Finished', new Map<String, String> {
            'Share Record Type' => 'OpportunityShare',
            'Record IDs' => String.join(new List<Id>(affectedRecordIds), ',')
        });
    }
}