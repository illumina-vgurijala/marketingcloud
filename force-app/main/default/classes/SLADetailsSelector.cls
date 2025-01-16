/**
 *    @author Mandeep Singh
 *    @date   13-Sep-2018
 *    @description    Class to get the SLA Detail records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Mandeep Singh              13-Sep-2018            Initial Version
 *    Prashanth                  24-Aug-2021            Added query instrumentation.
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class SLADetailsSelector extends ilib_SObjectSelector
{
    private static final String LOG_TITLE = 'SLADetailsSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
   /**
    *  @author Mandeep
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the proposal
    **/
   public Schema.SObjectType getSObjectType()
   {
        return SVMXC__SLA_Detail__c.sObjectType;
   }
    
   /**
     *  @author  Mandeep
     *  @description Retrieve list of fields for SLA Detail sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
       return new List<Schema.SObjectField> {
           SVMXC__SLA_Detail__c.id,
           SVMXC__SLA_Detail__c.SVMXC__Customer_Commitment__c,
           SVMXC__SLA_Detail__c.SVMXC__SLA_Terms__c
       };
    }
    
     /**
     *  @author  Mandeep
     *  @description Define ordering of records
     *  @return String 
     **/
    public override String getOrderBy(){
      return 'SVMXC__Customer_Commitment__c ASC';
    }
   
   /*
    * @author Mandeep Singh
    * @date   08-13-2018
    * @description  Fetch SLA Details fields on basis of SLA Term Ids.
    * @param setSLATermIds - Set of SLA Term IDs
    *
    */
    public List<SVMXC__SLA_Detail__c> selectSLADetailsFromSLATermIds(Set<Id> setSLATermIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectSLADetailsFromSLATermIds', UtilsCollection.serializeIds(setSLATermIds));
        }
        List<SVMXC__SLA_Detail__c> res =  (List<SVMXC__SLA_Detail__c>) Database.query(
            newQueryFactory().setCondition('SVMXC__SLA_Terms__c IN :setSLADetailIds').setCondition('SVMXC__Commitment_Type__c = \'InitialResponse\'').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }

        return res;
    }
}