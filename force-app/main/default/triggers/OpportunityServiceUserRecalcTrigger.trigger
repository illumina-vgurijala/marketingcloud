trigger OpportunityServiceUserRecalcTrigger on Opportunity_Service_User_Recalc__e (after insert) {
    ilib_SObjectDomain.triggerHandler(OpportunityServiceUserRecalcs.class);
}