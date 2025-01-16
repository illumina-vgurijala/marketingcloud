/********************
 * Author : Shalin Shah
 * Date : 24-May-2024
 * Description : Class to query records on Customer Historical Discount object.
 ********************/

public without sharing class CustomerHistoricalDiscountSelector extends ilib_SObjectSelector {
    
    private static final String LOG_TITLE = 'CustomerHistoricalDiscountSelector';
    public static final string STRING_SALES_QUERY_LOG = 'SalesQueryLogs';
    public static final String FREQUENCY_FOR_DISCOUNT_GUIDANCE = 'Frequency_For_Discount_Guidance';
    public static final String FREQUENCY = Code_Parameter__mdt.getInstance(FREQUENCY_FOR_DISCOUNT_GUIDANCE).Values_Text__c;
    
    /**
     * To get sObject Type.
     * @return Schema.SObjectType
     **/
    public Schema.SObjectType getSObjectType() {
        return Customer_Historical_Discount__c.sObjectType;
    }
    
    /**
     * To retrieve list of fields of Customer Historical Discount.
     * @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList() {
        
        return new List<Schema.SObjectField> {
            Customer_Historical_Discount__c.Id,
            Customer_Historical_Discount__c.ERP_ID__c,
            Customer_Historical_Discount__c.SKU_MG1__c,
            Customer_Historical_Discount__c.IsActive__c,
            Customer_Historical_Discount__c.Frequency__c,
            Customer_Historical_Discount__c.Valid_From_Date__c,
            Customer_Historical_Discount__c.Historical_Discount__c
        };
    }
    
    /**
     * Method to fetch Customer Historical Discount records for given set of ERP IDs and SKUs/MG1s.
     **/
    public List<Customer_Historical_Discount__c> fetchCustomerHistoricalDiscountRecords(Set<String> erpCustomerIdSet, Set<String> skuOrMG1Set) {
        
        ilib_LogQuery logger;
        if (Feature.isOn(STRING_SALES_QUERY_LOG)) logger = new ilib_LogQuery(
            LOG_TITLE + '.getCustomerHistoricalDiscountRecords',
            (UtilsCollection.serializeIds(erpCustomerIdSet) + ' -- ' + UtilsCollection.serializeIds(skuOrMG1Set))
        );
        
        ilib_QueryFactory query = newQueryFactory();
        query.setCondition('ERP_ID__c IN :erpCustomerIdSet AND SKU_MG1__c IN :skuOrMG1Set AND IsActive__c = TRUE AND Valid_From_Date__c <= TODAY AND Frequency__c = :FREQUENCY');
        //query.addOrdering('Valid_From_Date__c', ilib_QueryFactory.SortOrder.DESCENDING);

        List<Customer_Historical_Discount__c> res = (List<Customer_Historical_Discount__c>) Database.query(query.toSOQL());

        if (Feature.isOn(STRING_SALES_QUERY_LOG)) logger.stop(res.size());
        return res;
    }
    
     /**
     *  @author Saurabh Brahmankar 
     *  @description Order By DESC of Valid From Date field
     *  @return Date
     **/
    public override String getOrderBy() 
    {
        return 'Valid_From_Date__c DESC';
    }
}