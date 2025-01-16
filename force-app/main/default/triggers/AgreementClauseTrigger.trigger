/**
*    @author Saswati
*    @date   05 Dec 2019
*    @description    DCP-31654
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*             Developer                      Date               Description
*             Saswati Prusty               05 Dec 2019        Update Price Group
*    ------------------------------------------------------------------------------------ 
*                    
*/

trigger AgreementClauseTrigger on Apttus__Agreement_Clause__c (before insert, after insert, before update, after update) {
    ilib_SObjectDomain.triggerHandler(AgreementClauses.class);
}