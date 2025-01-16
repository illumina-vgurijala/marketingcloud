/**
*    @author Kushagra Desai
*    @date   15-Apr-2021
*    @description    
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             
*    ------------------------------------------------------------------------------------ 
*                    
*/
trigger NotificationDetailTrigger on Notification_Detail__c (before insert,before update) {
    ilib_SObjectDomain.triggerHandler(NotificationDetails.class);
}