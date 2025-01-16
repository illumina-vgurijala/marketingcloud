/**
*    @author: Deep Diwakar
*    @date:   March-08-2023
*    @description:  Selector class for No Charge Marketing Order Product object
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*           Deep Diwakar                  March-08-2023       DCP-59580: Selector class for No Charge Marketing Order Product object
*    ------------------------------------------------------------------------------------ 
*                    
*/

public with sharing class NoChargeMarketingOrderProductsSelector extends ilib_SObjectSelector {

    private static final String LOG_TITLE = 'NoChargeMarketingOrderProductsSelector';

    /**
    *  @author  Deep Diwakar
    *  @description Sets up object type at parent level
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public Schema.SObjectType getSObjectType() {
        return No_Charge_Marketing_Order_Product__c.sObjectType;
    }

    /**
    *  @author  Deep Diwakar
    *  @description Sets up default fields that are returned when any method of this selector is called
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            No_Charge_Marketing_Order_Product__c.Id,
            No_Charge_Marketing_Order_Product__c.Name,
            No_Charge_Marketing_Order_Product__c.NCMO__c, 
            No_Charge_Marketing_Order_Product__c.Product__c
        };
    }

    /**
     * @author     : Deep Diwakar
     * @param      : Set of email ids
     * @return     : Contact Record
     * @Description: Method that returns list of contacts for customer community specific fields using
                     email id as filter criteria.
    **/
    public List<No_Charge_Marketing_Order_Product__c> selectNcmoProductsById (Set<Id> setNcmoProductId) {
        ilib_LogQuery logger;

        if (Feature.isOn('MarketingQueryLogs')){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectNcmoProductsById',UtilsCollection.serializeIds(setNcmoProductId));
        }

        List<No_Charge_Marketing_Order_Product__c> res = (List<No_Charge_Marketing_Order_Product__c>) Database.query(newQueryFactory()
                                                    .selectField('Product__r.Open_Offer_Product__c')
                                                    .selectField('Product__r.Open_Offer_Product_Category__c')
                                                    .setCondition('Id IN : setNcmoProductId')
                                                    .toSOQL());
                                                                                            
        if (Feature.isOn('MarketingQueryLogs')){
            logger.stop(res.size());
        }

        return res;
        
    }

    
}