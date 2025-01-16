trigger SmIbTechnicalAttributesTrigger on SVMXC__SM_IB_Technical_Attributes__c (after insert, after update)
{
    ilib_SObjectDomain.triggerHandler(SmIbTechnicalAttributes.class);
}