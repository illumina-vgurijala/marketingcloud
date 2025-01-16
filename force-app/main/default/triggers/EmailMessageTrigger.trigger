/**
*    @author Soumya Ranjan Sahu
*    @date   2018-09-13
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*    Developer                      Date                Description
*    Soumya                         13-09-2018          Initial Version. 
*
*    --------------------------------------------------------------------------------------------------------------------------------------------------
*                    
*/
trigger EmailMessageTrigger on EmailMessage (before insert, before delete, after insert) {
    ilib_SObjectDomain.triggerHandler(EmailMessages.class);
}