    /*
    *  @Author: Todd Newman
    *  @Date: 
    *  @Description: Class which contains methods related to ApttusApprovalRequest, method to create
    *  Apttus_Approval__Approval_Request__Share records and to filter Sales Users by role in Territory
    *  Modification Log:
    *    ---------------------------------------------------------------------------------------------------------------------------
    *         Developer                      Date                Description         
    *         Todd Newman                                      Initial Version
    *         Rahul                                            DCP-25384 UC Apex Sharing
    *         Nesar Mohan                 2022-03-31           CodeScan Fix 
    *    ---------------------------------------------------------------------------------------------------------------------------
    */

public without sharing class TAPS_ApttusApprovalRequest extends TAPS_ComposedBase implements TAPS_IObjectsCustom {

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to retrieve the sObject Type of Apttus_Approval__Approval_Request__c
    *  @Param       : None
    *  @Return      : SObjectType
    */

    public override SObjectType getObjectType()
    {
        return Apttus_Approval__Approval_Request__c.sObjectType;
    }
    
    /*
    *  @Author      : Todd Newman
    *  @Description : Method to retrieve a merged map of SoldTo and UC account ids related to Apttus_Approval__Approval_Request__c
    *  Modified by Rahul : DCP-25384 UC Apex Sharing
    *  @Param       : Set<Id>
    *  @Return      : Map<Id, Set<Id>>
    */

    public override Map<Id, Set<Id>> mapRecordToAccountsCustom(Set<Id> recordIds)
    {
        List<Apttus_Approval__Approval_Request__c> recordDetails = [SELECT Id, Apttus_QPApprov__ProposalId__r.Apttus_Proposal__Opportunity__c, Apttus_QPApprov__ProposalId__r.Apttus_Proposal__Opportunity__r.AccountId,Apttus_QPApprov__ProposalId__r.Apttus_Proposal__Opportunity__r.Ultimate_Consignee__c FROM Apttus_Approval__Approval_Request__c WHERE Id IN :recordIds];
        Map<Id, Set<Id>> mapToSoldTo = UtilsCollection.getMapOfIdToIds(recordDetails, 'Id', 'Apttus_QPApprov__ProposalId__r.Apttus_Proposal__Opportunity__r.AccountId');
        Map<Id, Set<Id>> mapToUC = UtilsCollection.getMapOfIdToIds(recordDetails, 'Id', 'Apttus_QPApprov__ProposalId__r.Apttus_Proposal__Opportunity__r.Ultimate_Consignee__c');
        Map<Id, Set<Id>> accountsMap = UtilsCollection.getMergeMap(mapToSoldTo,mapToUC);
        return accountsMap;
    }
    
    /*
    *  @Author      : Todd Newman
    *  @Description : Method to retrieve a set of Apttus_Approval__Approval_Request__c ids based on the account ids passed as a parameter
    *  Modified by Rahul : DCP-25384 UC Apex Sharing
    *  @Param       : Set<Id>
    *  @Return      : Set<Id>
    */

    public override Set<Id> getRecordIdsFromAccountIdsCustom(Set<Id> accountIds)
    {
        //List<Apttus_Approval__Approval_Request__c> recordDetails = [SELECT Id FROM Apttus_Approval__Approval_Request__c WHERE Apttus_QPApprov__ProposalId__r.Apttus_Proposal__Opportunity__r.AccountId IN :accountIds OR Apttus_QPApprov__ProposalId__r.Apttus_Proposal__Opportunity__r.Ultimate_Consignee__c IN :accountIds];
        List<Apttus_Approval__Approval_Request__c> recordDetails = new ApttusApprovalRequestsSelector().selectByAccounts(accountIds);
        return UtilsCollection.getSetOfIds(recordDetails, 'Id');
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to retrieve a set of Apttus_Approval__Approval_Request__c ids based on the opportunity ids passed as a parameter
    *  @Param       : Set<Id>
    *  @Return      : Set<Id>
    */

    public override Set<Id> getRecordIdsFromModifiedRecordIdsCustom(Set<Id> modifiedRecordIds)
    {
        // record which gets reparented is opportunity
        List<Apttus_Approval__Approval_Request__c> recordDetails = [SELECT Id FROM Apttus_Approval__Approval_Request__c WHERE Apttus_QPApprov__ProposalId__r.Apttus_Proposal__Opportunity__c IN :modifiedRecordIds];
        System.debug('Approval recordDetails'+recordDetails);
        return UtilsCollection.getSetOfIds(recordDetails, 'Id');
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to retrieve sObjectType of Apttus_Approval__Approval_Request__Share
    *  @Param       : None
    *  @Return      : SObjectType
    */

    public override SObjectType getShareObjectType()
    {
        return Apttus_Approval__Approval_Request__Share.sObjectType;
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
    *  @Description : Method to create and return Apttus_Approval__Approval_Request__Share record based
    *  on the userId and recordId passed as parameters
    *  @Param       : two parameters of type Id
    *  @Return      : SObject
    */
    public override SObject createSharingRecord(Id recordId, Id userId)
    {
        return new Apttus_Approval__Approval_Request__Share(
                UserOrGroupId = userId,
                ParentId = recordId,
                AccessLevel = 'Edit',
                RowCause = Schema.Apttus_Approval__Approval_Request__Share.RowCause.Manual
        );
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to filter by role in territory to only include certain sales roles
    *  @Param       : three parameters of type Map<Id, Set<Id>>
    *  @Return      : Map<Id, Set<Id>>
    */
    public override Map<Id, Set<Id>> filterTerritoryIdToUserIds(Map<Id, Set<Id>> territoryIdToUserIds, Map<Id, Set<Id>> accountIdToTerritoryIds, Map<Id, Set<Id>> recordIdToAccountIds)
    {
        // filter by role in territory to only include certain sales roles
        return filterSalesUsersByRoleInTerritory(territoryIdToUserIds);
    }

}