/***************************************************************************************************************************************
* NAME         : FRUListSelector
* DESCRIPTION  : Class to get the FRUList records based on different conditions.
*                    
* @AUTHOR : Vaibhav
* @DATE   : 3-Aug-2018  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
public with sharing class FRUListSelector extends ilib_SObjectSelector 
{
    private static final String LOG_TITLE = 'FRUListSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';

    /**
     *  @author Vaibhav Parashar 
     *  @description  
     *  @return SObjectType The Schema.SObjectType of the proposal
     **/
    public Schema.SObjectType getSObjectType() {
        return FRU_List__c.sObjectType;
    }

    /**
     *  @author  Vaibhav Parashar  
     *  @description Retrieve list of fields for FRUList sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List < Schema.SObjectField > getSObjectFieldList() {
        return new List < Schema.SObjectField > {
            FRU_List__c.id,
            FRU_List__c.Name,
            FRU_List__c.ERP_Parent_Product__c,
			FRU_List__c.SVMX_PS_External_ID__c,
            FRU_List__c.ERP_Product__c
        };
    }


    /**
     *  @author Vaibhav
     *  @description Fetch all the FRUList records based on passed parent product ids.
     *  @return List of FRUList
     **/
    /*public List < FRU_List__c > selectFRUListForParentProduct(Set < Id > productIds) {
        return (List < FRU_List__c > ) Database.query(
            newQueryFactory().selectField('ERP_Product__r.Name')
            .setCondition('ERP_Parent_Product__c IN : productIds').toSOQL()

        );
    }*/
    public string stringSortOrder = 'Name ASC';
    /**
     *  @description  getOrderBy
     **/
    public override String getOrderBy(){
         return stringSortOrder;
     }
    /**
     *  @author Ritika
     *  @description Fetch all the FRUList records based on ServiceBOM Ids.
     *  @return List of FRUList
     **/
    public List <FRU_List__c> selectFRUListForServiceBOM(Set < Id > setServiceBOMIds, set<String> type) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectFRUListForServiceBOM', UtilsCollection.serializeIds(setServiceBOMIds)+'|'+ UtilsCollection.serializeIds(type));
		
        List <FRU_List__c> res = (List <FRU_List__c> ) Database.query(
            newQueryFactory().selectField('Service_Bill_Of_Materials__c')
            .setCondition('Service_Bill_Of_Materials__c IN : setServiceBOMIds ' + 
                          ' AND Service_Bill_Of_Materials__r.Active__c = TRUE ' +
                         ' AND Type__c IN :type').toSOQL()

        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
	  
	
	/**
     *  @author Vaibhav
     *  @description Fetch all the FRUList records based on passed parent product ids.
     *  @return List of FRUList
     **
    public List<FRU_List__c> selectFruListByExternalId(Set<String> setFruListExternalIds) 
    {
        return (List<FRU_List__c>) Database.query(
            newQueryFactory().setCondition('SVMX_PS_External_ID__c IN : setFruListExternalIds '
                                          ).toSOQL()
        );  
    }*/
	
	/**
     *  @author Vaibhav
     *  @description Fetch all the FRUList records based on ServiceBOM ERP Number.
     *  @return List of FRUList
     **/
    public List <FRU_List__c> selectFRUListForServiceBOMNumber(Set < String > setServiceBOMNumbers) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectFRUListForServiceBOMNumber', UtilsCollection.serializeIds(setServiceBOMNumbers));
		
        List <FRU_List__c> res = (List <FRU_List__c>) Database.query(
            newQueryFactory().selectField('Service_Bill_Of_Materials__c').selectField('Service_Bill_Of_Materials__r.ERP_Service_BoM_Number__c')
            .setCondition('Service_Bill_Of_Materials__r.ERP_Service_BoM_Number__c IN : setServiceBOMNumbers ').toSOQL()

        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
/**
     *  @author Sandeep
     *  @description Fetch all the FRUList records based on ServiceBOM Id.
     *  @return List of FRUList
     **/
    public List <FRU_List__c> selectFRUListForSBOM(Set <Id> setServiceBOM,string filter) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectFRUListForSBOM', UtilsCollection.serializeIds(setServiceBOM)+'|'+filter);
		
        stringSortOrder = 'Product_Code__c ASC';
        List <FRU_List__c> res = (List <FRU_List__c>) Database.query(
            newQueryFactory().selectField('Service_Bill_Of_Materials__c').selectField('Type__c').selectField('Product_Code__c').selectField('ERP_Product__r.Name')
            .selectField('ERP_Product__r.SFDC_Block__c').selectField('ERP_Product__r.IsActive').selectField('ERP_Product__r.Product_Image__c').selectField('ERP_Product__r.Description').setCondition('Service_Bill_Of_Materials__c IN : setServiceBOM and (ERP_Product__r.Description LIKE \'%'+filter+'%\' OR '+'ERP_Product__r.Name  LIKE \'%'+filter+'%\' OR '+'Product_Code__c LIKE \'%' + filter+'%\')').toSOQL()
            
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
}