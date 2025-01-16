/**
*    @author: Pankaj Singla
*    @date:   08-Sept-2020
*    @description:  Selector Class for Promotion_To_Incentive_Mapping__mdt
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla              08 Sept 2020           Initial Build
              
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class PromotionToIncentiveMDTSelector extends ilib_SObjectSelector {
    /**
    *  @author Pankaj Singla
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the proposal
    **/
    public Schema.SObjectType getSObjectType() {
        return Promotion_To_Incentive_Mapping__mdt.sObjectType;
    }  
    /**
     *  @author  Pankaj Singla
     *  @description Retrieve list of fields for Custom Metadata-Promotion_To_Incentive_Mapping__mdt
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
           Promotion_To_Incentive_Mapping__mdt.Incentive_Field_Name__c,
           Promotion_To_Incentive_Mapping__mdt.IsActive__c,
           Promotion_To_Incentive_Mapping__mdt.Promotion_Field_Name__c
           
       };
    }
    
    /**
     *  @author Pankaj Singla
     *  @description Fetch the active Records of the custom metadata
     *  @param None
     *  @return List of Active Custom Metadata Records
     **/
    
    public List<Promotion_To_Incentive_Mapping__mdt> selectActiveRecords(){
        return (List<Promotion_To_Incentive_Mapping__mdt>) Database.query(
        	 newQueryFactory().setCondition('IsActive__c=true').toSOQL()
        );
    }
    
}