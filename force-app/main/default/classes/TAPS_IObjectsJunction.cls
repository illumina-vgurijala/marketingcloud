/**
*    @author Todd Newman
*    @date   
*    @description  - Interface containing the methods which are to be implemented by a class whose
*    sObject is a junction object between account and another sObject for creating share records
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                  Date                   Description
*     Todd Newman                                      Initial Version
*     Aman Tyagi             31st March 2022           CodeScan Fixes
*    ------------------------------------------------------------------------------------                    
*/
public interface TAPS_IObjectsJunction extends TAPS_IObjects {

    // name the junction object that sits between the target and account
    String getJunctionTableName();

    // name the field that refers to the shared record in the junction
    String getKeyFieldName();

    // name the field that referes to account in the junction
    String getValueFieldName();

}