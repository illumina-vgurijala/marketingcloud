/**
*    @author Kushagra Desai
*    @date   20-Aug-2019
*    @description    
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*            Deep Diwakar                 Jul-30-2024          CMCM-7519/7968: Added before save to include marketing task updates          
*    ------------------------------------------------------------------------------------ 
*                    
*/
trigger TaskTrigger on Task (before insert, after insert,after update,after delete) {
    
    ilib_SObjectDomain.triggerHandler(Tasks.class);
}