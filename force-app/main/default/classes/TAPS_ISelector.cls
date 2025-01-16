/**
*    @author Todd Newman
*    @date   
*    @description  interface wuth method for fetching out manual shares 
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                  Date                   Description
*     Todd Newman                                      Initial Version
*     Aman Tyagi             31st March 2022           CodeScan Fixes
*    ------------------------------------------------------------------------------------                    
*/
public interface TAPS_ISelector {

    // returns manual shares related to passed-in recordIds
    List<ContactShare> selectManualByParentId(Set<Id> recordIds);

}