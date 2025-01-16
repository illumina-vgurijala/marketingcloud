trigger OpportunityContactRoleTrigger on OpportunityContactRole (before insert,before update,before delete, after insert,after update,after delete) {
	 ilib_SObjectDomain.triggerHandler(OpportunityContactRoles.class);
}