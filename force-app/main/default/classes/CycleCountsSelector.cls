/**
 *    @author Soumya
 *    @date   02-04-2019
 *    @description    Class to get the cycle count records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                	Description
 *    Soumya Ranjan Sahu     		02-Apr-2019            Initial Version
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class CycleCountsSelector extends ilib_SObjectSelector
{

    private static final String LOG_TITLE = 'CycleCountsSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
	
	/**
     *  @author - Soumya
     *  @description - SObjectType The Schema.SObjectType of the Cycle Count
     **/

	public Schema.SObjectType getSObjectType()
   {
        return Cycle_Count__c.sObjectType;
   }


    /**
     *  @author  Soumya
     *  @description Retrieve list of fields for Cycle Count sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
       return new List<Schema.SObjectField> {
           Cycle_Count__c.id,
		   Cycle_Count__c.Name,
           Cycle_Count__c.Work_Order__c,
           Cycle_Count__c.OwnerId,
           Cycle_Count__c.Status__c,
           Cycle_Count__c.Field_Support__c,
           Cycle_Count__c.Inventory_Location__c
           
       };
    }

    /**
     *  @author Soumya
     *  @description Fetch Cycle Counts which are associated with set of Work Orders passed as parameter
     *  @return List of Cycle Counts
     **/
   public List<Cycle_Count__c> selectCycleCountWithWO(Set<Id> setWorkOrderIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCycleCountWithWO', UtilsCollection.serializeIds(setWorkOrderIds));

        List<Cycle_Count__c> res = (List<Cycle_Count__c>)Database.query(
            newQueryFactory().selectField('Work_Order__r.SVMXC__Order_Status__c')
            				 .setCondition('Work_Order__c IN : setWorkOrderIds').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
}