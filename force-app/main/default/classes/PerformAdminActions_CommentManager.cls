/**
* @author Shivani Jain
* @date 8th April 2022
*
* @description DCP-49914 Class to update Post Chatter field to trigger notifiction for we chat comments
*/
public with sharing class PerformAdminActions_CommentManager implements ilib_AdminOperationLogicInterface {

    private static final String LOG_TITLE = 'PostChatterWeChatCase_CommentManager';

    /*******************************************************************************************************
    * @description DCP-49914 Interface method
    * @param lstCommentIds List<Id>
    */
    public static void doBusinessLogic(List<Id> lstCommentIds) {
        triggerChatterPostOnComment(lstCommentIds);
    }

    /*******************************************************************************************************
    * @description DCP-49914 Logic to update Post Chatter field on Comment
    * @param lstCommentIds list of comment Ids
    */
    private static void triggerChatterPostOnComment(List<Id> lstCommentIds){
        List<Comment__c> lstCommentsToUpdate = new List<Comment__c>();

        for(Id commentId : lstCommentIds){
            Comment__c comment = new Comment__c(Id = commentId);
            comment.Perform_Actions_as_Admin__c = true;
            lstCommentsToUpdate.add(comment);
        }
        if(!lstCommentsToUpdate.isEmpty()) {
            List<Database.SaveResult> srListComments = Database.update(lstCommentsToUpdate, false);
            ApexExceptions.emitSaveErrors(srListComments, LOG_TITLE);
        }
    }
}