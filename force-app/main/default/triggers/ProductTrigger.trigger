/**
*    @author Rohan Chandarana
*    @date   2018-06-22
*    @description   DCP-4568: Material Association with Category,Group and Line
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*             Developer                      Date                Description
*             Rohan Chandarana               22 June 2018        Material Association with Category,Group and Line
*             Joshith K                      4 Nov 2018          Added Before Update Event
*    ------------------------------------------------------------------------------------ 
*                    
*/
trigger ProductTrigger on Product2 (before insert, before update, after insert, after update) 
{
    ilib_SObjectDomain.triggerHandler(Products.class);
}