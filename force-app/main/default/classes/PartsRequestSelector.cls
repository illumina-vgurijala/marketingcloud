/**
*    @author Vaibhav
*    @date   15 Oct 2018
*    @description  Parts Request Selector class
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                  Date                   Description
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class PartsRequestSelector extends ilib_SObjectSelector
{
    private static final String LOG_TITLE = 'PartsRequestSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
	
	/**
     *  @author - Vaibhav 
     *  @return - SObjectType The Schema.SObjectType of the Parts Request
     **/
    public Schema.SObjectType getSObjectType()
    {
        return SVMXC__Parts_Request__c.sObjectType;
    }
    
    /**
     *  @author  Vaibhav 
     *  @description Retrieve list of fields for SVMXC__Parts_Request__c sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
           SVMXC__Parts_Request__c.Id,
           SVMXC__Parts_Request__c.Name,
           SVMXC__Parts_Request__c.SVMXC__Requested_From__c
       };
    }
    
    /**
     *  @author Vaibhav
     *  @description Fetch Parts Request By Id.
     *  @param 
     *  @return 
     **/
    public List<SVMXC__Parts_Request__c> selectPartsRequestById(Set<Id> setPartsRequestIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPartsRequestById', UtilsCollection.serializeIds(setPartsRequestIds));
		
        List<SVMXC__Parts_Request__c> res = (List<SVMXC__Parts_Request__c>) Database.query(
            newQueryFactory().selectField('SVMXC__Requested_From__c')
            .selectField('SVMXC__Requested_From__r.SVMXC__Service_Engineer__c')
            .selectField('SVMXC__Requested_From__r.SVMX_PS_Preferred_Technician__r.SVMXC__Salesforce_User__c')
            .setCondition('Id IN :setPartsRequestIds').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
   
    
 }