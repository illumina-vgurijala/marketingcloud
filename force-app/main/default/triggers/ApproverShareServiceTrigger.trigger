trigger ApproverShareServiceTrigger on Approver_Share_Service__e(after insert)
{
    ilib_SObjectDomain.triggerHandler(ApproverShareServices.class);
}