/**
 *    @author Khushbu Vasani
 *    @date   2022-06-15
 *    @description  Account Pricing Tier queries
 *    Modification Log:
 *    --------------------------------------------------------------------------------------------------------------------
 *    Developer                    Date               Description
 *    Khushbu Vasani               15 June-2022        Initial Version
 *    Saddam                       17-AUg-2022         created new method getAccntPricingTiersForErpIds() which returns adt records only when TIer is not equal to null.
 *    Parthasarathy D              Septemeberr 2022    Updated the WHERE condition in the methods getAccountPricingForERPIds and getAccntPricingTiersForErpIds to fetch only the active ADT records.
 */
 
public without sharing class AccountDiscountTierSelector extends ilib_SObjectSelector{
    private static final String LOG_TITLE = 'PricingDiscountTierSelector';
    private static final String FEATURE_SALES_QUERY_LOGS = 'SalesQueryLogs';
    private Boolean removeDefaultOrderBy=false;

    /**
   *  @author Khushbu Vasani
   *  @description  
   *  @return SObjectType The Schema.SObjectType of the Line Items
   **/
   public Schema.SObjectType getSObjectType()
   {
      return Account_Discount_Tier__c.sObjectType;
   }
   /**
    *  @author Khushbu Vasani
    *  @description Retrieve list of fields for Line Item sObject 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
   public List<Schema.SObjectField> getSObjectFieldList()
   {
       return new List<Schema.SObjectField> {
          Account_Discount_Tier__c.id,
          Account_Discount_Tier__c.Pricing_Tier__c,
          Account_Discount_Tier__c.Discount_Type__c,
          Account_Discount_Tier__c.ERP_Customer_Id__c,
          Account_Discount_Tier__c.Sales_Area__c,
          Account_Discount_Tier__c.External_Id__c
       };
   }

   /*  
   * @description  Override Default ordering 
   */
   public override String getOrderBy() {
      if(removeDefaultOrderBy)
            return 'ERP_Customer_Id__c ASC';  
      else 
            return super.getOrderBy(); 
   }

   /**
    * @owner Khushbu Vasani
    * @description Get AccountPricing tier data for given For ERPIds
    * @param erpCustomerIds
    */
   public List<Account_Discount_Tier__c> getAccountPricingForERPIds(Set<String> setERPIds) {
      ilib_LogQuery logger = null;
      if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
          logger = new ilib_LogQuery(LOG_TITLE + '.getPricingTierBasedOnTier',UtilsCollection.serializeIds(setERPIds));
      }
      
      List<Account_Discount_Tier__c> res = (List<Account_Discount_Tier__c>)Database.query(newQueryFactory()
        .setCondition('ERP_Customer_Id__c IN :setERPIds AND IsInactive__c = false')
        .toSOQL());


      if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
         logger.stop(res.size());
       }
        
      return res;
   }

   /**
    * @owner Saddam  
    * @description Get AccountPricing tier data for given For ERPIds only when tier is not equal to null
    * @param erpCustomerIds
    */
   public List<Account_Discount_Tier__c> getAccntPricingTiersForErpIds(Set<String> setERPIds) {
      
      ilib_LogQuery logger = null;
      if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
         logger = new ilib_LogQuery(LOG_TITLE + '.getAccntPricingTiersForErpIds',UtilsCollection.serializeIds(setERPIds));
      }
      
      removeDefaultOrderBy = True;
      List<Account_Discount_Tier__c> res = (List<Account_Discount_Tier__c>)Database.query(newQueryFactory()
      .setCondition('ERP_Customer_Id__c IN :setERPIds and Pricing_Tier__c!=Null AND IsInactive__c = false').toSOQL());

      if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
         logger.stop(res.size());
      }
         
      return res;
   }

   /**
    * @owner: Parthasarathy D  
    * @description: Get Account Discount tier data for given ERPIds and Sales Orgs.
    * @param: setERPIds,setSalesOrgs
    */
   public List<Account_Discount_Tier__c> getAccntPricingTiersForErpAndSalesOrgIds(Set<String> setERPIds,Set<String> setSalesOrgs,Set<String> setDistributionChannel) {
      
      ilib_LogQuery logger = null;
       if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
           logger = new ilib_LogQuery(LOG_TITLE + '.getAccntPricingTiersForErpIds',UtilsCollection.serializeIds(setERPIds));
       }
       
       removeDefaultOrderBy = True;
       List<Account_Discount_Tier__c> res = (List<Account_Discount_Tier__c>)Database.query(newQueryFactory()
         .setCondition('ERP_Customer_Id__c IN :setERPIds AND Distribution_Channel__c IN :setDistributionChannel AND Sales_Area__c IN :setSalesOrgs AND IsInactive__c = false').toSOQL());
 
       if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
          logger.stop(res.size());
        }
         
       return res;
    }
}
