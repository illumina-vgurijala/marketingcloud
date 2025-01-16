
/***************************************************************************************************************************************
* NAME   : TAPS_SmaxPartsRequest 
* --------------------------------------------------------------------------------------------------------------------------------------
*/
public without sharing class TAPS_SmaxPartsRequest extends TAPS_ComposedBase implements TAPS_IObjectsCustom {


	/*******************************************************************************************************
    * @description Method to get Object Type
    * @return SObjectType
    */
    public override SObjectType getObjectType()
    {
        return SVMXC__Parts_Request__c.sObjectType;
    }

	/*******************************************************************************************************
    * @description Method to create Map 
    * @param recordIds Set<Id>
    * @return  Map<Id, Set<Id>>
    */	
    public override Map<Id, Set<Id>> mapRecordToAccountsCustom(Set<Id> recordIds)
    {
        List<SVMXC__Parts_Request__c> recordDetails = [SELECT Id, SVMX_PS_Work_Order__r.SVMXC__Company__c FROM SVMXC__Parts_Request__c WHERE Id IN :recordIds];
        return UtilsCollection.getMapOfIdToIds(recordDetails, 'Id', 'SVMX_PS_Work_Order__r.SVMXC__Company__c');
    }

	/*******************************************************************************************************
    * @description Method to get record ids from Map 
    * @param accountIds Set<Id>
    * @return  Set<Id>
    */	
    public override Set<Id> getRecordIdsFromAccountIdsCustom(Set<Id> accountIds)
    {
        List<SVMXC__Parts_Request__c> recordDetails = [SELECT Id FROM SVMXC__Parts_Request__c WHERE SVMX_PS_Work_Order__r.SVMXC__Company__c IN :accountIds];
        return UtilsCollection.getSetOfIds(recordDetails, 'Id');
    }

	/*******************************************************************************************************
    * @description Method to get record ids from Map 
    * @param modifiedRecordIds Set<Id>
    * @return  Set<Id>
    */	
    public override Set<Id> getRecordIdsFromModifiedRecordIdsCustom(Set<Id> modifiedRecordIds)
    {
        if (modifiedRecordIds.size() == 0) return modifiedRecordIds;

        // modified record IDs might be Work Orders
        if (UtilsCollection.getFirstIdFromSet(modifiedRecordIds).getSobjectType() == SVMXC__Service_Order__c.SObjectType)
        {
            List<SVMXC__Parts_Request__c> recordDetails = [SELECT Id FROM SVMXC__Parts_Request__c WHERE SVMX_PS_Work_Order__c IN :modifiedRecordIds];
            return UtilsCollection.getSetOfIds(recordDetails, 'Id');
        }

        return modifiedRecordIds;
    }

	/*******************************************************************************************************
    * @description Method to get object Type of Parts Request Share Object
    * @return SObjectType
    */	
    public override SObjectType getShareObjectType()
    {
        return SVMXC__Parts_Request__Share.sObjectType;
    }

	/*******************************************************************************************************
    * @description Method to get Parent Id
    * @return String
    */	
    public override String getShareParentFieldName()
    {
        return 'ParentId';
    }

	/*******************************************************************************************************
    * @description Method to create Sharing Record
    * @param recordId Id
    * @param userId Id
    * @return SObject
    */	
    public override SObject createSharingRecord(Id recordId, Id userId)
    {
        return new SVMXC__Parts_Request__Share(
                UserOrGroupId = userId,
                ParentId = recordId,
                AccessLevel = 'Read',
                RowCause = Schema.SVMXC__Parts_Request__Share.RowCause.Manual
        );
    }

	/*******************************************************************************************************
    * @description Method to filter Territories
    * @param territoryIdToUserIds Map<Id, Set<Id>>
    * @param accountIdToTerritoryIds Map<Id, Set<Id>>
    * @param recordIdToAccountIds Map<Id, Set<Id>>
    * @return Set<Id>
    */	
    public override Map<Id, Set<Id>> filterTerritoryIdToUserIds(Map<Id, Set<Id>> territoryIdToUserIds, Map<Id, Set<Id>> accountIdToTerritoryIds, Map<Id, Set<Id>> recordIdToAccountIds)
    {
        // filter by role in territory to only include certain sales roles
        return filterSalesUsersByRoleInTerritory(territoryIdToUserIds);
    }

}