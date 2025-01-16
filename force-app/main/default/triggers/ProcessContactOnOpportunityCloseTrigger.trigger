trigger ProcessContactOnOpportunityCloseTrigger on ProcessContactOnOpportunityClose__e (after insert) {
    ilib_SObjectDomain.triggerHandler(ProcessContactsOnOpportunityClose.class);
}