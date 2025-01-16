/**
 *    @author Vaibhav
 *    @date   19 Oct 2018
 *    @description    Class to get the Service Plan records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Prashanth                     24-Aug-2021         Added Query Instrumentation
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class ServicePlanSelector extends ilib_SObjectSelector
{
    private static final String LOG_TITLE = 'ServicePlanSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
   /**
    *  @author Vaibhav 
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the proposal
    **/
   public Schema.SObjectType getSObjectType()
   {
        return SVMXC__Service_Plan__c.sObjectType;
   }
    
    /**
     *  @author  Vaibhav
     *  @description Retrieve list of fields for Service Plan sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
        return new List<Schema.SObjectField> {
            SVMXC__Service_Plan__c.id,
            SVMXC__Service_Plan__c.Item_Number__c
        };
    }
    

    
    /**
     *  @author Vaibhav
     *  @description Fetch  Service Plan records based on Item Number 
     *  @return List of ServiceBoms
     **/
    public List<SVMXC__Service_Plan__c> selectServicePlanForItemNumber(Set<String> setItemNumber) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectServicePlanForItemNumber', UtilsCollection.serializeIds(setItemNumber));
        }
        List<SVMXC__Service_Plan__c> res = (List<SVMXC__Service_Plan__c>) Database.query(
            newQueryFactory().setCondition('Item_Number__c IN : setItemNumber '
                                          ).toSOQL()                                 
        ); 
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res; 
    }
    /**
     *  @author Kumar Gaurav
     *  @description Fetch  Service Plan records based on ServicePlan id
     *  @return List of ServicePlan
     **/
    public list<SVMXC__Service_Plan__c> getServicePlan(set<id> servicePlanIds){
	
        List<SVMXC__Service_Plan__c> res = (List<SVMXC__Service_Plan__c>)Database.query(
            newQueryFactory()
            .selectField('Id')
            .selectField('Consumables_Included__c')
            .selectField('Labor_Included__c')
            .selectField('Loaner_Included__c')
            .selectField('Parts_Included__c')
            .selectField('Remote_Support_Included__c')
            .selectField('SVMXC__SLA_Terms__c')
            .selectField('Travel_Included__c')
            .setCondition('ID IN: servicePlanIds')
            .toSOQL());

            return res;
            
}
}