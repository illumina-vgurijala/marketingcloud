/**
 *    @author KD
 *    @date   
 *    @description  Trigger for Line item
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------------------
 *     Developer                      Date                Description
 *   KD         					8-May-2021			Added before update
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
 */
trigger ApttusProductConfigLineTrigger on Apttus_Config2__LineItem__c (before insert,before update)
{
    ilib_SObjectDomain.triggerHandler(ApttusProductConfigItems.class);
}