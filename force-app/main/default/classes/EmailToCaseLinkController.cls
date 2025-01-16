/****************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************
* NAME         : EmailToCaseLinkController
* DESCRIPTION  : DCP - 25239 : Associate an EmailMessage record to an exisiting Case.
* @AUTHOR      : 
* @DATE        : 15-May-2019  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------

********************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************/
public with sharing class EmailToCaseLinkController {

  public static final String EMAIL_TRANSFERRED_IN_FROM = 'Copied in from ';
  public static final String EMAIL_TRANSFERRED_OUT_TO = 'Copied to ';

  /*
      *  @author Vaibhav Parashar
      *  @description - Associates the current in context email message to the selected case from "Move to Existing Case"
                        button placed on Email Message record layout.
      *  @PARAM :  Map < String, String > caseIdToEmailMessageId
      *  @RETURN:  String
      */
  @AuraEnabled
  public static String moveToExisitingCase(Map < String, String > caseIdToEmailMessageId) {

    /* APEX VARIABLES */
    Set < String > setEmailMessageId = new Set < String > (); // store the emailMessageRecordId coming from lightning component.
    List < EmailMessage > lstEmailMessageToInsert = new List < EmailMessage > (); // list to insert new email message records.
    List < String > lstCaseIds = new List < String > (); // store caseIDs in a list.
    String processingMessage = ''; //store any exception message.
    String currentRefId = ''; // get the current ref id from the text body.

    //DCP-34276
    List < ContentDocumentLink > lstNewAttachmentFiles = new List < ContentDocumentLink > ();
    //store a map with emailMessageId to list of attachments
    Map < Id, List < ContentDocumentLink >> emailMessageIdToAttachmentsLst = new Map < Id, List < ContentDocumentLink >> ();


    try {

      
        //store the emailMessageRecordId and caseId
        for (String caseRecsId: caseIdToEmailMessageId.keyset()) {
          setEmailMessageId.add(caseIdToEmailMessageId.get(caseRecsId));
          lstCaseIds.add(caseRecsId);
        }

        //get the current email message record based on the Id, this record will eventually be cloned.
        EmailMessage eMsg = new EmailMessagesSelector().selectEmailMessages(setEmailMessageId);

        //DCP-34276 - check if the original email message has an attachment
        emailMessageIdToAttachmentsLst.put(eMsg.Id, new List < ContentDocumentLink > ());
        for (ContentDocumentLink att: [Select ContentDocument.title, ContentDocumentId, LinkedEntityId from ContentDocumentLink where LinkedEntityId =: eMsg.Id]) {
          emailMessageIdToAttachmentsLst.get(eMsg.Id).add(att);
        }

        //clone the exisiting message record and set the fields accordingly.    
        EmailMessage clonedEmailMessage = eMsg.clone();

        //associate the email message with the new case id.
        clonedEmailMessage.Email_Transfer_Status__c = EMAIL_TRANSFERRED_IN_FROM + '<a href=/' + clonedEmailMessage.RelatedToId + '>' + new CasesSelector().selectCasesFromSetIds(new set < Id > {
          clonedEmailMessage.RelatedToId
        })[0].CaseNumber + '</a>';
        clonedEmailMessage.RelatedToId = lstCaseIds[0];
        clonedEmailMessage.ParentId = lstCaseIds[0];
		//get the existing refrence id from the textBody. It will be changed to the new case id below.
        if (String.isNotBlank(clonedEmailMessage.TextBody)) {
          currentRefId = clonedEmailMessage.TextBody.substringBetween('ref:_');
        }
        If(clonedEmailMessage.HtmlBody != null && clonedEmailMessage.HtmlBody.length() >= 131072){
           clonedEmailMessage.HtmlBody = '';
        } 
        If(clonedEmailMessage.HtmlBody != null && clonedEmailMessage.HtmlBody.length() <= 131072){
          String currentHTMLBody = clonedEmailMessage.HtmlBody;
          // Find the substring between "thread::" and "::"
          String extractedThreadID = currentHTMLBody.substringBetween('thread::', '::');
          // Remove the "thread::" from the currentHTMLBody and replace it with extractedThreadID
          String hTMLBodyWithoutThreadID = currentHTMLBody.replace('thread::' + extractedThreadID + '::', ' ');
          clonedEmailMessage.HtmlBody = hTMLBodyWithoutThreadID;
        }
        if (String.isNotBlank(currentRefId)) {
          //update text body to change reference Id.
          clonedEmailMessage.TextBody = String.isNotBlank(clonedEmailMessage.TextBody) ? clonedEmailMessage.TextBody.replace('ref' + currentRefId + 'ref', getThreadId(lstCaseIds[0])) : '';
          //Update Subject to change reference Id.
          clonedEmailMessage.Subject = String.isNotBlank(clonedEmailMessage.Subject) ? clonedEmailMessage.Subject.replace('[ ref' + currentRefId + 'ref ]', '[ ' + getThreadId(lstCaseIds[0]) + ' ]') : '';
          //Update HTMLBody to change reference Id.
          clonedEmailMessage.HtmlBody = String.isNotBlank(clonedEmailMessage.HtmlBody) ? clonedEmailMessage.HtmlBody.replace('ref' + currentRefId + 'ref', getThreadId(lstCaseIds[0])) : '';
        }

        //add the new email to insert.
        lstEmailMessageToInsert.add(clonedEmailMessage);

        //update original email message - transfer status
		If(eMsg.HtmlBody != null  &&  eMsg.HtmlBody.length() < 131072){
        eMsg.Email_Transfer_Status__c = EMAIL_TRANSFERRED_OUT_TO + '<a href=/' + clonedEmailMessage.RelatedToId + '>' + new CasesSelector().selectCasesFromSetIds(new set < Id > {
          clonedEmailMessage.RelatedToId
        })[0].CaseNumber + '</a>';
        update eMsg;
		}
        //insert the new cloned email message.
        if (lstEmailMessageToInsert != null && !lstEmailMessageToInsert.isEmpty())
          insert lstEmailMessageToInsert;

        //DCP-34276 
        //No duplicate attachments can be linked to a case.
        //Query attachments related to a case.
        string caseId = lstCaseIds[0];
        Map < String, ContentDocumentLink > attachmentIdToAttachmentsForCase = new Map < String, ContentDocumentLink > ();
        for (ContentDocumentLink att: [Select ContentDocument.title, ContentDocumentId, LinkedEntityId from ContentDocumentLink where LinkedEntityId =: caseId]) {
          attachmentIdToAttachmentsForCase.put(att.ContentDocumentId, att);
        }

        for (Id emailMessageObjId: emailMessageIdToAttachmentsLst.keyset()) {
            for (ContentDocumentLink attObj: emailMessageIdToAttachmentsLst.get(emailMessageObjId)) {
              ContentDocumentLink newFile = new ContentDocumentLink(ContentDocumentId = attObj.ContentDocumentId, LinkedEntityId = lstEmailMessageToInsert[0].Id);
              //do it for case as well - if an attachment is already present, do not add a duplicate attachment.
              ContentDocumentLink newFileForCase = new ContentDocumentLink(ContentDocumentId = attObj.ContentDocumentId, LinkedEntityId = lstCaseIds[0]);
              lstNewAttachmentFiles.add(newFile);

              if (attachmentIdToAttachmentsForCase != null && !attachmentIdToAttachmentsForCase.containsKey(newFileForCase.ContentDocumentId))
                lstNewAttachmentFiles.add(newFileForCase);

            }
          }
        

        if (lstNewAttachmentFiles != null && !lstNewAttachmentFiles.isEmpty())
          insert lstNewAttachmentFiles;

        //return succcess message.
        processingMessage = 'Operation Successfull';

    
    } catch (Exception e) {

      processingMessage = 'Error: ' + e;
      ApexExceptions.emit('Unable to Move email to exisiting Case ', e);
      ilib_LogEvent.push('EXCEPTION');
      ilib_LogEvent.message(e.getMessage().abbreviate(4000));
      ilib_LogEvent.pop();
    }

    return processingMessage;
  }

  /*
   *  @author Vaibhav Parashar
   *  @description - returns the relatedTo Sobject name back to lightning component.
   *  @PARAM :  String emailMessageId.
   *  @RETURN:  String
   */
  @AuraEnabled
  public static string getRelatedToSobject(String emailMessageRecordId) {

    //get the current email message record based on the Id, this record will eventually be cloned.
    EmailMessage eMsg = new EmailMessagesSelector().selectEmailMessages(new set < String > {
      emailMessageRecordId
    });
    Schema.SObjectType sobjectType = eMsg.relatedToId.getSObjectType();
    String sobjectName = sobjectType.getDescribe().getName();
    return sobjectName;

  }
  
    /*
   *  @author Vaibhav Parashar
   *  @description - prepares the reference id by the case id.
   *  @PARAM :  String caseId.
   *  @RETURN:  String
   */
  private Static String getThreadId(String caseId) {
    return 'ref:_' +
      UserInfo.getOrganizationId().left(5) +
      UserInfo.getOrganizationId().mid(10, 5) + '._' +
      caseId.left(5) +
      caseId.mid(10, 5) + ':ref';
  }




}