/*
*    @Author: Todd Newman
*    @Date:   2019-02-21
*    @Description:  Implementation of object methods
*    This class is composed into TAPS_ComposedBase which is inherited by object-specific
*    implementations. That means there are default implementations here which may be overridden
*    The methods in the composed class are defined as virtual. The methods are defined virtual
*    in TAPS_ComposedBase rather than here because this class will not have descendants
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Todd Newman                 2019-02-21           Initial Version
          Nesar Mohan                 2022-03-30           CodeScan Fix 
*    ---------------------------------------------------------------------------------------------------------------------------
*/

public without sharing class TAPS_ObjectsImpl implements TAPS_IObjects {

    // the composed base will be extended by an implementation for a specific object (e.g. quotes)
    // that instantiation will have methods implemented that are object specific which we need to access
    private TAPS_ComposedBase objectSpecificImpl;
    private static final String LOG_TITLE = 'TAPS_ObjectsImpl';
    /*
    *  @Author: Todd Newman
    *  @Description: Constructor to initialize the TAPS_ComposedBase reference passed as a parameter
    *  @Param: TAPS_ComposedBase
    *  @Return: void
    */

    public TAPS_ObjectsImpl(TAPS_ComposedBase objectSpecificImpl)
    {
        this.objectSpecificImpl = objectSpecificImpl;
    }

    /*
    *  @Author: Todd Newman
    *  @Description: Method to return the related account IDs based on the IDs of records passed as
    *  as a parameter to be shared
    *  @Param: Set<Id>
    *  @Return: Map<Id, Set<Id>>
    */

    public Map<Id, Set<Id>> getRecordIdToAccountIds(Set<Id> recordIds)
    {
        ilib_LogEvent.push(LOG_TITLE + '.getRecordIdToAccountIds');
        Map<Id, Set<Id>> recordIdToAccountIds;

        if (objectSpecificImpl instanceof TAPS_IObjectsDirect)
        {
            recordIdToAccountIds = mapRecordToAccountsDirect(recordIds);
           
        }
        else if (objectSpecificImpl instanceof TAPS_IObjectsJunction)
        {
            recordIdToAccountIds = mapRecordToAccountsJunction(recordIds);
        }
        else if (objectSpecificImpl instanceof TAPS_IObjectsCustom)
        {
            TAPS_IObjectsCustom objectCustomImpl = (TAPS_IObjectsCustom)objectSpecificImpl;
            recordIdToAccountIds = objectCustomImpl.mapRecordToAccountsCustom(recordIds);
        }
        else
        {
            throw new ApexSharingException(TAPS_ComposedBase.SUB_INTERFACE_REQUIRED);
        }
        ilib_LogEvent.message('recordIdToAccountIds ' + recordIdToAccountIds);
        ilib_LogEvent.emit();
        return recordIdToAccountIds;
    }

    /*
    *  @Author: Todd Newman
    *  @Description: given the record IDs that have been modified (keys in the map paramenter)
    *  return the record IDs that will be shared. default implementation is all of them.
    *  for some objects, business rules may filter to a subset based on record or account data
    *  as a parameter to be shared
    *  @Param: Map<Id, Set<Id>>
    *  @Return: Set<Id>
    */

    public Set<Id> filterRecordsRelatedToAccount(Map<Id, Set<Id>> recordIdToAccountId)
    {
        return recordIdToAccountId.keySet();
    }

    /*
    *  @Author: Todd Newman
    *  @Description: given the territory IDs related to modified records as parameter, return the territory IDs that records will be shared to
    *  default implementation is all of them
    *  for some objects, business rules may filter to a subset based on territory, record, or account data
    *  @Param: Set<Id> and Map<Id, Set<Id>>
    *  @Return: Set<Id>
    */

    public Set<Id> filterTerritories(Set<Id> territoryIds, Map<Id, Set<Id>> recordIdToAccountIds)
    {
        return territoryIds;
    }

    /*
    *  @Author: Todd Newman
    *  @Description: given the territory IDs and linked user IDs filter down the map to territories and users for which records will be shared to
    *  default implementation is all of them
    *  for some objects, business rules may filter to a subset based on territory or user data
    *  @Param: Map<Id, Set<Id>> and Map<Id, Set<Id>> and Map<Id, Set<Id>>
    *  @Return: Map<Id, Set<Id>>
    */

    public Map<Id, Set<Id>> filterTerritoryIdToUserIds(Map<Id, Set<Id>> territoryIdToUserIds, Map<Id, Set<Id>> accountIdToTerritoryIds, Map<Id, Set<Id>> recordIdToAccountIds)
    {
        return territoryIdToUserIds;
    }

    /*
    *  @Author: Todd Newman
    *  @Description: TAPS_IObjectsDirect, the object being shared.
    *  Throw an ApexSharingException stating 'Implementation is required'
    *  @Param: None
    *  @Return: SObjectType ApexSharingException
    */

    public SObjectType getObjectType()
    {
        throw new ApexSharingException(TAPS_ComposedBase.IMPLEMENTATION_REQUIRED);
    }

    /*
    *  @Author: Todd Newman
    *  @Description: TAPS_IObjectsDirect, name the relationship field on the target object to the parent Account.
    *  Throw an ApexSharingException stating 'Implementation is required for TAPS_IObjectsDirect'
    *  @Param: None
    *  @Return: SObjectType ApexSharingException
    */

    public String getLookupFieldName()
    {
        throw new ApexSharingException(TAPS_ComposedBase.REQUIRED_FOR_DIRECT);
    }
    
    /*
    *  @Author: Todd Newman
    *  @Description: TAPS_IObjectsJunction, name the junction object that sits between the target and account.
    *  Throw an ApexSharingException stating 'Implementation is required for TAPS_IObjectsJunction'
    *  @Param: None
    *  @Return: SObjectType ApexSharingException
    */

    public String getJunctionTableName()
    {
        throw new ApexSharingException(TAPS_ComposedBase.REQUIRED_FOR_JUNCTION);
    }

    /*
    *  @Author: Todd Newman
    *  @Description: TAPS_IObjectsJunction, name the field that refers to the shared record in the junction.
    *  Throw an ApexSharingException stating 'Implementation is required for TAPS_IObjectsJunction'
    *  @Param: None
    *  @Return: SObjectType ApexSharingException
    */

    public String getKeyFieldName()
    {
        throw new ApexSharingException(TAPS_ComposedBase.REQUIRED_FOR_JUNCTION);
    }

    /*
    *  @Author: Todd Newman
    *  @Description: TAPS_IObjectsJunction, name the field that referes to account in the junction.
    *  Throw an ApexSharingException stating 'Implementation is required for TAPS_IObjectsJunction'
    *  @Param: None
    *  @Return: SObjectType ApexSharingException
    */

    public String getValueFieldName()
    {
        throw new ApexSharingException(TAPS_ComposedBase.REQUIRED_FOR_JUNCTION);
    }

    /*
    *  @Author: Todd Newman
    *  @Description: TAPS_IObjectsCustom, navigate from records to accounts.
    *  Throw an ApexSharingException stating 'Implementation is required for TAPS_IObjectsCustom'
    *  @Param: None
    *  @Return: SObjectType ApexSharingException
    */

    public Map<Id, Set<Id>> mapRecordToAccountsCustom(Set<Id> recordIds)
    {
        throw new ApexSharingException(TAPS_ComposedBase.REQUIRED_FOR_CUSTOM);
    }

    /*
    *  @Author: Todd Newman
    *  @Description: Method to return account ids based on the recordIds passed as a parameter
    *  through direct navigation
    *  @Param: Set<Id>
    *  @Return: Map<Id, Set<Id>>
    */

    private Map<Id, Set<Id>> mapRecordToAccountsDirect(Set<Id> recordIds)
    {
        String objectName = objectSpecificImpl.getObjectType().getDescribe().getName();
        String lookupFieldName = objectSpecificImpl.getLookupFieldName();

        String soql = 'SELECT Id, ' + lookupFieldName + ' FROM ' + objectName + ' WHERE Id IN :recordIds';
        List<SObject> records = Database.query(soql);

        Map<Id, Set<Id>> recordIdToAccountIds = UtilsCollection.getMapOfIdToIds(records, 'Id', lookupFieldName);
        return recordIdToAccountIds;
    }

    /*
    *  @Author: Todd Newman
    *  @Description: Method to return account ids based on the recordIds passed as a parameter
    *  through a junction object
    *  @Param: Set<Id>
    *  @Return: Map<Id, Set<Id>>
    */

    private Map<Id, Set<Id>> mapRecordToAccountsJunction(Set<Id> recordIds)
    {
        String junctionTableName = objectSpecificImpl.getJunctionTableName();
        String keyFieldName = objectSpecificImpl.getKeyFieldName();
        String valueFieldName = objectSpecificImpl.getValueFieldName();

        // retrieve junction object records
        String soql = 'SELECT ' + keyFieldName + ', ' + valueFieldName
                + ' FROM ' + junctionTableName
                + ' WHERE ' + keyFieldName + ' IN :recordIds';
        List<SObject> junctionRows = Database.query(soql);

        Map<Id, Set<Id>> recordIdToAccountIds = UtilsCollection.getMapOfIdToIds(junctionRows, keyFieldName, valueFieldName);
        return recordIdToAccountIds;
    }

    /*
    *  @Author: Todd Newman
    *  @Description: Custom Exception class
    */

    public class ApexSharingException extends Exception { }

}