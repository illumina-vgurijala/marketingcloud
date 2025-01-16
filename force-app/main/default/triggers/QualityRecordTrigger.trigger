/***************************************************************************************************************************************
 * NAME   : QualityRecordTrigger
 * DESCRIPTION  : Trigger for Quality Record
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
trigger QualityRecordTrigger on Quality_Record__c (after insert, after update) {   
	ilib_SObjectDomain.triggerHandler(QualityRecords.class);
}