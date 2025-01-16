trigger CustomerReadinessFormTrigger on Customer_Readiness_Form__c (after insert, after update, before insert, before update)
{
    ilib_SObjectDomain.triggerHandler(CustomerReadinessForms.class);
}