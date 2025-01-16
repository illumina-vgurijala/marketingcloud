/**
*    @author Rishab Wali
*    @date   22nd Feb 2021
*    @description    Class to get the Custom Metadata records for CLM Preferred Language to Template 
*    Modification Log:
*   ------------------------------------------------------------------------------------------------
*    Developer                      Date                		Description
*    Rishab Wali                    22nd Feb 2021               Initial Version
*    -----------------------------------------------------------------------------------------------
*/
public with sharing class CLMPreferredLanguageToTemplatesSelector extends ilib_SObjectSelector{
    /* getSObjectType method*/
    public Schema.SObjectType getSObjectType()
    {
        return CLM_Preferred_Language_To_Template__mdt.sObjectType;
    } 

/**
*  @author - Rishab Wali
*  @description - Retrieve list of fields for CLM Preferred Language to Template Metadata type 
*  @return - sObjectFieldList list of Schema.SObjectField
**/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            CLM_Preferred_Language_To_Template__mdt.DeveloperName,
            CLM_Preferred_Language_To_Template__mdt.Record_Type_Name__c,
            CLM_Preferred_Language_To_Template__mdt.Supported_Languages__c
        };
    }

/**
*  @author Rishab Wali
*  @description Fetch CLM Preferred Language To Template records
*  @return list of CLM Preferred Language to Template records
**/
    public List<CLM_Preferred_Language_To_Template__mdt> selectAllRecords(){
        return (List<CLM_Preferred_Language_To_Template__mdt>) Database.query(
            newQueryFactory().toSOQL()
        );
    }
}