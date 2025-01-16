/**
 *    @author Tapas C
 *    @date   22-May-2020
 *    @description    Class to get the Knowledge Articles records based on different conditions
 *    Modification Log:
 *    -------------------------------------------------------------------------------------------------------------
 *    Developer              Date                    Description
 *    Tapas                  22-May-2020             Initial Version
 *    Adyasha Satapathy      20-Nov-2020             Added new fields and selectById() as part of DCP: 43356  
 *    Kushagra Desai         26-Nov-2020             DCP-43372 : Added selectArticleByTitleExcludedList
 *    Kushagra Desai         4-Dec-2020              DCP-43374 : Add field to getSObjectFieldList
 *    Sarath Pullanikkatt    17-Apr-2021             TASK0580795 : New selector selectArticleByDocumentNumber()
 *    Gladis                 16-Sept-2021            CMCP-98 Knowledge Article Approval for CP and added instrumentation.
 *    Gladis                 10-June-2022            DCP- 54039 Added method selectPublishedKnowledgeArticles, to get Billable published articles.
 *    Gladis                 20-Sep-2022             Added Query Instrumentation
 *    ------------------------------------------------------------------------------------------------------------- 
 *                    
 */
public with sharing class KnowledgeArticlesSelector extends ilib_SObjectSelector
{
    private static final string  LOG_TITLE = 'KnowledgeArticlesSelector';
    private static final  string SERVICE_QUERY_LOGS = 'ServiceQueryLogs';

   /**
    *  @author Tapas C
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the proposal
    **/
   public Schema.SObjectType getSObjectType()
   {
        return Knowledge__Kav.sObjectType;
   }
    
    /**
     *  @author  Tapas C
     *  @description Retrieve list of fields for Knowledge__Kav sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
       return new List<Schema.SObjectField> {
           Knowledge__Kav.id,
           Knowledge__Kav.Article_Categories__c,
           Knowledge__Kav.Title, //DCP: 43356  
           Knowledge__Kav.KnowledgeArticleId, //DCP: 43356
           Knowledge__Kav.Knowledge_Source__c,
           Knowledge__Kav.LastModifiedDate,
           Knowledge__Kav.Primary_WorkFlow__c,//DCP 43373
           Knowledge__Kav.Secondary_Workflow__c, //DCP 43373
           Knowledge__Kav.RecordTypeId,
           Knowledge__Kav.External_Content_ID__c,
           Knowledge__kav.Document_Number__c,
           Knowledge__Kav.TeamSite_ID__c,
           Knowledge__Kav.Link_to_External_Content__c,
           //DCP-54039 starts
           Knowledge__Kav.Summary,
           Knowledge__Kav.ArticleNumber,
           Knowledge__Kav.Language,
           Knowledge__Kav.Title 
           //DCP-54039 ends

       };
    }
    /*  
    * @description  Related select field
    */
    private ilib_QueryFactory getRelatedFieldsQuery(){
        return newQueryFactory()
            .selectField('RecordType.Name');
    }
    /*
     * @author Tapas C
     * @params ListKnowledgeIds and ValidationStatus and Review_Status__c
     * @returns List<Knowledge__Kav>
     */
    public List<Knowledge__Kav> selectlKnowledgeRecordsByValidationAndReviewStatuses(List<Id> lstKnowledgeIds, String strValidationStatus, String reviewStatus){
        
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + 'selectlKnowledgeRecordsByValidationAndReviewStatuses', strValidationStatus);
        }
        
        List<Knowledge__Kav> res = (List<Knowledge__Kav>) Database.query(
            newQueryFactory()
            .setCondition('ID  IN : lstKnowledgeIds ' + 
                                            '  AND ValidationStatus =: strValidationStatus ' + 
                                            ' AND Review_Status__c =: reviewStatus').toSOQL()
        );
        
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }
    /*
    * @author Adyasha Satapathy
    * @params Set<Id> idSet
    * @returns List<Knowledge__Kav>
    */
    public List<Knowledge__Kav> selectById(Set<Id> idSet) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + 'selectById', UtilsCollection.serializeIds(idSet));
        }
            

        List<Knowledge__Kav> res = (List<Knowledge__Kav>) Database.query(
            newQueryFactory()
            .selectField('Knowledge_Source__c')//CMCP-98
            .selectField('Enable_for_CP__c')//CMCP-98
            .selectField('PublishStatus')//CMCP-98
            .selectField('ValidationStatus')//CMCP-98
            .selectField('KnowledgeArticleId')//CMCP-98
            .selectField('CP_Article_Approval_Status__c')//CMCP-98
            .selectField('Review_Status__c')//CMCP-98
            .setCondition('Id IN :idSet')
            .toSOQL());

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }

    /*
    * @author : KD
    * @Description : Get article based on title and excluded list
    * @params Set<Id> idSet
    * @returns List<Knowledge__Kav>
    */
    public List<Knowledge__Kav> selectArticleByTitleExcludedList(String strSearchKey,Set<Id> idSet)
    {
        String strPublishStatus = 'Online';
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + 'selectArticleByTitleExcludedList', strSearchKey);
        }
        
        List<Knowledge__Kav> res = (List<Knowledge__Kav>) Database.query(
            getRelatedFieldsQuery()
            .setCondition('Title LIKE:strSearchKey and Id NOT IN:idSet and PublishStatus=: strPublishStatus')
            .toSOQL());
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }   

        return res;    
    }
    /*
    * @author : KD
    * @Description : Get article based on content
    * @params Content Id
    * @returns List<Knowledge__Kav>
    */
    public List<Knowledge__Kav> selectArticleByContentId(String strContentId,String strPublishStatus)
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + 'selectArticleByContentId', strContentId);
        }
        
        List<Knowledge__Kav> res = (List<Knowledge__Kav>) Database.query(
            getRelatedFieldsQuery()
            .setCondition('External_Content_ID__c =:strContentId and PublishStatus=: strPublishStatus')
            .toSOQL());
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }   

        return res; 
    }

    /*
     * @author : Sarath Pullanikkatt
     * @Description : Get articles based on the document number and publish status.
     * @params Document Number, Publish Status
     * @returns List<Knowledge__Kav>
	 * Added additional check for Knowledge Source for INC0323291 by Shruti Karn
     */
    public List<Knowledge__Kav> selectArticleByDocumentNumber(String strDocumentNumber, String strPublishStatus)
    {
        String knowledgeSource ='ICE';
		ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + 'selectArticleByDocumentNumber', strDocumentNumber);
        }
        
        List<Knowledge__Kav> res = (List<Knowledge__Kav>) Database.query(
            getRelatedFieldsQuery()
            .setCondition('Document_Number__c = :strDocumentNumber AND PublishStatus = :strPublishStatus AND Knowledge_Source__c = :knowledgeSource')
            .toSOQL());

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }   

        return res;   
    }
    
     /*
     * @author : Gladis CMCP-98
     * @Description : Get articles based on KnowledgeArticleId.
     * @params Set of KnowledgeArticleIds
     * @returns List<Knowledge__Kav>
     */
    public List<Knowledge__Kav> selectArticlesByKnowledgeArticleIds(Set<Id> setKnowledgeArticleIds) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + 'selectArticlesByKnowledgeArticleIds', UtilsCollection.serializeIds(setKnowledgeArticleIds));
        }

        List<Knowledge__Kav> res = (List<Knowledge__Kav>) Database.query(
            newQueryFactory()
            .selectField('Knowledge_Source__c')
            .selectField('Enable_for_CP__c')
            .selectField('PublishStatus')
            .selectField('ValidationStatus')
            .selectField('KnowledgeArticleId')
            .selectField('CP_Article_Approval_Status__c')
            .selectField('Review_Status__c')
            .selectField('Primary_Approver__c')
            .selectField('Secondary_Approver__c')
            .setCondition('KnowledgeArticleId IN :setKnowledgeArticleIds')
            .toSOQL());

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }   

        return res;
    }

    /*
     * @author : Gladis
     * @Description : DCP- 54039 method to get Billable published articles.
     * @returns List<Knowledge__Kav>
    */
    public List<Knowledge__Kav> selectPublishedKnowledgeArticles(String strKeyWord) {
        String strPublishStatus ='Online';
		ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + 'selectPublishedKnowledgeArticles', strKeyWord);
        }

        List<Knowledge__Kav> res = (List<Knowledge__Kav>) Database.query(
            getRelatedFieldsQuery()
            .setCondition('Title LIKE \'%'+strKeyWord+'%\' and PublishStatus = :strPublishStatus')
            .toSOQL());

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }   

        return res;    
    }
}