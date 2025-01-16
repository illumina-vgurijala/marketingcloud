trigger AttendeeTrigger on openq__Attendee__c (after insert) {
    ilib_SObjectDomain.triggerHandler(Attendees.class);
}