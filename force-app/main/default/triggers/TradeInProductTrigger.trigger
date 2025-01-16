trigger TradeInProductTrigger on Trade_In_Product__c (before insert, before update, before delete) {
    ilib_SObjectDomain.triggerHandler(TradeInProducts.class);
}