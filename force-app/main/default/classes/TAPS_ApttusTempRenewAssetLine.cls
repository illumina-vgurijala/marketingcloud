    /*
    *  @Author: Todd Newman
    *  @Date: 
    *  @Description: Class contains methods related to the logic of Apttus_Config2__TempRenewAssetLineItem__c
    *  Modification Log:
    *    ---------------------------------------------------------------------------------------------------------------------------
    *         Developer                      Date                Description         
    *         Todd Newman                                      Initial Version
    *         Rahul                                            DCP-25384 UC Apex Sharing
    *         Nesar Mohan                 2022-03-31           CodeScan Fix 
    *    ---------------------------------------------------------------------------------------------------------------------------
    */

public without sharing class TAPS_ApttusTempRenewAssetLine extends TAPS_ComposedBase implements TAPS_IObjectsCustom {

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to retrieve the sObject Type of Apttus_Config2__TempRenewAssetLineItem__c
    *  @Param       : None
    *  @Return      : SObjectType
    */
    public override SObjectType getObjectType()
    {
        return Apttus_Config2__TempRenewAssetLineItem__c.sObjectType;
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to retrieve a merged map of SoldTo and UC account ids related to Apttus_Config2__TempRenewAssetLineItem__c
    *  Modified by Rahul : DCP-25384 UC Apex Sharing
    *  @Param       : Set<Id>
    *  @Return      : Map<Id, Set<Id>>
    */
    public override Map<Id, Set<Id>> mapRecordToAccountsCustom(Set<Id> recordIds)
    {
        List<Apttus_Config2__TempRenewAssetLineItem__c> recordDetails = [SELECT Id, Apttus_Config2__RenewAssetGroupId__r.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.AccountId,Apttus_Config2__RenewAssetGroupId__r.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Ultimate_Consignee__c FROM Apttus_Config2__TempRenewAssetLineItem__c WHERE Id IN :recordIds];
        Map<Id, Set<Id>> mapToSoldTo = UtilsCollection.getMapOfIdToIds(recordDetails, 'Id', 'Apttus_Config2__RenewAssetGroupId__r.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.AccountId');
        Map<Id, Set<Id>> mapToUC = UtilsCollection.getMapOfIdToIds(recordDetails, 'Id', 'Apttus_Config2__RenewAssetGroupId__r.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Ultimate_Consignee__c');
        Map<Id, Set<Id>> accountsMap = UtilsCollection.getMergeMap(mapToSoldTo,mapToUC);
        return accountsMap;
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to retrieve a set of Apttus_Config2__TempRenewAssetLineItem__c ids based on the account ids passed as a parameter
    *  Modified by Rahul : DCP-25384 UC Apex Sharing
    *  @Param       : Set<Id>
    *  @Return      : Set<Id>
    */

    public override Set<Id> getRecordIdsFromAccountIdsCustom(Set<Id> accountIds)
    {
        List<Apttus_Config2__TempRenewAssetLineItem__c> recordDetails = [SELECT Id FROM Apttus_Config2__TempRenewAssetLineItem__c WHERE Apttus_Config2__RenewAssetGroupId__r.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.AccountId IN :accountIds OR Apttus_Config2__RenewAssetGroupId__r.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Ultimate_Consignee__c IN :accountIds];
        return UtilsCollection.getSetOfIds(recordDetails, 'Id');
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to retrieve a set of Apttus_Config2__TempRenewAssetLineItem__c ids based on the opportunity ids passed as a parameter
    *  @Param       : Set<Id>
    *  @Return      : Set<Id>
    */
    public override Set<Id> getRecordIdsFromModifiedRecordIdsCustom(Set<Id> modifiedRecordIds)
    {
        if (modifiedRecordIds.size() == 0) return modifiedRecordIds;

        // modified record IDs could be Opportunities
        if (UtilsCollection.getFirstIdFromSet(modifiedRecordIds).getSobjectType() == Opportunity.SObjectType)
        {
            List<Apttus_Config2__TempRenewAssetLineItem__c> recordDetails = [SELECT Id FROM Apttus_Config2__TempRenewAssetLineItem__c WHERE Apttus_Config2__RenewAssetGroupId__r.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__c IN :modifiedRecordIds];
            return UtilsCollection.getSetOfIds(recordDetails, 'Id');
        }

        return modifiedRecordIds;
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to retrieve sObjectType of Apttus_Config2__TempRenewAssetLineItem__Share
    *  @Param       : None
    *  @Return      : SObjectType
    */
    public override SObjectType getShareObjectType()
    {
        return Apttus_Config2__TempRenewAssetLineItem__Share.sObjectType;
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to retrieve the API name of parentId field
    *  @Param       : None
    *  @Return      : String
    */
    public override String getShareParentFieldName()
    {
        return 'ParentId';
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to create and return Apttus_Config2__TempRenewAssetLineItem__Share record based
    *  on the userId and recordId passed as parameters
    *  @Param       : two parameters of type Id
    *  @Return      : SObject
    */
    public override SObject createSharingRecord(Id recordId, Id userId) {
        return new Apttus_Config2__TempRenewAssetLineItem__Share(
                UserOrGroupId = userId,
                ParentId = recordId,
                AccessLevel = 'Read',
                RowCause = Schema.Apttus_Config2__TempRenewAssetLineItem__Share.RowCause.Manual
        );
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to filter by role in territory to only include certain sales roles
    *  @Param: three parameters of type Map<Id, Set<Id>>
    *  @Return      : Map<Id, Set<Id>>
    */
    public override Map<Id, Set<Id>> filterTerritoryIdToUserIds(Map<Id, Set<Id>> territoryIdToUserIds, Map<Id, Set<Id>> accountIdToTerritoryIds, Map<Id, Set<Id>> recordIdToAccountIds)
    {
        // filter by role in territory to only include certain sales roles
        return filterSalesUsersByRoleInTerritory(territoryIdToUserIds);
    }

}