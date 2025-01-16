/**
*    @author Soumya Sahu
*    @date   2019-04-01
*    @description    To handle insert and update actions on Cycle Count Object
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Soumya Ranjan Sahu             01 Apr 2019         To handle insert and update actions on Cycle Count Object
*             
*    ------------------------------------------------------------------------------------ 
*                    
*/
trigger CycleCountTrigger on Cycle_Count__c (before update,before insert,after insert,after update,after delete) {
    ilib_SObjectDomain.triggerHandler(CycleCounts.class);
}