/**
 * Created by tnewman on 2018-12-11.
 */

trigger LocationTrigger on SVMXC__Site__c (after insert, after update, before insert, before update) {
    ilib_SObjectDomain.triggerHandler(Locations.class);
    
}