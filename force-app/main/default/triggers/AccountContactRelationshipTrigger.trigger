/**
*    @author Saddam
*    @date   2022-02-22
*    @description    PM-33 - Created ACR-TRIGGER to update Account record based on ACR records
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Saddam                        2022-feb-22         Created ACR-TRIGGER to update Account record based on ACR records
*    ------------------------------------------------------------------------------------ 
*                    
*/
trigger AccountContactRelationshipTrigger on AccountContactRelation (after update,after insert) {
    ilib_SObjectDomain.triggerHandler(AccountContactRelationships.class);
}