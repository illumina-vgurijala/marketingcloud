/**
*    @author Tapas
*    @date   2018-05-25
*    @description    DCP-1010,598: Opportunity Selector class
*    Modification Log:
*    ----------------------------------------------------------------------------------------------------------------------
*     Developer                      Date                Description
*     Tapas                          21-Sep-2020         Opportunity Selector Class
*
*/
public with sharing class StandingQuoteOpportunityProductsSelector extends ilib_SObjectSelector{
    /**
*  @author  Tapas
*  @description Retrieve list of fields for Standing_Quote_Opportunity_Product__c sObject 
*  @return sObjectFieldList list of Schema.SObjectField
**/
    public Schema.SObjectType getSObjectType(){
        return Standing_Quote_Opportunity_Product__c.sObjectType;
    }
    
    /**
*  @author  Tapas
*  @description Retrieve list of fields for Standing_Quote_Opportunity_Product__c sObject 
*  @return sObjectFieldList list of Schema.SObjectField
**/
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
        return new List<Schema.SObjectField> 
        {
            Standing_Quote_Opportunity_Product__c.id,
			Standing_Quote_Opportunity_Product__c.Name,
			Standing_Quote_Opportunity_Product__c.Material_Group__c,
			Standing_Quote_Opportunity_Product__c.Material_Group_Description__c,
			Standing_Quote_Opportunity_Product__c.Opportunity__c,
			Standing_Quote_Opportunity_Product__c.Line_Type__c,
			Standing_Quote_Opportunity_Product__c.Forecast_Amount__c,
            Standing_Quote_Opportunity_Product__c.Material_Name__c,
            Standing_Quote_Opportunity_Product__c.Material_Number__c
                
		};
	}
    /**
*  @author  Tapas
*  @description Retrieve list of SQ opportunity Products whose parent opp ids are given 
*  @param Set<Id> Opportunities
*  @return List of Standing_Quote_Opportunity_Product__c 
**/
    public List<Standing_Quote_Opportunity_Product__c> selectSQProductsByOpportunityIds(Set<ID> setOppIds)
    { 
        return (List<Standing_Quote_Opportunity_Product__c>) Database.query(
            newQueryFactory()
            .setCondition('Opportunity__c  IN : setOppIds')
            .toSOQL()
        );   
    } 
}