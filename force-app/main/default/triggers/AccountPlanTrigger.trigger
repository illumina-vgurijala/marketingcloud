/**
*    @author Kushagra Desai
*    @date   20-Aug-2019
*    @description    
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             
*    ------------------------------------------------------------------------------------ 
*                    
*/
trigger AccountPlanTrigger on Account_Plan__c (after insert,before insert,before delete,before update,after update) {
    
    ilib_SObjectDomain.triggerHandler(AccountPlans.class);
}