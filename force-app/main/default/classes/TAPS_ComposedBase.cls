/*
 * @Author: Todd Newman
 * @Date:
 * @Description : A poor-man's composition.  Apex has its limitations.  Perhaps I could have encapsulated logic further
 *                but I declared it good enough.
 *                Default implementations are divvied out into three classes.  This class composes the three and declares some
 *                methods virtual so descendants can provide object-specific implementations.  Those three are:
 *                TAPS_BatchImpl -- methods that support batch update of share records
 *                TAPS_ObjectsImpl -- methods that traverse the objects and relationships, providing useful maps mostly
 *                TAPS_OrchestrationImpl -- methods that gather information and execute the appropriate batch updates
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                 Date                        Description
 * Todd Newman                                         Inital Verion
 * Himanshu                 30-Mar-2022                Code Scan Fixes
 * 
 * ---------------------------------------------------------------------------------------------------------------------------------------
 */
public without sharing virtual class TAPS_ComposedBase implements TAPS_IObjects, TAPS_IOrchestration, TAPS_IBatch {


    public static final String IMPLEMENTATION_REQUIRED = 'Implementation is required';
    public static final String SUB_INTERFACE_REQUIRED = 'Must implement a sub-interface of TAPS_IObjects';
    public static final String REQUIRED_FOR_DIRECT = 'Implementation is required for TAPS_IObjectsDirect';
    public static final String REQUIRED_FOR_JUNCTION = 'Implementation is required for TAPS_IObjectsJunction';
    public static final String REQUIRED_FOR_CUSTOM = 'Implementation is required for TAPS_IObjectsCustom';
    public static final String ETM_SHARING_NOT_SUPPORTED = 'Sharing of object not supported by TAPS ';
    public static final String ETM_FUNCTIONALITY_NOT_SUPPORTED = 'This functionality is not currently supported by TAPS';

    private TAPS_BatchImpl batchImpl;
    private TAPS_ObjectsImpl objectsImpl;
    private TAPS_OrchestrationImpl orchestrationImpl;
    /**
     * @author Todd Newman
     * @description constructor called
    **/
    public TAPS_ComposedBase()
    {
        batchImpl = new TAPS_BatchImpl(this);
        objectsImpl = new TAPS_ObjectsImpl(this);
        orchestrationImpl = new TAPS_OrchestrationImpl(this);
    }

    /*
     *
     * TAPS_IObjects (and descendant) methods
     *
     */

    /**
    * @description given IDs of records to be shared, return the related account IDs
    * @params Set<Id> recordIds
    * @return Map<Id, Set<Id>>
    **/
    public Map<Id, Set<Id>> getRecordIdToAccountIds(Set<Id> recordIds)
    {
        return objectsImpl.getRecordIdToAccountIds(recordIds);
    }

    /**
    * @description given the record IDs that have been modified (keys in the map paramenter)
    *              return the record IDs that will be shared
    *              default implementation is all of them
    *              for some objects, business rules may filter to a subset based on record or account data 
    * @params Map<Id, Set<Id>> recordIdToAccountId
    * @return Set<Id>
    **/
    public virtual Set<Id> filterRecordsRelatedToAccount(Map<Id, Set<Id>> recordIdToAccountId)
    {
        return objectsImpl.filterRecordsRelatedToAccount(recordIdToAccountId);
    }

    /**
    * @description given the territory IDs related to modified records
    *              return the territory IDs that records will be shared to
    *              default implementation is all of them
    *              for some objects, business rules may filter to a subset based on record or account data 
    * @params Map<Id, Set<Id>> recordIdToAccountId
    * @return Set<Id>
    **/
    public virtual Set<Id> filterTerritories(Set<Id> territoryIds, Map<Id, Set<Id>> recordIdToAccountIds)
    {
        return objectsImpl.filterTerritories(territoryIds, recordIdToAccountIds);
    }

    /**
    * @description given the territory IDs and linked user IDs
    *              filter down the map to territories and users for which records will be shared to 
    *              default implementation is all of them
    *              for some objects, business rules may filter to a subset based on territory or user data 
    * @params Map<Id, Set<Id>> territoryIdToUserIds, Map<Id, Set<Id>> accountIdToTerritoryIds, Map<Id, Set<Id>> recordIdToAccountIds
    * @return Map<Id, Set<Id>>
    **/
    public virtual Map<Id, Set<Id>> filterTerritoryIdToUserIds(Map<Id, Set<Id>> territoryIdToUserIds, Map<Id, Set<Id>> accountIdToTerritoryIds, Map<Id, Set<Id>> recordIdToAccountIds)
    {
        return objectsImpl.filterTerritoryIdToUserIds(territoryIdToUserIds, accountIdToTerritoryIds, recordIdToAccountIds);
    }
    /**
    * @description DCP-27435 Add method to indicate if Account to Field Support Users need sharing. If required override implementing class and return true
    * @params NA
    * @return boolean
    **/
    public virtual Boolean needToShareToATFS(){
        return false;
    }
    /**
    * @description the object being shared
    * @params NA
    * @return SObjectType
    **/
    public virtual SObjectType getObjectType()
    {
        return objectsImpl.getObjectType();
    }
    /**
    * @description name the relationship field on the target object to the parent Account
    * @params NA
    * @return String
    **/
    public virtual String getLookupFieldName()
    {
        return objectsImpl.getLookupFieldName();
    }

    /**
    * @description name the junction object that sits between the target and account
    * @params NA
    * @return String
    **/
    public virtual String getJunctionTableName()
    {
        return objectsImpl.getJunctionTableName();
    }
    /**
    * @description  name the field that refers to the shared record in the junction
    * @params NA
    * @return String
    **/
    public virtual String getKeyFieldName()
    {
        return objectsImpl.getKeyFieldName();
    }

    /**
    * @description  name the field that referes to account in the junction
    * @params NA
    * @return String
    **/
    public virtual String getValueFieldName()
    {
        return objectsImpl.getValueFieldName();
    }

    /**
    * @description  navigate from records to accounts
    * @params Set<Id> recordIds
    * @return Map<Id, Set<Id>
    **/
    public virtual Map<Id, Set<Id>> mapRecordToAccountsCustom(Set<Id> recordIds)
    {
        return objectsImpl.mapRecordToAccountsCustom(recordIds);
    }


    /*
     *
     * TAPS_IOrchestration methods
     *
     */

    /**
    * @description  navigate from account ID to record IDs
    * @params Set<Id> recordIds
    * @return Set<Id>
    **/
    public virtual Set<Id> getRecordIdsFromAccountIds(Set<Id> accountIds)
    {
        return orchestrationImpl.getRecordIdsFromAccountIds(accountIds);
    }

    
    /**
    * @description this method receives IDs of records that were modified
    *              which may need to be converted to IDs that need to be shared
    *              direct = no conversion
    *              junction = query and translate from junction IDs to shared IDs
    *              custom = custom logic
    * @params Set<Id>
    * @return Set<Id>>
    **/
    public virtual Set<Id> getRecordIdsFromModifiedRecordIds(Set<Id> modifiedRecordIds)
    {
        return orchestrationImpl.getRecordIdsFromModifiedRecordIds(modifiedRecordIds);
    }
    /**
    * @description  kick off a batch job to recalculate shares based on ETM for the following IDs
    * @params Set<Id> affectedRecordIds
    * @return NA
    **/
    public void batchRecalculateShares(Set<Id> affectedRecordIds)
    {
        orchestrationImpl.batchRecalculateShares(affectedRecordIds);
    }
    /**
    * @description  given IDs of records to be shared, return the related account IDs
    * @params Set<Id> affectedRecordIds
    * @return Set<Id>
    **/ 
    public virtual Set<Id> getRecordIdsFromAccountIdsCustom(Set<Id> accountIds)
    {
        return orchestrationImpl.getRecordIdsFromAccountIdsCustom(accountIds);
    }
    /**
    * @description  given a list of records that were modified, return the IDs of the records that need to be shared these are often the same IDs but might not be if there is a junction object for instance
    * @params Set<Id> modifiedRecordIds
    * @return Set<Id>
    **/ 
    public virtual Set<Id> getRecordIdsFromModifiedRecordIdsCustom(Set<Id> modifiedRecordIds)
    {
        return orchestrationImpl.getRecordIdsFromModifiedRecordIdsCustom(modifiedRecordIds);
    }


    /*
     *
     * TAPS_IBatch methods
     *
     */

    /**
    * @description  traversing all the intermediary objects, generate a map from the records to be shared  to the users that need sharing based on ETM rules
    * @params Set<Id> recordIds
    * @return Map<Id, Set<Id>> 
    **/ 
    public Map<Id, Set<Id>> mapRecordIdToUserIds(Set<Id> recordIds)
    {
        return batchImpl.mapRecordIdToUserIds(recordIds);
    }

    /**
    * @description  get the specific SObject that holds sharing records
    * @params NA
    * @return SObjectType
    **/ 
    public virtual SObjectType getShareObjectType()
    {
        return batchImpl.getShareObjectType();
    }

    /**
    * @description   name the field on the Share table that refers to the parent record ID will be ParentId for all custom objects but a more specific name for standard objects
    * @params NA
    * @return String
    **/ 
    public virtual String getShareParentFieldName()
    {
        return batchImpl.getShareParentFieldName();
    }

    /**
    * @description retrieve manual shares on these records
    * @params Set<Id> recordIds
    * @return List<SObject>
    **/ 
    public List<SObject> getExtantShares(Set<Id> recordIds)
    {
        return batchImpl.getExtantShares(recordIds);
    }

    /**
    * @description create Apex sharing records from the record IDs to the user IDs
    * @params Map<Id, Set<Id>> recordIdToUserIds
    * @return NA
    **/ 
    public void createSharingRecords(Map<Id, Set<Id>> recordIdToUserIds)
    {
        batchImpl.createSharingRecords(recordIdToUserIds);
    }

    /**
    * @description creates a share record specific to this implementation for account to field support
    * @params Id recordId, Id userId
    * @return SObject
    **/ 
    public virtual SObject createATFSSharingRecord(Id recordId, Id userId)
    {
        return batchImpl.createSharingRecord(recordId, userId);
    }

    /**
    * @description creates a share record specific to this implementation
    * @params Id recordId, Id userId
    * @return SObject
    **/ 
    public virtual SObject createSharingRecord(Id recordId, Id userId)
    {
        return batchImpl.createSharingRecord(recordId, userId);
    }

    /**
    * @description delete Apex sharing records from the record IDs to the user IDs
    * @params Id recordId, Id userId
    * @return void
    **/ 
    public void removeSharingRecords(Map<Id, Set<Id>> recordIdToUserIds)
    {
        batchImpl.removeSharingRecords(recordIdToUserIds);
    }

    /**
    * @description filter out direct territories, preserving only the indirect ones
    * @params Set<Id> territoryIds
    * @return Set<Id> 
    **/ 
    protected Set<Id> keepDirectTerritories(Set<Id> territoryIds)
    {
        List<Territory2> territoryDetails = new TerritoriesSelector().keepDirectTerritories(territoryIds);
        return UtilsCollection.getSetOfIds(territoryDetails, 'Id');
    }

   /**
    * @description filter out indirect territories, preserving only the direct ones
    * @params Set<Id> territoryIds
    * @return Set<Id> 
    **/ 
    protected Set<Id> keepIndirectTerritories(Set<Id> territoryIds)
    {
        List<Territory2> territoryDetails = new TerritoriesSelector().keepIndirectTerritories(territoryIds);
        return UtilsCollection.getSetOfIds(territoryDetails, 'Id');
    }

    /**
    * @description filter out direct territories, preserving only the indirect ones
    * @params Set<Id> territoryIds
    * @return Set<Id> 
    **/ 
    protected Map<Id, Set<Id>> filterSalesUsersByRoleInTerritory(Map<Id, Set<Id>> territoryIdToUserIds)
    {
        Map<Id, Set<Id>> results = new Map<Id, Set<Id>>();

        // split IDs into direct and indirect territories
        Set<Id> directTerritoryIds = new Set<Id>();
        Set<Id> indirectTerritoryIds = new Set<Id>();
        Map<Id, Territory2> territoryDetails = new Map<Id, Territory2>(new TerritoriesSelector().getTerritoryTypes(territoryIdToUserIds.keySet()));

        for (Id i : territoryDetails.keySet())
        {
            if (territoryDetails.get(i).Territory2Type.MasterLabel.contains(Territories2.CHANNEL_PARTNER_DESCRIPTION))
                indirectTerritoryIds.add(i);
            else
                directTerritoryIds.add(i);
        }

        // add indirect key/values to results as is
        // we are not filtering on the role of indirect users
        for (Id i : indirectTerritoryIds)
        {
            if (territoryIdToUserIds.containsKey(i))
                results.put(i, territoryIdToUserIds.get(i));
        }

        // filter the direct users by role
        Map<String, String> settingKeyToValues = UtilsSettings.getCustomMetadataMap('TAPS_Sales_Roles');
        List<String> includedRoles = settingKeyToValues.get('Roles').split('\\|');

        List<UserTerritory2Association> filteredUserList = new UserTerritory2AssociationSelector().selectUsersByTerritoriesAndRoles(directTerritoryIds, includedRoles);
        Map<Id, Set<Id>> directResults = UtilsCollection.getMapOfIdToIds(filteredUserList, 'Territory2Id', 'UserId');

        // add direct results to indirect
        for (Id i : directResults.keySet())
            results.put(i, directResults.get(i));

        return results;
    }

}