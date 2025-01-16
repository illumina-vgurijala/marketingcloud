/**
 *    @author Bharath Varma
 *    @date   25-March-2022
 *    @description    TAPS_ApttusRelatedAgreement object type class 
 *    Modification Log:
 *   ---------------------------------------------------------------------------------------------------------------------------
 *    Developer                   Date                  Description    
 *    Bharath Varma           25-Mar-2022             Initial Commit
 *   ---------------------------------------------------------------------------------------------------------------------------
**/
public without sharing class TAPS_ApttusRelatedAgreement extends TAPS_ComposedBase implements TAPS_IObjectsCustom {
    // Added to TAPS_ObjectSupport
    /*
    *  @AUTHOR:  Bharath Varma
    *  @DESCRIPTION: get SObjective type 
    *  @PARAM :  none
    *  @RETURN:  SObjectType
    */
    public override SObjectType getObjectType() {
        return Apttus__APTS_Related_Agreement__c.sObjectType;
    }

    /*
    @Author : Bharath Varma
    @Story : TASK0718153
    @Description : Add key and value to a map
    */
    private void addValuesToMap(Map<Id, Set<Id>> mapIdToSetIds, Id key, Id value) {
        if (!mapIdToSetIds.containsKey(key)) {
            mapIdToSetIds.put(key, new Set<Id>());
        }
        mapIdToSetIds.get(key).add(value);
    }
    
    /*
    *  @AUTHOR:  Bharath Varma
    *  @DESCRIPTION: get map of record ids to set of Account Ids 
    *  @PARAM :  Set<Id> recordIds
    *  @RETURN:  Map<Id, Set<Id>> map of record id to set of account ids
    */
    public override Map<Id, Set<Id>> mapRecordToAccountsCustom(Set<Id> recordIds)
    {
        // get all the related agreement records along with the Agreement Ids
        List<Apttus__APTS_Related_Agreement__c> recordDetails = new ApttusRelatedAgreementSelectors().getRelatedAgreementRecordsByIds(recordIds);
        Map<Id, Set<Id>> mapAgrIdToRelatedAgreementIds = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> accountsMap = new Map<Id, Set<Id>>();
        for(Apttus__APTS_Related_Agreement__c relatedAgr : recordDetails) {
            // Add contract from Id to map
            addValuesToMap(mapAgrIdToRelatedAgreementIds, relatedAgr.Apttus__APTS_Contract_From__c, relatedAgr.Id);
            // Add contract to Id to map
            addValuesToMap(mapAgrIdToRelatedAgreementIds, relatedAgr.Apttus__APTS_Contract_To__c, relatedAgr.Id);
        }

        // from the agreement Ids, query the Agreement Account relatioships to get all the accounts associated to these agreements
        List<Agreement_Account_Relationship__c> relatedAccountRelatioships = new AgreementAccountRelationshipSelectors().selectByAgreementId(mapAgrIdToRelatedAgreementIds.keySet());

        for(Agreement_Account_Relationship__c relatedAccountRelatioship : relatedAccountRelatioships) {
            if (mapAgrIdToRelatedAgreementIds.containsKey(relatedAccountRelatioship.Agreement__c)) {
                for(Id relatedAgrId : mapAgrIdToRelatedAgreementIds.get(relatedAccountRelatioship.Agreement__c)) {
                    addValuesToMap(accountsMap, relatedAgrId, relatedAccountRelatioship.Account__c);
                }
            }
        }

        return accountsMap;
    }

    /*
    *  @AUTHOR:  Bharath Varma
    *  @DESCRIPTION: get set of record ids from Account Ids
    *  @PARAM :  Set<Id> accountIds
    *  @RETURN:  Set<Id> record Ids
    */
    public override Set<Id> getRecordIdsFromAccountIdsCustom(Set<Id> accountIds)
    {
        List<Agreement_Account_Relationship__c> relatedAccountRelatioships = new AgreementAccountRelationshipSelectors().selectByAccountId(accountIds);
        Set<Id> agreementIds = UtilsCollection.getSetOfIds(relatedAccountRelatioships, 'Agreement__c');

        List<Apttus__APTS_Related_Agreement__c> recordDetails = new ApttusRelatedAgreementSelectors().getRelatedAgreementToForParentAgreements(agreementIds);

        return UtilsCollection.getSetOfIds(recordDetails, 'Id');
    }

    /*
    *  @AUTHOR:  Bharath Varma
    *  @DESCRIPTION: get set of record Ids from modified set
    *  @PARAM :  Set<Id> modifiedRecordIds
    *  @RETURN:  Set<Id> recordIds
    */
    public override Set<Id> getRecordIdsFromModifiedRecordIdsCustom(Set<Id> modifiedRecordIds)
    {
        // record which gets reparented is Agreement
        List<Apttus__APTS_Related_Agreement__c> recordDetails = new ApttusRelatedAgreementSelectors().getRelatedAgreementToForParentAgreements(modifiedRecordIds);
        return UtilsCollection.getSetOfIds(recordDetails, 'Id');
    }

    /*
    *  @AUTHOR:  Bharath Varma
    *  @DESCRIPTION: get share record SObjective type 
    *  @PARAM :  none
    *  @RETURN:  SObjectType
    */
    public override SObjectType getShareObjectType()
    {
        return Apttus__APTS_Related_Agreement__Share.sObjectType;
    }

    /*
    *  @AUTHOR:  Bharath Varma
    *  @DESCRIPTION: get share record parent field name 
    *  @PARAM :  none
    *  @RETURN:  String
    */
    public override String getShareParentFieldName()
    {
        return 'ParentId';
    }

    /*
    *  @AUTHOR:  Bharath Varma
    *  @DESCRIPTION: create sharing record 
    *  @PARAM :  Id recordId, Id userId
    *  @RETURN:  SObject
    */
    public override SObject createSharingRecord(Id recordId, Id userId) {
        return new Apttus__APTS_Related_Agreement__Share(
                UserOrGroupId = userId,
                ParentId = recordId,
                AccessLevel = 'Edit',
                RowCause = Schema.Apttus_Approval__Approval_Request_History__Share.RowCause.Manual
        );
    }

    /*
    *  @AUTHOR:  Bharath Varma
    *  @DESCRIPTION: filter users based on territories 
    */
    public override Map<Id, Set<Id>> filterTerritoryIdToUserIds(Map<Id, Set<Id>> territoryIdToUserIds, Map<Id, Set<Id>> accountIdToTerritoryIds, Map<Id, Set<Id>> recordIdToAccountIds)
    {
        // filter by role in territory to only include certain sales roles
        return filterSalesUsersByRoleInTerritory(territoryIdToUserIds);
    }
}