/**
*    @author: Deep Diwakar
*    @date:   Oct-05-2024
*    @description:  Selector class for IdeaArticle object
*    @Test Class: TestIdeaKnowledgeController
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*           Deep Diwakar                  Oct-05-2024       CMCM-10147: Selector class for IdeaArticle object
*    ------------------------------------------------------------------------------------ 
*                    
*/

public with sharing class IdeaArticlesSelector extends ilib_SObjectSelector {

    private static final String LOG_TITLE = 'IdeaArticlesSelector';
    private static final String MKTG_FEATURE_FLAG = 'MarketingQueryLogs';


    /**
    *  @author  Deep Diwakar
    *  @description Sets up object type at parent level
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public Schema.SObjectType getSObjectType() {
        return IdeaArticle__c.sObjectType;
    }

    /**
    *  @author  Deep Diwakar
    *  @description Sets up default fields that are returned when any method of this selector is called
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            IdeaArticle__c.Id
        };
    }

    /**
     * @author     : Deep Diwakar
     * @param      : Set of KAV Ids
     * @return     : List of IdeaArticle records
     * @Description: This method returns the list of IdeaArticle records filtered by set of KAV Ids
    **/
    public List<IdeaArticle__c> selectIdeaArticlesByKavId (Set<Id> setKavIds) {
        ilib_LogQuery logger = null;

        if (Feature.isOn(MKTG_FEATURE_FLAG)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectIdeaArticlesByKavId',UtilsCollection.serializeIds(setKavIds));
        }

        List<IdeaArticle__c> res = (List<IdeaArticle__c>) Database.query(newQueryFactory()
                                                    .selectField('Idea_Innohub__c')
                                                    .selectField('Knowledge__c')
                                                    .selectField('Case__c')
                                                    .setCondition('Knowledge__c IN : setKavIds')
                                                    .setLimit(2000)
                                                    .toSOQL());
                                                                                            
        if (Feature.isOn(MKTG_FEATURE_FLAG)) {
            logger.stop(res.size());
        }

        return res;

    }

    /**
     * @author     : Deep Diwakar
     * @param      : Set of KAV Ids
     * @param      : Set of Idea Ids
     * @return     : List of IdeaArticle records
     * @Description: This method returns the list of IdeaArticle records filtered by set of KAV Ids and set of Idea Ids
    **/
    public List<IdeaArticle__c> selectIdeaArticlesByKavAndIdeaIds (Set<Id> setKavIds, Set<Id> setIdeaIds) {
        ilib_LogQuery logger = null;

        if (Feature.isOn(MKTG_FEATURE_FLAG)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectIdeaArticlesByKavAndIdeaIds',UtilsCollection.serializeIds(setKavIds));
        }

        List<IdeaArticle__c> res = (List<IdeaArticle__c>) Database.query(newQueryFactory()
                                                    .selectField('Idea_Innohub__c')
                                                    .selectField('Knowledge__c')
                                                    .selectField('Case__c')
                                                    .setCondition('Knowledge__c IN : setKavIds AND Idea_Innohub__c IN : setIdeaIds')
                                                    .toSOQL());
                                                                                            
        if (Feature.isOn(MKTG_FEATURE_FLAG)) {
            logger.stop(res.size());
        }

        return res;

    }

}