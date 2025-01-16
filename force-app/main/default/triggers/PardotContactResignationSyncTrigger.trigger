trigger PardotContactResignationSyncTrigger on PardotContactResignationSync__e (after insert) {
    ilib_SObjectDomain.triggerHandler(PardotContactsResignationSync.class);
}