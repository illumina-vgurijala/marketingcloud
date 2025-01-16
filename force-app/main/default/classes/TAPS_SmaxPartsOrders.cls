/***************************************************************************************************************************************
* NAME   : TAPS_SmaxPartsOrders 
* --------------------------------------------------------------------------------------------------------------------------------------
*/
public without sharing class TAPS_SmaxPartsOrders extends TAPS_ComposedBase implements TAPS_IObjectsCustom {

    /* 
    * @description: To return Object API Name
    * @return: SObjectType
    */	
    public override SObjectType getObjectType()
    {
        return SVMXC__RMA_Shipment_Order__c.sObjectType;
    }

    /* 
    * @description: to fetch ACcount record based on Parts Order
    * @Param:Set<Id>
    * @return: Map<Id, Set<Id>>
    */
    public override Map<Id, Set<Id>> mapRecordToAccountsCustom(Set<Id> recordIds)
    {
        List<SVMXC__RMA_Shipment_Order__c> recordDetails = [SELECT Id, SVMXC__Service_Order__r.SVMXC__Company__c FROM SVMXC__RMA_Shipment_Order__c WHERE Id IN :recordIds];
        return UtilsCollection.getMapOfIdToIds(recordDetails, 'Id', 'SVMXC__Service_Order__r.SVMXC__Company__c');
    }
 
    /* 
    * @description:Fetch record Id based on related account Id of PO
    * @Param:Set<Id>
    * @return: Set<Id>
    */	
    public override Set<Id> getRecordIdsFromAccountIdsCustom(Set<Id> accountIds)
    {
        List<SVMXC__RMA_Shipment_Order__c> recordDetails = [SELECT Id FROM SVMXC__RMA_Shipment_Order__c WHERE SVMXC__Service_Order__r.SVMXC__Company__c IN :accountIds];
        return UtilsCollection.getSetOfIds(recordDetails, 'Id');
    }

    /* 
    * @description: to fetch modified records
    * @Param:Set<Id>
    * @return: Set<Id>
    */	
    public override Set<Id> getRecordIdsFromModifiedRecordIdsCustom(Set<Id> modifiedRecordIds)
    {
        if (modifiedRecordIds.size() == 0) return modifiedRecordIds;

        // modified record IDs might be Work Orders
        if (UtilsCollection.getFirstIdFromSet(modifiedRecordIds).getSobjectType() == SVMXC__Service_Order__c.SObjectType)
        {
            List<SVMXC__RMA_Shipment_Order__c> recordDetails = [SELECT Id FROM SVMXC__RMA_Shipment_Order__c WHERE SVMXC__Service_Order__c IN :modifiedRecordIds];
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
        return SVMXC__RMA_Shipment_Order__Share.sObjectType;
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
        return new SVMXC__RMA_Shipment_Order__Share(
            UserOrGroupId = userId,
            ParentId = recordId,
            AccessLevel = 'Edit',
            RowCause = Schema.SVMXC__RMA_Shipment_Order__Share.RowCause.Manual
        );
    }

}