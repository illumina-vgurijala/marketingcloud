/**
*    @author: Pankaj Singla
*    @date:   08-Sept-2020
*    @description:  Selector Class for Apttus_Config2__Incentive__c
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla              08 Sept 2020           Initial Build
              
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class IncentiveSelector extends ilib_SObjectSelector{
	/**
    *  @author Pankaj Singla
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the proposal
    **/	
     public Schema.SObjectType getSObjectType(){
        return Apttus_Config2__Incentive__c.sObjectType;
     }
     
    /**
     *  @author  Pankaj Singla
     *  @description Retrieve list of fields for Apttus_Config2__Incentive__c
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
      public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField>{
            Apttus_Config2__Incentive__c.Id,
            Apttus_Config2__Incentive__c.Apttus_Config2__Active__c,
            Apttus_Config2__Incentive__c.Approval_Required__c,
            Apttus_Config2__Incentive__c.Approver__c,
            Apttus_Config2__Incentive__c.Change_History__c,
            Apttus_Config2__Incentive__c.Country__c,
            Apttus_Config2__Incentive__c.Customer_Description__c,
            Apttus_Config2__Incentive__c.Distribution_Channel__c,
            Apttus_Config2__Incentive__c.Distribution_Channel_Description__c,
            Apttus_Config2__Incentive__c.Distribution_Channel_Description__c,
            Apttus_Config2__Incentive__c.Apttus_Config2__ExpirationDate__c,
            Apttus_Config2__Incentive__c.Limit_View__c,
            Apttus_Config2__Incentive__c.Apttus_Config2__Description__c,
            Apttus_Config2__Incentive__c.Primary_Product_Line__c,
            Apttus_Config2__Incentive__c.Promotion_Channel_Description__c,
            Apttus_Config2__Incentive__c.Promo_Channel__c,
            Apttus_Config2__Incentive__c.Apttus_Config2__IncentiveCode__c,
            Apttus_Config2__Incentive__c.Name,
            Apttus_Config2__Incentive__c.Promotion_Details__c,
            Apttus_Config2__Incentive__c.Promotion_Owner__c,
            Apttus_Config2__Incentive__c.Regions__c,
            Apttus_Config2__Incentive__c.Sales_Org__c,
            Apttus_Config2__Incentive__c.Sales_Description__c,
            Apttus_Config2__Incentive__c.Stackable__c,
            Apttus_Config2__Incentive__c.Promotion_Terms_and_Conditions__c,
            Apttus_Config2__Incentive__c.Master_Promotions__c
        
        };
      }
     /**
     *  @author Pankaj Singla
     *  @description Fetch the Incentive Records
     *  @param setPromotionIds- Set of promotion Ids
     *  @return List of Incentive Records
     **/ 
      public List<Apttus_Config2__Incentive__c> selectIncentiveList(Set<Id> setPromotionIds) {
            return (List<Apttus_Config2__Incentive__c>) Database.query(
                newQueryFactory().setCondition('Master_Promotions__c IN :setPromotionIds').toSOQL()
                
            );
      }

}