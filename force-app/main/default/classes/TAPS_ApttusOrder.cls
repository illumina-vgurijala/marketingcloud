/*
 * @Author: Todd Newman
 * @Date:
 * @Description : Class for maintaining logic for order shares creation
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                 Date                        Description
 * Todd Newman                                         Inital Verion
 * Himanshu                 30-Mar-2022                Code Scan Fixes
 * 
 * ---------------------------------------------------------------------------------------------------------------------------------------
 */
public without sharing class TAPS_ApttusOrder extends TAPS_ComposedBase implements TAPS_IObjectsCustom {

    /*
    *   @author Todd Newman   
    *   @description  Describe the object
    *
    */
    public override SObjectType getObjectType() {
        return Apttus_Config2__Order__c.sObjectType;
    }
    /**
    * @author  Rahul
    * @description DCP-25384 UC Apex Sharing
    * @params Set<Id> recordIds
    * @return Map<Id, Set<Id>>
    **/
    public override Map<Id, Set<Id>> mapRecordToAccountsCustom(Set<Id> recordIds)
    {
        List<Apttus_Config2__Order__c> recordDetails = [SELECT Id, Apttus_Config2__SoldToAccountId__c,Ultimate_Consignee__c FROM Apttus_Config2__Order__c WHERE Id IN :recordIds];
        Map<Id, Set<Id>> mapToSoldTo = UtilsCollection.getMapOfIdToIds(recordDetails, 'Id', 'Apttus_Config2__SoldToAccountId__c');
        Map<Id, Set<Id>> mapToUC = UtilsCollection.getMapOfIdToIds(recordDetails, 'Id', 'Ultimate_Consignee__c');
        Map<Id, Set<Id>> accountsMap = UtilsCollection.getMergeMap(mapToSoldTo,mapToUC);
        System.debug('accountsMap'+accountsMap);
        return accountsMap;
    }

    /**
    * @author  Rahul
    * @description DCP-25384 UC Apex Sharing
    * @params Set<Id> recordIds
    * @return Set<Id>
    **/
    public override Set<Id> getRecordIdsFromAccountIdsCustom(Set<Id> accountIds)
    {
        List<Apttus_Config2__Order__c> recordDetails = new ApttusOrdersSelector().selectOrdersBySoldToAndUC(accountIds);
        return UtilsCollection.getSetOfIds(recordDetails, 'Id');
    }
    /**
    * @author  Rahul
    * @description mehod to return recordId which gets reparented is opportunity
    * @params Set<Id> 
    * @return Set<Id>
    **/
    public override Set<Id> getRecordIdsFromModifiedRecordIdsCustom(Set<Id> modifiedRecordIds)
    {
        // record which gets reparented is opportunity
        List<Apttus_Config2__Order__c> recordDetails = [SELECT Id FROM Apttus_Config2__Order__c WHERE Apttus_Config2__RelatedOpportunityId__c IN :modifiedRecordIds];
        return UtilsCollection.getSetOfIds(recordDetails, 'Id');
    }
    /*
    *   @author  Todd Newman     
    *   @description  Describe the object
    *
    */
    public override SObjectType getShareObjectType()
    {
        return Apttus_Config2__Order__Share.sObjectType;
    }
    /**
    * @author  Rahul
    * @description mehod to return parentId for sharing record
    * @params NA
    * @return void
    **/
    public override String getShareParentFieldName()
    {
        return 'ParentId';
    }
    /**
    * @author  Rahul
    * @description mehod to create sharing record for defined Sobject
    * @params Id recordId, Id userId
    * @return Apttus_Config2__Order__Share record
    **/
    public override SObject createSharingRecord(Id recordId, Id userId) {
        return new Apttus_Config2__Order__Share(
                UserOrGroupId = userId,
                ParentId = recordId,
                AccessLevel = 'Read',
                RowCause = Schema.Apttus_Config2__Order__Share.RowCause.Manual
        );
    }
    /**
    * @author  Rahul
    * @description mehod to filter by role in territory to only include certain sales roles
    * @params Map<Id, Set<Id>> territoryIdToUserIds, Map<Id, Set<Id>> accountIdToTerritoryIds, Map<Id, Set<Id>> recordIdToAccountIds
    * @return  Map<Id, Set<Id>>
    **/
    public override Map<Id, Set<Id>> filterTerritoryIdToUserIds(Map<Id, Set<Id>> territoryIdToUserIds, Map<Id, Set<Id>> accountIdToTerritoryIds, Map<Id, Set<Id>> recordIdToAccountIds)
    {
        // filter by role in territory to only include certain sales roles
        return filterSalesUsersByRoleInTerritory(territoryIdToUserIds);
    }

}