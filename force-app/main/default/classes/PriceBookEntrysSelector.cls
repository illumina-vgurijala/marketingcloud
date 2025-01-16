/**
 *    @author Jitesh Lakhwani
 *    @date   2022-Sept-07
 *    @description    Class to get the Price Book Entry records based on different conditions
 *    @Test Class coverage for atleast 90%.      
 *      - TestOpportunityLineItems
 *      - TestPricingDataReceiver
 *    @Test Class coverage for at least 75% 
 *      - TestOpportunityLineItems
 *      - TestPricingDataReceiver
 *    Modification Log:
 *   ---------------------------------------------------------------------------------------------------------------------------
 *    Developer                    Date                 Description
 *    Jitesh Lakhwani             4 Nov 2022           Added new method to fetch price book entries based on product Ids
 */

public with sharing class PriceBookEntrysSelector extends ilib_SObjectSelector {
    
    private static final String LOG_TITLE = 'PricebookEntry';
    public static final String SALES_QUERYLOGS = 'SalesQueryLogs';

    /**
    *  @author Jitesh Lakhwani
    *  @description
    *  @return SObjectType The Schema.SObjectType of the Price Book Entries
    **/
    public Schema.SObjectType getSObjectType()
    {
       return PricebookEntry.sObjectType;
    }

    /**
     *  @author  Jitesh Lakhwani
     *  @description Retrieve list of fields for Price Book Entries sObject
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {

            PricebookEntry.Id,
            PricebookEntry.IsActive,
            PricebookEntry.CurrencyIsoCode,
            PricebookEntry.ProductCode,
            PricebookEntry.Product2Id,
            PricebookEntry.UnitPrice
        };
    }

    /**
    *  @author Jitesh Lakhwani
    *  @description fetch Price Book Entries for the product code set passed in the argument
    *  @param productCodeSet set of Product Code
    *  @return list of Price Book Entry records
    **/
    public List<PricebookEntry> selectByProductCode(Set<String> productCodeSet)
    {
        ilib_LogQuery logger;
        if (Feature.isOn(SALES_QUERYLOGS)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectById',
            UtilsCollection.serializeIds(productCodeSet)
        );

        List<PricebookEntry> res = (List<PricebookEntry>) Database.query( 
        newQueryFactory()

       .setCondition('IsActive = true AND ProductCode IN :productCodeSet')
       .toSOQL()
       );
        if (Feature.isOn(SALES_QUERYLOGS)) logger.stop(res.size());
        return res;
    }
}