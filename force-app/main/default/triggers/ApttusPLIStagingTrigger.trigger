trigger ApttusPLIStagingTrigger on Apttus_PLI_Staging__c (before insert)
{
    ilib_SObjectDomain.triggerHandler(ApttusPLIStagings.class);
}