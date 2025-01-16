/**
 *    @author Sandeep Ram Ch.
 *    @date   25-01-2018
 *    @description    Class to get the PM Plan records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Sandeep Ram Ch.                 26-May-2018             Initial Version
 *     Prashanth                      24-Aug-2021             Added Query Instrumentation
 *    ------------------------------------------------------------------------------------ 
 *                    
 */

public with sharing class PreventiveMaintenancePlansSelector extends ilib_SObjectSelector{
    private static final String LOG_TITLE = 'PreventiveMaintenancePlansSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    /**
    *  @author Sandeep Ram Ch. 
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the PM Plan
    **/
   public Schema.SObjectType getSObjectType()
   {
        return SVMXC__PM_Plan__c.sObjectType;
   }
     /**
     *  @author  Sandeep Ram Ch. 
     *  @description Retrieve list of fields for PM Plan sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
       return new List<Schema.SObjectField> {
           SVMXC__PM_Plan__c.Id,
           SVMXC__PM_Plan__c.SVMXC__Service_Contract__c
       };
    }
    
    /**
     *  @author Sandeep Ram Ch.
     *  @description Fetch PM Plan associated with SMC
     *  @param SMC ids
     *  @return PM Plan
     **/
    public List<SVMXC__PM_Plan__c> selectPMPlanForSMC(Set<Id> setServiceContractId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPMPlanForSMC', UtilsCollection.serializeIds(setServiceContractId));
        }
        List<SVMXC__PM_Plan__c> res = (List<SVMXC__PM_Plan__c>) Database.query(
            newQueryFactory().selectField('Id').selectField('SVMXC__Status__c').selectField('SVMXC__Service_Contract__c').setCondition('SVMXC__Service_Contract__c IN : setServiceContractId').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;
    }

    /**
     *  @author Soumya Ranjan Sahu
     *  @description Select PM plans with Contract and ServicePlans
     *  @param PM plan Ids
     *  @return PM Plan records
     **/
    public List<SVMXC__PM_Plan__c> selectPMPlanWithServicePlans(Set<Id> setPMPlanIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPMPlanWithServicePlans', UtilsCollection.serializeIds(setPMPlanIds));
        }
        List<SVMXC__PM_Plan__c> res = (List<SVMXC__PM_Plan__c>) Database.query(
            newQueryFactory().selectField('SVMXC__Service_Contract__r.SVMXC__Service_Plan__r.OQ_Required__c')
            //DCP-47686 PM Work Order Optimization : correcting setCondition
            .setCondition('Id IN : setPMPlanIds AND SVMXC__Service_Contract__c != null AND SVMXC__Service_Contract__r.SVMXC__Service_Plan__c !=null')
            //.setCondition('SVMXC__Service_Contract__c != null')
            //.setCondition('SVMXC__Service_Contract__r.SVMXC__Service_Plan__c !=null')
            .toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;
    }

}