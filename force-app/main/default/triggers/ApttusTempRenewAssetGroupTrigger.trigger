trigger ApttusTempRenewAssetGroupTrigger on Apttus_Config2__TempRenewAssetGroup__c (after insert, after update)
{
    ilib_SObjectDomain.triggerHandler(ApttusTempRenewAssetGroups.class);
}