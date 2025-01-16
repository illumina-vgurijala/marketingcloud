/**
*    @author: Roopal 
*    @date:   02-Nov-2020
*    @description:  selector class for Approval Priority Combination Metadata
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Roopal                       02-Nov-2020        Selector class for Approval_Priority_Combination__mdt
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class ApprovalPriorityMetadataSelector extends ilib_SObjectSelector {

    /**
     * @Roopal
     * Getting Approval priority combination metadata schema
     */
    public Schema.SObjectType getSObjectType()
    {
        return Approval_Priority_Combination__mdt.sObjectType;
    }
    
    /**
     *  @author  Roopal
     *  @description Retrieve list of fields for Approval Priority Combination Metadata
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Approval_Priority_Combination__mdt.Country_Blank__c,
            Approval_Priority_Combination__mdt.Country_Check__c,
            Approval_Priority_Combination__mdt.Currency_Blank__c,
            Approval_Priority_Combination__mdt.Currency_Check__c,
            Approval_Priority_Combination__mdt.Distribution_Channel_Blank__c,
            Approval_Priority_Combination__mdt.Distribution_Channel_Check__c,
            Approval_Priority_Combination__mdt.Price_List_Type_Check__c,
            Approval_Priority_Combination__mdt.Price_List_Type_Blank__c, 
            Approval_Priority_Combination__mdt.Region_Blank__c,
            Approval_Priority_Combination__mdt.Sales_Org_Blank__c,
            Approval_Priority_Combination__mdt.Sales_Org_Check__c,
            Approval_Priority_Combination__mdt.Value__c,
            Approval_Priority_Combination__mdt.Region_Check__c
        };
    }    
    
    /**
     *  @author  Roopal
     *  @description Fetch the list of all records in Approval_Priority_Combination__mdt
     *      
     **/
     
    public List<Approval_Priority_Combination__mdt> selectAllPriorityCombinations() 
    {
        return (List<Approval_Priority_Combination__mdt>) Database.query(
        newQueryFactory().toSOQL());
    }   
    
    
}