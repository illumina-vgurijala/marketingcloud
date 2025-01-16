trigger SmIbAttributesHistoryTrigger on SVMXC__SM_IB_Attributes_History__c (after insert, after update)
{
    ilib_SObjectDomain.triggerHandler(SmIbAttributesHistories.class);
}