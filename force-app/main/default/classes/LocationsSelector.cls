/**
 *    @author Sandeep Ram Ch. 
 *    @date   05-07-2018
 *    @description    Class to get the Location records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Sandeep Ram Ch.            05-Jul-2018             Initial Version
 *    KD                         28-June-2021            DCP-46257 : New method selectDistributorPartnerStockLocationByAccount
 *    Sagar Madkaikar            17-Sep-2021             CMCP-22: Added field in selectDistributorPartnerStockLocationByAccount();
 *    Romi Taskar                1-Sep-2022              DCP-52923: Add field in selectLocations method 
 *    Dhairya Shah               29-Feb-2024             CMCM-9
 *  ------------------------------------------------------------------------------------ 
 *                    
 */
 
public with sharing class LocationsSelector extends ilib_SObjectSelector
{
    private static final String LOG_TITLE = 'LocationsSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    
   /**
    *  @author  Sandeep Ram Ch. 
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the proposal
    **/
   public Schema.SObjectType getSObjectType()
   {
        return SVMXC__Site__c.sObjectType;  
   }
    
    /**
     *  @author  Sandeep Ram Ch.
     *  @description Retrieve list of fields for Technician sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
       return new List<Schema.SObjectField> {
            SVMXC__Site__c.id,
            SVMXC__Site__c.SVMX_PS_Active__c,
            SVMXC__Site__c.Name,
            SVMXC__Site__c.Is_Illumina_Address__c,
            SVMXC__Site__c.SVMXC__Country__c,
			SVMXC__Site__c.SVMX_PS_External_ID__c,
            SVMXC__Site__c.Is_Primary_Illumina_Address__c,
			SVMXC__Site__c.Inventory_Authority__c,
			SVMXC__Site__c.Type__c,
            SVMXC__Site__c.SVMXC__Account__c,
			SVMXC__Site__c.ERP_Customer_ID__c
			
            
       };
    }
    /**
     *  @author Sandeep Ram Ch. 
     *  @description Fetch Locations for the countries where illumina address is true
     *  @return List of Country Names
     **/
    public List<SVMXC__Site__c> selectIlluminaAddresses(List<String> lstCountryNames) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectIlluminaAddresses', UtilsCollection.serializeIds(new Set<String>(lstCountryNames)));
		
        List<SVMXC__Site__c> res = (List<SVMXC__Site__c>) Database.query(
            newQueryFactory().setCondition('Is_Illumina_Address__c = true AND SVMXC__Country__c IN: lstCountryNames')
            .toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    } 
    
    /**
     *  @author Sandeep Ram Ch. 
     *  @description Fetch Locations for id passed
     *  @return List of Location Ids
     **/
    public List<SVMXC__Site__c> selectLocations(List<Id> lstLocationIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectLocations', UtilsCollection.serializeIds(new Set<Id>(lstLocationIds)));
		
        List<SVMXC__Site__c> res = (List<SVMXC__Site__c>) Database.query(
            newQueryFactory().selectField('SVMXC__Service_Engineer__c')
                            .selectField('SVMX_PS_Preferred_Technician__c')
                            .selectField('SVMX_PS_Preferred_Technician__r.SVMXC__Salesforce_User__c')
                            .selectField('Shipping_Location_Address__c') //DCP-52923
                            .selectField('SVMXC__Account__c') //CMCM-9
							.setCondition('Id IN : lstLocationIds')
                            .toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

	 /**
     *  @author Vaibhav
     *  @description Fetch Locations for external ids passed.
     *  @return List of Location Ids
     **/
    public List<SVMXC__Site__c> selectLocationsForExternalId(set<String> setLocationExtIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectLocationsForExternalId', UtilsCollection.serializeIds(setLocationExtIds));
		
        List<SVMXC__Site__c> res = (List<SVMXC__Site__c>) Database.query(
            newQueryFactory().setCondition('SVMX_PS_External_ID__c IN : setLocationExtIds')
            .toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    } 
    /**
     *  @author Soumya
     *  @description Fetch Locations for id passed
     *  @return List of Location Ids
     **/
    public List<SVMXC__Site__c> selectLocationsInventoryLocation(set<Id> setLocationIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectLocationsInventoryLocation', UtilsCollection.serializeIds(setLocationIds));
		
        List<SVMXC__Site__c> res = (List<SVMXC__Site__c>) Database.query(
            newQueryFactory().selectField('SVMXC__Service_Engineer__c')
                            .selectField('SVMX_PS_Preferred_Technician__c')
                            .selectField('SVMX_PS_Preferred_Technician__r.SVMXC__Salesforce_User__c')
                            .setCondition('Id IN : setLocationIds AND (SVMX_PS_Preferred_Technician__c !=NULL OR SVMXC__Service_Engineer__c != NULL)')
                            .toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
	
	/**
     *  @author Soumya
     *  @description Fetch Locations by Name
     *  @return List of Location Ids
     **/
    public List<SVMXC__Site__c> selectLocationByName(string locationName) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectLocationByName', locationName);

        List<SVMXC__Site__c> res = (List<SVMXC__Site__c>) Database.query(
            newQueryFactory().setCondition('Name = : locationName')
            .toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
	
	 /**
     *  @author Sravankumar
     *  @description Fetch Locations for id passed
     *  @return List of Location Ids
     **/
    public List<SVMXC__Site__c> selectToLocations(set<Id> setToLocationIds) 
    {  
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectToLocations', UtilsCollection.serializeIds(setToLocationIds));
		
        List<SVMXC__Site__c> res = (List<SVMXC__Site__c>) Database.query(
            newQueryFactory().selectField('ERP_Customer_ID__c')
                             .setCondition('Id IN : setToLocationIds')
                             .toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
	
	/**
     *  @author Sravan
     *  @description Fetch Locations for id passed
     *  @return List of Location Ids
     **/
    public List<SVMXC__Site__c> selectLocationsFromIds(set<Id> setLocationIds) 
    {  
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectLocationsFromIds', UtilsCollection.serializeIds(setLocationIds));
		
        List<SVMXC__Site__c> res = (List<SVMXC__Site__c>) Database.query(
            newQueryFactory().setCondition('Id IN : setLocationIds')
            .toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Ritika
     *  @description Fetch Locations for account id passed
     *  @return List of Location Ids
     **/
    public List<SVMXC__Site__c> selectLocationsFromAccountIds(set<Id> setAccountIds) 
    {  
        ilib_LogQuery logger = new ilib_LogQuery();
        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectLocationsFromAccountIds',
            UtilsCollection.serializeIds(setAccountIds)
        );
        String strQuery= newQueryFactory(true)
            .setCondition('SVMXC__Account__c IN: setAccountIds')
            .toSOQL();

        List<SVMXC__Site__c> res = (List<SVMXC__Site__c>) Database.query(strQuery);
        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) logger.stop(res.size());
        return res;
        
    }
    /**
     *  @author KD
    *  @description DCP-46257 : Fetch location details based on Account and partner location
    */
    public List<SVMXC__Site__c> selectDistributorPartnerStockLocationByAccount(Set<Id> setAccountIds){
        String strLocationType = 'Partner Stock'; 
        ilib_LogQuery logger = new ilib_LogQuery();
        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectInstalledProductByAccountAndSerialNumber',
            UtilsCollection.serializeIds(setAccountIds)
        );
        String strQuery= newQueryFactory(true)
            .selectField('SVMX_PS_External_ID__c')
            .setCondition('Type__c =: strLocationType AND SVMXC__Account__c IN: setAccountIds AND Name LIKE \'%'+strLocationType+'%\'')
            .toSOQL();

        List<SVMXC__Site__c> res = (List<SVMXC__Site__c>) Database.query(strQuery);
        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) logger.stop(res.size());
        return res;
    }

    /**
     *  @author Dhairya
     *  @description Fetch Locations for ERP Customer id passed with location Type as (Ship To, Sold To, Ultimate consignee)
     *  @return set of string for Location Ids, set of string for location Type
     * @US  CMCM-9
     **/
    public List<SVMXC__Site__c> selectLocationsFromErpCusIds(set<String> seterpCusIds,Set<String> setTypes) 
    {  
        ilib_LogQuery logger = new ilib_LogQuery();
        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectLocationsFromErpCusIds',
            UtilsCollection.serializeIds(seterpCusIds)
        );
        String strQuery= newQueryFactory(true)
            .setCondition('ERP_Customer_ID__c IN: seterpCusIds AND Type__c IN :setTypes')
            .toSOQL();

        List<SVMXC__Site__c> res = (List<SVMXC__Site__c>) Database.query(strQuery);
        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) logger.stop(res.size());
        return res;

    }
}