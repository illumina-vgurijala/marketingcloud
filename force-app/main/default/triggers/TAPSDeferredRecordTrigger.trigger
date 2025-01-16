/**
*    @author Ashwin
*    Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                    Description
*    Ashwin Kumar                   06-April-2022           DCP-52339
*    ------------------------------------------------------------------------------------                  
**/
trigger TAPSDeferredRecordTrigger on TAPS_Deferred_Record__c (after delete) {
    ilib_SObjectDomain.triggerHandler(TAPS_DeferredRecords.class);
}