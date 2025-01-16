/**
*    @author Rahul Sharma
*    @date   2019-05-16
*    @description    DCP-25198: Partner Request Sharing
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Rahul Sharma                 16 May 2019           Partner Request Sharing
*    ------------------------------------------------------------------------------------ 
*                    
*/
trigger PartnerRequestTrigger on Partner_Request__c (after insert) 
{
        ilib_SObjectDomain.triggerHandler(PartnerRequests.class);
}