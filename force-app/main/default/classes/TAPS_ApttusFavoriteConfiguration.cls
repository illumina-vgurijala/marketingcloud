/**
 * @author 
 * @date   
 * @description : Apttus Favorite Configuration data controller class extending TAPS_ComposedBase and impementing the TAPS_IObjectsCustom
 * Modification Log:
 *       ------------------------
 * Rahul                      No Date Available           DCP-25384 UC Apex Sharing               
 * Jitesh Lakhwani            6-July-2022                 Code Scan fixes of Comments
 * 
 */

public without sharing class TAPS_ApttusFavoriteConfiguration extends TAPS_ComposedBase implements TAPS_IObjectsCustom {

    /**
    *@description : this will return the Apttus Favorite configuration sObjectType. 
    *@return SObjectType 
    */
    public override SObjectType getObjectType()
    {
        return Apttus_Config2__FavoriteConfiguration__c.sObjectType;
    }

    /**
    *@description : this is an implentation of the TAPS_IObjectsCustom.mapRecordToAccountsCustom method and will return the map of account id's based on favorite configuration object
    *@param : set<id> recordIds
    *@return : Map<Id, Set<Id>> : 'Id' is key and set<id> is account record id (example: 'Id' -> <record_1_id, record_2_id, ...>)
    * modified as part of DCP-25384
    */
    public override Map<Id, Set<Id>> mapRecordToAccountsCustom(Set<Id> recordIds)
    {
        List<Apttus_Config2__FavoriteConfiguration__c> recordDetails = [SELECT Id, Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.AccountId,Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Ultimate_Consignee__c FROM Apttus_Config2__FavoriteConfiguration__c WHERE Id IN :recordIds];
        Map<Id, Set<Id>> mapToSoldTo = UtilsCollection.getMapOfIdToIds(recordDetails, 'Id', 'Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.AccountId');
        Map<Id, Set<Id>> mapToUC = UtilsCollection.getMapOfIdToIds(recordDetails, 'Id', 'Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Ultimate_Consignee__c');
        Map<Id, Set<Id>> accountsMap = UtilsCollection.getMergeMap(mapToSoldTo,mapToUC);
        return accountsMap;
    }

    /**
    *@description : this is an implentation of the TAPS_IObjectsCustom.getRecordIdsFromAccountIdsCustom method and will return the set of apttus favorite configuration id's
    *@param  : set<id> accountids
    *@return : Set<Id> : set of apttus favorite configuration 
    * modified as part of DCP-25384
    */
    public override Set<Id> getRecordIdsFromAccountIdsCustom(Set<Id> accountIds)
    {
        List<Apttus_Config2__FavoriteConfiguration__c> recordDetails = [SELECT Id FROM Apttus_Config2__FavoriteConfiguration__c WHERE Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.AccountId IN :accountIds OR Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Ultimate_Consignee__c IN :accountIds ];
        return UtilsCollection.getSetOfIds(recordDetails, 'Id');
    }
    
    /**
    *@description : this is an implentation of the TAPS_IObjectsCustom.getRecordIdsFromModifiedRecordIdsCustom method and will return the set of apttus favorite configuration id's based on opportunity id's
    *@param  : set<id> modifiedRecordIds
    *@return : Set<Id> : set of apttus favorite configuration 
    * modified as part of DCP-25384
    */
    public override Set<Id> getRecordIdsFromModifiedRecordIdsCustom(Set<Id> modifiedRecordIds)
    {
        if (modifiedRecordIds.size() == 0) return modifiedRecordIds;

        // modified record IDs could be Opportunities
        if (UtilsCollection.getFirstIdFromSet(modifiedRecordIds).getSobjectType() == Opportunity.SObjectType)
        {
            List<Apttus_Config2__FavoriteConfiguration__c> recordDetails = [SELECT Id FROM Apttus_Config2__FavoriteConfiguration__c WHERE Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__c IN :modifiedRecordIds];
            return UtilsCollection.getSetOfIds(recordDetails, 'Id');
        }

        return modifiedRecordIds;
    }

    /**
    *@description : this will return the Favorite Configuration Share sObjectType. 
    *@return SObjectType 
    */
    public override SObjectType getShareObjectType()
    {
        return Apttus_Config2__FavoriteConfiguration__Share.sObjectType;
    }

    /**
    *@description : this will return the Favorite Configuration share object parent field name  
    *@param  : None
    *@return : String : Favorite Configuration share parent id field name : ParentId
    */
    public override String getShareParentFieldName()
    {
        return 'ParentId';
    }

    /**
    *@description : this will create the Favorite Configuration share object record and will return it  
    *@param  : Id recordId, Id userId
    *@return : SObject 
    */
    public override SObject createSharingRecord(Id recordId, Id userId) {
        return new Apttus_Config2__FavoriteConfiguration__Share(
                UserOrGroupId = userId,
                ParentId = recordId,
                AccessLevel = 'Edit',
                RowCause = Schema.Apttus_Config2__FavoriteConfiguration__Share.RowCause.Manual
        );
    }

    /**
    * @description filter by role in territory to only include certain sales roles
    * @params Map<Id, Set<Id>> territoryIdToUserIds, Map<Id, Set<Id>> accountIdToTerritoryIds, Map<Id, Set<Id>> recordIdToAccountIds
    * @return Map<Id, Set<Id>> 
    **/ 
    public override Map<Id, Set<Id>> filterTerritoryIdToUserIds(Map<Id, Set<Id>> territoryIdToUserIds, Map<Id, Set<Id>> accountIdToTerritoryIds, Map<Id, Set<Id>> recordIdToAccountIds)
    {
        // filter by role in territory to only include certain sales roles
        return filterSalesUsersByRoleInTerritory(territoryIdToUserIds);
    }

}