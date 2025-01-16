/**
 * @author Vignesh S 
 * @description  Query Selector for Qualtrics Survey Response Share.
 * Modification Log:
*  ------------------------------------------------------------------------------------ 
*   Developer                Date                Description                                                 
*   Vignesh S                09-Jun-2020         Initial version
*   Prashanth                24-Aug-2021         Added Query Instrumentation
*  -----------------------------------------------------------------------------------          
*/
public with sharing class QualtricsSurveyResponseShareSelector extends ilib_SObjectSelector {
    private static final String LOG_TITLE = 'QualtricsSurveyResponseShareSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
	
    /**
    *  @author Prashantth
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the PM Plan
    **/
    public Schema.SObjectType getSObjectType()
    {
        return Qualtrics_Survey_Response__Share.sObjectType;
    }
	
     /**
     *  @author  prashanth
     *  @description Retrieve list of fields for Qualtrics survey reponse sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/ 
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
           Qualtrics_Survey_Response__Share.ParentId,
           Qualtrics_Survey_Response__Share.UserOrGroupId,
           Qualtrics_Survey_Response__Share.AccessLevel,
           Qualtrics_Survey_Response__Share.RowCause
       };
    }

    /*
    Author : Vignesh
    Description : Method to Query Share Records with Parent Id.
    */
    public List<Qualtrics_Survey_Response__Share> getShareRecordsWithParentId(Set<Id> setQSRIds, List<Id> lstUserOrGroupId, String manualRowCause){
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.getShareRecordsWithParentId', UtilsCollection.serializeIds(setQSRIds)+'|'+ UtilsCollection.serializeIds(new Set<Id>(lstUserOrGroupId))+'|'+manualRowCause);
        }
        List<Qualtrics_Survey_Response__Share> res = (List<Qualtrics_Survey_Response__Share>)Database.query(
            newQueryFactory(true)
            .setCondition('ParentId IN :setQSRIds AND UserOrGroupId IN :lstUserOrGroupId AND RowCause = :manualRowCause')
            .toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;
    }
}