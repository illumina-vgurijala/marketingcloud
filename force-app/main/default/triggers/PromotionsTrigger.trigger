trigger PromotionsTrigger on Promotions__c (after insert,after update) {
    ilib_SObjectDomain.triggerHandler(Promotions.class);
}