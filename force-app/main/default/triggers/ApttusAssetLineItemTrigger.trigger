trigger ApttusAssetLineItemTrigger on Apttus_Config2__AssetLineItem__c (after insert, after update)
{
    ilib_SObjectDomain.triggerHandler(ApttusAssetLineItems.class);
}