/**
 *    @author Charket
 *    @date   
 *    @description : Class for updating Comment
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                  Description
 *    Charket                       13-Oct-2023          Added query selector 
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class CharketServiceUpdateLogic implements ilib_AdminOperationLogicInterface{
    private static final String LOG_TITLE = 'CharketServiceUpdateLogic';
    private static final String COMMENT_TYPE = 'Illumina Comment';
    private static final String WECHAT_RECORD_TYPE_NAME = 'Case - WeChat';

     /**
     *  @author       : Charket
     *  @description  : Update Comment's Customer Read Date Time by Guest User using platform event
     *  @return       : void
     */
    public static void doBusinessLogic(List<Id> caseIds){
        ilib_LogEvent.push(LOG_TITLE + '.execute()');
        try{
            String recordTypeId = Schema.SObjectType.Comment__c.getRecordTypeInfosByName().get(WECHAT_RECORD_TYPE_NAME).getRecordTypeId();
            List<Comment__c> updateComments = new CharketSelector().selectUnreadWeChatCommentByCaseId(caseIds, COMMENT_TYPE, recordTypeId); 
                
            if(!updateComments.isEmpty()){
                for(Comment__c comment : updateComments){
                    comment.Customer_Read_Date_Time__c = Datetime.now();
                }
                
                update updateComments;
            }
        }catch(Exception e){
            ApexExceptions.emit(LOG_TITLE,e);
        }
        ilib_LogEvent.pop();
    ilib_LogEvent.emit();
    }
}