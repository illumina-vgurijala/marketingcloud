/**
* @author Shivani Jain
* @date 1st April 2022
*
* @description DCP-49914 Optimize WeChat case and follower management in SFDC
*/
public with sharing class ToggleUnreadEmailController {

    static final String COMMENT_TYPE_WECHAT = 'WeChat Comment'; 
    static final String CHARKET_USERNAME = 'Charket User'; 
    static final String LOG_TITLE = 'ToggleUnreadEmailController'; 

    /*******************************************************************************************************
    * @description method to check if Related We-Chat Comments are present
    * @param recordId Id 
    * @return Boolean
    */
	@AuraEnabled(cacheable=true)
    public static Boolean checkRelatedWeChatComments(Id recordId) {
        Set<String> typeSet = new Set<String> {COMMENT_TYPE_WECHAT};

        try {
            List<Comment__c> lstCommentRecords 
                = new CommentsSelector()
                .selectCommentsSpecificCaseIdsTypeUser
                	(new Set<Id>{recordId}, 
                 		typeSet, CHARKET_USERNAME);                                 
            return !lstCommentRecords.isEmpty();
        } catch(Exception ex) {
            ApexExceptions.emit(LOG_TITLE, recordId, ex);
            throw  new AuraHandledException(ex.getMessage());
        }
    }
}