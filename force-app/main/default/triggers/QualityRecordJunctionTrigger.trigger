/***************************************************************************************************************************************
 * NAME   : QualityRecordJunctionTrigger
 * DESCRIPTION  : Trigger for Quality Record Junction
 *				      
 * @AUTHOR : Gladis Evangaly
 * @DATE   : 04-Apr-2022  
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Gladis             	04-Apr-2022          Initial Version. Events handled before/after dmls
  ****************************************************************************************************************************************/ 
trigger QualityRecordJunctionTrigger on Quality_Record_Junction__c (after insert, after update) {
    ilib_SObjectDomain.triggerHandler(QualityRecordJunctions.class);
}