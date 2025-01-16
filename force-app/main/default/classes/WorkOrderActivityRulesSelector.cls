/**
*    @author Raja Siva Krishna
*    @date   2020-11-19
*    @description    DCP-43185: WorkOrderActivityRulesSelector class from work order activity rule object
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*             Developer                      Date                Description
*    ------------------------------------------------------------------------------------
*             Siva                   19/11/2020          Initial Version
*           Prashanth                18/08/2021           Modified
*                    
*/
public with sharing class WorkOrderActivityRulesSelector extends ilib_SObjectSelector {
    private static final String LOG_TITLE = 'WorkOrderActivityRulesSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    /**
    *  @author Raja Siva Krishna
    *  @return SObjectType The Schema.SObjectType of the Work_Order_Activity_Rules__c
    **/
    public Schema.SObjectType getSObjectType()
    {
        return Work_Order_Activity_Rules__c.sObjectType;
    }
    
    /**
    *  @author  Raja Siva Krishna
    *  @description Retrieve list of fields for Work_Order_Activity_Rules__c 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Work_Order_Activity_Rules__c.id,
            Work_Order_Activity_Rules__c.Document_Name__c
        }; 
            
    }

   /**
     *  @author Raja Siva Krishna
     *  @description Fetch List of uploaded document names
     *  @param  Id
     *  @return Work_Order_Activity_Rules__c
     **/
    @AuraEnabled(cacheable=true)
    public Static Work_Order_Activity_Rules__c getWorkOrderActivityRuleById(Id recId) 
    {
        try{
            return new WorkOrderActivityRulesSelector().getWorkOrderActivityRuleByIds(recId);
        }catch(Exception e){
            //get exception message
            throw new AuraHandledException(e.getMessage());
            
        }
    } 

    /**
     *  @author Raja Siva Krishna
     *  @description Fetch work order activity rule by id
     *  @param  Id
     *  @return Work_Order_Activity_Rules__c
     **/
    public Work_Order_Activity_Rules__c getWorkOrderActivityRuleByIds(Id recId) 
    {
        ilib_LogQuery logger=null;
		if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
			logger = new ilib_LogQuery(LOG_TITLE + '.getWorkOrderActivityRuleByIds', recId);
		}
        Work_Order_Activity_Rules__c res = (Work_Order_Activity_Rules__c)Database.query(
            newQueryFactory().setCondition('Id =:recId').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
			logger.stop();
		}
		return res;
    } 

    /**
     *  @author Raja Siva Krishna
     *  @description Fetch work order activity rule by id
     *  @param  list of activities, product id, product group 
     *  @return List<Work_Order_Activity_Rules__c>
     **/
    public List<Work_Order_Activity_Rules__c> getWorkOrderActivityRuleByConditions(List<String> activities,String productId, String productGrp) 
    {
        ilib_LogQuery logger=null;
		if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
			logger = new ilib_LogQuery(LOG_TITLE + '.getWorkOrderActivityRuleByConditions', UtilsCollection.serializeIds(new Set<String>(activities))+'|'+productId+'|'+productGrp);
		}
        List<Work_Order_Activity_Rules__c> res =  Database.query(
            newQueryFactory().setCondition('Active__c=True AND Activity_Type__c IN :activities AND (Product_Code__c=:productId OR Product_Group__c=:productGrp)').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
			logger.stop(res.size());
		}
		return res;
    } 

    /**
     *  @author Raja Siva Krishna
     *  @description Fetch work order activity rule by set of WD activities
     *  @param  set of activities 
     *  @return List<Work_Order_Activity_Rules__c>
     **/
    public List<Work_Order_Activity_Rules__c> getWorkOrderActivityRuleByAcitivity(set<String> activities) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
			logger = new ilib_LogQuery(LOG_TITLE + '.getWorkOrderActivityRuleByAcitivity', UtilsCollection.serializeIds(activities));
		}
        List<Work_Order_Activity_Rules__c> res = Database.query(
           newQueryFactory()
            .selectField('Activity_Type__c')
            .selectField('Product_Code__c')
            .selectField('Product_Group__c')
            .selectField('Required__c')
            .setCondition('Active__c=True AND Activity_Type__c IN :activities').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
			logger.stop(res.size());
		}
		return res;
    } 
    /**
     *  @author Raja Siva Krishna
     *  @description Fetch work order activity rule by set of WD activities
     *  @param  set of activities 
     *  @return List<Work_Order_Activity_Rules__c>
     **/
    public List<Work_Order_Activity_Rules__c> getActiveWorkOrderActivityRules() {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
			logger = new ilib_LogQuery(LOG_TITLE + '.getActiveWorkOrderActivityRules');
		}
        List<Work_Order_Activity_Rules__c> res = Database.query(
           newQueryFactory()
            .selectField('Activity_Type__c')
            .selectField('Product_Code__c')
            .selectField('Product_Group__c')
            .selectField('Required__c')
            .selectField('Is_Tool_Debrief_Mandatory__c')
            .selectField('Repair_Protocol__c')
            .setCondition('Active__c=True').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
			logger.stop(res.size());
		}
		return res;
    } 
}