/**
*    @author Todd Newman
*    @date   
*    @description  : Interface that contains methods for filtering records based on inputs and supplied criteria
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                  Date                   Description
*     Todd Newman                                      Initial Version
*     Aman Tyagi             31st March 2022           CodeScan Fixes
*    ------------------------------------------------------------------------------------ 
*                    
*/
public interface TAPS_IObjects {

    // the object being shared
    SObjectType getObjectType();

    // given IDs of records to be shared, return the related account IDs
    Map<Id, Set<Id>> getRecordIdToAccountIds(Set<Id> recordIds);

    /*
     * these three methods have a default implementation in the virtual class
     * to return all records (filter nothing)
     * override if filtering is needed
     */

    // given the record IDs that have been modified (keys in the map parameter)
    // return the record IDs that will be shared
    // default implementation is all of them
    // for some objects, business rules may filter to a subset based on record or account data
    Set<Id> filterRecordsRelatedToAccount(Map<Id, Set<Id>> recordIdToAccountId);

    // given the territory IDs related to modified records
    // return the territory IDs that records will be shared to
    // default implementation is all of them
    // for some objects, business rules may filter to a subset based on territory, record, or account data
    Set<Id> filterTerritories(Set<Id> territoryIds, Map<Id, Set<Id>> recordIdToAccountIds);

    // given the territory IDs and linked user IDs
    // filter down the map to territories and users for which records will be shared to
    // default implementation is all of them
    // for some objects, business rules may filter to a subset based on territory or user data
    Map<Id, Set<Id>> filterTerritoryIdToUserIds(Map<Id, Set<Id>> territoryIdToUserIds, Map<Id, Set<Id>> accountIdToTerritoryIds, Map<Id, Set<Id>> recordIdToAccountIds);

}