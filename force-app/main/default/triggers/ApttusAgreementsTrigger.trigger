/**
*    @author Saswati
*    @date   05 Dec 2019
*    @description    DCP-31654
*    Modification Log:
*    ------------------------------------------------------------------------------------
*        Developer                  Date              Description
*        Saswati Prusty             05 Dec 2019       DCP-31654
*    ------------------------------------------------------------------------------------
*
*/

trigger ApttusAgreementsTrigger on Apttus__APTS_Agreement__c (before insert, after insert, before update, after update) {
    ilib_SObjectDomain.triggerHandler(ApttusAgreements.class);
}
