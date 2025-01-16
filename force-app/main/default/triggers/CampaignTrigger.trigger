/**
*    @author: Pankaj Singla
*    @date:   27-Aug-2018
*    @description:  Create Campaign Member status picklist values DCP-9584
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             
*    ------------------------------------------------------------------------------------ 
*                    
*/


trigger CampaignTrigger on Campaign (after insert) {
    
     ilib_SObjectDomain.triggerHandler(Campaigns.class);

}