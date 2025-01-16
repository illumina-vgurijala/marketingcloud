trigger OpportunitySyncToQuoteTrigger on OpportunitySyncToQuote__e (after insert) {
    ilib_SObjectDomain.triggerHandler(OpportunitySyncToQuotes.class);
}