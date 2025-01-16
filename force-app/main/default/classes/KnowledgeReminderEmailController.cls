/*
 * Name: KnowledgeReminderEmailController
 * Description: Used in the "Knowledge : Send Reminder to Approvers" Email template, controller of VF component KnowledgeREminderEmail
 * Created Date: May-25-2020
 * Created By: Tapas C
 */
global with sharing class KnowledgeReminderEmailController {
    global string knowledgeId {get;set;}
    global string knowledgeTitle {get;set;}
    global Integer versionNumber {get;set;}
    global string knowledgeCategories {get;set;}
    global String sfdcURL {
        get {
            return URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/Knowledge__kav/' + this.knowledgeId + '/view';
        }
        set;}
    global String Submitter{
        get{
            List<ProcessInstance> lstProcess = [SELECT SubmittedBy.Name FROM ProcessInstance WHERE TargetObjectId =: this.knowledgeId ORDER BY SystemModStamp DESC LIMIT 1];
            if(lstProcess != null && lstProcess.size() > 0)
                return lstProcess[0].SubmittedBy.Name;
            else 
                return null;
        }
        set;
    }
}