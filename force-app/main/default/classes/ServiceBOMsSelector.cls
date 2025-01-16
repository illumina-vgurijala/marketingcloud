/**
 *    @author Ritika Maheshwari
 *    @date   14-09-2018
 *    @description    Class to get the Work Order records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Ritika                 14-Sept-2018             Initial Version
 *    Prashanth               24-Aug-2021              Added query Instrumentation
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class ServiceBOMsSelector extends ilib_SObjectSelector
{
    private static final String LOG_TITLE = 'ServiceBOMsSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
   /**
    *  @author Ritika Maheshwari 
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the proposal
    **/
   public Schema.SObjectType getSObjectType()
   {
        return Service_Bill_Of_Materials__c.sObjectType;
   }
    
    /**
     *  @author  Ritika Maheshwari 
     *  @description Retrieve list of fields for Case sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
       	return new List<Schema.SObjectField> {
        	Service_Bill_Of_Materials__c.id,
        	Service_Bill_Of_Materials__c.Product__c,
			Service_Bill_Of_Materials__c.ERP_Service_BoM_Number__c,
            Service_Bill_Of_Materials__c.Active__c
        };
    }
    

    /**
     *  @author Ritika
     *  @description Fetch Default ServiceBoms which are associated with a Product
     *  @return List of work orders
     **/
    public List<Service_Bill_Of_Materials__c> selectDefaultServiceBOMsForProduct(Set<Id> setProductIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectDefaultServiceBOMsForProduct', UtilsCollection.serializeIds(setProductIds));
        }
        List<Service_Bill_Of_Materials__c> res = (List<Service_Bill_Of_Materials__c>) Database.query(
            newQueryFactory().setCondition('Product__c IN : setProductIds '
                                          +' AND Default__c = TRUE').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;
    }
	
	 /**
     *  @author Vaibhav
     *  @description Fetch  ServiceBoms based on ERP ServiceBOM Number 
     *  @return List of ServiceBoms
     **/
    public List<Service_Bill_Of_Materials__c> selectServiceBOMsByERPServiceBOMNumber(Set<String> setERPServiceBOMNumbers) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectServiceBOMsByERPServiceBOMNumber', UtilsCollection.serializeIds(setERPServiceBOMNumbers));
        }
        List<Service_Bill_Of_Materials__c> res = (List<Service_Bill_Of_Materials__c>) Database.query(
            newQueryFactory().setCondition('ERP_Service_BOM_Number__c IN : setERPServiceBOMNumbers '
                                          ).toSOQL()
        ); 
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;
    }
}