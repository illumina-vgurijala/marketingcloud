/**
*    @author Rishi Sharma
*    @date   4th June 2021
*    @description    Class to get the Custom Metadata records for Tender Region to Email mapping 
*    Modification Log:
*   ------------------------------------------------------------------------------------------------
*    Developer                      Date                		Description
*    Rishi Sharma                   4th June 2021              Initial Version
*    -----------------------------------------------------------------------------------------------
*/
public with sharing class TenderRegiontoEmailSelector extends ilib_SObjectSelector{
    /* getSObjectType method*/
    public Schema.SObjectType getSObjectType()
    {
        return Region_to_Email_Mapping__mdt.sObjectType;
    } 

/**
*  @author - Rishi Sharma
*  @description - Retrieve list of fields for Region to Email Metadata 
*  @return - sObjectFieldList list of Schema.SObjectField
**/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Region_to_Email_Mapping__mdt.Region__c,
            Region_to_Email_Mapping__mdt.Email__c,
            Region_to_Email_Mapping__mdt.ToAddress__c,
            Region_to_Email_Mapping__mdt.CcAddress__c
       };
    }

/**
*  @author Rishi Sharma
*  @description Fetch Region to Email mapping metadata records
*  @return list of Region to Email mapping metadata records
**/
    public List<Region_to_Email_Mapping__mdt> selectAllRecords(){
        return (List<Region_to_Email_Mapping__mdt>) Database.query(
            newQueryFactory().toSOQL()
        );
    }

    /**
    *  @author Dushyant Srivastava
    *  @description Fetch Email To Address According to region
    *  @return list of Region to Email mapping metadata records
    **/
    public List<Region_to_Email_Mapping__mdt> selectAllRecords(Set<String>strCondition){
        return (List<Region_to_Email_Mapping__mdt>) Database.query(
            newQueryFactory()
            .selectField('ToAddress__c')
            .selectField('CcAddress__c')
            .selectField('MasterLabel')
            .setCondition('MasterLabel Like: strCondition')
            .toSOQL()
        );
    }
}