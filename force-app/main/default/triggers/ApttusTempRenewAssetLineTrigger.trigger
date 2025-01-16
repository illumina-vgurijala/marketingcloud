trigger ApttusTempRenewAssetLineTrigger on Apttus_Config2__TempRenewAssetLineItem__c (after insert, after update)
{
    ilib_SObjectDomain.triggerHandler(ApttusTempRenewAssetLines.class);
}