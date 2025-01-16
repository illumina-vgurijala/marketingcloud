/**
 * @author 
 * @date   
 * @description : Partner Request data controller class extending TAPS_ComposedBase and impementing the TAPS_IObjectsCustom
 * Modification Log:
 *       ------------------------            
 * Jitesh Lakhwani               6-July-2022            Code Scan fixes of Comments
 */

public without sharing class TAPS_PartnerRequest extends TAPS_ComposedBase implements TAPS_IObjectsCustom
{

    /**
    *@description : this will return the Partner Request sObjectType. 
    *@return SObjectType 
    */
    public override SObjectType getObjectType()
    {
        return Partner_Request__c.sObjectType;
    }

    /**
    *@description : this will return the Partner Request Share sObjectType. 
    *@return SObjectType 
    */
    public override SObjectType getShareObjectType()
    {
        return Partner_Request__Share.sObjectType;
    }

    /**
    *@description : this will return the Partner Request share object parent field name  
    *@param  : None
    *@return : String : Partner Request share parent id field name : ParentId
    */
    public override String getShareParentFieldName()
    {
        return 'ParentId';
    }

    /**
    *@description : this is an implentation of the TAPS_IObjectsCustom.getRecordIdsFromAccountIdsCustom method and will return the set of Partner Request id's
    *@param  : set<id> accountids
    *@return : Set<Id> : set of Partner Request
    */
    public override Set<Id> getRecordIdsFromAccountIdsCustom(Set<Id> accountIds)
    {
        List<Partner_Request__c> recordDetails = [SELECT Id FROM Partner_Request__c WHERE CreatedBy.Contact.AccountId IN :accountIds];
        return UtilsCollection.getSetOfIds(recordDetails, 'Id');
    }

    /**
    *@description : this is an implentation of the TAPS_IObjectsCustom.getRecordIdsFromModifiedRecordIdsCustom method
    *@param  : set<id> modifiedRecordIds
    *@return : Set<Id> : set of Partner Request
    */
    public override Set<Id> getRecordIdsFromModifiedRecordIdsCustom(Set<Id> modifiedRecordIds)
    {
        return modifiedRecordIds;
    }

    /**
    *@description : this is an implentation of the TAPS_IObjectsCustom.mapRecordToAccountsCustom method and will return the map of account id's based on Partner Request object
    *@param : set<id> recordIds
    *@return : Map<Id, Set<Id>> : 'Id' is key and set<id> is account record id (example: 'Id' -> <record_1_id, record_2_id, ...>)
    */
    public override Map<Id, Set<Id>> mapRecordToAccountsCustom(Set<Id> recordIds)
    {
        List<Partner_Request__c> recordDetails = [SELECT Id, CreatedBy.Contact.AccountId FROM Partner_Request__c WHERE Id IN :recordIds];
        return UtilsCollection.getMapOfIdToIds(recordDetails, 'Id', 'CreatedBy.Contact.AccountId');
    }

    /**
    *@description : this will create the Partner Request share object record and will return it  
    *@param  : Id recordId, Id userId
    *@return : SObject 
    */
    public override SObject createSharingRecord(Id recordId, Id userId)
    {
        Partner_Request__Share share = new Partner_Request__Share(
            UserOrGroupId = userId,
            AccessLevel = 'Edit',
            RowCause = Schema.Partner_Request__Share.RowCause.Manual
        );
        share.put(getShareParentFieldName(), recordId);
        return share;
    }

}