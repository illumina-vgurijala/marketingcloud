/**
* @ author       : SAddam
* @ date         : 09-Feb-22
* @ Description  : PM-41: Batch to send an email to account owners manager monthly
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Saddam                09-Feb-22                Initial version
*/
public with sharing class BatchtoEmailAccountOwnerManager extends ilib_ScheduleAndBatch {

    private static final String LOG_TITLE = 'batchtoaccountowner';
    private static ID reportId;
    private static final String  EMAIL_TEMPLATE_NAME= 'R_Q_Non_Compliant_Accounts';

    
    
    /**
    * @author saddam
    * @date   09-Feb-22
    * @description  Overriding execute method for scheduled job 
    */
    public override void execute(SchedulableContext sc) {
        String strBatchId;
        strBatchId=Database.executeBatch(new BatchtoEmailAccountOwnerManager());
        ilib_LogEvent.message('strBatchId--'+strBatchId);
    }

    /**
    * @author saddam
    * @date   09-Feb-22
    * @description  Overriding start method for batch
    */
    public override Database.QueryLocator start(Database.BatchableContext bc) {
        
        return Database.getQueryLocator('Select Id ,name,email,(Select ID,name FROM ManagedUsers WHERE ID IN ( Select OwnerId FROM Account WHERE R_Q_Contact_Compliant__c = \'Non Compliant\')) from user'
               + (Test.isRunningTest()?' LIMIT 200 ':''));
    }

    /**
    * @authorsaddam
    * @date   09-Feb-22
    * @description  Overriding execute method for batch
    */
    public override void execute(Database.BatchableContext bc, List<sObject> lstRecords) {

        ilib_LogEvent.push(LOG_TITLE + '.execute');

        List<User> lstUser = (List<User>)lstRecords;
        list<string> listreportname=new list<string>();
        listreportname.add(System.Label.Non_Compliant_Account_Report);
        ReportQuerySelector req =new ReportQuerySelector();
        list<report> re= req.selectByReportName(listreportname);
        if (!re.isEmpty()) { //codescan fix
            reportId =re[0].id;
        }
        ilib_LogEvent.message('reportId--'+reportId);
        List<Messaging.SingleEmailMessage> lstEmails = new List<Messaging.SingleEmailMessage>();
        for(User objUser : lstUser) {
            if(!objuser.managedusers.isEmpty()) {    
                  lstEmails.add(createEmail(objUser,reportId));
            }
        }
        try {
            if (!lstEmails.isEmpty()) {
                ilib_LogEvent.message('lstEmails--'+lstEmails);
                Messaging.sendEmail(lstEmails);
            }
        } catch(Exception e) {
            ApexExceptions.emit('BatchtoEmailAccountOwnerManager', e);
            throw e;
        }
        ilib_LogEvent.pop();
    }    

    /**
    * @authorsaddam
    * @date   09-Feb-22
    * @description  Emailtemplate-report link link is replaced inside this method
    *param :  Manager User and Reportid 
    *return : Email 
    */
    public static Messaging.SingleEmailMessage createEmail(User userr,ID reportId) {

        // Write logic to send mail here.
        ilib_LogEvent.push(LOG_TITLE + '.createEmail');
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        EmailTemplate emailTemplatei = new EmailTemplatesSelector().selectByNameOrDeveloperName(new List<String>{EMAIL_TEMPLATE_NAME})[0];
                List<String> strEmailId = new List<String>();
                String strBaseURL=URL.getSalesforceBaseUrl().toExternalForm() +'/';
                ilib_LogEvent.message('strBaseURL--'+strBaseURL+reportId);
                EmailTemplate emltmplte = emailTemplatei;
                String htmlBody = emltmplte.HtmlValue;
                String plainBody = emltmplte.Body;

                //stores all the email id
                strEmailId.add(userr.email);
                htmlBody=htmlBody.replace('[[RECEIVINGUSERNAME ]]', userr.name);
                htmlBody=htmlBody.replace('[[REPORTURL]]', strBaseURL+reportId);
                ilib_LogEvent.message('htmlBody--'+htmlBody);
                
                plainBody = plainBody.replace('[[RECEIVINGUSERNAME]]', userr.name);

            email.setHtmlBody(htmlBody);
            email.setPlainTextBody(plainBody);
            email.setToAddresses(strEmailId);
            email.setSubject(emltmplte.Subject);
            email.setTargetObjectId(userr.id);
            email.setSaveAsActivity(false);
            ilib_LogEvent.message('email--'+email);
            
            
            ilib_LogEvent.pop();
            return email;
    }
    /**
    * @author saddam
    * @date   09-Feb-22
    * @description  Overriding finish method for batch
    */
    public override void finish(Database.BatchableContext bc) {

    }

}
