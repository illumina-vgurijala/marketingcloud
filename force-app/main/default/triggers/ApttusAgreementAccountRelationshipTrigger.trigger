trigger ApttusAgreementAccountRelationshipTrigger on Agreement_Account_Relationship__c (before insert, before update, after insert, after update) {
    ilib_SObjectDomain.triggerHandler(AgreementAccountRelationships.class);
}