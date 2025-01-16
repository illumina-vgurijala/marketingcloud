/**
 *    @author Soumya Sahu
 *    @date   04-12-2019
 *    @description    Class to get the Parts Ordering Restrictions records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer              Date                    Description
 *    Soumya                 04-Dec-2019             Initial Version
 *    ------------------------------------------------------------------------------------ 
 *                    
 */

public with sharing class PartsOrderingRestrictionsSelector extends ilib_SObjectSelector
{
    private static final String LOG_TITLE = 'PartsOrderingRestrictionsSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    
    
    /**
    *  @author Soumya Sahu
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the proposal
    **/
   public Schema.SObjectType getSObjectType()
   {
        return Parts_Ordering_Restrictions__c.sObjectType;
   }
    
    /**
     *  @author  Soumya Sahu
     *  @description Retrieve list of fields for Parts Order Restrictions sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
       return new List<Schema.SObjectField> {
           Parts_Ordering_Restrictions__c.id,
           Parts_Ordering_Restrictions__c.Product__c,
           Parts_Ordering_Restrictions__c.Name,
           Parts_Ordering_Restrictions__c.Ownerid
       };
    }
    
    /**
     *  @author Soumya Sahu
     *  @description Fetch parts order Restrictions from Restriction Key
     *  @param set of Restriction Key Ids
     *  @return parts order Restrictions records
     **/
    public List<Parts_Ordering_Restrictions__c> selectPORestrictionsByKey(set<string> setProductCodes,set<string> setClinincalTypes,set<string> setCustomerTypes,set<string> setTerritoryRegion)
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPORestrictionsByKey', UtilsCollection.serializeIds(setProductCodes)+'|'+UtilsCollection.serializeIds(setClinincalTypes)+'|'+UtilsCollection.serializeIds(setCustomerTypes)+'|'+UtilsCollection.serializeIds(setTerritoryRegion));

        List<Parts_Ordering_Restrictions__c> res = (List<Parts_Ordering_Restrictions__c>) Database.query(
                        newQueryFactory().selectField('Clinical_Type__c')
                                         .selectField('Customer_Type__c')
                                        .selectField('Territory_Region__c')
                                        .selectField('Comment__c')
                                        .selectField('Product_Code__c')
                                        .selectField('Territory_Region__c')
                                        .setCondition('Product_Code__c IN :setProductCodes AND ( Clinical_Type__c IN :setClinincalTypes OR Customer_Type__c IN :setCustomerTypes OR Territory_Region__c IN :setTerritoryRegion ) ').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res; 
    }
}