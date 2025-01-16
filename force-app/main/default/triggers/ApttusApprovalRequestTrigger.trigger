trigger ApttusApprovalRequestTrigger on Apttus_Approval__Approval_Request__c (after insert, after update, after delete)
{
    ilib_SObjectDomain.triggerHandler(ApttusApprovalRequests.class);

}