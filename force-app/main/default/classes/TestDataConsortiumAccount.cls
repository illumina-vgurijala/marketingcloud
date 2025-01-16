/**
* Consortium Account and associated records
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    ------------------------------------------------------------------------------------
**/
@isTest

public with sharing class TestDataConsortiumAccount{

    /**
    * 
    *
    * @desc initConsrtuimAccount
    */
    public static Consortium_Account__c initConsortiumAccount(Consortium__c c, Account a, boolean booIsInactive){

        Consortium_Account__c consortiumAcc = new Consortium_Account__c(
            Consortia__c = c.id,
            Account__c = a.id,
            Is_InActive__c = booIsInactive
            );

        return consortiumAcc;
    }
}