trigger WorkOrderActivityRulesTrigger on Work_Order_Activity_Rules__c (before insert,before update) {
    ilib_SObjectDomain.triggerHandler(WorkOrderActivityRules.class);
}