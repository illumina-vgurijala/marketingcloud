/**
 *    @author Digvijay
 *    @date   21-05-2019
 *    @description    Class to get the Work Order Resource records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Ritika                    21-May-2019             Initial Version
 *    Joshith k                 04-July-2019           Added Fields in selectWorkOrderResources
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
 
 
public with sharing class WorkOrderResourceSelector extends ilib_SObjectSelector
{
	private static final String LOG_TITLE = 'WorkOrderResourceSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
  /**
    *  @author Digvijay
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the proposal
    **/
   public Schema.SObjectType getSObjectType()
   {
        return SVMXC__Work_Order_Resource__c.sObjectType;
   }


 /**
     *  @author  Digvijay
     *  @description Retrieve list of fields for Case sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
       return new List<Schema.SObjectField> {
           SVMXC__Work_Order_Resource__c.id,
           SVMXC__Work_Order_Resource__c.Account__c,
           SVMXC__Work_Order_Resource__c.Contact__c,
           SVMXC__Work_Order_Resource__c.Primary__c,
           SVMXC__Work_Order_Resource__c.SVMXC__Preference_Type__c,
           SVMXC__Work_Order_Resource__c.Schedule_Date_Time__c,
           SVMXC__Work_Order_Resource__c.Subject__c,
           SVMXC__Work_Order_Resource__c.SVMXC__Group_Member__c,
           SVMXC__Work_Order_Resource__c.SVMXC__Work_Order__c,
           SVMXC__Work_Order_Resource__c.Work_Order_Status__c
       };
    }

    /**
     *  @author Digvijay 
     *  @description Fetch work order Resource associated with WorkOrder
     *  @param Work order ids
     *  @return work order Resource List
     **/
  public List<SVMXC__Work_Order_Resource__c> selectWorkOrderResources(Set<Id> setWorkOrderIds) 
   {	
	   	ilib_LogQuery logger=null;
		if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
			logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrderResources', UtilsCollection.serializeIds(setWorkOrderIds));
		}
		List<SVMXC__Work_Order_Resource__c> res = Database.query(
           newQueryFactory().selectField('SVMXC__Group_Member__c').selectField('Id').selectField('Primary__c')
            .selectField('SVMXC__Group_Member__r.SVMXC__Active__c')
            .selectField('SVMXC__Group_Member__r.SVMXC__Salesforce_User__c')
            .selectField('SVMXC__Group_Member__r.SVMXC__Salesforce_User__r.FederationIdentifier')
            .selectField('SVMXC__Group_Member__r.SVMXC__Salesforce_User__r.Alias')
            .setCondition('SVMXC__Work_Order__c IN : setWorkOrderIds').toSOQL()
        );
		if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
			logger.stop(res.size());
		}
		return res;
   }

}