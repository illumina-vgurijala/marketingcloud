/**
 *    @author Sandeep Ram Ch.
 *    @date   11-06-2018
 *    @description    Class to get the Technician records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *     Sandeep Ram Ch.         11-Jun-2018             Initial Version
 *    KD                       2-June-2021             Update method selectTechniciansMatchingUsers
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class TechniciansSelector extends ilib_SObjectSelector
{
    private static final String LOG_TITLE = 'TechniciansSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
   /**
    *  @author  Sandeep Ram Ch.
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the proposal
    **/
   public Schema.SObjectType getSObjectType()
   {
        return SVMXC__Service_Group_Members__c.sObjectType;
   }
    
    /**
     *  @author  Sandeep Ram Ch.
     *  @description Retrieve list of fields for Technician sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
       return new List<Schema.SObjectField> {
            SVMXC__Service_Group_Members__c.id,
            SVMXC__Service_Group_Members__c.SVMXC__Active__c,
            SVMXC__Service_Group_Members__c.Name,
            SVMXC__Service_Group_Members__c.SVMXC__Email__c,
            SVMXC__Service_Group_Members__c.SVMXC__Salesforce_User__c,
			SVMXC__Service_Group_Members__c.SVMXC__Inventory_Location__c
            
       };
    }
	
    /**
    *  @author Digvijay
    *  @description  Retrieve Technician records based on the salesforce user Ids.
    *  @return SObjectType The Schema.SObjectType of the proposal
    **/
    public List<SVMXC__Service_Group_Members__c> selectTechniciansMatchingUsers(Set<Id> setUserIds) 
    {
        ilib_LogQuery logger=null;
        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(
                LOG_TITLE + '.selectTechniciansMatchingUsers',
                UtilsCollection.serializeIds(setUserIds)
            );
        }
        String strQuery= newQueryFactory()
            .selectField('Related_User_Email__c')
            .selectField('SVMXC__Service_Group__c')
            .selectField('SVMXC__Inventory_Location__r.SVMXC__Account__r.ERP_Customer_Id__c')
            .setCondition('SVMXC__Salesforce_User__c IN :setUserIds')
            .toSOQL();

        List<SVMXC__Service_Group_Members__c> res = (List<SVMXC__Service_Group_Members__c>) Database.query(strQuery);
        if (Feature.isOn('ServiceQueryLogs')){
            logger.stop(res.size());
        }
        return res;  
    } 
	
	/**
    *  @author Digvijay
    *  @description  Retrieve Technician records based on the technician Ids.
    *  @return SObjectType The Schema.SObjectType of the proposal
    **/
   public List<SVMXC__Service_Group_Members__c> selectTechnicians(Set<Id> setTechnicianIds) 
    {
        ilib_LogQuery logger=null;
        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(
                LOG_TITLE + '.selectTechnicians',
                UtilsCollection.serializeIds(setTechnicianIds)
            );
        }
        List<SVMXC__Service_Group_Members__c> res =  Database.query(
           newQueryFactory().selectField('Id')
                            .selectField('SVMXC__Salesforce_User__c')
                            .selectField('SVMXC__Salesforce_User__r.IsPortalEnabled')
                            .selectField('Related_User_Email__c')
                            .selectField('Preferred_Service_Report_Language__c')
                            .selectField('SVMXC__Salesforce_User__r.TimeZoneSidKey')
							.selectField('SVMXC__Inventory_Location__r.SVMXC__Account__r.ERP_Customer_Id__c')
                            .setCondition('Id IN : setTechnicianIds').toSOQL()
        );
        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;
    }
	
	/**
    *  @author Digvijay
    *  @description  Retrieve Technician records based on the technician Ids and Salesforce User Id.
    *  @return SObjectType The Schema.SObjectType of the proposal
    **/
	public List<SVMXC__Service_Group_Members__c> selectTechniciansrecords(Set<Id> setTechnicianIds,Set<Id> setUserIds) 
    {
        ilib_LogQuery logger=null;
        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(
                LOG_TITLE + '.selectTechniciansrecords',
                UtilsCollection.serializeIds(setTechnicianIds)+'|'+UtilsCollection.serializeIds(setUserIds)
            );
        }
        List<SVMXC__Service_Group_Members__c> res =  Database.query(
           newQueryFactory().selectField('Id')
                            .selectField('SVMXC__Salesforce_User__c')
                            .selectField('SVMXC__Service_Group__c')
                            .selectField('SVMXC__Salesforce_User__r.IsPortalEnabled')
                            .selectField('Related_User_Email__c')
                            .selectField('Preferred_Service_Report_Language__c')
							.selectField('SVMXC__Inventory_Location__r.SVMXC__Account__r.ERP_Customer_Id__c')
                            .selectField('SVMXC__Salesforce_User__r.TimeZoneSidKey')
                            .setCondition('Id IN : setTechnicianIds'+' OR SVMXC__Salesforce_User__c IN :setUserIds').toSOQL()
        );
        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;
    } 

}