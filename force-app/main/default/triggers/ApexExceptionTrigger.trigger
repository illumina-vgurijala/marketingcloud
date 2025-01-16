trigger ApexExceptionTrigger on Apex_Exception__e (after insert) {

    ilib_SObjectDomain.triggerHandler(ApexExceptions.class);

}