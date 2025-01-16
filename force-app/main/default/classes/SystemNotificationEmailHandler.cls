/***************************************************************************************************************************************
* NAME   : SystemNotificationEmailHandler 
* DESCRIPTION  : DCP-11785 Creation of System notification record.
*    
* @AUTHOR : Dipika
* @DATE   : 17-Oct-2018  
****************************************************************************************************************************************/ 
global class SystemNotificationEmailHandler implements Messaging.InboundEmailHandler {

    /*
    * @description:This method is used to create system notification record and attachment from the email body
    * @return: Messaging.InboundEmailResult
    */    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, 
                                                           Messaging.InboundEnvelope env){
                                                               
       // Create an InboundEmailResult object for returning the result of the 
       // Apex Email Service
       Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
       
       System_Notification__c objSystemNotification = new System_Notification__c( From_Address__c = email.fromAddress,
                                                                                 Email_Date__c = Datetime.now());
       
       if(!String.isblank(email.subject)){
           objSystemNotification.Email_Subject__c = email.subject.left(255);
           
       }
       if(email.htmlBody != null){
           objSystemNotification.Email_Body__c = email.htmlBody;
       }
       else if(email.plainTextBody != null){
           objSystemNotification.Email_Body__c = email.plainTextBody;
       }
       if(email.toAddresses != null){
           for(String toAdd : email.toAddresses){
               if(!String.isblank(toAdd) && !toadd.contains(Label.System_Notification_Email)){
                   objSystemNotification.To_Address__c =  String.isblank(objSystemNotification.To_Address__c) ? toAdd : (objSystemNotification.To_Address__c+','+toAdd);
                }
               
           }
       }
       if(email.ccAddresses != null){
           for(String cc: email.ccAddresses){
               if(!String.isblank(cc)){
                   objSystemNotification.CC_Address__c =  String.isblank(objSystemNotification.CC_Address__c) ? cc : objSystemNotification.CC_Address__c +','+cc;
               }
               
           }
       }
       insert objSystemNotification;
       
       list<ContentVersion> lstContentVersion = new list<ContentVersion>();
       if(email.binaryAttachments != null){
           for(Messaging.InboundEmail.BinaryAttachment binAttachment : email.binaryAttachments){
               ContentVersion cont = createContentVersion(binAttachment.fileName,
                                                          binAttachment.fileName,'H',
                                                          binAttachment.body);
               
               lstContentVersion.add(cont);
               
           }
       }
       
       
       if(email.textAttachments != null){
           for(Messaging.InboundEmail.TextAttachment textAttachment : email.textAttachments){
               ContentVersion cont = createContentVersion(textAttachment.fileName,
                                                          textAttachment.fileName,'H',
                                                          blob.valueOf(textAttachment.body));
               
               lstContentVersion.add(cont);
           }
       }
       
       if(lstContentVersion.size()>0){
           insert lstContentVersion ;
           Set<ID> setContentVersionIds = new Set<ID>();
           for(ContentVersion objConversion: lstContentVersion ){
               setContentVersionIds.add(objConversion.Id);
           }
           list<ContentDocumentLink> lstContentDocumentLink = new list<ContentDocumentLink>();
           ContentVersionsSelector objContentVersion = new ContentVersionsSelector();
           for(ContentVersion conVersion : objContentVersion.selectByContentVersionId(setContentVersionIds)){
               ContentDocumentLink conDocLink = new ContentDocumentLink();
               conDocLink.ContentDocumentId = conVersion.ContentDocumentId;
               conDocLink.LinkedEntityId = objSystemNotification.id;
               conDocLink.ShareType = 'V';
               lstContentDocumentLink.add(conDocLink);
           }
           if(lstContentVersion.size()>0){
               insert lstContentDocumentLink ;
           }
           
       }
       
       
       // Set the result to true. No need to send an email back to the user 
       // with an error message
       result.success = true;
       
       // Return the result for the Apex Email Service
       return result;
    }
    
    /*
    * @description:This method is used to Intantiate create ContentVersion
    * @return: ContentVersion
    */ 
    global ContentVersion createContentVersion(String title,String pathOnclient, String origin,Blob body){
        ContentVersion objContVersion = new ContentVersion();
        objContVersion.Title = title;
        objContVersion.PathOnClient = pathOnclient;
        objContVersion.VersionData = body ;
        objContVersion.Origin = origin;
        return objContVersion;
    }
    
}