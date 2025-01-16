/**
 * @author 
 * @date   
 * @description : Customer Readiness Form data controller class extending TAPS_ComposedBase and impementing the TAPS_IObjectsCustom
 * Modification Log:
 *       ------------------------            
 * Jitesh Lakhwani               6-July-2022            Code Scan fixes of Comments
 */
public without sharing class TAPS_CustomerReadinessForm extends TAPS_ComposedBase implements TAPS_IObjectsCustom {

    /**
    *@description : this will return the apttus Customer Readiness Form sObjectType. 
    *@return SObjectType 
    */
    public override SObjectType getObjectType()
    {
        return Customer_Readiness_Form__c.sObjectType;
    }

    /**
    *@description : this is an implentation of the TAPS_IObjectsCustom.mapRecordToAccountsCustom method and will return the map of account id's based on apttus Customer Readiness Form object
    *@param : set<id> recordIds
    *@return : Map<Id, Set<Id>> : 'Id' is key and set<id> is account record id (example: 'Id' -> <record_1_id, record_2_id, ...>)
    */
    public override Map<Id, Set<Id>> mapRecordToAccountsCustom(Set<Id> recordIds)
    {
        Map<Id, Set<Id>> recordIdToAccountIds = new Map<Id, Set<Id>>();

        List<Customer_Readiness_Form__c> recordDetails =
            [SELECT Id, Opportunity_Name__c, Opportunity_Name__r.Ultimate_Consignee__c, Opportunity_Name__r.Distributor__c
             FROM Customer_Readiness_Form__c
             WHERE Id IN :recordIds];

        for (Customer_Readiness_Form__c crf : recordDetails)
        {
            recordIdToAccountIds.put(crf.Id, new Set<Id>());

            // add both UC and Distributor IDs
            if (crf.Opportunity_Name__r.Ultimate_Consignee__c != null)
                recordIdToAccountIds.get(crf.Id).add(crf.Opportunity_Name__r.Ultimate_Consignee__c);
            if (crf.Opportunity_Name__r.Distributor__c != null)
                recordIdToAccountIds.get(crf.Id).add(crf.Opportunity_Name__r.Distributor__c);
        }

        return recordIdToAccountIds;
    }

    /**
    *@description : this is an implentation of the TAPS_IObjectsCustom.getRecordIdsFromAccountIdsCustom method and will return the set of apttus Customer Readiness Form id's
    *@param  : set<id> accountids
    *@return : Set<Id> : set of apttus Customer Readiness Form 
    * modified as part of DCP-25384
    */
    public override Set<Id> getRecordIdsFromAccountIdsCustom(Set<Id> accountIds)
    {
        List<Customer_Readiness_Form__c> recordDetails = [SELECT Id FROM Customer_Readiness_Form__c WHERE Opportunity_Name__r.Ultimate_Consignee__c IN :accountIds OR Opportunity_Name__r.Distributor__c IN :accountIds];
        return UtilsCollection.getSetOfIds(recordDetails, 'Id');
    }

    /**
    *@description : this is an implentation of the TAPS_IObjectsCustom.getRecordIdsFromModifiedRecordIdsCustom method and will return the set of apttus Customer Readiness Form id's based on opportunity id's
    *@param  : set<id> modifiedRecordIds
    *@return : Set<Id> : set of apttus Customer Readiness Form 
    * modified as part of DCP-25384
    */
    public override Set<Id> getRecordIdsFromModifiedRecordIdsCustom(Set<Id> modifiedRecordIds)
    {
        if (modifiedRecordIds.size() == 0) return modifiedRecordIds;

        // modified record IDs could be Opportunities
        if (UtilsCollection.getFirstIdFromSet(modifiedRecordIds).getSobjectType() == Opportunity.SObjectType)
        {
            List<Customer_Readiness_Form__c> recordDetails = [SELECT Id FROM Customer_Readiness_Form__c WHERE Opportunity_Name__c IN :modifiedRecordIds];
            return UtilsCollection.getSetOfIds(recordDetails, 'Id');
        }

        return modifiedRecordIds;
    }

    /**
    *@description : this will return the Customer Readiness Form Share sObjectType. 
    *@return SObjectType 
    */
    public override SObjectType getShareObjectType()
    {
        return Customer_Readiness_Form__Share.sObjectType;
    }

    /**
    *@description : this will return the Customer Readiness Form share object parent field name  
    *@param  : None
    *@return : String : Customer Readiness Form share parent id field name : ParentId
    */
    public override String getShareParentFieldName()
    {
        return 'ParentId';
    }

    /**
    *@description : this will create the Customer Readiness Form share object record and will return it  
    *@param  : Id recordId, Id userId
    *@return : SObject 
    */
    public override SObject createSharingRecord(Id recordId, Id userId)
    {
        Customer_Readiness_Form__Share share = new Customer_Readiness_Form__Share(
                UserOrGroupId = userId,
                AccessLevel = 'Edit',
                RowCause = Schema.Customer_Readiness_Form__Share.RowCause.Manual
        );
        share.put(getShareParentFieldName(), recordId);
        return share;
    }

}