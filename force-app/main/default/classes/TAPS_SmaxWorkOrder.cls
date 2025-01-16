/***************************************************************************************************************************************
* NAME   : TAPS_SmaxWorkOrder 
* --------------------------------------------------------------------------------------------------------------------------------------
*/
public without sharing class TAPS_SmaxWorkOrder extends TAPS_ComposedBase implements TAPS_IObjectsDirect
{

    /*******************************************************************************************************
    * @description Method to get Object Type
    * @return SObjectType
    */
    public override SObjectType getObjectType() {
        return SVMXC__Service_Order__c.sObjectType;
    }

	/*******************************************************************************************************
    * @description Method to get field Name Company
    * @return String
    */	
    public override String getLookupFieldName() {
        return 'SVMXC__Company__c';
    }

	/*******************************************************************************************************
    * @description Method to get object Type of Service Order Share Object
    * @return SObjectType
    */	
    public override SObjectType getShareObjectType() {
        return SVMXC__Service_Order__Share.sObjectType;
    }

	/*******************************************************************************************************
    * @description Method to get Parent Id
    * @return String
    */	
    public override String getShareParentFieldName() {
        return 'ParentId';
    }

	/*******************************************************************************************************
    * @description Method to create Sharing Record
    * @param recordId Id
    * @param userId Id
    * @return SObject
    */
    public override SObject createSharingRecord(Id recordId, Id userId) {
        return new SVMXC__Service_Order__Share(
                UserOrGroupId = userId,
                ParentId = recordId,
                AccessLevel = 'Read',
                RowCause = Schema.SVMXC__Service_Order__Share.RowCause.Manual
        );
    }

	/*******************************************************************************************************
    * @description Method to create Map Territories to User Id
    * @param accountIdToTerritoryIds Map<Id, Set<Id>>
    * @param territoryIdToUserIds Map<Id, Set<Id>>
    * @param territoryIdToUserIds Map<Id, Set<Id>>
    * @return Map<Id, Set<Id>>
    */	
    public override Map<Id, Set<Id>> filterTerritoryIdToUserIds(Map<Id, Set<Id>> territoryIdToUserIds, Map<Id, Set<Id>> accountIdToTerritoryIds, Map<Id, Set<Id>> recordIdToAccountIds)
    {
        // filter by role in territory to only include certain sales roles
        return filterSalesUsersByRoleInTerritory(territoryIdToUserIds);
    }
	
	/*******************************************************************************************************
    * @description  DCP-42919 Method to filter Territories
    * @param territoryIds Set<Id>
    * @param recordIdToAccountIds Map<Id, Set<Id>>
    * @return Set<Id>
    */	
	public override Set<Id> filterTerritories(Set<Id> territoryIds, Map<Id, Set<Id>> recordIdToAccountIds)
    {
        return keepDirectTerritories(territoryIds);
    }

}