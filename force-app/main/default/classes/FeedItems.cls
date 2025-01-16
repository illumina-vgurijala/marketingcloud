/**
 *    @author Anisha Bharti
 *    @date   19-Nov-2020
 *    @description : Handler class for FeedItemTrigger.
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                  Description
 *  
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class FeedItems extends ilib_SObjectDomain {

    public static FINAL string FEEDBACK_SOBJECT_API_NAME = 'Feedback__c';
    public static FINAL string TEMPLATE_NAME = 'Feedback_Chatter_posted';
    public static FINAL string  DISPLAY_NAME = 'SystemNotification';

    /** 
     * @description  Constructor
     * @param List of FeedItem
     */
    public feedItems(List<FeedItem> sObjectList)
    {
        super(sObjectList);
    }

    /** 
     * @description  implements ilib_SObjectDomain.IConstructable
     */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /** 
         * @description  construct method
         */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new FeedItems(sObjectList);
        }
    }
    
    /** 
     * @description  onAfterInsert method
     */
    public override void onAfterInsert(){
        
        sendNotification((List<FeedItem>) records);
    }
    
    /** 
     * @description to send notification onAfterInsert method
     */
    public void sendNotification(List<FeedItem> lstFeedItems){
        set<Id> setFeedBackId = new set<Id>();

        for (FeedItem feed: lstFeedItems) {
            if(string.valueOf(feed.parentId.getsobjecttype()) == FEEDBACK_SOBJECT_API_NAME){
                setFeedBackId.add(feed.ParentId);
            }
        }

        if(!setFeedBackId.isEmpty()){
            sendFeedbackNotification(lstFeedItems , setFeedBackId);
        }
    }

    /*
        Method name: sendFeedbackNotification 
        Description: Method to send Notification to Feedback
    */
    public void sendFeedbackNotification(List<FeedItem> lstFeedItems, set<Id> setFeedBackId){ 
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        list<Messaging.SingleEmailMessage> messages = new list<Messaging.SingleEmailMessage>();
        Map<Id,Feedback__c> mapFeedbacks = new  Map<Id,Feedback__c> (new FeedbackSelector().getFeedbackByIds(setFeedBackId));
        ilib_SecurityUtils.bypassInternalFlsAndCrud = true;
        CustomNotificationType type = [select ID FROM CustomNotificationType where DeveloperName = :system.Label.FeedBack_Notification_Type ];
        ilib_SecurityUtils.bypassInternalFlsAndCrud = false;
        
        List <EmailTemplate> emailTemplate = new EmailTemplatesSelector().selectByNameOrDeveloperName(new List<String>{TEMPLATE_NAME});
        Id templateId = emailTemplate[0].Id;
        string strGroupIdPrefix = '00G';

        for (FeedItem feed: (List<FeedItem>) records) {
            if(string.valueOf(feed.parentId.getsobjecttype()) == FEEDBACK_SOBJECT_API_NAME && string.valueOf(mapFeedbacks.get(feed.parentId).ownerId).left(3) != strGroupIdPrefix  ){
                Set<String> setOwnerId = new set<String>();
                List<String> lstOwnerId = new List<String>();
                
                setOwnerId.add(mapFeedbacks.get(feed.parentId).createdById);
                lstOwnerId.add(mapFeedbacks.get(feed.parentId).createdById);
                
                if(string.valueOf(mapFeedbacks.get(feed.parentId).ownerId).left(3) != strGroupIdPrefix){
                    setOwnerId.add(mapFeedbacks.get(feed.parentId).ownerId);
                    lstOwnerId.add(mapFeedbacks.get(feed.parentId).ownerId);
                }
                
                notification.setBody( mapFeedbacks.get(feed.parentId).Name +' - '+  feed.Body.stripHtmlTags());
                notification.setTitle(System.Label.FeedBack_Chatter_Header + mapFeedbacks.get(feed.parentId).Name);
                notification.setSenderId(Userinfo.getUserId());
                notification.setNotificationTypeId(type.id);
                notification.setTargetId(feed.parentId); 
                notification.send(setOwnerId); 
                
                String subject = emailTemplate[0].Subject;
                subject = subject.replace('{!Feedback__c.Name}', mapFeedbacks.get(feed.parentId).Name);
                
                String htmlBody = emailTemplate[0].HtmlValue;
                htmlBody = htmlBody.replace('{!Feedback__c.Feedback_Owner__c}', mapFeedbacks.get(feed.parentId).Feedback_Owner__c);
                htmlBody = htmlBody.replace('{!Feedback__c.Name}', mapFeedbacks.get(feed.parentId).Name);
                htmlBody = htmlBody.replace('{!myCustomString}', feed.body.stripHtmlTags());
                
                String plainBody = emailTemplate[0].Body;
                plainBody = plainBody.replace('{!Feedback__c.Feedback_Owner__c}', mapFeedbacks.get(feed.parentId).Feedback_Owner__c);
                plainBody = plainBody.replace('{!Feedback__c.Name}', mapFeedbacks.get(feed.parentId).Name);
                plainBody = plainBody.replace('{!myCustomString}', feed.body.stripHtmlTags());
                
                message.toAddresses = lstOwnerId;
                message.setSubject(subject);
                message.setHtmlBody(htmlBody);
                message.setPlainTextBody(plainBody);
                message.setTemplateId(templateId);
                message.setTargetObjectId(mapFeedbacks.get(feed.parentId).ownerId);
                message.setSaveAsActivity(false);
                message.setOrgWideEmailAddressId(addOrdWideEmailAddress());
                messages.add(message);
            }
        }
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
    }


    
    /** 
     * @description to query OrgWideEmailAddress
     */
    public Id addOrdWideEmailAddress(){
        OrgWideEmailAddress[] owea = [select id,DisplayName,Address from OrgWideEmailAddress where DisplayName =: DISPLAY_NAME];
        if ( owea.size() > 0 ) {
            return owea[0].Id;
        }
        return null;
    }
}