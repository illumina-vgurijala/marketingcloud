/**
* @author Shivani Jain  
* @date 1st April 2022
*
* @description DCP-49914 Optimize WeChat case and follower management in SFDC
*/
public with sharing class CommentsSelector extends ilib_SObjectSelector { 
    private static final String LOG_TITLE = 'CommentsSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    
    /*******************************************************************************************************
    * @description Retrieve Object type 
    * @return  Schema.SObjectType
    */
    public Schema.SObjectType getSObjectType() {
        return Comment__c.sObjectType;
    }

    /*******************************************************************************************************
    * @description Retrieve list of fields for Comment__c sObject 
    * @return List<Schema.SObjectField>
    */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            Comment__c.Type__c,
            Comment__c.CreatedBy.Name
        };
    }

    /*******************************************************************************************************
    * @description query comment records filtered by Case Ids, Type and Created user
    * @param setCaseIds Set<Id>
    * @param typeValues Set<String>
    * @param userName String
    * @return List<Comment__c>
    */
    public List<Comment__c> selectCommentsSpecificCaseIdsTypeUser(Set<Id> setCaseIds, Set<String> typeValues, String userName) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCommentsbyCaseSpecificTypes', UtilsCollection.serializeIds(setCaseIds));

        List<Comment__c> res = (List<Comment__c>) Database.query(
            newQueryFactory()
            .setCondition('Case__c IN : setCaseIds AND Type__c IN: typeValues AND CreatedBy.Name =: userName')
            .toSOQL()
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
                logger.stop(res.size());
    
        return res;
    }

    /*******************************************************************************************************
    * @description query comment records
    * @param setCommentIds Set<Id>
    * @return List<Comment__c>
    */
    public List<Comment__c> selectWeChatCommentsSpecificIds(Set<Id> setCommentIds) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWeChatCommentsSpecificIds', UtilsCollection.serializeIds(setCommentIds));

        List<Comment__c> res = (List<Comment__c>) Database.query(
            newQueryFactory()
            .selectField('Case__c')
            .setCondition('Id IN : setCommentIds AND Case__c != NULL')
            .toSOQL()
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
                logger.stop(res.size());
    
        return res;
    }

}