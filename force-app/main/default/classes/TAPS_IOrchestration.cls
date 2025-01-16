/**
*    @author Todd Newman
*    @date   
*    @description  interface wuth methods for fetching out record ids
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                  Date                   Description
*     Todd Newman                                      Initial Version
*     Aman Tyagi             31st March 2022           CodeScan Fixes
*    ------------------------------------------------------------------------------------                    
*/
public interface TAPS_IOrchestration {

    // navigate from account ID to record IDs
    Set<Id> getRecordIdsFromAccountIds(Set<Id> accountIds);

    // this method receives IDs of records that were modified
    // which may need to be converted to IDs that need to be shared
    // direct = no conversion
    // junction = query and translate from junction IDs to shared IDs
    // custom = custom logic
    Set<Id> getRecordIdsFromModifiedRecordIds(Set<Id> modifiedRecordIds);

    // kick off a batch job to recalculate shares based on ETM for the following IDs
    void batchRecalculateShares(Set<Id> affectedRecordIds);

}