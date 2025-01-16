/**
* @author Saptarshi  
*
* @description QACM-175 Case Comment Selector class 
*/
public with sharing class CaseCommentSelector extends ilib_SObjectSelector { 
    private static final String LOG_TITLE = 'CaseCommentSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    
    /*******************************************************************************************************
    * @description Retrieve Object type 
    * @return  Schema.SObjectType
    */
    public Schema.SObjectType getSObjectType() {
        return CaseComment.sObjectType;
    }

    /*******************************************************************************************************
    * @description Retrieve list of fields for CaseComment sObject 
    * @return List<Schema.SObjectField>
    */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            CaseComment.Id,
            CaseComment.CommentBody,
            CaseComment.CreatedByID,
            CaseComment.IsPublished,
            CaseComment.CreatedDate,
            CaseComment.ParentId

        };
    }

    /*******************************************************************************************************
    * @description fetch caseComment records for a specific Case
    * @param CaseId String
    * @return List<CaseComment>
    */
    public List<CaseComment> selectCaseComments(String caseId) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCaseComments', caseId);

             String strQuery = newQueryFactory()
            .selectField('Id')
            .selectField('CreatedBy.Name')
            .selectField('IsPublished')
            .selectField('CommentBody')  
            .selectField('CreatedDate')  
            .setCondition('ParentId = : caseId')
            .toSOQL();

        List<CaseComment> res = (List<CaseComment>) Database.query(strQuery);
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;
    }
}