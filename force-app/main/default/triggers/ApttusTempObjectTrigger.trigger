/**
 * Created by tnewman on 2018-11-28.
 */

trigger ApttusTempObjectTrigger on Apttus_Config2__TempObject__c (after insert, after update)
{
    ilib_SObjectDomain.triggerHandler(ApttusTempObjects.class);
}