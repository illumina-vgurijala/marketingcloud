/*Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                    Description
*    KD                             8-Sept-2020             DCP-39107 Added logic to share plan records
*    Ashwin Kumar                   25-June-2021            TASK0608051 - Query & Defer Child Territories here instead of deferring in TAPS_Orchestrator.getAccountIdsFromTerritoryIds
*    ------------------------------------------------------------------------------------                  
*/
public with sharing class UserTerritory2Associations extends ilib_SObjectDomain {


    /**
    * @description initialise Association
    * @author 
    * @param sObjectList 
    **/
    public UserTerritory2Associations(List<UserTerritory2Association> sObjectList)
    {
        super(sObjectList);
    }
    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /**
        * @description returns new instances 
        * @author  
        * @param sObjectList 
        * @return ilib_SObjectDomain 
        **/
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new UserTerritory2Associations(sObjectList);
        }
    }

    /**
    * @description initiate Deferred Sharing after Insert
    * @author 
    **/
    public override void onAfterInsert()
    {
        //TAPS_Orchestrator.recalculateTerritoryChanges(UtilsCollection.getSetOfIds(records, 'Territory2Id'));
        initiateDeferredSharing(UtilsCollection.getSetOfIds(records, 'Territory2Id'));
        shareInstalledProductsWithDistributorUsers(UtilsCollection.getSetOfIds(records, 'UserId'));
        // DCP-39107
        PlanShareService.reSharePlanRecords((List<UserTerritory2Association>)records);
    }

    /**
    * @description set new role after update
    * @author  
    * @param oldRecords 
    **/
    public override void onAfterUpdate(Map<Id, sObject> oldRecords)
    {
        Map<String, String> settingKeyToValues = UtilsSettings.getCustomMetadataMap('TAPS_Sales_Roles');
        List<String> includedRoles = settingKeyToValues.get('Roles').split('\\|');

        Set<Id> roleChangeTerritoryIds = new Set<Id>();
        for (SObject rec : records)
        {
            String newRole = (String)rec.get('RoleInTerritory2');
            String oldRole = (String)oldRecords.get(rec.Id).get('RoleInTerritory2');
            newRole = (newRole == null ? '' : newRole);
            oldRole = (oldRole == null ? '' : oldRole);
            if (newRole != oldRole && (includedRoles.contains(newRole) || includedRoles.contains(oldRole)))
            {
                System.debug('TAPS: role change for user ' + rec.get('UserId') + ' from ' + oldRole + ' to ' + newRole);
                roleChangeTerritoryIds.add((Id) rec.get('Territory2Id'));
            }
        }

        if (roleChangeTerritoryIds.size() > 0)
        {
            System.debug('TAPS: recalculating for territory IDs ' + roleChangeTerritoryIds);
            //TAPS_Orchestrator.recalculateTerritoryChanges(roleChangeTerritoryIds);
            initiateDeferredSharing(roleChangeTerritoryIds);
        }
    }

    /**
    * @description initiate Deferred Sharing after Delete
    * @author  
    **/
    public override void onAfterDelete()
    {
        //TAPS_Orchestrator.recalculateTerritoryChanges(UtilsCollection.getSetOfIds(records, 'Territory2Id'));
        initiateDeferredSharing(UtilsCollection.getSetOfIds(records, 'Territory2Id'));
        shareInstalledProductsWithDistributorUsers(UtilsCollection.getSetOfIds(records, 'UserId'));
        // DCP-39107
        PlanShareService.reSharePlanRecords((List<UserTerritory2Association>)records);
    }

    // if the account has users attached then it is a distributor account
    // requirement is to search for distributor users, then see which accounts they have ETM access to (assumed to be UCs)
    // then look for installed products on those UCs that have the same values as this update
    // for all that match, share the installed products to the distributor users
    private void shareInstalledProductsWithDistributorUsers(Set<Id> userIds)
    {
        // which of these are distributor users
        List<User> userDetails = [SELECT Id, AccountId FROM User WHERE Id IN :userIds AND AccountId != null and IsActive = true];
        if (userDetails.size() == 0) return;

        Set<Id> distributorIds = UtilsCollection.getSetOfIds(userDetails, 'AccountId');
        InstalledProductsService.shareWithDistributorUsers(distributorIds);
    }
    /*
    * @desc future method created to avoid MIXED DML exception, creates TAPS_Deferred_Record__c records
    */
    @future
    private static void initiateDeferredSharing(Set<Id> recordIds)
    {
        //TASK0608051
        TAPS_DeferredRun.deferSharing(TAPS_DeferredRun.TERRITORY_JOB_OBJECT_NAME, TAPS_DeferredRun.selectAndAddChildTerritoriesByTerritoryId(recordIds));
    }
}