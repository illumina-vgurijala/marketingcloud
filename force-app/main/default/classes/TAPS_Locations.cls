/***************************************************************************************************************************************
* NAME   : TAPS_Locations 
* --------------------------------------------------------------------------------------------------------------------------------------
*/
public without sharing class TAPS_Locations extends TAPS_ComposedBase implements TAPS_IObjectsCustom
{
	/* 
    * @description: To return Object API Name
    * @return: SObjectType
    */
    public override SObjectType getObjectType()
    {
        return SVMXC__Site__c.sObjectType;
    }

	/* 
    * @description: to fetch ACcount record based on location 
    * @Param:Set<Id>
    * @return: Map<Id, Set<Id>>
    */
    public override Map<Id, Set<Id>> mapRecordToAccountsCustom(Set<Id> recordIds)
    {
        ilib_LogEvent.push('TAPS_Locations.mapRecordToAccountsCustom');
        List<SVMXC__Site__c> recordDetails = new LocationsSelector().selectLocationsFromIds(recordIds);

        // get map of locations mapped directly to accounts
        // this is for the case where the location has a link to account directly
        Map<Id, Set<Id>> recordIdToAccountIds = UtilsCollection.getMapOfIdToIds(recordDetails, 'Id', 'SVMXC__Account__c');

        // collect locations without accounts
        Set<Id> recordIDsWithNoAccount = new Set<Id>();
        for (SVMXC__Site__c record : recordDetails)
        {
            if (record.SVMXC__Account__c == null)
                recordIDsWithNoAccount.add(record.Id);
        }
        ilib_LogEvent.message('locationIDsWithNoAccount ' + recordIDsWithNoAccount);

        if (!recordIDsWithNoAccount.isEmpty())
        {
            // look for the account via the installed product (IP)
            List<SVMXC__Installed_Product__c> ipDetails = new InstalledProductsSelector().selecInstalledProductsFromLocation(recordIDsWithNoAccount);
            Map<Id, Id> recordIdToAccountId = UtilsCollection.getMapOfIdToId(ipDetails, 'SVMXC__Site__c', 'SVMXC__Company__c');
            ilib_LogEvent.message('recordIdToAccountId (via IP record) ' + recordIdToAccountId);

            for (Id recordId : recordIDsWithNoAccount)
            {
                if (recordIdToAccountId.containsKey(recordId))
                {
                    // got a match, add it to output
                    recordIdToAccountIds.put(recordId, new Set<Id> {recordIdToAccountId.get(recordId)});
                }
            }
        }

        ilib_LogEvent.message('final recordIdToAccountIds ' + recordIdToAccountIds);
        ilib_LogEvent.pop();
        return recordIdToAccountIds;
    }

	/* 
    * @description: to fetch ACcount record based on location 
    * @Param:Set<Id>
    * @return:  Set<Id>
    */
    public override Set<Id> getRecordIdsFromAccountIdsCustom(Set<Id> accountIds)
    {
        List<SVMXC__Site__c> recordDetails = new LocationsSelector().selectLocationsFromAccountIds(accountIds);
        return UtilsCollection.getSetOfIds(recordDetails);
    }

	/* 
    * @description: to fetch Ids based on location
    * @Param:Set<Id>
    * @return: Set<Id>
    */
    public override Set<Id> getRecordIdsFromModifiedRecordIdsCustom(Set<Id> modifiedRecordIds)
    {
        if (modifiedRecordIds.size() == 0) return modifiedRecordIds;

        if (UtilsCollection.getFirstIdFromSet(modifiedRecordIds).getSobjectType() == SVMXC__Installed_Product__c.SObjectType) { // assume must be IP IDs
            // lookup location IDs from IP IDs
            List<SVMXC__Installed_Product__c> recordDetails = new InstalledProductsSelector().selectInstalledProductsFromIds(modifiedRecordIds);
            return UtilsCollection.getSetOfIds(recordDetails, 'SVMXC__Site__c');
        }

        return modifiedRecordIds;
    }

	/* 
    * @description: To return Object API Name
    * @return: SObjectType
    */
    public override SObjectType getShareObjectType()
    {
        return SVMXC__Site__Share.sObjectType;
    }

	/* 
    * @description: To return Field API Name
    * @return: SObjectType
    */
    public override String getShareParentFieldName()
    {
        return 'ParentId';
    }

	/* 
    * @description: Create Sharing Record
    * @Param: Id,Id
    * @return: SObject
    */
    public override SObject createSharingRecord(Id recordId, Id userId)
    {
        return new SVMXC__Site__Share(
            UserOrGroupId = userId,
            ParentId = recordId,
            AccessLevel = 'Read',
            RowCause = Schema.SVMXC__Site__Share.RowCause.Manual
        );
    }

	/* 
    * @description: Filter Territories logic
    * @Param: Set<Id>, Map<Id, Set<Id>>
    * @return: Set<Id>
    */
    public override Set<Id> filterTerritories(Set<Id> territoryIds, Map<Id, Set<Id>> recordIdToAccountIds)
    {
        return keepIndirectTerritories(territoryIds);
    }

}