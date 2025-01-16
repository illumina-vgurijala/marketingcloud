/**
* @author Shivani Jain
* @date 31st March 2022
*
* @description DCP-49914 Class to update WeChat cases Unread Email toggle 
*                        when Comment is inserted by Charket User
*/
public with sharing class UpdateWeChatCases_CommentManager implements ilib_AdminOperationLogicInterface {

    private static final String LOG_TITLE = 'UpdateWeChatCases_CommentManager';

    /*******************************************************************************************************
    * @description DCP-49914 Interface method
    * @param lstCaseIds List<Id>
    */
    public static void doBusinessLogic(List<Id> lstCaseIds) {
        updateUnreadEmailsCheckboxOnCase(lstCaseIds);
    }

    /*******************************************************************************************************
    * @description DCP-49914 Logic to update Unread Emails checkbox on the cases
    * @param setUnreadEmailsCaseIds set of Case Ids to update
    */
    private static void updateUnreadEmailsCheckboxOnCase(List<Id> setUnreadEmailsCaseIds){
        List<Case> lstCasesToUpdate = new List<Case>();

        for(Id caseId : setUnreadEmailsCaseIds){
            Case cs = new Case(Id = caseId);
            cs.Unread_Emails__c = true;
            lstCasesToUpdate.add(cs);
        }
        if(!lstCasesToUpdate.isEmpty()) {
            List<Database.SaveResult> srListCases = Database.update(lstCasesToUpdate, false);
            ApexExceptions.emitSaveErrors(srListCases, LOG_TITLE);
        }
    }
}