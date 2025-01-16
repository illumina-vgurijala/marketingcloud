/**
*    @author Vandana Kuncham
*    @date   2024-05-28
*    @description    DGP-322: Discount Guidance Selector class   
*/

public without sharing class DiscountGuidanceSelector extends ilib_SObjectSelector {
    
    private static final string LOG_TITLE = 'DiscountGuidanceSelector';
    private static final string SALES_QUERY_LOGS = 'SalesQueryLogs';
    
    private static final String COUNTRY = Label.UI_Label_Country;
    private static final String PRICE_LIST_TYPE = Label.Price_List_Type;
    private static final String TIER_TYPE_SPEND = Label.TierTypeSpend;
    private static final String TIER_TYPE_CREDIT = Label.TierTypeCredit;
    
    private Set<String> channelSet;
    private Set<String> priceListTypeSet;
    private Set<String> discountGridGroupSet;
    private Set<String> billingCountryCodeSet;
    private Set<String> primaryCustomerTypeSet;
    private Set<Decimal> customerSpendSet;
    private Set<Decimal> instrumentCreditSet;
    private Set<Date> dateValueSet;
    private Set<String> currencyIsoCodeSet;
    
    /**
     * To get sObject Type.
     * @return Schema.SObjectType
     **/
    public Schema.SObjectType getSObjectType() {
        return Discount_Guidance__c.sObjectType;
    }
    
    /**
     * To retrieve list of fields of Discount Guidance.
     * @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList() {
        
        return new List<Schema.SObjectField> {
            Discount_Guidance__c.Id,
            Discount_Guidance__c.Name,
            Discount_Guidance__c.Channel__c,
            Discount_Guidance__c.Country__c,
            Discount_Guidance__c.Price_List_Type__c,
            Discount_Guidance__c.Discount_Grid_Group__c,
            Discount_Guidance__c.Primary_Customer_Type__c,
            Discount_Guidance__c.Discount_Guidance_Level__c,
            Discount_Guidance__c.Tier_Min__c,
            Discount_Guidance__c.Tier_Max__c,
            Discount_Guidance__c.Tier_Type__c,
            Discount_Guidance__c.End_Date__c,
            Discount_Guidance__c.Start_Date__c,
            Discount_Guidance__c.Max_Discount__c,
            Discount_Guidance__c.Median_Discount__c,
            Discount_Guidance__c.Customer_Discount_Tier__c
        };
    }
    
    
    /** 
    * @author Vandana Kuncham
    * @description Fetch Discount Guidance records matching specified criteria
    
    * This method is not using the Query Factory at this time as it did not work well with INCLUDES keyword for multiselect picklist field Country__c
    
    * @param countryString String of unique Country values
    * @param pricelistTypeSet Set of unique PricelistType values
    * @param channelSet Set of unique channel values
    * @param currencyCodeSet Set of unique currency code values
    * @param discountTierSet Set of unique discount tier values
    * @param customerTypeSet Set of unique customer type values
    * @param discountGridGroupSet Set of unique discount grid group values
    * @param medianDiscountSet Set of unique median discount values
    * @param maxDiscountSet Set of unique maximum discount values
    * @param discountRecordIds Ids of records being modified/created
    * @return List of Discount_Guidance__c records
    *
    */
    public List<Discount_Guidance__c> selectDiscountGuidanceRecords(String countryString, Set<String> pricelistTypeSet, Set<String> channelSet, Set<String> currencyCodeSet, Set<String> discountTierSet, Set<String> customerTypeSet, Set<String> discountGridGroupSet, Set<Id> discountRecordIds) {
        ilib_LogQuery logger=null;

        if(Feature.isOn(SALES_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectDiscountGuidanceRecords');
        }

        ilib_QueryFactory query = newQueryFactory()
        .selectFields(getSObjectFieldList())
        .setCondition('Channel__c IN :channelSet AND ' +
                        'Discount_Grid_Group__c IN :discountGridGroupSet AND ' +
                        'Primary_Customer_Type__c IN :customerTypeSet AND ' +
                        'CurrencyISOCode IN :currencyCodeSet AND ' + 
                        'Customer_Discount_Tier__c IN :discountTierSet AND ' +
                        'Id Not IN :discountRecordIds AND ' +
                        '((Discount_Guidance_Level__c = \'' + COUNTRY + '\' AND Country__c INCLUDES ' + countryString + ' AND Price_List_Type__c = null) OR ' +
                        ' (Discount_Guidance_Level__c = \'' + PRICE_LIST_TYPE + '\' AND Country__c = null AND Price_List_Type__c IN :priceListTypeSet))  AND  ' +
                        'Is_Active__c = true');
        List<Discount_Guidance__c> res = Database.query(query.toSOQL());
        
        if(Feature.isOn(SALES_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }
    
    
    /**
     * DGP-42 & DGP-103
     * 
     * Method to fetch Discount Guidance records based on Channel, Price List Type, Discount Grid Group, Billing Country Code,
     * Primary Customer Type, Customer Historical Spend, Instrument Credit and Agreement Line Item Start Date.
     * 
     * These values have to be added in respective Set variables in class.
     **/ 
    public List<Discount_Guidance__c> fetchDiscountGuidanceRecordsForLineItems() {
        
        ilib_LogQuery logger;
        
        if(Feature.isOn(SALES_QUERY_LOGS)) logger = new ilib_LogQuery(
            LOG_TITLE + '.fetchDiscountGuidanceRecordsForLineItems'
        );
        
        String countryStr = '(\'' + String.join(new List<String>(billingCountryCodeSet), '\', \'') + '\')';
        
        ilib_QueryFactory query = newQueryFactory();
		query.getOrderings().clear();
        query.setCondition('Channel__c IN :channelSet  AND  ' +
                          'Discount_Grid_Group__c IN :discountGridGroupSet  AND  ' +
                          'Primary_Customer_Type__c IN :primaryCustomerTypeSet  AND  ' +
                          '((Tier_Type__c = \'' + TIER_TYPE_SPEND + '\' AND Tier_Min__c <= :customerSpendSet AND Tier_Max__c >= :customerSpendSet AND CurrencyIsoCode IN :currencyIsoCodeSet) OR ' +
                          ' (Tier_Type__c = \'' + TIER_TYPE_CREDIT +'\' AND Tier_Min__c <= :instrumentCreditSet AND Tier_Max__c >= :instrumentCreditSet))  AND  ' +
                          '((Discount_Guidance_Level__c = \'' + COUNTRY + '\' AND Country__c INCLUDES ' + countryStr + ' AND Price_List_Type__c = null) OR ' +
                          ' (Discount_Guidance_Level__c = \'' + PRICE_LIST_TYPE + '\' AND Country__c = null AND Price_List_Type__c IN :priceListTypeSet))  AND  ' +
                          'Start_Date__c <= :dateValueSet  AND  ' +
                          'End_Date__c >= :dateValueSet  AND  ' +
                          'Is_Active__c = true')
            .addOrdering('LastModifiedDate', ilib_QueryFactory.SortOrder.DESCENDING);
        
        List<Discount_Guidance__c> res = (List<Discount_Guidance__c>) Database.query(query.toSOQL());
        
        if (Feature.isOn(SALES_QUERY_LOGS)) logger.stop(res.size());
        
        return res;
    }
    
    
    /**
     * To add Channel to set.
     **/
    public void addChannelToSet(String channel) {
        if(this.channelSet == null) {
            this.channelSet = new Set<String>();
        }
        this.channelSet.add(channel);
    }
    
    /**
     * To add Price List Type to set.
     **/
    public void addPriceListTypeToSet(String priceListType) {
        if(this.priceListTypeSet == null) {
            this.priceListTypeSet = new Set<String>();
        }
        this.priceListTypeSet.add(priceListType);
    }
    
    /**
     * To add Discount Grid Group to set.
     **/
    public void addDiscountGridGroupToSet(String discountGridGroup) {
        if(this.discountGridGroupSet == null) {
            this.discountGridGroupSet = new Set<String>();
        }
        this.discountGridGroupSet.add(discountGridGroup);
    }
    
    /**
     * To add given set of Discount Grid Groups to set.
     **/
    public void addAllDiscountGridGroupToSet(Set<String> discountGridGroupSet) {
        if(this.discountGridGroupSet == null) {
            this.discountGridGroupSet = new Set<String>();
        }
        this.discountGridGroupSet.addAll(discountGridGroupSet);
    }
    
    /**
     * To add Billing Country Code to set.
     **/
    public void addBillingCountryCodeToSet(String billingCountryCode) {
        if(this.billingCountryCodeSet == null) {
            this.billingCountryCodeSet = new Set<String>();
        }
        this.billingCountryCodeSet.add(billingCountryCode);
    }
    
    /**
     * To add Primary Customer Type to set.
     **/
    public void addPrimaryCustomerTypeToSet(String primaryCustomerType) {
        if(this.primaryCustomerTypeSet == null) {
            this.primaryCustomerTypeSet = new Set<String>();
        }
        this.primaryCustomerTypeSet.add(primaryCustomerType);
    }
    
    /**
     * To add Customer Historical Spend to set.
     **/
    public void addCustomerSpendToSet(Decimal customerSpend) {
        if(this.customerSpendSet == null) {
            this.customerSpendSet = new Set<Decimal>();
        }
        this.customerSpendSet.add(customerSpend);
    }
    
    /**
     * To add Instrument Credit to set.
     **/
    public void addInstrumentCreditToSet(Decimal instrumentCredit) {
        if(this.instrumentCreditSet == null) {
            this.instrumentCreditSet = new Set<Decimal>();
        }
        this.instrumentCreditSet.add(instrumentCredit);
    }
    
    /**
     * To add Date Value to set.
     **/
    public void addDateValueToSet(Date dateValue) {
        if(this.dateValueSet == null) {
            this.dateValueSet = new Set<Date>();
        }
        this.dateValueSet.add(dateValue);
    }

    /**
     * To add Currency ISO code to set.
     **/
    public void addCurrencyIsoCodeToSet(String currencyIsoCode) {
        if(this.currencyIsoCodeSet == null) {
            this.currencyIsoCodeSet = new Set<String>();
        }
        this.currencyIsoCodeSet.add(currencyIsoCode);
    }
}