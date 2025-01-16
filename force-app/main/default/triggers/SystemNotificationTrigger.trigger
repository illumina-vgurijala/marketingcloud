/**
*    @author Joshith k
*    @date   2018-11-16
*    @description   DCP-15322: Send email to Part order owner when system notification is added with Part order number in subject
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*             Developer                      Date                Description
*             Joshith K                  16 Nov 2018        Forward email to PartsOrder owner
*    ------------------------------------------------------------------------------------ 
*                    
*/
trigger SystemNotificationTrigger on System_Notification__c (after insert) {
	 ilib_SObjectDomain.triggerHandler(SystemNotifications.class);
}