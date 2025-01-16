/***************************************************************************************************************************************
* NAME   : TAPS_ProductStock 
* --------------------------------------------------------------------------------------------------------------------------------------
*/
public without sharing class TAPS_ProductStock extends TAPS_ComposedBase implements TAPS_IObjectsCustom {

	/* 
    * @description: To return Object API Name
    * @return: SObjectType
    */	
    public override SObjectType getObjectType()
    {
        return SVMXC__Product_Stock__c.sObjectType;
    }

	/* 
    * @description: to fetch ACcount record based on Product Stock record 
    * @Param:Set<Id>
    * @return: Map<Id, Set<Id>>
    */
    public override Map<Id, Set<Id>> mapRecordToAccountsCustom(Set<Id> recordIds)
    {
        List<SVMXC__Product_Stock__c> recordDetails = [SELECT Id, SVMXC__Location__r.SVMXC__Account__c FROM SVMXC__Product_Stock__c WHERE Id IN :recordIds];
        return UtilsCollection.getMapOfIdToIds(recordDetails, 'Id', 'SVMXC__Location__r.SVMXC__Account__c');
    }

	/* 
    * @description: to fetch ACcount record based on Product Stock 
    * @Param:Set<Id>
    * @return:  Set<Id>
    */	
    public override Set<Id> getRecordIdsFromAccountIdsCustom(Set<Id> accountIds)
    {
        List<SVMXC__Product_Stock__c> recordDetails = [SELECT Id FROM SVMXC__Product_Stock__c WHERE SVMXC__Location__r.SVMXC__Account__c IN :accountIds];
        return UtilsCollection.getSetOfIds(recordDetails, 'Id');
    }

	/* 
    * @description: to fetch modified records based on Ids
    * @Param:Set<Id>
    * @return: Set<Id>
    */	
    public override Set<Id> getRecordIdsFromModifiedRecordIdsCustom(Set<Id> modifiedRecordIds)
    {
        if (modifiedRecordIds.size() == 0) return modifiedRecordIds;

        // modified record IDs might be location
        if (UtilsCollection.getFirstIdFromSet(modifiedRecordIds).getSobjectType() == SVMXC__Site__c.SObjectType)
        {
            List<SVMXC__Product_Stock__c> recordDetails = [SELECT Id FROM SVMXC__Product_Stock__c WHERE SVMXC__Location__c IN :modifiedRecordIds];
            return UtilsCollection.getSetOfIds(recordDetails, 'Id');
        }

        return modifiedRecordIds;
    }

	/* 
    * @description: To return Object API Name
    * @return: SObjectType
    */	
    public override SObjectType getShareObjectType()
    {
        return SVMXC__Product_Stock__Share.sObjectType;
    }

    /* 
    * @description: To return Field API Name
    * @return: String
    */	
    public override String getShareParentFieldName()
    {
        return 'ParentId';
    }

	/* 
    * @description: Create Sharing Record
    * @Params :Id,Id
    * @return: SObject
    */
    public override SObject createSharingRecord(Id recordId, Id userId)
    {
        SVMXC__Product_Stock__Share share = new SVMXC__Product_Stock__Share(
                UserOrGroupId = userId,
                AccessLevel = 'Edit',
                RowCause = Schema.SVMXC__Product_Stock__Share.RowCause.Manual
        );
        share.put(getShareParentFieldName(), recordId);
        return share;
    }

	/* 
    * @description: logic to filter Territories
    * @Params :Set<Id>, Map<Id, Set<Id>>
    * @return: Set<Id>
    */	
    public override Set<Id> filterTerritories(Set<Id> territoryIds, Map<Id, Set<Id>> recordIdToAccountIds)
    {
        return keepIndirectTerritories(territoryIds);
    }

}