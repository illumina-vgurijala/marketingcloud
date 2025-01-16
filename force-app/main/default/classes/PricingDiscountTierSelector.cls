/**
 *    @author Khushbu Vasani
 *    @date   2022-06-15
 *    @description  Pricing Discount Tier queries
 *    Modification Log:
 *    --------------------------------------------------------------------------------------------------------------------
 *    Developer                    Date               Description
 *    Khushbu Vasani               15 June-2022        Initial Version
 *    SADDAM                       10-Aug-2022         DCP-55553 created new method getPricingTierBasedOnCustomerTier() to get PDT from set of tiers from ADT.
 *    Vivek                        08-Sep-2022         DCP-55537 modified the query filter criteria for the methods getPricingTierBasedOnTier() & getPricingTierBasedOnCustomerTier()
 */
 
public with sharing class PricingDiscountTierSelector extends ilib_SObjectSelector{
    private static final String LOG_TITLE = 'PricingDiscountTierSelector';
    private static final String FEATURE_SALES_QUERY_LOGS = 'SalesQueryLogs';//DCP-52708

     /**
    *  @author Khushbu Vasani
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the Line Items
    **/
    public Schema.SObjectType getSObjectType()
    {
       return Pricing_Discount_Tier__c.sObjectType;
    }
    /**
     *  @author Khushbu Vasani
     *  @description Retrieve list of fields for Line Item sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Pricing_Discount_Tier__c.id,
            Pricing_Discount_Tier__c.Discount_Tier__c,
            Pricing_Discount_Tier__c.UG_Discount_Type__c,
            Pricing_Discount_Tier__c.Discount_Value__c,
            Pricing_Discount_Tier__c.Valid_From__c,
            Pricing_Discount_Tier__c.Valid_To__c,
            Pricing_Discount_Tier__c.Open_Offer_Product_Category__c,
            Pricing_Discount_Tier__c.Minimum_Value__c,
            Pricing_Discount_Tier__c.Maximum_Value__c
        };
    }

    /**
     *  @author Khushbu Vasani
     *  @description Retrieve fields for PricingDiscountTier sObject 
     *  @return PricingDiscountTier
     **/
    public List<Pricing_Discount_Tier__c> getPricingTierBasedOnTier(Set<Decimal> setTier, Datetime pricingDate)
    {
        ilib_LogQuery logger = null;
        if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.getPricingTierBasedOnTier',UtilsCollection.serializeIds(setTier));
        }
        
        List<Pricing_Discount_Tier__c> res = (List<Pricing_Discount_Tier__c>)Database.query(newQueryFactory()
        .setCondition('Discount_Tier__c IN: setTier AND (Valid_From__c <= :pricingDate AND Valid_To__c >= :pricingDate) AND IsActive__c= true').toSOQL());

        if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
            logger.stop(res.size());
          }

        return res;
    }
    /**
     *  @author saddam
     *  @description Retrieve fields for PricingDiscountTier sObject DCP-55553
     *  @return set of PricingDiscountTier
     **/
    public List<Pricing_Discount_Tier__c> getPricingTierBasedOnCustomerTier(Set<Decimal> setTier) {
        ilib_LogQuery logger = null;
        if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.getPricingTierBasedOnCustomerTier',UtilsCollection.serializeIds(setTier));
        }
        
        List<Pricing_Discount_Tier__c> res = (List<Pricing_Discount_Tier__c>)Database.query(newQueryFactory()
        .setCondition('Discount_Tier__c IN: setTier AND IsActive__c= true').toSOQL());

        if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
            logger.stop(res.size());
          }

        return res;
    }
}