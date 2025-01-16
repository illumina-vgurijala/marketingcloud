/**
* @author Deepika Ayyavari
* @date 31-Aug-2021
*
* @group EmailMessage
* @group-content 
*
* @description Apex Class to send Case related Emails to LWC component.
* DCP-43125
*/
public class EmailRelatedListController {
    /* @description Method to get the EmailMessages related to Case
    * @param caseId parameter which holds the case Id
    * @return returns the emailmessages related to case
      
    */
    @AuraEnabled
    public static List<EmailMessage> getRecords(Integer offSetCount, Id caseId) {
        try{
            List<EmailMessage> emailRelatedList = new List<EmailMessage>();
            set<Id> setCaseIds = new set<Id>();
            setCaseIds.add(caseId);
            if (String.isNotBlank(caseId)) {
            
                //fetch email messages based on case Id
                emailRelatedList = new List <EmailMessage> (new EmailMessagesSelector().selectEmailMsgByParentId(offSetCount, setCaseIds
                ));
                system.debug('emailRelatedList:' +emailRelatedList);
            } 
            return emailRelatedList;
        }
        catch(Exception e){
            //get exception message
            throw new AuraHandledException(e.getMessage()); 
        }
    }    
    
}