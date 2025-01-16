/*************************************************************************************
*   @Author:Joshith K
*   @Date: 13-11-2018
*   @Description:DCP-15322 to forward inbound emails received from  SAP to SFDC to the owner of Parts Order
 
 Modification Log:
 *    ------------------------------------------------------------------------------------
 *             Developer                      Date                Description
 *              Joshith K                   13-11-2018          initial version
 *    ------------------------------------------------------------------------------------
*/
public with sharing class SystemNotifications extends ilib_SObjectDomain {
    public static final String STRING_REGEXSTR_SUBJECT = '([0-9]+)';
    public static final Pattern PATTERN_REGEXSTR_SUBJECT = Pattern.compile(STRING_REGEXSTR_SUBJECT);
	
		/*
         * Constructor
         */	
    public SystemNotifications(List < System_Notification__c > sObjectList) {
        super(sObjectList);

    }

    /**
     * Boilerplate which is required for base class instantiation logic
     **/
    public class Constructor implements ilib_SObjectDomain.IConstructable {
	    /*Param - sobjectList  */
        public ilib_SObjectDomain construct(List < SObject > sObjectList) {
            return new SystemNotifications(sObjectList);
        }
    }

    /**
     *  @author  Joshith K
     *  @description After Insert Logic (forward email to part order owner)
     **/
    public override void onAfterInsert() {

        // Part order format in subject Illumina Shipment Order - 1166881 will be sfdc ERP Sales Order Number.
        
        set < string > setPartOrderNo = new set < string > ();
        set < id > setSysNotificationIds = new set < id > ();//DCP-46067
		
        for (System_Notification__c objSystemNotification: (List < System_Notification__c > ) records) {
            system.debug('objSystemNotification ==> ' + objSystemNotification);
            if (!String.isblank(objSystemNotification.Email_Subject__c)) {
                Matcher objMatcher = PATTERN_REGEXSTR_SUBJECT.matcher(objSystemNotification.Email_Subject__c);
                system.debug('objMatcher ==> ' + objMatcher);
                if (objMatcher.find()) {
                    system.debug('objMatcher.group(1) ' + objMatcher.group(1));
                    setPartOrderNo.add(objMatcher.group(1));
					setSysNotificationIds.add(objSystemNotification.id);//DCP-46067
                }
            }
        }
        
        List < SVMXC__RMA_Shipment_Order__c > lstPartOrders = new PartsOrdersSelector().selectPartsOrdersWithName(setPartOrderNo);
        map < string, SVMXC__RMA_Shipment_Order__c > mapPartOrder = new map < string, SVMXC__RMA_Shipment_Order__c > ();
        
        for (SVMXC__RMA_Shipment_Order__c objPartOrder: lstPartOrders) {
            mapPartOrder.put(objPartOrder.ERP_Sales_Order_Number__c, objPartOrder);
            }
        
        //46067 :Start
        
        if(!mapPartOrder.isEmpty() && mapPartOrder!=null){
            System.debug('inside if'+records);
            ilib_Queueablethread queueableThread=new ilib_Queueablethread('SystemNotificationAfterInsert');
            
            queueableThread.logandQueue(new SystemNotificationsQueueable('createAttachmentAndSendEmail',mapPartOrder,records,setSysNotificationIds),
                                        'SystemNotificationsQueueable','createAttachmentAndSendEmail');
            
            if(queueableThread!=null)
                ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SERVICE); 
        }
        //DCP-46067 :End   
        
      
    }
	
	  
    /*DCP-46067 and previous functionality*/
    public static void createAttachmentAndSendEmail(map<string, SVMXC__RMA_Shipment_Order__c> mapPartOrder, List<System_Notification__c> records,Set<id> setSysNotificationIds){
       //DCP-46067 :Start
        List<ContentDocumentLink> lstContentDocLink= new List<ContentDocumentLink>();
        //fetch contentdocLink from System notification related file section
        if(setSysNotificationIds!=null && !setSysNotificationIds.isEmpty()){
            lstContentDocLink= new ContentDocumentLinksSelector().selectContentDocumentLinks(setSysNotificationIds); 
        }
        //DCP-46067:END
        
        list < Messaging.SingleEmailMessage > lstSingleEmail = new list < Messaging.SingleEmailMessage > ();
        list < attachment > lstPartOrderAttach = new list < attachment > ();
        
        OrgWideEmailAddress[] lstOrgWideEmail = [Select Id from OrgWideEmailAddress WHERE DisplayName = 'SystemNotification'];
        
        //DCP-46067:Start
        //fetch contentDocumentid from System notification related file section
        List<id> contentDocumentids = new List<id>();
        if(!lstContentDocLink.isEmpty()){
            for(contentDocumentLink cdLink :lstContentDocLink)
            {
                contentDocumentids.add(cdLink.ContentDocumentid);  
            }
        }
        List<Messaging.Emailfileattachment> fileAttachments= new List<Messaging.Emailfileattachment>();
        if(!contentDocumentids.isEmpty()){
            //fetch ContentVersion from System notification related file section
            for ( ContentVersion cversion : new ContentVersionsSelector().selectByContentDocument(contentDocumentids))
            {
                blob fileContent = cversion.versiondata;
				if(Limits.getHeapSize() + fileContent.size() < Limits.getLimitHeapSize()) {
					system.debug('body : '+fileContent+'-----------'+cversion.title);
					Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
					efa.setFileName(cversion.ContentDocument.Title);
					efa.setBody(fileContent);
					fileAttachments.add(efa); 
				}
				else{
                    ApexExceptions.emit('SystemNotifications-'+cversion.id,'Apex heap size too large',ilib_LogEvent.SERVICE);
                }
            } 
        }
        //DCP-46067:End
        
        
        for (System_Notification__c objSystemNotification: (List < System_Notification__c > ) records) {
            if (!String.isblank(objSystemNotification.Email_Subject__c) && mapPartOrder != null && !mapPartOrder.isEmpty()) {
                
                Matcher objMatch = PATTERN_REGEXSTR_SUBJECT.matcher(objSystemNotification.Email_Subject__c);
                if (objMatch.find())
                {
                    system.debug('future matched body' + objSystemNotification.Email_Body__c);
                    string stringEmailBody = objSystemNotification.Email_Body__c;
                    string stringPartOrder = objMatch.group(1);
                    system.debug('Owner Email ' + mapPartOrder.get(stringPartOrder).ownerId);
                    
                    string[] lStToAddress = new string[] { mapPartOrder.get(stringPartOrder).owner.email };
                    
                        Messaging.SingleEmailMessage objSingleEmail = new Messaging.SingleEmailMessage();
                    objSingleEmail.settoaddresses(lStToAddress);
                    objSingleEmail.setSubject(objSystemNotification.Email_Subject__c);
                    objSingleEmail.setPlainTextBody(stringEmailBody.stripHtmlTags());
                    objSingleEmail.setHtmlBody(stringEmailBody);
                    //DCP-46067 Start
                    //Mail attachment to the parts order user/Owner
                    if(fileAttachments!=null && !fileAttachments.isEmpty())
                        objSingleEmail.setFileAttachments(fileAttachments);
                    //DCP-46067 End
                    if (!lstOrgWideEmail.isempty()) {
                        objSingleEmail.setOrgWideEmailAddressId(lstOrgWideEmail.get(0).Id);
                    }
                    // attach email forwarded as attachment to Part order
                    attachment objAttachment = new attachment();
                    objAttachment.name = objSystemNotification.Email_Subject__c + '.html';
                    if (!String.isblank(stringEmailBody)) {
                        
                        objAttachment.ContentType = 'text/html; charset=UTF-8';
                        stringEmailBody = '<html><body>' + stringEmailBody + '</body></html>';
                        objAttachment.Body = Blob.valueOf(stringEmailBody);
                        
                        
                    }
                    objAttachment.ownerid = mapPartOrder.get(stringPartOrder).ownerid;
                    objAttachment.parentid = mapPartOrder.get(stringPartOrder).id;
                    lstPartOrderAttach.add(objAttachment);
                    
                    lstSingleEmail.add(objSingleEmail);
                }
            }
        }
        
        if (!lstSingleEmail.isempty()) {
            Messaging.sendEmail(lstSingleEmail);
            
        }
        if (!lstPartOrderAttach.isempty()) {
            insert lstPartOrderAttach;
            
        }
        
        
    }
    

}
