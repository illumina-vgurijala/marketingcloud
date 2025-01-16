/**
*    @author Todd Newman
*    @date   
*    @description  : Interface containing the methods which are to be implemented by a class whose
*    sObject doesnot have direct relation between account object for sharing the sObject records
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                  Date                   Description
*     Todd Newman                                      Initial Version
*     Aman Tyagi             31st March 2022           CodeScan Fixes
*    ------------------------------------------------------------------------------------                    
*/
public interface TAPS_IObjectsCustom extends TAPS_IObjects {

    // navigate from records to accounts
    Map<Id, Set<Id>> mapRecordToAccountsCustom(Set<Id> recordIds);

    // given IDs of records to be shared, return the related account IDs
    Set<Id> getRecordIdsFromAccountIdsCustom(Set<Id> accountIds);

    // given a list of records that were modified, return the IDs of the records that need to be shared
    // these are often the same IDs but might not be if there is a junction object for instance
    Set<Id> getRecordIdsFromModifiedRecordIdsCustom(Set<Id> modifiedRecordIds);

}