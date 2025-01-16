/*
* @ author       : Prashanth
* @ date         : 30-Aug-2021
* @ Description  : selector class for Allocated stocks.
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                              Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Prashanth              30-Aug-2021                        Initial version
* Pooja                  22-Sep-2022                       Added Query Instrumentation   
* ---------------------------------------------------------------------------------------------------------------------------------------   
*/
public with sharing class AllocatedStocksSelector extends ilib_SObjectSelector {

   
    private static final String LOG_TITLE = 'AllocatedStocksSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
     /*
    * @author Sandeep
    * @date   12-05-2020   
    * @description  set select fields
    */
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            SVMXC__Allocated_Stock__c.Id
           
        };
    }

    /*
    * @author Sandeep
    * @date   12-05-2020 
    * @description  describe the object
    *
    */
    public Schema.SObjectType getSObjectType()
    {
        return SVMXC__Allocated_Stock__c.sObjectType;
    }
    
    /*
    * @author Sandeep
    * @date   12-05-2020 
    * @description Fetch Related Allocated Stocks
    * @param Set of wd Ids
    *
    */
    public List<SVMXC__Allocated_Stock__c> selectAllocatedStockWithWd(Set<Id> setwdIds) 
    {
		
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAllocatedStockWithWd', UtilsCollection.serializeIds(setwdIds));
        }
        List<SVMXC__Allocated_Stock__c> res = (List<SVMXC__Allocated_Stock__c>) Database.query(
        newQueryFactory()
        .selectField('SVMX_PS_VS_Work_Detail__c')
        .selectField('SVMXC__Allocated_Qty__c')
        .selectField('SVMXC__Product_Stock__c')
        .selectField('SVMX_PS_VS_Stocked_Serial__c')
        .selectField('Product__c')
        .selectField('Location__c')
        .selectField('Batch_Number__c')
        .selectField('Work_Order__c')
        .setCondition('SVMX_PS_VS_Work_Detail__c IN :setwdIds').toSOQL());
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }
    
    /*
    * @author Sravan
    * @date   12-05-2020 
    * @description DCP-33467: Fetch Allocated Stocks related to given batch number and location
    * @param Set location Ids, set batchnumbers
    * @return Allocated Stock list
    */
    public List<SVMXC__Allocated_Stock__c> selectAllocatedStocksByBatchAndLocation(set<Id> setFromLocationId, set<String> setBatchNumber)
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAllocatedStocksByBatchAndLocation', UtilsCollection.serializeIds(setFromLocationId)  + '|' + UtilsCollection.serializeIds(setBatchNumber));
        }    
        List<SVMXC__Allocated_Stock__c> res = (List<SVMXC__Allocated_Stock__c>) Database.query(
        newQueryFactory().selectField('SVMXC__Allocated_Qty__c')
            			 .selectField('Work_Order__r.Name')
             			 .selectField('Location__c')
            			 .selectField('Location__r.ERP_Customer_ID__c')
            			 .selectField('Batch_Number__c')
            			 .selectField('Product_Code__c')
            			 .setCondition('Location__c IN :setFromLocationId AND Batch_Number__c IN :setBatchNumber').toSOQL());
						 
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }

    /*
    * @author Sravan
    * @date   18-05-2020 
    * @description DCP-33467: Fetch Allocated Stocks related to given stock serial id
    * @param Set stockserial Ids
    * @return Allocated Stock list
    */
    public List<SVMXC__Allocated_Stock__c> selectAllocatedStocksByStockSerialIds(set<Id> setStockSerialId)
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAllocatedStocksByStockSerialIds', UtilsCollection.serializeIds(setStockSerialId));
        }    
        List<SVMXC__Allocated_Stock__c> res = (List<SVMXC__Allocated_Stock__c>) Database.query(
        newQueryFactory().selectField('SVMX_PS_VS_Work_Detail__c').selectField('Work_Order__r.Name').selectField('SVMX_PS_VS_Stocked_Serial__c').setCondition('SVMX_PS_VS_Stocked_Serial__c IN :setStockSerialId').toSOQL());
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;


    }
    
    /*
    * @author Sravan
    * @date   03-06-2020 
    * @description DCP-33467: Fetch Allocated Stocks related to given product stock id
    * @param Set product stock Ids
    * @return Allocated Stock list
    */
    public List<SVMXC__Allocated_Stock__c> selectAllocatedStocksByProductStockIds(set<Id> setProductStockId)
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAllocatedStocksByProductStockIds', UtilsCollection.serializeIds(setProductStockId));
        }    
        List<SVMXC__Allocated_Stock__c> res = (List<SVMXC__Allocated_Stock__c>) Database.query(
        newQueryFactory().selectField('SVMXC__Allocated_Qty__c').selectField('Work_Order__r.Name').selectField('SVMX_PS_VS_Work_Detail__c').selectField('SVMXC__Product_Stock__c').setCondition('SVMXC__Product_Stock__c IN :setProductStockId AND Batch_Number__c=null AND SVMX_PS_VS_Stocked_Serial__c=null').toSOQL());
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }
}