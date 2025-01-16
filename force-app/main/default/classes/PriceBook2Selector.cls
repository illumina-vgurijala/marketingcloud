/**
 *    @author Jitesh Lakhwani
 *    @date   2022-Sept-07
 *    @description    Class to get the Price Book records based on different conditions
 *    @Test Class coverage for atleast 90%.
 *      - TestPricingDataReceiver
 *    @Test Class coverage for at least 75% 
 *      - TestPricingDataReceiver
 *    Modification Log:
 *   ---------------------------------------------------------------------------------------------------------------------------
 *    Developer                    Date                 Description
 *    Jitesh Lakhwani             07-Nov-2022         initial class creation 
 */
public with sharing class PriceBook2Selector extends ilib_SObjectSelector{
    
    private static final String LOG_TITLE = 'PriceBook2';
    public static final String SALES_QUERYLOGS = 'SalesQueryLogs';

    /**
    *  @author Jitesh Lakhwani
    *  @description
    *  @return SObjectType The Schema.SObjectType of the PriceBook2
    **/
    public Schema.SObjectType getSObjectType()
    {
       return Pricebook2.sObjectType;
    }

    /**
     *  @author  Jitesh Lakhwani
     *  @description Retrieve list of fields for PriceBook2 sObject
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {

            Pricebook2.Id,
            Pricebook2.IsActive,
            Pricebook2.IsStandard
        };
    }

    /**
    *  @author Jitesh Lakhwani
    *  @description fetch Standard PriceBook2 
    *  @param : none
    *  @return list of Price Book records
    **/
    public List<Pricebook2> selectByStandardPriceBook()
    {
        ilib_LogQuery logger;
        if (Feature.isOn(SALES_QUERYLOGS)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectByStandardPriceBook'
        );

        List<Pricebook2> res = (List<Pricebook2>) Database.query( 
        newQueryFactory()
       .setCondition('IsActive = true AND IsStandard = true')
       .toSOQL()
       );
        if (Feature.isOn(SALES_QUERYLOGS)) logger.stop(res.size());
        return res;
    }
}
