/**
 * @author Gerardo Garcia
 * @description Trigger for Competitive_Complementary_Technology__c
 * Modification Log:
 *   ---------------------------------------------------------------------------------------------------------------------------
 *    Developer                     Date(YY-MM-DD)                  Description
 *    Gerardo Garcia                2023-10-02                      Initial Version CMCM-2893
 *   ---------------------------------------------------------------------------------------------------------------------------
 */
trigger CompetitiveComplementaryTechTrigger on Competitive_Complementary_Technology__c (before insert, after insert, before update, after update, after delete) {
    ilib_SObjectDomain.triggerHandler(CompetitiveComplementaryTechnologies.class);
}