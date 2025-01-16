/***************************************************************************************************************************************
* NAME   : TAPS_Comments 
* --------------------------------------------------------------------------------------------------------------------------------------
*/
public without sharing class TAPS_Comments extends TAPS_ComposedBase implements TAPS_IObjectsCustom {

    /*
    * @description: return Object API Name
    * @return: SObjectType 
    */
    public override SObjectType getObjectType()
    {
        return Comment__c.sObjectType;
    }

	/*
    * @description: used to fetch data related to Account 
    * @return: Map<Id, Set<Id>> 
    */	
    public override Map<Id, Set<Id>> mapRecordToAccountsCustom(Set<Id> recordIds)
    {
        List<Comment__c> recordDetails = [SELECT Id, Work_Order__c, Work_Order__r.SVMXC__Company__c FROM Comment__c WHERE Id IN :recordIds];
        return UtilsCollection.getMapOfIdToIds(recordDetails, 'Id', 'Work_Order__r.SVMXC__Company__c');
    }

	/*
    * @description: returns Id related to comment Object
    * @return: Set<Id>
    */
    public override Set<Id> getRecordIdsFromAccountIdsCustom(Set<Id> accountIds)
    {
        List<Comment__c> commentDetails = [SELECT Id FROM Comment__c WHERE Work_Order__r.SVMXC__Company__c IN :accountIds];
        return UtilsCollection.getSetOfIds(commentDetails, 'Id');
    }

	/*
    * @description: used to fetch data related to Account 
    * @return: Map<Id, Set<Id>> 
    */
    public override Set<Id> getRecordIdsFromModifiedRecordIdsCustom(Set<Id> modifiedRecordIds)
    {
        if (modifiedRecordIds.size() == 0) return modifiedRecordIds;

        // modified record IDs could be Work Orders
        if (UtilsCollection.getFirstIdFromSet(modifiedRecordIds).getSobjectType() == SVMXC__Service_Order__c.SObjectType)
        {
            List<Comment__c> recordDetails = [SELECT Id FROM Comment__c WHERE Work_Order__c IN :modifiedRecordIds];
            return UtilsCollection.getSetOfIds(recordDetails, 'Id');
        }

        return modifiedRecordIds;
    }

	/*
    * @description:Returns Object API Name
    * @return: SObjectType
    */
    public override SObjectType getShareObjectType()
    {
        return Comment__Share.sObjectType;
    }

	/*
    * @description:Returns Field API Name 
    * @return: String
    */	
    public override String getShareParentFieldName()
    {
        return 'ParentId';
    }

	/*
    * @description:Create Sharing Record
    * @return: SObject
    */	
    public override SObject createSharingRecord(Id recordId, Id userId)
    {
        Comment__Share share = new Comment__Share(
            UserOrGroupId = userId,
            AccessLevel = 'Read',
            RowCause = Schema.Comment__Share.RowCause.Manual
        );
        share.put(getShareParentFieldName(), recordId);
        return share;
    }

	/*
    * @description: Used to filter territory based on user Id
    * @return: Map<Id, Set<Id>>
    */	
    public override Map<Id, Set<Id>> filterTerritoryIdToUserIds(Map<Id, Set<Id>> territoryIdToUserIds, Map<Id, Set<Id>> accountIdToTerritoryIds, Map<Id, Set<Id>> recordIdToAccountIds)
    {
        // filter by role in territory to only include certain sales roles
        return filterSalesUsersByRoleInTerritory(territoryIdToUserIds);
    }

}