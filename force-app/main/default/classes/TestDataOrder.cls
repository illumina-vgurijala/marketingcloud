/**
 *    @author         : 
 *    @date           :
 *    @description    : Test class to create data for Data Order
 *    Modification Log:
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
 *    Developer                     Date                Description
 *    Vivek R                       06-Oct-22           Codescan fixes: added comments
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
*/
 @isTest
public with sharing class TestDataOrder {

    /**
     *  @description : Method to create Data Order through the Id of the account record
     *  @param       : Id
     *  @return      : Apttus_Config2__Order__c
    */
    public static Apttus_Config2__Order__c getNewOrder(Id accountId) {
        Apttus_Config2__Order__c rec = initOrder(accountId);
        insert rec;
        return rec;
    }
    /**
     *  @description : Method to create Data Order through the Id of the account record
     *  @param       : Id
     *  @return      : Apttus_Config2__Order__c
    */
    public static Apttus_Config2__Order__c initOrder(Id accountId) {
        Apttus_Config2__Order__c rec = new Apttus_Config2__Order__c(
            Apttus_Config2__SoldToAccountId__c = accountId
        );
        return rec;
    }

}