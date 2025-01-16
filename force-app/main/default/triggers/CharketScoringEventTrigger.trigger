trigger CharketScoringEventTrigger on Charket_Scoring_Event__e (after insert) {
     ilib_SObjectDomain.triggerHandler(CharketScoringEvents.class);
}