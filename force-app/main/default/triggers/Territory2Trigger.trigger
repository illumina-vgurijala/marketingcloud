trigger Territory2Trigger on Territory2 (after insert, after update) {
    ilib_SObjectDomain.triggerHandler(Territories2.class);
}