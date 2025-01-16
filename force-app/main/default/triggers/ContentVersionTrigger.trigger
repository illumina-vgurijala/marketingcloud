/*
*@author         :Vignesh Sethuramalingam
*@date           :11-Mar-2022
*@description    :Trigger for ContentVersion
*Modification Log:
*------------------------------------------------------------------------------------
*       Developer                      Date                Description
* Vignesh Sethuramalingam           11-Mar-2022          Initial Version
*------------------------------------------------------------------------------------ 
*                    
*/
trigger ContentVersionTrigger on ContentVersion (before insert) {
    ilib_SObjectDomain.triggerHandler(ContentVersions.class);
}