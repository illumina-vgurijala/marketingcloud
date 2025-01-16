/**
 * Agreement Condition Mapping Selector
 */
public with sharing class AgreementConditionMappingSelector extends ilib_SObjectSelector{
    /**
    *  @author Satya Swain
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the meta data
    **/
    public Schema.SObjectType getSObjectType()
    {
       return Agreement_Condition_Table_Type_Mapping__mdt.sObjectType;
    }
    /**
     *  @author Satya Swain
     *  @description Retrieve list of fields for Custom Metadata  
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Agreement_Condition_Table_Type_Mapping__mdt.id,
            Agreement_Condition_Table_Type_Mapping__mdt.DeveloperName,
            Agreement_Condition_Table_Type_Mapping__mdt.MasterLabel,
            Agreement_Condition_Table_Type_Mapping__mdt.Condition_Table__c,
            Agreement_Condition_Table_Type_Mapping__mdt.Condition_Type__c,
            Agreement_Condition_Table_Type_Mapping__mdt.Discount_Type__c,
            Agreement_Condition_Table_Type_Mapping__mdt.Has_Error__c,
            Agreement_Condition_Table_Type_Mapping__mdt.Subtype__c,//DCP-43353
            Agreement_Condition_Table_Type_Mapping__mdt.Line_Type__c,
            Agreement_Condition_Table_Type_Mapping__mdt.Record_Type__c
        };
    }

    /*
     * Method to get Agreement Condition Mapping
     */
    public List<Agreement_Condition_Table_Type_Mapping__mdt> getAgreementConditionMapping(Set<String> setLineType, Set<String> setDiscountType){
        if(setLineType.isEmpty() || setDiscountType.isEmpty()) {
            return new List<Agreement_Condition_Table_Type_Mapping__mdt>();
        }
        ilib_QueryFactory query = newQueryFactory();
        query.setCondition('Line_Type__c IN :setLineType AND Discount_Type__c IN :setDiscountType');            
        system.debug('@@@@ Query inside getAgreementConditionMapping method: -> '+query.toSOQL());
        return (List<Agreement_Condition_Table_Type_Mapping__mdt>) Database.query(query.toSOQL());
    }
}