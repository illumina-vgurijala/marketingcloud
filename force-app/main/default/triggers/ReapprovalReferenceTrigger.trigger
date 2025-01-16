/**
*    @author Kumar Gaurav
*    @date   2024-06-24
*    @description Created for DGP-31 for updating quote with reapproval reference Id
*    Modification Log:
*    ------------------------------------------------------------------------------------
*         Developer                      Date               Description
*         Kumar Gaurav                   25-Jun-2024        Inital Commit 
*    ------------------------------------------------------------------------------------ 
*
*/

trigger ReapprovalReferenceTrigger on Reapproval_Reference__c (after insert) {

    ilib_SObjectDomain.triggerHandler(ReapprovalReferences.class);

}