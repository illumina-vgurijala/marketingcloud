/**
 *    @author Adyasha Satapathy
 *    @date   02-December-2021
 *    @description : DCP-50392 : Share Objective_Opportunity_Relationship__c records on the basis of related Account Plan
 *    Modification Log:
 *    ----------------------------------------------------------------------------------------------- 
 *    Developer             Date                      Description
 *    Adyasha           02-December-2021            Initial Version
 *    -----------------------------------------------------------------------------------------------        
 */
public without sharing class TAPS_ObjectiveOpportunityRelationships extends TAPS_ComposedBase implements TAPS_IObjectsCustom
{
    // Added to TAPS_ObjectSupport
    /*
    *  @AUTHOR:  Adyasha
    *  @DESCRIPTION: get SObjective type 
    *  @PARAM :  none
    *  @RETURN:  SObjectType
    */
    public override SObjectType getObjectType()
    {
        return Objective_Opportunity_Relationship__c.sObjectType;
    }

    /*
    *  @AUTHOR:  Adyasha
    *  @DESCRIPTION: get map of record ids to set of Account Ids 
    *  @PARAM :  Set<Id> recordIds
    *  @RETURN:  Map<Id, Set<Id>> map of record id to set of account ids
    */
    public override Map<Id, Set<Id>> mapRecordToAccountsCustom(Set<Id> recordIds)
    {
        List<Objective_Opportunity_Relationship__c> recordDetails = [SELECT Id, Account_Plan__r.Account_Name__c FROM Objective_Opportunity_Relationship__c WHERE Id IN :recordIds];

        return UtilsCollection.getMapOfIdToIds(recordDetails,'Id','Account_Plan__r.Account_Name__c');
    }

    /*
    *  @AUTHOR:  Adyasha
    *  @DESCRIPTION: get set of record ids from Account Ids
    *  @PARAM :  Set<Id> accountIds
    *  @RETURN:  Set<Id> record Ids
    */
    public override Set<Id> getRecordIdsFromAccountIdsCustom(Set<Id> accountIds)
    {
        Map<Id,Objective_Opportunity_Relationship__c> recordDetails = new Map<Id,Objective_Opportunity_Relationship__c>([SELECT Id FROM Objective_Opportunity_Relationship__c WHERE Account_Plan__r.Account_Name__c IN :accountIds]);
        return recordDetails.keySet();
    }

    /*
    *  @AUTHOR:  Adyasha
    *  @DESCRIPTION: get set of record Ids from modified set
    *  @PARAM :  Set<Id> modifiedRecordIds
    *  @RETURN:  Set<Id> recordIds
    */
    public override Set<Id> getRecordIdsFromModifiedRecordIdsCustom(Set<Id> modifiedRecordIds)
    {
        if (modifiedRecordIds == null ||  modifiedRecordIds.isEmpty()) { return modifiedRecordIds; }

        List<Objective_Opportunity_Relationship__c> recordDetails = [SELECT Id FROM Objective_Opportunity_Relationship__c WHERE Account_Plan_Objective__c IN :modifiedRecordIds];

        return UtilsCollection.getSetOfIds(recordDetails, 'Id');
    }

    /*
    *  @AUTHOR:  Adyasha
    *  @DESCRIPTION: get share record SObjective type 
    *  @PARAM :  none
    *  @RETURN:  SObjectType
    */
    public override SObjectType getShareObjectType()
    {
        return Objective_Opportunity_Relationship__Share.sObjectType;
    }

    /*
    *  @AUTHOR:  Adyasha
    *  @DESCRIPTION: get share record parent field name 
    *  @PARAM :  none
    *  @RETURN:  String
    */
    public override String getShareParentFieldName()
    {
        return 'ParentId';
    }

    /*
    *  @AUTHOR:  Adyasha
    *  @DESCRIPTION: create sharing record 
    *  @PARAM :  Id recordId, Id userId
    *  @RETURN:  SObject
    */
    public override SObject createSharingRecord(Id recordId, Id userId)
    {
        return new Objective_Opportunity_Relationship__Share(
            UserOrGroupId = userId,
            ParentId = recordId,
            AccessLevel = 'Edit',
            RowCause = Schema.Objective_Opportunity_Relationship__Share.RowCause.Manual
        );
    }

    /*
    *  @AUTHOR:  Adyasha
    *  @DESCRIPTION: create sharing record for ATFS scenario
    *  @PARAM :  Id recordId, Id userId
    *  @RETURN:  SObject
    */
    public override SObject createATFSSharingRecord(Id recordId, Id userId)
    {
        Objective_Opportunity_Relationship__Share share = new Objective_Opportunity_Relationship__Share(
            UserOrGroupId = userId,
            AccessLevel = 'Read',
            RowCause = Schema.Objective_Opportunity_Relationship__Share.RowCause.Manual
        );
        share.put(getShareParentFieldName(), recordId);
        return share;
    }

    /*
    *  @AUTHOR:  Adyasha
    *  @DESCRIPTION: returns boolean based on ATFS share needed
    *  @PARAM :  none
    *  @RETURN:  Boolean
    */
    public override Boolean needToShareToATFS()
    {
        return true;
    }
}