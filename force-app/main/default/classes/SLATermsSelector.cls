/**
 *    @author Mandeep Singh
 *    @date   13-Sep-2018
 *    @description    Class to get the SLA Term records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Mandeep Singh              13-Sep-2018            Initial Version
 *    Prashanth                   24-Aug-2021           Added query instrumentation
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class SLATermsSelector extends ilib_SObjectSelector
{
    private static final String LOG_TITLE = 'SLATermsSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
   /**
    *  @author Mandeep
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the proposal
    **/
   public Schema.SObjectType getSObjectType()
   {
        return SVMXC__Service_Level__c.sObjectType;
   }
    
   /**
     *  @author  Mandeep
     *  @description Retrieve list of fields for SLA Term sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
       return new List<Schema.SObjectField> {
           SVMXC__Service_Level__c.id,
           SVMXC__Service_Level__c.Least_SLA__c
       };
    }
    
   /*
    * @author Mandeep Singh
    * @date   08-13-2018
    * @description  Fetch SLA Terms fields on basis of record Id.
    * @param setSLATermIds - Set of SLA Term IDs
    *
    */
    public List<SVMXC__Service_Level__c> selectSLATermsFromIds(Set<Id> setSLATermIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectSLATermsFromIds', UtilsCollection.serializeIds(setSLATermIds));
        }
        List<SVMXC__Service_Level__c> res =  (List<SVMXC__Service_Level__c>) Database.query(
            newQueryFactory().setCondition('Id IN :setSLATermIds').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;
    }
}