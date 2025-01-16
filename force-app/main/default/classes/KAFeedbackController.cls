/**
 *    @author Monika
 *    @date   10-Nov-2020
 *    @description: Controller Class for LWC feedbackComponent  
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Monika Parihar              10-Nov-2020           Original version
 *    Adyasha Satapathy           17-Nov-2020           Added methods, Selector Class
 *    Adyasha Satapathy           03-Dec-2020           Removed File Upload Method
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class KAFeedbackController {  

    /*
    * @author Adyasha Satapathy
    * @params String strVoteType, String strKnowledgeArticleId, String strVoteId
    * @returns void
    */  
    @AuraEnabled
    public static Vote createVoteRecord(String strVoteType, String strKnowledgeArticleId, String strVoteId) {
        Vote  vt;
        try{
            if(String.isBlank(strVoteId) || strVoteId == NULL){
                vt = new Vote(ParentId = strKnowledgeArticleId,Type = strVoteType);
                insert vt; 
            }
            else{
                vt = new Vote(Id = strVoteId,Type = strVoteType);
                update vt;
            }
            return vt;
        }
        catch(Exception e){
            errorHandling(e);
            throw new AuraHandledException(e.getMessage()); 
        }
    }
  
    /*
    * @author Adyasha Satapathy
    * @params Id kaId
    * @returns String
    */    
    @AuraEnabled
    public static String fetchDetails(Id kaId){
        try{
            Knowledge__kav objKnowledge = new KnowledgeArticlesSelector().selectById(new Set<Id>{kaId}).get(0);
            Schema.DescribeFieldResult fieldResult = Feedback__c.Feedback_Reason__c.getDescribe();
            List<Schema.PicklistEntry> lstPicklist = fieldResult.getPicklistValues();
            List<Vote> lstVote = getLikeVoteCount(objKnowledge.KnowledgeArticleId);
            
            Map<String,String> mapLabels = new Map<String,String>{
                'UI_Message_Feedback_Submitted' => Label.Feedback_Submitted,
                'UI_Message_File_Attached' => Label.File_Attached,
                'UI_Message_Reason_Required' => Label.Reason_Required,
                'UI_Text_Additional_Feedback' => Label.FeedbackOptionAdditionalFeedback,
                'UI_Text_Feedback_Description' => Label.FeedbackDescription,
                'UI_Message_Feedback_Insufficient_Access_Error' => Label.FeedbackInsufficientAccessError,
                'UI_Message_Feedback_Description_Length_Error' => Label.FeedbackDescriptionLengthError,
                'UI_Text_Feedback_Reason_Helpful' => Label.FeedbackReasonHelpful,
                'UI_Text_Feedback_Status_Open' => Label.FeedbackStatusOpen,
                'UI_Text_Feedback_Disposition_New' => Label.FeedbackDispositionNew
            };
  
            return '{"knowledgeRecord": '+JSON.serialize(objKnowledge)+','
                    +'"feedbackReasonValues": '+JSON.serialize(lstPicklist)+','
                    +'"listVotes": '+JSON.serialize(lstVote)+','
                    +'"mapLabels": '+JSON.serialize(mapLabels)+'}';
        }
        catch(Exception e){
            errorHandling(e);
            throw new AuraHandledException(e.getMessage());
        }
    }
  
    /*
    * @author Adyasha Satapathy
    * @params Knowledge__kav knwldgeArticle
    * @returns List<Vote>
    */   
    @AuraEnabled
    public static List<Vote> getLikeVoteCount(Id knowledgeArticleId) { 
        List<Vote> vtList = new VotesSelector().selectByParentId(knowledgeArticleId);
        return  vtList;
    }
  
    /**
      *  @author Adyasha
      *  @description Error Handling 
      *  @param Exception
      **/
      public static void errorHandling(Exception e){
          System.debug(LoggingLevel.ERROR, 'Error at line        : ' + e.getLineNumber());
          System.debug(LoggingLevel.ERROR,'The following exception has occurred:++++getMessage+++ ' + e.getMessage());
          System.debug(LoggingLevel.ERROR,'Exception type caught : ' + e.getTypeName());
          System.debug(LoggingLevel.ERROR,'Cause                 : ' + e.getCause());
          System.debug(LoggingLevel.ERROR,'Stack trace           : ' + e.getStackTraceString());
      }
  }