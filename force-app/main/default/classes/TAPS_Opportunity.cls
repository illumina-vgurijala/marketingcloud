/**
*    @author        
*    @date          
*    @description   Accounts domain class
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Akshay Mohan                18-June-2021           DCP-38968 Change sharing logic for Opportunity to Field Support
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*/
public without sharing class TAPS_Opportunity extends TAPS_ComposedBase implements TAPS_IObjectsCustom {
    // Modified by Bharath Varma: DCP-43227 UC Territory based Edit access
    private final static String SHAREACCESSLEVEL = 'Edit';

    /*
     * method to return the ObjectType
     */
    public override SObjectType getObjectType()
    {
        return Opportunity.sObjectType;
    }

    /*
     * method to map records to Accounts
     */
    public override Map<Id, Set<Id>> mapRecordToAccountsCustom(Set<Id> recordIds)
    {
        Map<Id, Set<Id>> recordIdToAccountIds = new Map<Id, Set<Id>>();

        List<Opportunity> recordDetails =
            [SELECT Id, Ultimate_Consignee__c, Distributor__c,Current_Ultimate_Consignee__c//DCP-38968
             FROM Opportunity
             WHERE Id IN :recordIds];

        for (Opportunity o : recordDetails)
        {
            Set<Id> setAccountIds =new Set<Id>();
            
            // add both UC and Distributor IDs
            if (o.Ultimate_Consignee__c != null) {
                setAccountIds.add(o.Ultimate_Consignee__c);
            }
            if (o.Distributor__c != null) {
                setAccountIds.add(o.Distributor__c);
            }
            //DCP-38968: Start-Add Current UC to set
            if (o.Current_Ultimate_Consignee__c != null) {
                setAccountIds.add(o.Current_Ultimate_Consignee__c);
            }
            recordIdToAccountIds.put(o.Id, setAccountIds);
            //DCP-38968: End-Add Current UC to set
        }

        return recordIdToAccountIds;
    }

    /*
     * method to get recordIds from AccountIds
     */
    public override Set<Id> getRecordIdsFromAccountIdsCustom(Set<Id> accountIds)
    {
        List<Opportunity> recordDetails =
            [SELECT Id
             FROM Opportunity
             WHERE Ultimate_Consignee__c IN :accountIds
             OR Distributor__c IN :accountIds
             OR Current_Ultimate_Consignee__c IN :accountIds];//DCP-38968

        return UtilsCollection.getSetOfIds(recordDetails, 'Id');
    }

    /*
     * method to return modified record ids
     */
    public override Set<Id> getRecordIdsFromModifiedRecordIdsCustom(Set<Id> modifiedRecordIds)
    {
        Id oneId = UtilsCollection.getFirstIdFromSet(modifiedRecordIds);
        if (oneId == null) {
            return modifiedRecordIds;
        }

        // if Account to Field Support records were modified, convert those to opportunity IDs
        if (oneId.getSobjectType() == Account_to_Field_Support__c.SObjectType)
        {
            List<Account_to_Field_Support__c> accountToFieldSupports = new AccountToFieldSupportSelector().selectByIds(modifiedRecordIds);
            Set<Id> accountIds = UtilsCollection.getSetOfIds(accountToFieldSupports, 'Account__c');
            List<Opportunity> opportunities = new OpportunitySelector().selectByAccountIds(accountIds);
            return UtilsCollection.getSetOfIds(opportunities, 'Id');
        }

        // opportunity records were modified
        return modifiedRecordIds;
    }

    /*
     * method to return share object type
     */
    public override SObjectType getShareObjectType()
    {
        return OpportunityShare.sObjectType;
    }

    /*
     * method to return Parent Field name
     */
    public override String getShareParentFieldName()
    {
        return 'OpportunityId';
    }

    /*
     * method to create sharing records with Access level
     */
    public override SObject createSharingRecord(Id recordId, Id userId)
    {
        OpportunityShare share = new OpportunityShare(
            UserOrGroupId = userId,
            OpportunityAccessLevel = shareAccessLevel,
            RowCause = Schema.OpportunityShare.RowCause.Manual
        );
        share.put(getShareParentFieldName(), recordId);
        return share;
    }

    
    /*
     * method to filter Territory Id based on User Ids
     */
    public override Map<Id, Set<Id>> filterTerritoryIdToUserIds(Map<Id, Set<Id>> territoryIdToUserIds, Map<Id, Set<Id>> accountIdToTerritoryIds, Map<Id, Set<Id>> recordIdToAccountIds)
    {
        //Modified by Rahul : DCP-25384 UC Apex Sharing
        // filter by role in territory to only include certain sales roles
        return filterSalesUsersByRoleInTerritory(territoryIdToUserIds);
    }

    /*DCP-38968
     * Account to Field support Sharing override base class method to make read sharing
     */
    public override SObject createATFSSharingRecord(Id recordId, Id userId)
    {
        OpportunityShare share = new OpportunityShare(
            UserOrGroupId = userId,
            OpportunityAccessLevel = 'Read',
            RowCause = Schema.OpportunityShare.RowCause.Manual
        );
        share.put(getShareParentFieldName(), recordId);
        return share;
    }

    /*DCP-38968
     * Account to Field support Sharing override base class method to signify to share to account to Field Support Users
    */
    public override Boolean needToShareToATFS()
    {
        return true;
    }

}