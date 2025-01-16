/**
* Contact and associated records
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Satya Swain                 04 July 2018           getNewContact(Account)
*                                                                initContact(Account)                                                              
*    ------------------------------------------------------------------------------------
**/
@isTest(isparallel=true)
public with sharing class TestDataContact {
    
    /*
    *  @AUTHOR:  Satya Swain
    *  @DESCRIPTION:This method creates Contact
    *  @PARAM :  Account a
    *  @RETURN:  Contact bject
    */
    public static Contact getNewContact(Account a)
    {
        Contact c = initContact(a);
        insert c;
        return c;
    }

    /*
    * Description: returns Contact record
    */
    public static Contact initContact(Account a)
    {
        return TestDataPerson.initContact(a.Id);
    }

}