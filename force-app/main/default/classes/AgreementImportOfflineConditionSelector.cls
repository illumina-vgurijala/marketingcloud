/**
 *    @author Joshith K
 *    @date   11-Nov-2020
 *    @description    Selector class for Agreement_Import_Offline_Condition_Table__mdt custom metadata.
 *    Modification Log:
 *   ---------------------------------------------------------------------------------------------------------------------------
 *    Developer                   Date                  Description
 *    Joshith K                   11-Nov-2020           Initial Version
 *  ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class AgreementImportOfflineConditionSelector extends ilib_SObjectSelector {
    /**
    *  @author Joshith k
    *  @description  DCP-43693
    *  @return SObjectType The Schema.SObjectType of the meta data
    **/

    public Schema.SObjectType getSObjectType()
    {
       return Agreement_Import_Offline_Condition_Table__mdt.sObjectType;
    }
    /**
     *  @author Joshith K
     *  @description Retrieve list of fields for Custom Metadata  
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Agreement_Import_Offline_Condition_Table__mdt.id,
            Agreement_Import_Offline_Condition_Table__mdt.DeveloperName,
            Agreement_Import_Offline_Condition_Table__mdt.MasterLabel,
            Agreement_Import_Offline_Condition_Table__mdt.Record_Type__c,
            Agreement_Import_Offline_Condition_Table__mdt.SubType__c,
            Agreement_Import_Offline_Condition_Table__mdt.Update_Category_Status__c
            
        };
    }
     /**
    *  @author Joshith k
    *  @description  method to return metadata records based on record type and subtype.
    *  @return List of the meta data
    **/
    public List<Agreement_Import_Offline_Condition_Table__mdt> getImportOfflineDocumentConditionMapping(String recordType, String subType){
        if(String.isEmpty(recordType) || String.isEmpty(subType))
            return new List<Agreement_Import_Offline_Condition_Table__mdt>();
        ilib_QueryFactory query = newQueryFactory();
        query.setCondition('Record_Type__c=:recordType AND SubType__c =:subType');            
        
        return (List<Agreement_Import_Offline_Condition_Table__mdt>) Database.query(query.toSOQL());
    }
}