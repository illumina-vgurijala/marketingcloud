trigger SmIbAttributesTemplateInstanceTrigger on SVMXC__SM_IB_Attributes_Template_Instance__c (after insert, after update,before Insert,before update)
{
    ilib_SObjectDomain.triggerHandler(SmIbAttributesTemplateInstances.class);
}