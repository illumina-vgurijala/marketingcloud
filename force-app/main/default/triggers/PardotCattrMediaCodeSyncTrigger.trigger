trigger PardotCattrMediaCodeSyncTrigger on PardotCattrMediaCodeSync__e (after insert) {
    ilib_SObjectDomain.triggerHandler(PardotCattrMediaCodeSync.class);
}