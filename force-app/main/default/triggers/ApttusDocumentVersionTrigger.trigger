trigger ApttusDocumentVersionTrigger on Apttus__DocumentVersion__c (before insert, after insert) {
    ilib_SObjectDomain.triggerHandler(ApttusDocumentVersions.class);
}