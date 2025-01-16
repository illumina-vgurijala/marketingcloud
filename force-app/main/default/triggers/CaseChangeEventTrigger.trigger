/**
 *    @author KD
 *    @date   30-March-2021
 *    @description  Trigger for CaseChangeEvent
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------------------
 *     Developer                      Date                Description
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
 */
trigger CaseChangeEventTrigger on CaseChangeEvent (after insert) {
    ilib_SObjectDomain.triggerHandler(CaseChangeEvents.class);
}