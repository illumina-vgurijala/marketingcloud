/**
*    Author - Anshaj
*    Description - Class to get the Queueable Log REcords 
*    Modification Log:
*   ------------------------------------------------------------------------------------------------
*    Developer                      Date                		Description
*    -----------------------------------------------------------------------------------------------
*/
public with sharing class QueueableLogSelector extends ilib_SObjectSelector {
    /**
*    Author - Anshaj
*    Description - Class to return ObjectType
*/
    public Schema.SObjectType getSObjectType()
    {
        return Queueable_Log__c.sObjectType;
    }
/**    
*    @date  21-04-2022        
*    @description    Get the list of fields
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description	 
*/
   
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Queueable_Log__c.Id,
            Queueable_Log__c.CreatedById,
            Queueable_Log__c.Apex_JobId__c,
            Queueable_Log__c.OwnerId,
            Queueable_Log__c.logIdentifier__c,
            Queueable_Log__c.Name,
            Queueable_Log__c.Org_Id__c,
            Queueable_Log__c.Transaction_Id__c,
            Queueable_Log__c.Workstream__c
        };
    }
/**    
*    @date  21-04-2022        
*    @description    Get the SOQL 
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description	 
*/
    public List<Queueable_Log__c> selectQueueableLogsByIdentifier(String logIdentifier){
        List<Queueable_Log__c> qLog = (List<Queueable_Log__c>) Database.query(
        newQueryFactory()
        .selectField('Id')
        .selectField('Apex_JobId__c')
        .selectField('Interface_Log__c')
        .selectField('logIdentifier__c')
        .selectField('Name')
        .selectField('Org_Id__c')
        .selectField('Transaction_Id__c')
        .selectField('Workstream__c')
        .setCondition('logIdentifier__c = :logIdentifier')
        .toSOQL()
        );
        System.debug('@@@@ value of Queueable Log query result: '+qLog);
        return qLog;
    }
}
