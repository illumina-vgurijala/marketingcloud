trigger IlmnLogTrigger on ILMN_Log__e (after insert) {
    ilib_SObjectDomain.triggerHandler(IlmnLogs.class);
}