/*
    * @Author: Todd Newman
    * @Date: 
    * @Description : 
    * -------------------------------------------------------------------------------------------------------
    *        Developer               Date                Description
    *        Todd Newman                                Initial Version
    *        Aman Tyagi             2022-03-29          CodeScan Fixes
    *        Iram Malik             14-Jul-2022         Codescan Fix
    * -------------------------------------------------------------------------------------------------------
    */
	public without sharing class TAPS_BatchImpl implements TAPS_IBatch {
        private static final String LOG_TITLE = 'TAPS_BatchImpl';

        // NOTE: without sharing added so that the insert in createSharingRecords will work for non-admin users
    
        /*
         * Implementation of batch methods
         *
         * This class is composed into TAPS_ComposedBase which is inherited by object-specific
         * implementations.  That means there are default implementations here which may be overridden
         * The methods in the composed class are defined as virtual. The methods are defined virtual
         * in TAPS_ComposedBase rather than here because this class will not have descendants
         */
    
    
        // the composed base will be extended by an implementation for a specific object (e.g. quotes)
        // that instantiation will have methods implemented that are object specific which we need to access
        private TAPS_ComposedBase objectSpecificImpl;
        private Map<Id, Set<Id>> recordIdToExclusiveATFSUsers= new Map<Id, Set<Id>>();
    
        /*
        * @Author: Todd Newman
        * @Description : Constructor of TAPS_BatchImpl class and instantiating TAPS_ComposedBase
        * @param: TAPS_ComposedBase objectSpecificImpl
        */
        public TAPS_BatchImpl(TAPS_ComposedBase objectSpecificImpl)
        {
            this.objectSpecificImpl = objectSpecificImpl;
        }
    
        /*
        * @Author:Todd Newman
        * @Description : traversing all the intermediary objects, generate a map from the records to be shared
        * to the users to share with based on ETM rules 
        * @param: Set<Id> recordIds
        * @return: recordIdToUserIds
        */
        public Map<Id, Set<Id>> mapRecordIdToUserIds(Set<Id> recordIds)
        {
            ilib_LogEvent.push(LOG_TITLE + '.mapRecordIdToUserIds');
    
            // map related ID -> Account IDs
            ilib_LogEvent.message('recordIds ' + recordIds);
            Map<Id, Set<Id>> recordIdToAccountIds = objectSpecificImpl.getRecordIdToAccountIds(recordIds);
            ilib_LogEvent.message('recordIdToAccountIds ' + recordIdToAccountIds);
    
            // filter based on the records, the accounts, or their relationship
            Set<Id> toShareRecordIds = objectSpecificImpl.filterRecordsRelatedToAccount(recordIdToAccountIds);
            Map<Id, Set<Id>> toShareRecordIdToAccountIds = buildFilteredRecordIdToAccountIds(toShareRecordIds, recordIdToAccountIds);
            ilib_LogEvent.message('filtered recordIdToAccountIds ' + toShareRecordIdToAccountIds);
    
            // map Account ID -> Territory IDs
            Set<Id> accountIds = UtilsCollection.flattenMapValueSets(toShareRecordIdToAccountIds);
            Map<Id, Set<Id>> accountIdToTerritoryIds = getAccountIdToTerritoryIds(accountIds);
            ilib_LogEvent.message('accountIdToTerritoryIds ' + accountIdToTerritoryIds);
    
            // filter on territory type (e.g. ignore levels in the tree)
            Set<Id> territoryIds = UtilsCollection.flattenMapValueSets(accountIdToTerritoryIds);
            Set<Id> toShareToTerritoryIds = objectSpecificImpl.filterTerritories(territoryIds, toShareRecordIdToAccountIds);
            Map<Id, Set<Id>> accountIdToSharedTerritoryIds = buildAccountIdToSharedTerritoryIds(accountIdToTerritoryIds, toShareToTerritoryIds);
            ilib_LogEvent.message('filtered accountIdToTerritoryIds ' + accountIdToSharedTerritoryIds);
    
            // map Territory ID -> User IDs
            Map<Id, Set<Id>> territoryIdToUserIds = getTerritoryIdToUserIds(toShareToTerritoryIds);
            ilib_LogEvent.message('territoryIdToUserIds ' + territoryIdToUserIds);
    
            // filter on role or some combination of role and record information
            Map<Id, Set<Id>> territoryIdToShareToUserIds = objectSpecificImpl.filterTerritoryIdToUserIds(territoryIdToUserIds, accountIdToSharedTerritoryIds, recordIdToAccountIds);
            ilib_LogEvent.message('filtered territoryIdToUserIds ' + territoryIdToShareToUserIds);
    
            //DCP-27435 Get Account To Field Support user details for each account for sharing
            Map<Id, Set<Id>> accountIdToFSUserIds = getAccountIdToFieldSupportUserIds(accountIds);
            ilib_LogEvent.message('accountIdToFSUserIds: ' + accountIdToFSUserIds);
            
            // combine maps to go from related ID -> User ID
            Map<Id, Set<Id>> recordIdToUserIds = buildMapOfRecordIdToUserIds(toShareRecordIdToAccountIds, accountIdToSharedTerritoryIds, territoryIdToShareToUserIds,accountIdToFSUserIds);
            ilib_LogEvent.message('recordIdToUserIds ' + recordIdToUserIds);
    
            ilib_LogEvent.pop();
            return recordIdToUserIds;
        }
    
         /*
        * @Author:Todd Newman
        * @Description :get the specific SObject that holds sharing records
        * @param: none
        */
        public SObjectType getShareObjectType()
        {
            throw new ApexSharingException('Implementation is required');
        }
     
        /*
        * @Author: Todd Newman
        * @Description: name the field on the Share table that refers to the parent record ID
        * will be ParentId for all custom objects but a more specific name for standard objects
        * @return : String
        * @param : none
        */
        public String getShareParentFieldName()
        {
            return 'ParentId';
        }
    
        /*
        * @Author: Todd Newman
        * @Description: get a dynamically-built selector that will retrieve manual shares for this object
        * @param : none
        */
        private TAPS_ISelector getShareSelector()
        {
            return new TAPS_ShareSelector(objectSpecificImpl);
        }
    
        /*
        * @Author: Todd Newman
        * @Description: retrieve manual shares on these records
        * @param : Set<Id> recordIds
        * @return : List<SObject>
        */
        public List<SObject> getExtantShares(Set<Id> recordIds)
        {
            return getShareSelector().selectManualByParentId(recordIds);
        }
    
        /*
        * @Author:Todd Newman
        * @Description: create Apex sharing records from the record IDs to the user IDs
        * @param : Map<Id, Set<Id>> recordIdToUserIds
        * @return : void
        */
        public void createSharingRecords(Map<Id, Set<Id>> recordIdToUserIds)
        {
            ilib_LogEvent.push(LOG_TITLE + '.createSharingRecords');
            if (recordIdToUserIds.size() == 0) return;
    
            List<SObject> shares = new List<SObject>();
    
            for (Id recordId : recordIdToUserIds.keySet())
            {
                if (recordId == null || recordIdToUserIds.get(recordId) == null || recordIdToUserIds.get(recordId).size() == 0) continue;
                for (Id userId : recordIdToUserIds.get(recordId)) {
                    SObject res = getShareRecord(recordId, userId);

                    if(res != null) {
                        shares.add(res);
                    } else {
                        ilib_LogEvent.info('TAPS.createSharingRecords: null from:' 
                          + String.valueOf(objectSpecificImpl).split(':')[0]);
                        ilib_LogEvent.info('recordId:' + recordId );
                        ilib_LogEvent.info('userId:' + userId );
                        ilib_LogEvent.info('isExclusiveATFSUser:' + isExclusiveATFSUser(recordId, userId));
                    }
                }
            }

            List<Database.SaveResult> allResults = Database.insert(shares, false);
            for (Integer i = 0; i < allResults.size(); i++)
            {
                Database.SaveResult res = allResults.get(i);
                if (!res.isSuccess())
                    documentDmlError(shares.get(i), res.getErrors());
                else
                    ilib_LogEvent.message('TAPS: share inserted successfully for ' + shares.get(i));
            }
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
        }

        /**
         * @Author: Gerardo Garcia
         * @Description: Gets record Share record depending if is from is ExclusiveATFSUser
         * @return: SObject
         */
        private SObject getShareRecord(Id recordId, Id userId) {
            // DCP-27435 changes for Account To Field Support sharing
            return isExclusiveATFSUser(recordId, userId) ?
                objectSpecificImpl.createATFSSharingRecord(recordId, userId) 
                : objectSpecificImpl.createSharingRecord(recordId, userId);
        }

        /**
         * @Author: Gerardo Garcia
         * @Description: Verifies if is from ExclusiveATFUser
         * @return Boolean.
         */
        private Boolean isExclusiveATFSUser(Id recordId, Id userId) {
            return recordIdToExclusiveATFSUsers.containsKey(recordId)
              && recordIdToExclusiveATFSUsers.get(recordId).contains(userId);
        }

        /*
        * @Author:Todd Newman
        * @Description: creates a share record specific to this implementation
        * @param : Id recordId, Id userId
        * @return : SObject
        */
        public SObject createSharingRecord(Id recordId, Id userId)
        {
            throw new ApexSharingException('Implementation is required');
        }
    
        /*
        * @Author: Todd Newman
        * @Description:  delete Apex sharing records from the record IDs to the user IDs
        * @param : Map<Id, Set<Id>> recordIdToUserIds
        * @return : void
        */
        public void removeSharingRecords(Map<Id, Set<Id>> recordIdToUserIds)
        {
            if (recordIdToUserIds.size() == 0) return;
    
            for (Id recordId : recordIdToUserIds.keyset())
                if (recordIdToUserIds.get(recordId).size() == 0)
                    recordIdToUserIds.remove(recordId);
    
            if (recordIdToUserIds.size() == 0) return;
    
            List<SObject> shares = getShareSelector().selectManualByParentId(recordIdToUserIds.keyset());
    
            List<SObject> sharesToRemove = new List<SObject>();
            for (SObject share : shares)
            {
                Set<Id> userIds = recordIdToUserIds.get((Id)share.get(objectSpecificImpl.getShareParentFieldName()));
                if (userIds.contains((Id)share.get('UserOrGroupId')))
                    sharesToRemove.add(share);
            }
    
            List<Database.DeleteResult> allResults = Database.delete(sharesToRemove, false);
            for (Integer i = 0; i < allResults.size(); i++)
            {
                Database.DeleteResult res = allResults.get(i);
                if (!res.isSuccess())
                    documentDmlError(shares.get(i), res.getErrors());
                else
                    ilib_LogEvent.message('TAPS: share removed successfully for ' + shares.get(i));
            }
    
        }
    
        private void documentDmlError(SObject objShare, List<Database.Error> errors)
        {
            String allErrorsString = '';
            for (Database.Error e : errors)
                allErrorsString += e.getMessage() + '\n\n';
                
            ilib_LogEvent.push('documentDmlError');
                    ilib_LogEvent.error('Error Description' + allErrorsString +'----');
                    ilib_LogEvent.pop();	
            /*
            ilib_LogEvent.quickEmit(
                    'TAPS: Insert sharing record error for ' + + objShare,
                    new Map<String, String> { 'Error Description' => allErrorsString }
            );*/
        }
    
        // now that records have been filtered, build map of the filtered IDs to account ID
        private Map<Id, Set<Id>> buildFilteredRecordIdToAccountIds(Set<Id> toShareRecordIds, Map<Id, Set<Id>> recordIdToAccountIds)
        {
            Map<Id, Set<Id>> toShareRecordIdToAccountId = new Map<Id, Set<Id>>();
            for (Id recordId : toShareRecordIds)
                toShareRecordIdToAccountId.put(recordId, recordIdToAccountIds.get(recordId));
    
            return toShareRecordIdToAccountId;
        }
    
        /*
        * @Author: Todd Newman
        * @Description: Changed from private to public for DCP-25384 UC Apex Sharing
        * getting accountId to the territory Ids
        * @param : Set<Id> accountIds
        * @return : accountIdToTerritoryIds
        */
        public Map<Id, Set<Id>> getAccountIdToTerritoryIds(Set<Id> accountIds)
        {
            // query for account->territory associations
            // INC0242945--Query only Direct territory association for related accounts    
            List<ObjectTerritory2Association> territoryLinks = new List<ObjectTerritory2Association>();
            if (objectSpecificImpl.getObjectType() == Opportunity.sObjectType)
                territoryLinks = new ObjectTerritory2AssociationsSelector().selectDirectByAccountIds(accountIds);
            else
                territoryLinks = new ObjectTerritory2AssociationsSelector().selectByAccountIds(accountIds);
            
            Map<Id, Set<Id>> accountIdToTerritoryIds = UtilsCollection.getMapOfIdToIds(territoryLinks, 'ObjectId', 'Territory2Id');
    
            // query for all parent nodes in territory hierarchy
            Set<Id> leafTerritoryIds = UtilsCollection.getSetOfIds(territoryLinks, 'Territory2Id');
            Map<Id, Set<Id>> territoryLeafIdToParentIds = new TerritoriesSelector().selectTerritoriesInHierarchy(leafTerritoryIds);
    
            // add parent territories to account->territory associations
            for (Id accountId : accountIdToTerritoryIds.keySet())
            {
                if (!accountIdToTerritoryIds.containsKey(accountId)) continue;
    
                Set<Id> parentTerritoryIds = new Set<Id>();
                for (Id leafId : accountIdToTerritoryIds.get(accountId))
                    if (territoryLeafIdToParentIds.containsKey(leafId))
                        parentTerritoryIds.addAll(territoryLeafIdToParentIds.get(leafId));
    
                accountIdToTerritoryIds.get(accountId).addAll(parentTerritoryIds);
            }
    
            return accountIdToTerritoryIds;
        }
    
        // now that territories have been filtered, build map of account IDs to filtered territory IDs
        private Map<Id, Set<Id>> buildAccountIdToSharedTerritoryIds(Map<Id, Set<Id>> accountIdToTerritoryIds, Set<Id> toShareToTerritoryIds)
        {
            Map<Id, Set<Id>> accountIdToSharedTerritoryIds = new Map<Id, Set<Id>>();
    
            for (Id accountId : accountIdToTerritoryIds.keySet())
            {
                Set<Id> filteredTerritoryIds = new Set<Id>();
                accountIdToSharedTerritoryIds.put(accountId, filteredTerritoryIds);
                for (Id territoryId : accountIdToTerritoryIds.get(accountId))
                {
                    if (toShareToTerritoryIds.contains(territoryId))
                        filteredTerritoryIds.add(territoryId);
                }
            }
    
            return accountIdToSharedTerritoryIds;
        }
    
        /*
        * @Author: Todd Newman
        * @Description: Changed from private to public for DCP-25384 UC Apex Sharing
        * getting territoryIds to the userIds
        * @param : Set<Id> territoryIds
        * @return : territoryIdToUserIds
        */
        public Map<Id, Set<Id>> getTerritoryIdToUserIds(Set<Id> territoryIds)
        {
            Map<Id, Set<Id>> territoryIdToUserIds = UtilsCollection.getMapOfIdToIds(new UserTerritory2AssociationSelector().selectByTerritoryId(territoryIds), 'Territory2Id', 'UserId');
            return territoryIdToUserIds;
        }
    
        /*
        * @Author: Todd Newman
        * @Description: DCP-27435 Get Account To Field Support user details for each account for sharing
        * @param : Set<Id> setAccountIds
        * @return: mapAccountToFSUsers
        */
        public Map<Id, Set<Id>> getAccountIdToFieldSupportUserIds(Set<Id> setAccountIds){
            Map<Id, Set<Id>> mapAccountToFSUsers = new Map<Id, Set<Id>>();
            if(!objectSpecificImpl.needToShareToATFS())
                return mapAccountToFSUsers;
            mapAccountToFSUsers = UtilsCollection.getMapOfIdToIds(new AccountToFieldSupportSelector().selectAccountToFieldSupport(setAccountIds)
                                                                    , 'Account__c', 'User__r.SVMXC__Salesforce_User__c');
            return mapAccountToFSUsers;
        }
    
        /*
        * @Author: Todd Newman
        * @Description: given all the maps we've built, create one from records to share to users
        *  Changed from private to public for DCP-25384 UC Apex Sharing
        *  DCP-27435 Changed signature for allowing account to Field support sharing 
        * @param :Map<Id, Set<Id>> recordIdToAccountIds, Map<Id, Set<Id>> accountIdToTerritoryIds, Map<Id, Set<Id>> territoryIdToUserIds,Map<Id, Set<Id>> accountIdToFSUserIds
        * @return: recordIdToUserIds
        */
        public Map<Id, Set<Id>> buildMapOfRecordIdToUserIds(Map<Id, Set<Id>> recordIdToAccountIds, Map<Id, Set<Id>> accountIdToTerritoryIds, Map<Id, Set<Id>> territoryIdToUserIds,Map<Id, Set<Id>> accountIdToFSUserIds)
        {
            Map<Id, Set<Id>> recordIdToUserIds = new Map<Id, Set<Id>>();
    
            for (Id recordId : recordIdToAccountIds.keySet())
            {
                Set<Id> userIds = new Set<Id>(),setTerritoryUserIds=new Set<Id>(),setExclusiveATFSUsers=new Set<Id>();
                recordIdToUserIds.put(recordId, userIds);
                
                if (!recordIdToAccountIds.containsKey(recordId)) continue;
                for (Id accountId : recordIdToAccountIds.get(recordId))
                {
                    if (accountId == null) continue;
                    //DCP-27435 Add values from accountIdToFSUserIds only if account id is found in map.
                    if (accountIdToFSUserIds.containsKey(accountId))
                    {
                        userIds.addAll(accountIdToFSUserIds.get(accountId));
                        setExclusiveATFSUsers.addAll(accountIdToFSUserIds.get(accountId));
                    }
                
                    if (!accountIdToTerritoryIds.containsKey(accountId)) continue;
                    for (Id territoryId : accountIdToTerritoryIds.get(accountId))
                    {
                        if (territoryId == null) continue;
                        if (!territoryIdToUserIds.containsKey(territoryId)) continue;
    
                        Set<Id> newUserIds = territoryIdToUserIds.get(territoryId);
                        newUserIds.remove(null);
    
                        userIds.addAll(newUserIds);
                        setTerritoryUserIds.addAll(newUserIds);
                    }
                    
                }
                //DCP-27435 Remove Territory users for exclusive field support users
                setExclusiveATFSUsers.removeAll(setTerritoryUserIds);            
                recordIdToExclusiveATFSUsers.put(recordId,setExclusiveATFSUsers);
            }
    
            ilib_LogEvent.message('recordIdToExclusiveATFSUsers: ' + recordIdToExclusiveATFSUsers);
            return recordIdToUserIds;
        }
    
        /*
        * @Author: Todd Newman
        * @Description: exception class for apex sharing
        * @param :none
        * @return: none
        */
        public class ApexSharingException extends Exception { }
    
    }