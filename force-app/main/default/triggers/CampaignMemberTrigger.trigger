/**
*    @author: Pankaj Singla
*    @date:   12-Oct-2018
*    @description:  Trigger for Campaign Member object
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             
*    ------------------------------------------------------------------------------------ 
*                    
*/


trigger CampaignMemberTrigger on CampaignMember (after insert,after update, before insert, before update) {
    
     ilib_SObjectDomain.triggerHandler(CampaignMembers.class);

}