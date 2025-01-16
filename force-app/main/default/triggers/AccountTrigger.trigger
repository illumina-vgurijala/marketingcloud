/**
*    @author Prakhar Kumar
*    @date   2018-09-13
*    @description    DCP-: Allow Account COnversion only when Partner Request status field's value is 'Pending'
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Prakhar                       25 Aug 2018            To populate the price list on Account Sales Area
*             Gerardo Garcia                07 Aug 2024            CMCM-7890 Implement before update
*    ------------------------------------------------------------------------------------ 
*
*/

trigger AccountTrigger on Account (before insert, before update, after insert, after update) {
     ilib_SObjectDomain.triggerHandler(Accounts.class);
}