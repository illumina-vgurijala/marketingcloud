/**
*    @author Todd Newman
*    @date   
*    @description  : Interface that contains methods to be implemented for record sharing calculations
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                  Date                   Description
*     Todd Newman                                      Initial Version
*     Aman Tyagi             31st March 2022           CodeScan Fixes
*    ------------------------------------------------------------------------------------ 
*                    
*/
public interface TAPS_IBatch {

    // traversing all the intermediary objects, generate a map from the records to be shared
    // to the users that need sharing based on ETM rules
    Map<Id, Set<Id>> mapRecordIdToUserIds(Set<Id> recordIds);

    // get the specific SObject that holds sharing records
    SObjectType getShareObjectType();

    // name the field on the Share table that refers to the parent record ID
    // will be ParentId for all custom objects but a more specific name for standard objects
    String getShareParentFieldName();

    // retrieve manual shares on these records
    List<SObject> getExtantShares(Set<Id> recordIds);

    // create Apex sharing records from the record IDs to the user IDs
    void createSharingRecords(Map<Id, Set<Id>> recordIdToUserIds);

    // creates a share record specific to this implementation
    SObject createSharingRecord(Id recordId, Id userId);

    // delete Apex sharing records from the record IDs to the user IDs
    void removeSharingRecords(Map<Id, Set<Id>> recordIdToUserIds);

}