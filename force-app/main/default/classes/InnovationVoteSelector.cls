/**
*    Description - Selector class to query Innovation Votes object records 
*    Modification Log:
*   ------------------------------------------------------------------------------------------------------------
*    Developer                      Date                		Description
*    Rishab Wali                    29th Aug 2022               DCP-56319 Like Dislike Fucntionality 
*    -----------------------------------------------------------------------------------------------------------
*/
public with sharing class InnovationVoteSelector extends ilib_SObjectSelector{
    private static final String LOG_TITLE = 'InnovationVoteSelector';
    private static final String MARKETING_QUERY_LOGS = 'MarketingQueryLogs';

   /*
    * @author 
    * @date   18-Aug-2022   
    * @description  set select fields
    */
    public List<Schema.SObjectField> getSObjectFieldList()
    {   
        return new List<Schema.SObjectField> {

            innohub__Innovation_Idea_Vote__c.CreatedById,
            innohub__Innovation_Idea_Vote__c.innohub__Vote_Type__c,
            innohub__Innovation_Idea_Vote__c.innohub__Innovation_Idea__c
            
        };
    }


    /*
    * @author 
    * @date   18-Aug-2022 
    * @description  describe the object
    *
    */
    public Schema.SObjectType getSObjectType()
    { 
        return innohub__Innovation_Idea_Vote__c.sObjectType;
    }
    
		  
    /**
     * @author : 
     * @description return all InnovationVote by 
     * Returns  
     **/    
    public List<innohub__Innovation_Idea_Vote__c> getInnovationIdeaVote(Id ideaId, Id userId) {        
        ilib_LogQuery logger = null;
        if (Feature.isOn(MARKETING_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.getInnovationIdeaVote() ',ideaId);
        }
        List<innohub__Innovation_Idea_Vote__c> res = (List<innohub__Innovation_Idea_Vote__c>)Database.query(
            newQueryFactory().selectField('CreatedById')
            .selectField('innohub__Vote_Type__c')
            .selectField('innohub__Innovation_Idea__c')                            
            .setCondition('innohub__Innovation_Idea__c =:ideaId and CreatedById =: userId')
            .toSOQL()
        );        
        if(Feature.isOn(MARKETING_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }
}
