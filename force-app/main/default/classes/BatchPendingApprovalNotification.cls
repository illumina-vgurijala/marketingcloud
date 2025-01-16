/**
*    @author Anish Pathak
*    @date   25 August 2021
*    @description  DCP-46934: Pending Approval Notifications
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*       Developer            Date            Description
*       Prem Ranjan         20-Feb-2023      CodeScan Fixes (APEX) Variable Naming Conventions
*    -----------------------------------------------------------------------------------------------------------------------------------
*  
*/
public without sharing class BatchPendingApprovalNotification extends ilib_ScheduleAndBatch implements Schedulable {


    List<String> lstApprovalStatus = new List<String>{'Assigned','Reassigned'};
    List<User> lstUser = new List<User>();
    public static Final String LIST_VEW_NAME = 'My_Pending_Approvals';
    public static Final String OBJECT_TYPE = 'Apttus_Approval__Approval_Request__c';
    public static Final String SUB_URL = '/lightning/o/Apttus_Approval__Approval_Request__c/list?filterName=';
    public static Final String APPROVAL_STAGE = 'In Review';


    /* Batch Start Method to query records */
    public override Database.QueryLocator start(Database.BatchableContext bc){ 

        String strTimeZone = 'None';
        DateTime dt = Datetime.now();
        Integer hour = dt.hourGMT();
        TimeZoneSelector objTimeZoneSelector = new TimeZoneSelector();
        List<Time_Zones__mdt> lstTimeZoneByHour = objTimeZoneSelector.selectByHour(hour);
        for(Time_Zones__mdt timeZone : lstTimeZoneByHour){
            if(timeZone.Time_Zones__c != null && timeZone.Time_Zones__c != ''){
                strTimeZone = strTimeZone + ','+timeZone.Time_Zones__c;
            }
        }
        List<String> lstTimeZone = strTimeZone.split(',');
        System.debug('Time zone test'+lstTimeZone);
        String query;
        if(!Test.isRunningTest())
        {
         query  = 'Select Id,Email from User Where TimeZoneSidKey IN : lstTimeZone'; 
        }
        else
        {
            User testUser = TestDataUser.findUserInProfile('System Administrator');
            String userId = testUser.id;
            query  = 'Select Id,Email from User where id =:userId';
        }           
        return Database.getQueryLocator(query);
    }


    /* Batch Execute Method to process records */
    public override void execute(Database.BatchableContext bc, List<sobject> lstUser){  
    try
    {
        List<User> lstUsers =  (List<User>)lstUser;
        List<Id> lstOwnerId = new List<Id>();
        String listViewURL = getListViewURL();
        List<Messaging.SingleEmailMessage> lstEmailMsgs = new List<Messaging.SingleEmailMessage>();  
        Messaging.SingleEmailMessage email;
        ApttusApprovalRequestsSelector objApttusApprovalRequestsSelector = new ApttusApprovalRequestsSelector();
        List<Apttus_Approval__Approval_Request__c> lstOpenApprovalReq = objApttusApprovalRequestsSelector.selectByParentandUserId(lstUsers , lstApprovalStatus, APPROVAL_STAGE);
        Map<Id,List<Apttus_Approval__Approval_Request__c>> mapIdandAprReq = new Map<Id,List<Apttus_Approval__Approval_Request__c>>();
        for(Apttus_Approval__Approval_Request__c apr : lstOpenApprovalReq){
            if(mapIdandAprReq.containsKey(apr.OwnerId)){
                List<Apttus_Approval__Approval_Request__c> lstAprReq = mapIdandAprReq.get(apr.OwnerId);
                lstAprReq.add(apr);
            }else{
                mapIdandAprReq.put(apr.OwnerId,new List<Apttus_Approval__Approval_Request__c> {apr});
            }
        }
            
        for(Apttus_Approval__Approval_Request__c apr : lstOpenApprovalReq){
            if(!lstOwnerId.contains(apr.OwnerId)){
                lstOwnerId.add(apr.OwnerId);
                email = new Messaging.SingleEmailMessage();
                email.setTargetObjectId(apr.OwnerId);
                email.setSaveAsActivity(false);
                email.setSubject('Pending Approval Request Summary');
                email.setSenderDisplayName('Approvals Reminder');
                email.setHTMLBody(getTableEmailBody(mapIdandAprReq.get(apr.OwnerId),listViewURL, apr.Apttus_Approval__Assigned_To_Name__c));
                lstEmailMsgs.add(email);
            }
        }
            Messaging.SendEmailResult[] results = Messaging.sendEmail(lstEmailMsgs, false);             
    }
    catch(Exception e) { ApexExceptions.emit('BatchPendingApprovalNotification','',e); }
    }   
    /* Schedulable Execute Method to schedule Batch */   
    public override void execute(SchedulableContext sc)
    {
        BatchPendingApprovalNotification btch = new BatchPendingApprovalNotification();
        Database.executebatch(btch, 10);
    }

    /* Batch Finish Method for post execute logic */    
    public override void finish(Database.BatchableContext bc){
    //No Logic needed.
    }
   /* Method to get email body*/
    public static string getTableEmailBody(List<Apttus_Approval__Approval_Request__c> lstApr, String lstViewURL, String strUserName){
        String strApprovalEmail = System.URL.getSalesforceBaseUrl().toExternalForm()+'/apex/ApttusSubmitForApprovalPdfPage?sObjectType=Apttus_Approval__Approval_Request__c&sObjectId=';
        String approveReject = System.URL.getSalesforceBaseUrl().toExternalForm()+'/apex/Apttus_Approval__ApprovalSummaryLaunch?id=';
        String pageMode = '&pageMode=approveReject';
        String rowTag = '</td><td style="text-align: center;">';
        String breakTag = '</br> </br>';
        String htmlBody = 'Hi ' +strUserName+',';
        htmlBody += breakTag +'One or more Approval Requests are awaiting your approval.';

        htmlBody += breakTag+'How to Approve:';
        htmlBody += breakTag+'&bull;&nbsp;'+'The quote can be approved via e-mail from the original quote request.';
        htmlBody += '</br>'+'&bull;&nbsp;'+'The quote can also be approved within Salesforce by clicking this “Approve / Reject” link on the individual quote';
        htmlBody += breakTag + 'To view this list with the quote approval e-mail details within Salesforce, click <a href="'+lstViewURL+'">here.</a>';

        //open table..
        htmlBody += breakTag + '<table border="1" style="border-collapse: collapse"><caption>Approval Request(s) Summary:</caption><tr>'
            +'<th>Related Quote/Proposal</th>'
            +'<th>SoldTo Account Name</th>'
            +'<th>UC Subregion</th>'
            +'<th>Opportunity Name</th>'
            +'<th>Date Assigned</th>'
            +'<th>Max Sales Approval Level</th>'
            +'<th>Quote Value (Currency)</th>'
            +'<th>Approval Summary</th>'
            +'<th>Approval Action</th></tr>';
        //iterate over list and output columns/data into table rows...
        for(Apttus_Approval__Approval_Request__c a : lstApr){
            
                
            htmlBody += '<tr><td style="text-align: center;">' +  a.Apttus_QPApprov__ProposalId__r.Name 
                + rowtag + a.Apttus_QPApprov__ProposalId__r.Sold_To_Account_Name__c 
                + rowTag + a.Apttus_QPApprov__ProposalId__r.Ultimate_Consignee__r.Subregion__c
                + rowTag + a.Apttus_QPApprov__ProposalId__r.Apttus_Proposal__Opportunity__r.Name 
                + rowTag + a.Apttus_Approval__DateAssigned__c + rowTag + a.Apttus_QPApprov__ProposalId__r.Approval_Level__c 
                + rowTag + a.Apttus_QPApprov__ProposalId__r.Total_Net__c+ ' ('+a.Apttus_QPApprov__ProposalId__r.CurrencyIsoCode+')' 
                + rowTag + '<a href="'+strApprovalEmail+''+a.id+'">Approval Email</a>' 
                + rowTag + '<a href="'+approveReject+''+a.id+''+pageMode +'">Approve/Reject</a>' + '</td>'
                +'</tr>';

        }
        //close table...
        htmlBody += '</table>';

        system.debug('Email Body: ' + htmlBody);   
        return htmlBody;
    }
    /* Method to get url for list view*/
    public static string getListViewURL(){
       
        Id listViewId = [SELECT Id, Name, DeveloperName,SobjectType FROM ListView where SobjectType =: OBJECT_TYPE AND DeveloperName =:LIST_VEW_NAME][0].id;
        String baseUrl = System.URL.getSalesforceBaseUrl().toExternalForm(); 
        return baseUrl +SUB_URL +listViewId;
    }
}