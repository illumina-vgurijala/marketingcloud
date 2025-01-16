/**
*    @author Todd Newman
*    @date   
*    @description: Implementation of orchestration methods 
*    This class is composed into TAPS_ComposedBase which is inherited by object-specific
*    implementations.  That means there are default implementations here which may be overridden
*    The methods in the composed class are defined as virtual. The methods are defined virtual
*    in TAPS_ComposedBase rather than here because this class will not have descendants
*    the composed base will be extended by an implementation for a specific object (e.g. quotes)
*    that instantiation will have methods implemented that are object specific which we need to access
*    Modification Log:
*    -------------------------------------------------------------------------------------------------------------------------------------
*       Developer           Date            Description
*       Todd Newman                         Initial Version
*       Joshith K           01-Apr-2020     PRB0043528 -update Taps Deffered Run Creation logic.getDeferredList method
*       Joshith K           01-June-2020    PRB0043714 -changed  runOrDeferBatch() method call.
*       Satya Swain         12-Dec-2020     DCP-43261/TASK0548217: Modify batchRecalculateShares and triggerSharingLogic
*       Nesar Mohan         01-Apr-2022     Codescan Fix
* -------------------------------------------------------------------------------------------------------------------------------------
**/
public without sharing class TAPS_OrchestrationImpl implements TAPS_IOrchestration {

    // the composed base will be extended by an implementation for a specific object (e.g. quotes)
    // that instantiation will have methods implemented that are object specific which we need to access
    private TAPS_ComposedBase objectSpecificImpl;

    /*
    *  @Author      : Todd Newman
    *  @Description : Constructor to initialize the reference variable of type TAPS_ComposedBase
    *  @Param       : TAPS_ComposedBase
    */
    public TAPS_OrchestrationImpl(TAPS_ComposedBase objectSpecificImpl)
    {
        this.objectSpecificImpl = objectSpecificImpl;
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to navigate from account ID to record IDs
    *  @Param       : Set<Id>
    *  @Return      : Set<Id>
    */
    public Set<Id> getRecordIdsFromAccountIds(Set<Id> accountIds)
    {
        Set<Id> recordIds;

        if (objectSpecificImpl instanceof TAPS_IObjectsDirect)
        {
            TAPS_IObjectsDirect objectDirectImpl = (TAPS_IObjectsDirect)objectSpecificImpl;
            String objectName = objectDirectImpl.getObjectType().getDescribe().getName();

            String soql = 'SELECT Id FROM ' + objectName + ' WHERE ' + objectDirectImpl.getLookupFieldName() + ' IN :accountIds';
            List<SObject> records = Database.query(soql);
            recordIds = UtilsCollection.getSetOfIds(records, 'Id');
        }
        else if (objectSpecificImpl instanceof TAPS_IObjectsJunction)
        {
            TAPS_IObjectsJunction objectJunctionImpl = (TAPS_IObjectsJunction)objectSpecificImpl;
            String keyFieldName = objectJunctionImpl.getKeyFieldName();
            String valueFieldName = objectJunctionImpl.getValueFieldName();

            String soql = 'SELECT ' + keyFieldName + ' FROM ' + objectJunctionImpl.getJunctionTableName() + ' WHERE ' + valueFieldName + ' IN :accountIds';
            List<SObject> records = Database.query(soql);
            recordIds = UtilsCollection.getSetOfIds(records, keyFieldName);
        }
        else if (objectSpecificImpl instanceof TAPS_IObjectsCustom)
        {
            TAPS_IObjectsCustom objectCustomImpl = (TAPS_IObjectsCustom)objectSpecificImpl;
            recordIds = objectCustomImpl.getRecordIdsFromAccountIdsCustom(accountIds);
        }
        else
        {
            throw new ApexSharingException(TAPS_ComposedBase.SUB_INTERFACE_REQUIRED);
        }

        return recordIds;
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : this method receives IDs of records that were modified
    *  which may need to be converted to IDs that need to be shared
    *  direct = no conversion
    *  junction = query and translate from junction IDs to shared IDs
    *  custom = custom logic
    *  @Param       : Set<Id>
    *  @Return      : Set<Id>
    */
    public Set<Id> getRecordIdsFromModifiedRecordIds(Set<Id> modifiedRecordIds)
    {
        if (objectSpecificImpl instanceof TAPS_IObjectsDirect)
        {
            return modifiedRecordIds;
        }
        else if (objectSpecificImpl instanceof TAPS_IObjectsJunction)
        {
            TAPS_IObjectsJunction objectJunctionImpl = (TAPS_IObjectsJunction)objectSpecificImpl;

            String soql = 'SELECT ' + objectJunctionImpl.getKeyFieldName() + ' FROM ' + objectJunctionImpl.getJunctionTableName() + ' WHERE Id IN :modifiedRecordIds';
            List<SObject> junctionRecords = Database.query(soql);
            return UtilsCollection.getSetOfIds(junctionRecords, objectJunctionImpl.getKeyFieldName());
        }
        else if (objectSpecificImpl instanceof TAPS_IObjectsCustom)
        {
            TAPS_IObjectsCustom objectCustomImpl = (TAPS_IObjectsCustom)objectSpecificImpl;
            return objectCustomImpl.getRecordIdsFromModifiedRecordIdsCustom(modifiedRecordIds);
        }
        else
        {
            throw new ApexSharingException(TAPS_ComposedBase.SUB_INTERFACE_REQUIRED);
        }
    }

    /*
    * @author       : Todd Newman
    * @decription   : kick off a batch job to recalculate shares based on ETM for the record IDs  
    * @param        : Set<Id>
    * @return       : void
    */
    public void batchRecalculateShares(Set<Id> affectedRecordIds)
    {
        if(affectedRecordIds.isEmpty()) return;
        List<Set<Id>> recordIdChunks = chunkRecordIds(affectedRecordIds);

        String objectName = UtilsCollection.getFirstIdFromSet(affectedRecordIds).getSobjectType().getDescribe().getName();
        ITAPS_ExecutionStrategy executionImpl = getExecutionImpl(objectName);

        for (Set<Id> idChunk : recordIdChunks)
        {
            executionImpl.processChunk(objectName, idChunk);
        }

        executionImpl.execute();
    }

    /*
    * @author       : Todd Newman
    * @decription   : breaks the bigger sets into chunks and returns List of sets of records 
    * @param        : Set<Id>
    * @return       : List<Set<Id>>
    */
    private List<Set<Id>> chunkRecordIds(Set<Id> recordIds)
    {
        Integer maxIdsInEvent = TAPS_Config.getMaxIdsInEvent();
        List<Set<Id>> recordIdChunks = UtilsCollection.sliding(recordIds, maxIdsInEvent);
        return recordIdChunks;
    }

    /*
    * @author       : Todd Newman
    * @decription   : method to perform execution logic based on the TAPS_Config
    * @param        : String
    * @return       : ITAPS_ExecutionStrategy
    */
    private ITAPS_ExecutionStrategy getExecutionImpl(String objectName)
    {
        Boolean bypassEvent = TAPS_Config.bypassPlatformEvent();
        Boolean alwaysDeferSharingInTrigger = TAPS_Config.alwaysDeferSharingInTrigger();

        if (!Test.isRunningTest() && Trigger.isExecuting && alwaysDeferSharingInTrigger)
        {
            Set<String> objectsThatNeverDefer = TAPS_Config.getObjectsThatNeverDefer();

            if (!objectsThatNeverDefer.contains(objectName))
            {
                return new DeferExecution();
            }
        }

        if (!bypassEvent)
        {
            return new PublishExecution();
        }
        else
        {
            return new RunOrDeferExecution();
        }
    }

    /*
    * @author       : Todd Newman
    * @decription   : given IDs of records to be shared, return the related account IDs
    * @param        : Set<Id>
    * @return       : Set<Id>
    */

    public Set<Id> getRecordIdsFromAccountIdsCustom(Set<Id> accountIds)
    {
        throw new ApexSharingException(TAPS_ComposedBase.REQUIRED_FOR_CUSTOM);
    }

    /*
    * @author     : Todd Newman
    * @decription : given a list of records that were modified, return the IDs of the records that need to be shared
    * these are often the same IDs but might not be if there is a junction object for instance
    * @param      : Set<Id>
    * @return     : Set<Id>
    */
    public Set<Id> getRecordIdsFromModifiedRecordIdsCustom(Set<Id> modifiedRecordIds)
    {
        throw new ApexSharingException(TAPS_ComposedBase.REQUIRED_FOR_CUSTOM);
    }
    /*
    * @author       : Todd Newman
    * @decription   : custom Apex exception
    */
    public class ApexSharingException extends Exception { }

}