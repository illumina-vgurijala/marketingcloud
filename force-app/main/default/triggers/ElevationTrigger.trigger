/**
* @author:Deepika Ayyavari
* @date Dec-2021
* @group ElevationTrigger
* @description Trigger on Elevation that creates Work Order Comments 
* whenever Send Plan of Action is updated.
* Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Deepika Ayyavari              15-Dec-2021         Initial Version
 */
trigger ElevationTrigger on Elevations__c (after update, after insert,Before Update) {  
    ilib_SObjectDomain.triggerHandler(Elevations.class);
}