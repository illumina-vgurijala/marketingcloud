/**
*    @author Roopal Verma
*    @date   2018-09-07
*    @description    DCP-9717: Prevent deletion of COnsortium with Consortium Opportunity
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    ------------------------------------------------------------------------------------ 
*                    
*/
trigger ConsortiumAccountTrigger  on Consortium_Account__c (after insert, before delete)
{
    ilib_SObjectDomain.triggerHandler(ConsortiumAccounts.class);
}