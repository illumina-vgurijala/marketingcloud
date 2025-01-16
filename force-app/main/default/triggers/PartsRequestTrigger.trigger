trigger PartsRequestTrigger on SVMXC__Parts_Request__c (after insert, after update)
{
    ilib_SObjectDomain.triggerHandler(PartsRequests.class);
}