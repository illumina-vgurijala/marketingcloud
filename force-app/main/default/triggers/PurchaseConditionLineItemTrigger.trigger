trigger PurchaseConditionLineItemTrigger on Purchase_Condition_Line_Item__c (before insert,before update,before delete,after insert,after delete,after update) {
    ilib_SObjectDomain.triggerHandler(PurchaseConditionLineItems.class);
}