trigger ObjectiveOpportunityRelationshipTrigger on Objective_Opportunity_Relationship__c (after insert) {
    ilib_SObjectDomain.triggerHandler(ObjectiveOpportunityRelationships.class);
}