/***************************************************************************************************************************************
 * NAME   : WorkOrderResourceTrigger
 * DESCRIPTION  : Trigger for Work Order Resource
 *              
 * @AUTHOR : Digvijay Singh
 * @DATE   : 30-May-2019 
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Digvijay              30-May-2019         Initial Version. Events handled before delete
 * Joshith K			 04-July-2019		 After insert,After Update,After Delete	
  ****************************************************************************************************************************************/ 

trigger WorkOrderResourceTrigger on SVMXC__Work_Order_Resource__c (before delete , before update,before insert, After insert,After Update,After Delete) {
      ilib_SObjectDomain.triggerHandler(WorkOrderResources.class);
}