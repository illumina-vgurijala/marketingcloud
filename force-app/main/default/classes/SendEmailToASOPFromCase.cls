/**
 * @description       : 
 * @author            : Vaibhav
 * @group             : 
 * @last modified on  : 09-03-2020
 * @last modified by  : Vaibhav
 * Modifications Log 
 * Ver   Date         Author    Modification
 * 1.0   08-28-2020   Vaibhav   Initial Version
 **/
public with sharing class SendEmailToASOPFromCase {

  public static final string STRING_ASOP_EMAIL_SENT_SUCCESSFULLY = 'Success: Email Sent to ASOP successfully.';
  public static final string STRING_ASOP_NO_ATTACHMENT_WARNING = 'Warning: No attachment found, please add attachment.';
  public static final string STRING_ASOP_MUTIPLE_EMAIL_ERROR = 'Error: There are more than one emails associated to this Case, please use the Email Message detail page button to send out an email to ASOP.';
  public static final string STRING_ASOP_NO_EMAIL_ERROR = 'Error: No Email found to be sent to ASOP';
  
  public static final string STRING_ASOP_ONLOAD_SCENARIO_TEXT = 'OnLoad';
  public static final string STRING_ASOP_SENDEMAILCLICKED_SCENARIO_TEXT = 'sendEmailClicked';

  public static final string STRING_ILLUMINA_CUSTOMER_SERVICE_OWA_ID = '0D21N0000004Kjz'; //this id remains constant in each environment.

  public static Map < Id, EmailMessage > emailMessageIdToEmailMesageObjMap;
  public static string emailBody;
  public static string emailSubject;
  public static string recordInConextId;
  public static string caseIdForFinalEmailTracking;
  public static string searchTerm = '';
  public static Case caseObj;
  public static SendEmailToASOPFromCase.EmailMessageWrapper emailMessageWrapper = new SendEmailToASOPFromCase.EmailMessageWrapper();
  public static Map < EmailMessage, List < ContentDocumentLink >> emailToLstAttachmentMap = new Map < EmailMessage, List < ContentDocumentLink >> ();
  public static string userInteractionScenario = STRING_ASOP_ONLOAD_SCENARIO_TEXT;
  public static boolean sendEmailJustOnce = true;
  public static String lineBreak = '<br/>'; 
  public static final Integer INTEGER_ONE = 1;

  /**
   *  @description method to decide if the email will be sent out automatically or with user interaction.
   *  @param String recordId, String objectName, String scenario, String searchTerm, List<Map<String, Object>> files
   *  @return EmailMessageWrapper
   **/
  @AuraEnabled(cacheable = true)
  public static EmailMessageWrapper runASOPEmailBusinessLogic(String recordId, String objectName, String scenario, String searchTerm, List < Map < String, Object >> files) {

    userInteractionScenario = String.isNotBlank(scenario) ? scenario : userInteractionScenario; //UI loaded or SendEmail Button was clicked. 
    emailToLstAttachmentMap = storeEmailsWithAttachments(recordId, objectName); //stores all attachments tagged to a emailMessage
    emailMessageWrapper.uiDisplayMessage = ''; //message to be displayed on LWC UI.
    recordInConextId = recordId; //CaseId Or EmailMessage

    //get the case object info based on the record id received for Case or EmailMessage
    if (String.isNotBlank(objectName) && objectName.equalsIgnoreCase('Case')) {
      caseObj = new CasesSelector().selectCaseByCaseId(recordInConextId);
      caseIdForFinalEmailTracking = recordInConextId;
    } else if (String.isNotBlank(objectName) && objectName.equalsIgnoreCase('EmailMessage')) {
      EmailMessage emailObj = new EmailMessagesSelector().selectEmailMessages(new Set < String > {
        recordInConextId
      });
      caseObj = new CasesSelector().selectCaseByCaseId(emailObj.ParentId);
      caseIdForFinalEmailTracking = emailObj.ParentId;
    } 

    emailBody = prepareEmailBody(caseObj, searchTerm); //populate PO,Country,Region in the final email body


    //show the LWC UI send email button only when there no multiple attachments
    if (emailToLstAttachmentMap.keyset().size() == INTEGER_ONE) {

      Integer attachmentCount = 0; //count of attachments for an emailMessage record.
      
      for (EmailMessage emailMsgObj: emailToLstAttachmentMap.keyset()) {
        attachmentCount = emailToLstAttachmentMap.get(emailMsgObj).size(); //store count of attachments
        emailSubject = emailMsgObj.Subject; //set the final email subject as the original email message record.
        string emailForwardMessageSyntax = lineBreak + lineBreak +'--------------- Forwarded Message ---------------' + lineBreak + '<b>From:</b> ' + emailMsgObj.FromAddress + lineBreak + '<b>Sent:</b> ' + emailMsgObj.MessageDate + lineBreak + '<b>To:</b> ' + emailMsgObj.ToAddress + lineBreak + '<b>Subject:</b> ' + emailMsgObj.Subject + lineBreak ;
        string htmlOrTextBody = String.isNotBlank(emailMsgObj.HtmlBody) ? emailMsgObj.HtmlBody : emailMsgObj.TextBody;//populate textbody if html body is null.
        emailBody += emailForwardMessageSyntax + lineBreak + htmlOrTextBody + lineBreak; //set the final email body as the original email message record.
      }

      //Scenario 1 - If Object = Case, and we have 1 Email Message with 1 attachment, send out the email automatically.
      if (attachmentCount > 0 && userInteractionScenario.equalsIgnoreCase(STRING_ASOP_ONLOAD_SCENARIO_TEXT) && String.isNotBlank(objectName) && objectName.equalsIgnoreCase('Case')) {
        emailMessageWrapper.uiDisplayMessage = processSingleEmailMessageWithAttachment(emailToLstAttachmentMap, files); //sends out the email automatically without user interaction.
      } else if (attachmentCount == 0) {
        emailMessageWrapper.uiDisplayMessage = STRING_ASOP_NO_ATTACHMENT_WARNING; //if there are no attachments, show warning message on the UI.
      } 

      //send out an email when Send Email button is clicked from the LWC UI.
      if (userInteractionScenario.equalsIgnoreCase(STRING_ASOP_SENDEMAILCLICKED_SCENARIO_TEXT)) {
        emailMessageWrapper.uiDisplayMessage = processSingleEmailMessageWithAttachment(emailToLstAttachmentMap, files);
      }

    } else if (emailToLstAttachmentMap.keyset().size() > INTEGER_ONE) {
      emailMessageWrapper.uiDisplayMessage = STRING_ASOP_MUTIPLE_EMAIL_ERROR; //show error if there are multiple attachments
    } else {
      emailMessageWrapper.uiDisplayMessage = STRING_ASOP_NO_EMAIL_ERROR; //show error if there is no original email found
    }

    system.debug('emailMessageWrapper = ' + emailMessageWrapper);
    return emailMessageWrapper;

  }

  /**
   *  @description method to store emails with its attachments.
   *  @param String recordId, String objectName
   *  @return Map < EmailMessage, List < ContentDocumentLink >>
   **/
  public static Map < EmailMessage, List < ContentDocumentLink >> storeEmailsWithAttachments(String recordId, String objectName) {

    Map < EmailMessage, List < ContentDocumentLink >> emailMessageToAttachmentsLstMap = new Map < EmailMessage, List < ContentDocumentLink >> ();
    Map < EmailMessage, List < ContentDocumentLink >> finalEmailMessageToAttachmentsLstMap = new Map < EmailMessage, List < ContentDocumentLink >> ();

    if (String.isNotBlank(recordId)) {

      //fetch email messages based on case or emailMessage Id
      if (String.isNotBlank(objectName) && objectName.equalsIgnoreCase('Case')) {
        emailMessageIdToEmailMesageObjMap = new Map < Id, EmailMessage > (new EmailMessagesSelector().selectEmailMessageByParentId(new Set < String > {
          recordId
        }));
      } else if (String.isNotBlank(objectName) && objectName.equalsIgnoreCase('EmailMessage')) {
        emailMessageIdToEmailMesageObjMap = new Map < Id, EmailMessage > (new EmailMessagesSelector().selectEmailMessagesByIds(new Set < String > {
          recordId
        }));
      } 

      //fetch the attachments associated with email messages.
      if (emailMessageIdToEmailMesageObjMap != null && !emailMessageIdToEmailMesageObjMap.isEmpty()) {
        for (ContentDocumentLink attObj: new ContentDocumentLinksSelector().selectByEmailMessagesRecordIds(emailMessageIdToEmailMesageObjMap.keySet())) {
          if (emailMessageToAttachmentsLstMap.containsKey(emailMessageIdToEmailMesageObjMap.get(attObj.LinkedEntityId))) {
            emailMessageToAttachmentsLstMap.get(emailMessageIdToEmailMesageObjMap.get(attObj.LinkedEntityId)).add(attObj);
          } else {
            emailMessageToAttachmentsLstMap.put(emailMessageIdToEmailMesageObjMap.get(attObj.LinkedEntityId), new List < ContentDocumentLink > ());
            emailMessageToAttachmentsLstMap.get(emailMessageIdToEmailMesageObjMap.get(attObj.LinkedEntityId)).add(attObj);
          }

        }

        //prepare the email message map with list of its attachments.
        for (Id emailMessageId: emailMessageIdToEmailMesageObjMap.keyset()) {

          if (emailMessageToAttachmentsLstMap.containsKey(emailMessageIdToEmailMesageObjMap.get(emailMessageId))) {
            finalEmailMessageToAttachmentsLstMap.put(emailMessageIdToEmailMesageObjMap.get(emailMessageId), emailMessageToAttachmentsLstMap.get(emailMessageIdToEmailMesageObjMap.get(emailMessageId)));
          } else {
            finalEmailMessageToAttachmentsLstMap.put(emailMessageIdToEmailMesageObjMap.get(emailMessageId), new List < ContentDocumentLink > ());
          }

        }


      }


    }

    return finalEmailMessageToAttachmentsLstMap;

  }

  /**
   *  @description method to process and send out emails.
   *  @param Map < EmailMessage, List < ContentDocumentLink >> emailMessageToAttachmentsLstMap, List<Map<String, Object>> files
   *  @return string processing message
   **/
  private static string processSingleEmailMessageWithAttachment(Map < EmailMessage, List < ContentDocumentLink >> emailMessageToAttachmentsLstMap, List < Map < String, Object >> files) {

    List < Messaging.EmailFileAttachment > finalEmailAttachments = new List < Messaging.EmailFileAttachment > ();
    String processingMessage = STRING_ASOP_EMAIL_SENT_SUCCESSFULLY;

    for (EmailMessage emailMessageObj: emailMessageToAttachmentsLstMap.keyset()) {
      for (ContentDocumentLink attObj: emailMessageToAttachmentsLstMap.get(emailMessageObj)) {

        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName(attObj.ContentDocument.Title + '.' + attObj.ContentDocument.FileExtension);
        String blobValue = EncodingUtil.base64Encode(attObj.ContentDocument.LatestPublishedVersion.VersionData);
        efa.setBody(EncodingUtil.base64Decode(blobValue));

        //add attachments as attachments to the final email.
        finalEmailAttachments.add(efa);

      }

    }

    //attachments added from UI
    if (files != null && !files.isEmpty()){
      finalEmailAttachments.addAll(uploadFiles(files));
    }
      

    try {

      //final email to be sent out to ASOP.
      if (sendEmailJustOnce) {
        sendEmailToASOP(finalEmailAttachments);
        sendEmailJustOnce = false;
      }


    } catch (Exception e) {

      system.debug('Exception e ' + e);
      processingMessage = 'Error: ' +e.getMessage();

    }

    return processingMessage;

  }

  /**
   *  @description method to create final email body with Case details.
   *  @param Case caseObj, string searchTerm
   *  @return string email body
   **/
  private static string prepareEmailBody(Case caseObj, string searchTerm) {

    string poNumberValue = String.isNotBlank(caseObj.PO__c) ? caseObj.PO__c : '';
    string regionValue = String.isNotBlank(caseObj.Region__c) ? caseObj.Region__c : '';
    string countryValue = '';

    //show region AMEA as APAC
    if(String.isNotBlank(regionValue)){
      // POL-18 AC9 keywords replaced from APJ to AMEA
    regionValue = regionValue.equalsIgnoreCase('AMEA') || regionValue.equalsIgnoreCase('GC') ? 'APAC' : regionValue;  
    }

    if(String.isNotBlank(caseObj.AccountId)){
     countryValue =  String.isNotBlank(caseObj.Account.BillingCountryCode) ? caseObj.Account.BillingCountryCode : ''; 
    }

    String temporaryEmailBody = '@~PO_NUMBER~@ ' + poNumberValue + lineBreak + '@~REGION~@ ' + regionValue + lineBreak + '@~COUNTRY~@' + countryValue + lineBreak;
    temporaryEmailBody += '@~SEARCH_TERM~@ ' + searchTerm + lineBreak + '@~' + lineBreak;
    

    return temporaryEmailBody;

  }

  /**
   *  @description method to store attachments added from the UI.
   *  @param List<Map<String, Object>> files
   *  @return List < Messaging.EmailFileAttachment >
   **/
  public static List < Messaging.EmailFileAttachment > uploadFiles(List < Map < String, Object >> files) {

    List < Messaging.EmailFileAttachment > finalEmailAttachments = new List < Messaging.EmailFileAttachment > ();

    for (Map < String, Object > file: files) {
      String fileJson = JSON.serialize(file);
      RelatedFile relatedDocument = (RelatedFile) JSON.deserialize(fileJson, RelatedFile.class);

      Messaging.EmailFileAttachment uploadedAttachment = new Messaging.EmailFileAttachment();
      uploadedAttachment.setFileName(relatedDocument.title);
      String blobValue = EncodingUtil.base64Encode(relatedDocument.versionData);
      uploadedAttachment.setBody(EncodingUtil.base64Decode(blobValue));

      finalEmailAttachments.add(uploadedAttachment);

    }

    return finalEmailAttachments;

  }

  /**
   *  @description method to make final sendEmail call.
   *  @param List < Messaging.EmailFileAttachment > attachments
   *  @return void
   **/
  private static void sendEmailToASOP(List < Messaging.EmailFileAttachment > attachments) {

    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
    
    message.setOrgWideEmailAddressId(STRING_ILLUMINA_CUSTOMER_SERVICE_OWA_ID); //from address
   
    string toAddress = System.Label.ASOP_Email_Address;//set to address using custom label
    message.setToAddresses(new String[] {
      toAddress
    });

    //add attachments
    if (attachments != null && !attachments.isEmpty()){
    message.setFileAttachments(attachments);  
    }
      
    message.setSubject(emailSubject);
    message.setHtmlBody(emailBody);
    //message.setUseSignature(false); // to stop duplicate signature.

    message.setWhatId(caseIdForFinalEmailTracking); //attach the final email to Case for history tracking.
    message.setSaveAsActivity(true); //enable activity tracking for final email.

    //final email to ASOP
    Messaging.sendEmail(new Messaging.SingleEmailMessage[] {
      message
    });

  }

  /**
   *  @description wrapper class to display various UI messages.
   **/
  Public class EmailMessageWrapper {

    @AuraEnabled public string uiDisplayMessage {
      get;
      set;
    }

  }

  /**
   *  @description wrapper class to store information related to newly added attachments.
   **/
  Public class RelatedFile {
    public String pathOnClient;
    public String title;
    public Blob versionData;
  }



}