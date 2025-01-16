/**
*    @author Kushagra Desai
*    @date   5-Nov-2020
*    @description    
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description          
*    ------------------------------------------------------------------------------------ 
*                    
*/
trigger ChannelPartnerQuotaTrigger on Channel_Partner_Quota__c (after insert) {
    ilib_SObjectDomain.triggerHandler(ChannelPartnerQuotas.class);
}