/***************************************************************************************************************************************
 * NAME   : AssociatedProductTrigger
 * DESCRIPTION  : Trigger for Associated Product
 *                    
 * @AUTHOR : Priya Mukherjee
 * @DATE   : 19-Oct-2023  
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Priya               26-Oct-2023          Initial Version. Events handled before insert and before udpate
 * Abhishek            12-Feb-2023          CMCM-269. Events handled after insert , after udpate and after delete 
 * Dhairya            14-Feb-2024          CMCM-5753. Events handled before delete
  ****************************************************************************************************************************************/ 
trigger AssociatedProductTrigger on Associated_Product__c (before insert,before update,before delete,after insert,after update,after delete) {
            ilib_SObjectDomain.triggerHandler(AssociatedProduct.class);
}