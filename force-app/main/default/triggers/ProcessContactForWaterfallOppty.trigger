trigger ProcessContactForWaterfallOppty on ProcessContactForWaterfallOppty__e (after insert) {  
    ilib_SObjectDomain.triggerHandler(ProcessContactsForWaterfallOppty.class);
}