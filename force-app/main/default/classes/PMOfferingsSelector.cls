/**
 *    @author Sandeep Ram Ch.
 *    @date   25-01-2018
 *    @description    Class to get the PM Offering records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Sandeep Ram Ch.                 26-May-2018             Initial Version
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class PMOfferingsSelector extends ilib_SObjectSelector
{
    private static final String LOG_TITLE = 'PMOfferingsSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';

   /**
    *  @author Sandeep Ram Ch. 
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the PM Offering
    **/
   public Schema.SObjectType getSObjectType()
   {
        return SVMXC__PM_Offering__c.sObjectType;
   }
    
    /**
     *  @author  Sandeep Ram Ch. 
     *  @description Retrieve list of fields for PM Offering sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
       return new List<Schema.SObjectField> {
           SVMXC__PM_Offering__c.Id,
           SVMXC__PM_Offering__c.SVMXC__Service_Plan__c,
           SVMXC__PM_Offering__c.SVMXC__Service_Contract__c,
           SVMXC__PM_Offering__c.SVMXC__PM_Plan_Template__c
       };
    }
    
    /**
     *  @author Sandeep Ram Ch.
     *  @description Fetch PM Offering associated with SMC
     *  @param SMC ids
     *  @return PM Offering
     **/
    public List<SVMXC__PM_Offering__c> selectPMOfferingsForSMC(Set<Id> setServiceContractId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPMOfferingsForSMC', UtilsCollection.serializeIds(setServiceContractId));
		
        List<SVMXC__PM_Offering__c> res = (List<SVMXC__PM_Offering__c>) Database.query(
            newQueryFactory().setCondition('SVMXC__Service_Contract__c IN : setServiceContractId')
            .toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
	
	  /**
     *  @author Sandeep Ram Ch.
     *  @description Fetch PM Offering associated with SP
     *  @param SP ids
     *  @return PM Offering
     **/
    public List<SVMXC__PM_Offering__c> selectPMOfferingsForServicePlan(Set<Id> setServicePlanId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPMOfferingsForServicePlan', UtilsCollection.serializeIds(setServicePlanId));
		
        List<SVMXC__PM_Offering__c> res= (List<SVMXC__PM_Offering__c>) Database.query(
            newQueryFactory().setCondition('SVMXC__Service_Plan__c IN : setServicePlanId')
            .toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
}