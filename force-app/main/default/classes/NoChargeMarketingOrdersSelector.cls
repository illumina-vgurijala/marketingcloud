/**
*    @author: Deep Diwakar
*    @date:   March-08-2023
*    @description:  Selector class for No Charge Marketing Order object
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*           Deep Diwakar                  March-08-2023       DCP-59580: Selector class for No Charge Marketing Order object
*    ------------------------------------------------------------------------------------ 
*                    
*/

public with sharing class NoChargeMarketingOrdersSelector extends ilib_SObjectSelector {

    private static final String LOG_TITLE = 'NoChargeMarketingOrdersSelector';
    private static final String MKTG_FEATURE_FLAG = 'MarketingQueryLogs';

    /**
    *  @author  Deep Diwakar
    *  @description Sets up object type at parent level
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public Schema.SObjectType getSObjectType() {
        return No_Charge_Marketing_Order__c.sObjectType;
    }

    /**
    *  @author  Deep Diwakar
    *  @description Sets up default fields that are returned when any method of this selector is called
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            No_Charge_Marketing_Order__c.Id,
            No_Charge_Marketing_Order__c.Name
        };
    }

    /**
     * @author     : Deep Diwakar
     * @param      : Set of NCMO Ids
     * @return     : List of No_Charge_Marketing_Order__c records
     * @Description: This method returns the list of No_Charge_Marketing_Order__c records based on set of NCMO Ids
    **/
    public List<No_Charge_Marketing_Order__c> selectNcmoById (Set<Id> setNcmoId) {
        ilib_LogQuery logger;

        if (Feature.isOn(MKTG_FEATURE_FLAG)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectNcmoById',UtilsCollection.serializeIds(setNcmoId));
        }

        List<No_Charge_Marketing_Order__c> res = (List<No_Charge_Marketing_Order__c>) Database.query(newQueryFactory()
                                                    .selectField('Open_Offer_Product__c')
                                                    .setCondition('Id IN : setNcmoId')
                                                    .toSOQL());
                                                                                            
        if (Feature.isOn(MKTG_FEATURE_FLAG)){
            logger.stop(res.size());
        }

        return res;

    }

    /**
     * @author     : Deep Diwakar
     * @param      : Set of NCMO Ids
     * @return     : List of No_Charge_Marketing_Order__c records
     * @Description: This method returns the list of NCMO records with children NCMO products
    **/
    public List<No_Charge_Marketing_Order__c> selectNcmoWithProductsById (Set<Id> setNcmoId) {

        ilib_QueryFactory ncmoParentQuery = newQueryFactory();
        ncmoParentQuery.selectField('Open_Offer_Product__c');
                                                   
        ilib_QueryFactory ncmoProductSubquery = new NoChargeMarketingOrderProductsSelector().addQueryFactorySubselect(ncmoParentQuery, 'No_Charge_Marketing_Order_Products__r');                                                                                    
        ncmoProductSubquery.selectField('Id');
        ncmoProductSubquery.selectField('Name');
        ncmoProductSubquery.selectField('Product__r.Name');
        ncmoProductSubquery.selectField('Product__r.Open_Offer_Product__c');
        ncmoProductSubquery.selectField('Product__r.Open_Offer_Product_Category__c');

        ilib_LogQuery logger;

        if (Feature.isOn(MKTG_FEATURE_FLAG)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectNcmoWithProductsById',UtilsCollection.serializeIds(setNcmoId));
        }

        List<No_Charge_Marketing_Order__c> res = (List<No_Charge_Marketing_Order__c>) Database.query(
                                                    ncmoParentQuery
                                                    .setCondition('Id IN : setNcmoId')
                                                    .toSOQL());

        if (Feature.isOn(MKTG_FEATURE_FLAG)){
            logger.stop(res.size());
        }

        return res;
        
    }

}