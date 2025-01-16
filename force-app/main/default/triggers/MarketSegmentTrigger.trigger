/**
*    @author Adyasha Satapathy
*    @date   2022-05-25
*    @description    DCP-53375: Created Market Segment Trigger
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Adyasha                      25 May 2022           DCP-53375: Trigger created for Market Segment related functionalities
*    ------------------------------------------------------------------------------------                     
*/

trigger MarketSegmentTrigger on Market_Segment__c (before insert,before update,before delete,after insert,after update,after delete) {
    ilib_SObjectDomain.triggerHandler(MarketSegments.class);
}