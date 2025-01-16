/********************
 * Author : Shalin Shah
 * Date : 11-Jun-2024
 * Description : Class to query records on Customer Historical Spend object.
 ********************/

public without sharing class CustomerHistoricalSpendSelector extends ilib_SObjectSelector {
    
    private static final String LOG_TITLE = 'CustomerHistoricalSpendSelector';
    public static final string STRING_SALES_QUERY_LOG = 'SalesQueryLogs';
    public static final String FREQUENCY_FOR_DISCOUNT_GUIDANCE = 'Frequency_For_Discount_Guidance';
    public static final String FREQUENCY = Code_Parameter__mdt.getInstance(FREQUENCY_FOR_DISCOUNT_GUIDANCE).Values_Text__c;
    
    
    /**
     * To get sObject Type.
     * @return Schema.SObjectType
     **/
    public Schema.SObjectType getSObjectType() {
        return Customer_Historical_Spend__c.sObjectType;
    }
    
    /**
     * To retrieve list of fields of Customer Historical Spend.
     * @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList() {
        
        return new List<Schema.SObjectField> {
            Customer_Historical_Spend__c.Id,
            Customer_Historical_Spend__c.ERP_ID__c,
            Customer_Historical_Spend__c.Frequency__c,
            Customer_Historical_Spend__c.Valid_To_Date__c,
            Customer_Historical_Spend__c.Valid_From_Date__c,
            Customer_Historical_Spend__c.Fiscal_End_Date__c,
            Customer_Historical_Spend__c.Fiscal_Start_Date__c,
            Customer_Historical_Spend__c.Primary_Customer_Type__c,
            Customer_Historical_Spend__c.Customer_Historic_Spend__c,
            Customer_Historical_Spend__c.Total_Instrument_Credits__c
        };
    }
    
    /**
     * Method to fetch Customer Historical Spend records for given set of National Group Numbers (ERP IDs).
     **/
    public List<Customer_Historical_Spend__c> fetchCustomerHistoricalSpendRecords(Set<String> nationalGroupNumberSet) {
        
        ilib_LogQuery logger;
        if (Feature.isOn(STRING_SALES_QUERY_LOG)) logger = new ilib_LogQuery(
            LOG_TITLE + '.fetchCustomerHistoricalSpendRecords',
            UtilsCollection.serializeIds(nationalGroupNumberSet)
        );
        
        ilib_QueryFactory query = newQueryFactory();
        query.getOrderings().clear();
        query.setCondition('ERP_ID__c IN :nationalGroupNumberSet AND Valid_From_Date__c <= TODAY AND Valid_To_Date__c >= TODAY AND Frequency__c = :FREQUENCY');
        query.addOrdering('LastModifiedDate', ilib_QueryFactory.SortOrder.DESCENDING);
        
        List<Customer_Historical_Spend__c> res = (List<Customer_Historical_Spend__c>) Database.query(query.toSOQL());
        
        if (Feature.isOn(STRING_SALES_QUERY_LOG)) logger.stop(res.size());
        return res;
    }
}