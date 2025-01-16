/**
* @author:Pooja Shalwadi
* @date 2021
* @group ContentDocument
* @description Trigger on ContentDocument that handles ensuring the correct system flags are set on
* our special ContentDocument and validate before deleting any of the record
*/
trigger ContentDocumentTrigger on ContentDocument (before delete,after delete) {  
    ilib_SObjectDomain.triggerHandler(ContentDocuments.class);
}