/**
*    @author Rohan Chandarana
*    @date   2018-10-01
*    @description    Trigger for Asset Line Item History 
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*        Developer                      Date                Description
*        Gopesh Banker (Apttus)         01 OCT 2018        Initial Version 
*    ------------------------------------------------------------------------------------ 
*/
trigger ApttusAssetlLineItemHistoryTrigger on Apttus_Config2__AssetLineItemHistory__c (after insert, before update, after update)
{
	ilib_SObjectDomain.triggerHandler(ApttusAssetLineItemHistories.class);
}