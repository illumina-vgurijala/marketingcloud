/**
*    @author Govind Dubey
*    @date   2018-05-15
*    @description    DCP-1010,548: Contact Role Functionality 
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Govind Dubey                21 May 2018            To check Contact Role functionality for DCP-1010,548
              Akash Kumar                 07 July 2018           To check values for Primary Market Segment and Other Market Segment
                                                                 as per DCP-2138
*           Shashank Singhal            23 Aug 2018              Added the trigger event after update for story DCP-844
*    ------------------------------------------------------------------------------------ 
*                    
*/
trigger OpportunityTrigger on Opportunity (before update, before insert, after insert, after update)
{
        ilib_SObjectDomain.triggerHandler(Opportunities.class);
}