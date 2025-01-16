/**
*    @author Todd Newman
*    @date   
*    @description  interface which is extending TAPS_IObjects class
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                  Date                   Description
*     Todd Newman                                      Initial Version
*     Aman Tyagi             31st March 2022           CodeScan Fixes
*    ------------------------------------------------------------------------------------                    
*/
public interface TAPS_IObjectsDirect extends TAPS_IObjects {

    // name the relationship field on the target object to the parent Account
    String getLookupFieldName();

}