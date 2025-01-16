/**
 *    @author Anisha Bharti
 *    @date   07-Aug-2020
 *    @description  Test class for Plans
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------------------
 *     Developer                      Date                Description
 *   Anisha Bharti					25-Aug-2020			Added test method testafterupdate
 *   KD         					8-Sept-2020			Added after insert for sharing
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
 */
trigger PlanTrigger on Plan__c (before update, after update,after insert) {

    ilib_SObjectDomain.triggerHandler(Plans.class);
}