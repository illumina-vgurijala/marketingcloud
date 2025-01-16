/***************************************************************************************************************************************
* NAME   : TAPS_InstalledProducts 
* --------------------------------------------------------------------------------------------------------------------------------------
*/
public without sharing class TAPS_InstalledProducts extends TAPS_ComposedBase implements TAPS_IObjectsDirect {

    /* 
    * @description: To return Object API Name
    * @return: SObjectType
    */
    public override SObjectType getObjectType() {
        return SVMXC__Installed_Product__c.sObjectType;
    }

	/* 
    * @description: To return Field API Name
    * @return: SObjectType
    */
    public override String getLookupFieldName() {
        return 'SVMXC__Company__c';
    }

	/* 
    * @description: To return Object API Name
    * @return: SObjectType
    */
    public override SObjectType getShareObjectType() {
        return SVMXC__Installed_Product__Share.sObjectType;
    }

	/* 
    * @description: To return Field API Name
    * @return: SObjectType
    */	
    public override String getShareParentFieldName() {
        return 'ParentId';
    }

	/* 
    * @description: Create Sharing Record
    * @Param: Id, Id
    * @return: SObject
    */
    public override SObject createSharingRecord(Id recordId, Id userId) {
        return new SVMXC__Installed_Product__Share(
                UserOrGroupId = userId,
                ParentId = recordId,
                AccessLevel = 'Edit',
                RowCause = Schema.SVMXC__Installed_Product__Share.RowCause.Manual
        );
    }

	/* 
    * @description: Filter territories logic
    * @Param: Set<Id>, Map<Id, Set<Id>>
    * @return: SObject
    */	
    public override Set<Id> filterTerritories(Set<Id> territoryIds, Map<Id, Set<Id>> recordIdToAccountIds)
    {
        return keepDirectTerritories(territoryIds);
    }

}