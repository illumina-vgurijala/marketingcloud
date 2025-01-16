/***************************************************************************************************************************************
 * NAME   : LocationsCoveredTrigger
 * DESCRIPTION  : Trigger for Locations Covered
 *                    
 * @AUTHOR : Debanka
 * @DATE   : 4-July-2018 
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 *Debanka Chakraborty        19-June-2019          Initial Version. Events handled after insert and after delete
 **********************************************************************************************************************/
trigger LocationsCoveredTrigger on SVMXC__Service_Group_Site__c (after insert,after update, after delete) {
ilib_SObjectDomain.triggerHandler(LocationsCoveredCls.class);
}