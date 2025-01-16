trigger ApttusApprovalRequestHistoryTrigger on Apttus_Approval__Approval_Request_History__c (after insert, after update)
{
    ilib_SObjectDomain.triggerHandler(ApttusApprovalRequestHistories.class);
}