/**
*    Author - Anshaj
*    date - 5/20/2022
*    Description - Class to get the ILMN Debug Log Records 
*    Modification Log:
*   ------------------------------------------------------------------------------------------------
*    Developer                      Date                		Description
*    -----------------------------------------------------------------------------------------------
*/
public with sharing class ILMNDebugLogSelector extends ilib_SObjectSelector {
    /**
     * @author - Anshaj
     * date - 5/20/2022
     * Description - to return sobject type
     */
    public Schema.SObjectType getSObjectType()
    {
        return ILMN_Debug_Log__c.sObjectType;
    }
    /**    
*    @Author - Anshaj      
*    date - 5/20/2022  
*    @description    Get the list of fields
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description	 
*/
   
public List<Schema.SObjectField> getSObjectFieldList()
{
    return new List<Schema.SObjectField> {
        ILMN_Debug_Log__c.Id,
        ILMN_Debug_Log__c.CreatedById,
        ILMN_Debug_Log__c.CPU__c,
        ILMN_Debug_Log__c.OwnerId,
        ILMN_Debug_Log__c.Data__c,
        ILMN_Debug_Log__c.Name,
        ILMN_Debug_Log__c.Org_Id__c,
        ILMN_Debug_Log__c.Transaction_Id__c,
        ILMN_Debug_Log__c.Data_Length__c,
        ILMN_Debug_Log__c.DML__c,
        ILMN_Debug_Log__c.Elapsed_Time__c,
        ILMN_Debug_Log__c.Limits__c,
        ILMN_Debug_Log__c.User__c,
        ILMN_Debug_Log__c.Log_Categorization__c,
        ILMN_Debug_Log__c.Parent_Log__c,
        ILMN_Debug_Log__c.RecordTypeId,
        ILMN_Debug_Log__c.SOQL__c,
        ILMN_Debug_Log__c.SystemModstamp,
        ILMN_Debug_Log__c.Title__c,
        ILMN_Debug_Log__c.Workstream__c,
        ILMN_Debug_Log__c.Link_Key__c
    };
}
/**    
*    @Author - Anshaj 
*    date - 5/20/2022      
*    @description    Get the SOQL Query
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description	 
*/
public List<ILMN_Debug_Log__c> selectIlmnDebugLogsByTid(List<String> tid,List<String> linkKeyList){


    List<ILMN_Debug_Log__c> ilmnLog = (List<ILMN_Debug_Log__c>) Database.query(
    newQueryFactory()
    .selectField('Id')
    .selectField('Transaction_Id__c')
    .selectField('Parent_Log__c')
    .selectField('RecordTypeId')
    .selectField('Title__c')
    .selectField('Link_Key__c')
    .selectField('CPU__c')
    .setCondition('Transaction_Id__c IN :tid and (recordtype.developername = \'Pop_Parent\' OR (recordtype.developername = \'Emit\' and Log_Categorization__c != \'Soql\' ) ) and Link_Key__c IN : linkKeyList')
    .toSOQL()
    );
    System.debug('@@@@ value of ILMN Debug Log query result: '+ilmnLog);
    return ilmnLog; 
}
}