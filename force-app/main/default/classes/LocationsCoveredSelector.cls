/**
 *    @author Sandeep Ram Ch.
 *    @date   30-07-2018
 *    @description    Class to get the Location Covered records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *      Developer                      Date                Description
 *      Sandeep Ram Ch.                30-July-2018         Initial Version
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class LocationsCoveredSelector extends ilib_SObjectSelector
{
    private static final String LOG_TITLE = 'LocationsCoveredSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';

   /**
    *  @author Sandeep Ram Ch.
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the proposal
    **/
   public Schema.SObjectType getSObjectType()
   {
        return SVMXC__Service_Group_Site__c.sObjectType;
   }
    
    /**
     *  @author  Sandeep Ram Ch. 
     *  @description Retrieve list of fields for SVMXC__Service_Group_Site__c sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {  
       return new List<Schema.SObjectField> {
           SVMXC__Service_Group_Site__c.Id, 
           SVMXC__Service_Group_Site__c.SVMXC__Technician_Equipment__c, 
           SVMXC__Service_Group_Site__c.SVMXC__Site__c
           
       };
           
    }
    
    /**
     *  @author Sandeep Ram Ch.
     *  @description Fetch  Location covered records for the list of field support ids
     *  @param List of FieldSupport ids
     *  @return List of Location Covered
     **/
    public List<SVMXC__Service_Group_Site__c> selectRelatedLocationFieldSupport(List<Id> lstFieldSupportId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectRelatedLocationFieldSupport', UtilsCollection.serializeIds(new Set<Id>(lstFieldSupportId)));
		
        List<SVMXC__Service_Group_Site__c> res = (List<SVMXC__Service_Group_Site__c>) Database.query(
            newQueryFactory().setCondition('SVMXC__Technician_Equipment__c IN:lstFieldSupportId').toSOQL()
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Debanka Chakraborty
     *  @description Fetch federation id of the user
     **/
    public List<SVMXC__Service_Group_Site__c> selectLocationsCovered(Set<Id> locationIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectLocationsCovered', UtilsCollection.serializeIds(locationIds));
		
         List<SVMXC__Service_Group_Site__c> res = (List<SVMXC__Service_Group_Site__c>) Database.query(
            newQueryFactory()
            .selectField('SVMXC__Technician_Equipment__r.SVMXC__Active__c')
            .selectField('SVMXC__Technician_Equipment__r.SVMXC__Salesforce_User__c')
            .selectField('SVMXC__Site__c')
            .selectField('SVMXC__Technician_Equipment__r.SVMXC__Salesforce_User__r.FederationIdentifier')
            .selectField('SVMXC__Technician_Equipment__r.SVMXC__Salesforce_User__r.Alias')
            .setCondition('SVMXC__Site__c IN :locationIds')
            .toSOQL()
         );
                                
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;                        
    }   
}