/**
*    Description - Controller class for LWC IdeaLikeDislikeComponent
*    Modification Log:
*   ------------------------------------------------------------------------------------------------------------
*    Developer                      Date                		Description
*    Rishab Wali                    29th Aug 2022               DCP-56319 Like Dislike Fucntionality 
*    -----------------------------------------------------------------------------------------------------------
*/
public with sharing class IdeaLikeDislikeComponentController {

    private static final String LOG_TITLE = 'IdeaLikeDislikeComponentController';    

    /**
    * @description method to check user liked or disliked
    * @param Id ideaId
    * @return Boolean
    **/
    @AuraEnabled(cacheable=true)
    public static Boolean ideaLiked(Id ideaId){
        try {
            ilib_LogEvent.push(LOG_TITLE +'.ideaLiked');  
            ilib_LogEvent.message('ideaId-->'+ideaId);
            ID userId = UserInfo.getUserId();                  
            List<innohub__Innovation_Idea_Vote__c> ideaList=new InnovationVoteSelector().getInnovationIdeaVote(ideaId, userId);
            ilib_LogEvent.message('ideaList-->'+ideaList);
            ilib_LogEvent.pop();
            if(!ideaList.isEmpty()){
                return ideaList[0].innohub__Vote_Type__c;
            }
            else{
                return false;
            }                        
            
        } catch (Exception e) { ApexExceptions.emit(LOG_TITLE, e); throw new AuraHandledException(e.getMessage()); }
    }

    /**
    * @description method to update the vote
    * @param Boolean vote, Id ideaId
    **/
    @AuraEnabled
    public static void updateVote(Boolean vote, Id ideaId){
       try{
        ilib_LogEvent.push(LOG_TITLE +'.updateVote');  
        ilib_LogEvent.message('vote and ideaId-->'+vote+' '+ideaId);      
        ID userId = UserInfo.getUserId();        
        List<innohub__Innovation_Idea_Vote__c> ideaList=new InnovationVoteSelector().getInnovationIdeaVote(ideaId, userId);
            if(!ideaList.isEmpty()){
                ideaList[0].innohub__Vote_Type__c = vote;
                update ideaList[0];
            }
            else{
                innohub__Innovation_Idea_Vote__c ideaVote = new innohub__Innovation_Idea_Vote__c();
                ideaVote.innohub__Innovation_Idea__c = ideaId;
                ideaVote.innohub__Vote_Type__c = vote;
                insert ideaVote;
            }
            ilib_LogEvent.message('ideaList-->'+ideaList);                                            
            ilib_LogEvent.pop();
        }
        catch (Exception e) { ApexExceptions.emit(LOG_TITLE, e); throw new AuraHandledException(e.getMessage()); }
    }
    
}