/**
 *    @author Veerendra
 *    @date   09-June-2018
 *    @description    Class to get the Covered Location records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Veerendra                   09-Jun-2018            Initial Version
 *    Dhairya                     29-Feb-2024            CMCM-9
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class CoveredLocationSelector extends ilib_SObjectSelector
{
	
    private static final String LOG_TITLE = 'CoveredLocationSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    //Added below fields labels with CMCM-9 changes
    private static final String CONTRACT_NAME ='SVMXC__Service_Contract__r.Name';
    private static final String CONTRACT_ERPHEADERCONNUMB = 'SVMXC__Service_Contract__r.ERP_Header_Contract_Number__c';
    private static final String CONTRACT_SERVICELEVEL = 'SVMXC__Service_Contract__r.SVMXC__Service_Level__c';
    private static final String CONTRACT_ENDDATE = 'SVMXC__Service_Contract__r.SVMXC__End_Date__c';

   /**
    *  @author Veerendra
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the proposal
    **/
   public Schema.SObjectType getSObjectType()
   {
        return SVMXC__Service_Contract_Sites__c.sObjectType;
   }
    
   /**
     *  @author  Veerendra 
     *  @description Retrieve list of fields for Covered Locations sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
       return new List<Schema.SObjectField> {
           SVMXC__Service_Contract_Sites__c.id,
           SVMXC__Service_Contract_Sites__c.SVMXC__Site__c,
		   SVMXC__Service_Contract_Sites__c.SVMX_PS_External_ID__c,
           SVMXC__Service_Contract_Sites__c.SVMXC__Service_Contract__c
       };
    }
	public static final string STRING_SORT_ORDER = 'SVMXC__Service_Contract__r.SVMXC__End_Date__c ASC';
	/**
    *  @author Veerendra
    *  @description - returns SVMXC__Service_Contract__r.SVMXC__End_Date__c ASC
    **/
    public override String getOrderBy(){
        return STRING_SORT_ORDER;
    }

    /**
     *  @author Veerendra
     *  @description Fetch Covered Location associated with Locations
     *  @param Location Ids
     *  @return List of Covered Location that are entitled
     **/
    public List<SVMXC__Service_Contract_Sites__c> selectCoveredLocations(Set<Id> setLocationIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCoveredLocations', UtilsCollection.serializeIds(setLocationIds));
		
        List<SVMXC__Service_Contract_Sites__c> res = (List<SVMXC__Service_Contract_Sites__c>) Database.query(
            newQueryFactory().selectField(CONTRACT_NAME)
			.selectField(CONTRACT_ERPHEADERCONNUMB)
            .selectField(CONTRACT_SERVICELEVEL)
            .selectField(CONTRACT_ENDDATE)
            .setCondition('SVMXC__Site__c IN : setLocationIds AND SVMXC__Service_Contract__r.Status__c = \'Active\'').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
	
	/**
     *  @author Prakhar
     *  @description Fetch Covered Locations associated with Service Contract
     *  @param Service Contract Ids
     *  @return List of Covered Locations
     **/
    public List<SVMXC__Service_Contract_Sites__c> selectCoveredLocationsForServiceContracts(Set<Id> setServiceContractIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCoveredLocationsForServiceContracts', UtilsCollection.serializeIds(setServiceContractIds));
		
        List<SVMXC__Service_Contract_Sites__c> res = (List<SVMXC__Service_Contract_Sites__c>) Database.query(
            newQueryFactory().setCondition('SVMXC__Service_Contract__c IN : setServiceContractIds').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

     /**
     *  @author Dhairya
     *  @description Fetch Covered Location associated with Locations Or Accounts
     *  @param Location Ids , Account Ids
     *  @US CMCM-9
     *  @return List of Covered Location that are entitled
     **/
    public List<SVMXC__Service_Contract_Sites__c> selectCoveredLocForLocAndAcc(Set<Id> setLocationIds,Set<Id> setAccountIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCoveredLocForLocAndAcc', UtilsCollection.serializeIds(setLocationIds));

        List<SVMXC__Service_Contract_Sites__c> res = (List<SVMXC__Service_Contract_Sites__c>) Database.query(
            newQueryFactory().selectField(CONTRACT_NAME)
			.selectField(CONTRACT_ERPHEADERCONNUMB)
            .selectField(CONTRACT_SERVICELEVEL)
            .selectField(CONTRACT_ENDDATE)
            .setCondition('(SVMXC__Site__c IN : setLocationIds OR SVMXC__Site__r.SVMXC__Account__c IN:setAccountIds) AND SVMXC__Service_Contract__r.Status__c = \'Active\'').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
}