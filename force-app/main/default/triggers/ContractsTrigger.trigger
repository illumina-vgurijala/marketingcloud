trigger ContractsTrigger on Contracts__c (after insert) {
     ilib_SObjectDomain.triggerHandler(Contracts.class);
}