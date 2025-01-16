trigger ApttusOrderLineItemTrigger on Apttus_Config2__OrderLineItem__c (after insert, after update, before delete) {
    ilib_SObjectDomain.triggerHandler(ApttusOrderLineItems.class);
}