/**
 *    @author Raviteja Vakkalagadda 
 *    @date   18-11-2021
 *    @description    Class to get the Proactive Run Records records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Raviteja                 18-11-2021             Initial Version
 *    ------------------------------------------------------------------------------------ 
 */
public with sharing class ProactiveRunDetailSelector extends ilib_SObjectSelector{
    
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    private static final String LOG_TITLE = 'ProactiveRunDetailSelector';

    /**
     *  @author Raviteja Vakkalagadda 
     *  @description  
     *  @return SObjectType The Schema.SObjectType of the 
     */
    public Schema.SObjectType getSObjectType()
    {
        return Proactive_Run_Detail__c.sObjectType;
    }
    
    /**
     *  @author  Raviteja Vakkalagadda  
     *  @description Retrieve list of fields for Proative Run Detail sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     */
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
        return new List<Schema.SObjectField> {
           		Proactive_Run_Detail__c.id,
                Proactive_Run_Detail__c.Serial_Number__c,
                Proactive_Run_Detail__c.Proactive_Id__c,
                Proactive_Run_Detail__c.Run_ID__c,
                Proactive_Run_Detail__c.Environment__c

        };
    }

        
    /**
     *  @author Raviteja Vakkalagadda
     *  @description Fetch the PRD record based on the record Id passed
     *  @param PRD Ids
     *  
     *  @return List of Proactive Run Detail Records
     */
    public List<Proactive_Run_Detail__c> selectPRDRec(Id prdId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPRDRec', prdId);
        }

            List<Proactive_Run_Detail__c> res = (List<Proactive_Run_Detail__c>) Database.query(
                newQueryFactory()
                .selectField('id')
                .selectField('Serial_Number__c') // DCP-44003
                .selectField('Proactive_Id__c')
                .selectField('Run_ID__c')
                .selectField('Environment__c')
                .selectField('Product_Category__c')
                .selectField('Work_Order__c')
                .selectField('BS_Run_ID__c')
                .setCondition('ID =: prdId')
                .toSOQL()
            );    

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }

        return res;
    }

     /**
     *  @author Raviteja Vakkalagadda
     *  @description Fetch the PRD record based on the runId
     *  @param PRD Ids
     *  
     *  @return List of Proactive Run Detail Records
     */
    public List<Proactive_Run_Detail__c> selectPRDRecFromRunId(string runId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPRDRec', runId);
        }

            List<Proactive_Run_Detail__c> res = (List<Proactive_Run_Detail__c>) Database.query(
                newQueryFactory()
                .selectField('id')
                .selectField('Serial_Number__c') // DCP-44003
                .selectField('Proactive_Id__c')
                .selectField('Run_ID__c')
                .selectField('Environment__c')
                .selectField('Product_Category__c')
                .selectField('Work_Order__c')
                .setCondition('Run_ID__c =: runId')
                .toSOQL()
            );    

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }

        return res;
    }
    
}