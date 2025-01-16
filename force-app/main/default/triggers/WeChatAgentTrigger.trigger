/**
 *  @author Charket
 *  @date   29-Mar-2024
 *  @description Trigger on WeChat Agent object. Used for transfering open wechat chats to backup agent when the agent's status changes to 'Out of Office'.
 **/
trigger WeChatAgentTrigger on Charket__WeChatAgent__c (after update) {
    /** @DESCRIPTION - execute trigger handler **/
    ilib_SObjectDomain.triggerHandler(CharketCustomerCareAgents.class);
}