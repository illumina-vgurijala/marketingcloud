/**
*    @author: Deep Diwakar
*    @date:   Jul-29-2024
*    @description: Decorator class for calculating area of work for contacts
*    @Test Class: TestMktgTaskDecorator
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar      Jul-29-2024          CMCM-7519: Added Task decorator for marketing task updates
*         Deep Diwakar      Oct-14-2024          CMCM-9424: Updated to include marketing task updates for Non-MQ tasks
*    --------------------------------------------------------------------------------------------------
 */

public with sharing class MktgTaskDecorator extends ilib_SObjectDecorator {

    private static final String LOG_TITLE = 'MktgTaskDecorator';
    private static final String CODE_PARAM_MKTG_TASK_SUBJECT_VALUES = 'Mktg_Task_Subject_Values';

    /**
     * @author: Deep Diwakar
     * @date: Jul-29-2024 
     * @description: Constructor
     * @param: List of lead records
     */
    public MktgTaskDecorator(List<SObject> lstSObjectRecords) {
        super(lstSObjectRecords);
    }

    /**
     * @author: Deep Diwakar
     * @date: Jul-29-2024 
     * @description: Overriding decorator method to add marketing task updates for insert scenario
     * @param: none
     * @return: void
     */
    public override void decorate() { 
        ilib_LogEvent.push(LOG_TITLE + '.decorate');

        try {
            // method that calculates task values
            this.addMQTaskUpdates();
 
        } catch(Exception ex) {
            ilib_LogEvent.error('Exception occurred: ' + ex.getMessage());
            ApexExceptions.emit(LOG_TITLE, ex, ilib_LogEvent.MARKETING);

        }

        ilib_LogEvent.pop();

    }

    /**
     * @author: Deep Diwakar
     * @date: Jul-29-2024 
     * @description: This method calculates marketing task updates
     * @param: none
     * @return: void
     */
    private void addMQTaskUpdates() {

        ilib_LogEvent.info(LOG_TITLE + '.addMQTaskUpdates'); 
        List<Task> lstTasks = (List<Task>) lstRecords;

        Set<Id> setLeadIds = new Set<Id>();
        Set<Id> setContactIds = new Set<Id>();
        Map<Id, Lead> mapIdToLead = new Map<Id, Lead>();
        Map<Id, Contact> mapIdToContact = new Map<Id, Contact>();

        // get Marketing task subject values from Code Param CMT
        List<Code_Parameter__mdt> lstCodeParam = new List<Code_Parameter__mdt>();
        lstCodeParam = new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set<String>{CODE_PARAM_MKTG_TASK_SUBJECT_VALUES});
        String subjectValues = lstCodeParam[0].value__c;
        ilib_LogEvent.info('subjectValues: ' + subjectValues); // Marketing Qualified,Contact Me,Follow up information requested
        List<String> lstMktgTaskSubjectValues = lstCodeParam[0].value__c.split(',');
        ilib_LogEvent.info('lstMktgTaskSubjectValues: ' + lstMktgTaskSubjectValues); 

        // Note: We need exact match with subject keywords (lstMktgTaskSubjectValues). Current 'contains' method variations don't solve for this
        // therefore running nested loop to identify correct tasks for update
        for (Task task : lstTasks) {
            String whoId = task.WhoId;
            String subject = Task.Subject;
            if (String.isBlank(whoId) || String.isBlank(subject)) {
                continue;
            } 
            
            for (String keyWord: lstMktgTaskSubjectValues) {
                if (subject.containsIgnoreCase(keyWord)) {
                    if ('Lead'.equalsIgnoreCase(task.WhoId.getSObjectType().getDescribe().getName())) {
                        setLeadIds.add(whoId);
                    } else if ('Contact'.equalsIgnoreCase(task.WhoId.getSObjectType().getDescribe().getName())) {
                        setContactIds.add(whoId);
                    }
                    break;
                }
            }

        }

        ilib_LogEvent.info('setLeadIds: ' + setLeadIds); 
        ilib_LogEvent.info('setContactIds: ' + setContactIds); 

        if (!setLeadIds.isEmpty()) {
            // query lead object to get related fields for task update
            mapIdToLead = new Map<Id, Lead> (new LeadsSelector().selectLeadFieldsForTask(setLeadIds));

        }

        if (!setContactIds.isEmpty()) {
            // query contact object to get related fields for task update
            mapIdToContact = new Map<Id, Contact> (new ContactsSelector().selectContactFieldsForTask(setContactIds));

        }

        ilib_LogEvent.info('mapIdToLead: ' + mapIdToLead); 
        ilib_LogEvent.info('mapIdToContact: ' + mapIdToContact); 

        updateTaskFields(lstTasks, mapIdToLead, mapIdToContact);

    }

    /**
     * @author: Deep Diwakar
     * @date: Jul-29-2024 
     * @description: This method adds field updates on task records
     * @param: none
     * @return: void
     */
    private void updateTaskFields (List<Task> lstTasks, Map<Id, Lead> mapIdToLead, Map<Id, Contact> mapIdToContact) {
        
        ilib_LogEvent.info(LOG_TITLE + '.updateTaskFields'); 

        // looping to add task updates using related lead/contact field values
        for (Task task : lstTasks) { 
            String formType = '';
            String productInterest = '';
            String questionsForRep = '';
            String lastSubmissionUrl = '';
            if (mapIdToLead.containsKey(task.WhoId)) {
                Lead taskLead = mapIdToLead.get(task.WhoId);
                formType = taskLead.Form_Type__c;
                productInterest = taskLead.Product_Interest__c;
                questionsForRep = taskLead.Questions_For_Rep__c;
                lastSubmissionUrl = taskLead.Last_Form_Submission_URL__c;

            } else if (mapIdToContact.containsKey(task.WhoId)) {
                Contact taskContact = mapIdToContact.get(task.WhoId);
                formType = taskContact.Form_Type__c;
                productInterest = taskContact.Product_Interest__c + ';';
                questionsForRep = taskContact.Questions_For_Rep__c;
                lastSubmissionUrl = taskContact.Last_Form_Submission_URL__c;
            } else {
                // these are non-MQ task that are not needed to be updated
                ilib_LogEvent.message('non-MQ task or missing key info - no updated needed');
                continue;
            }

            ilib_LogEvent.message('formType: ' + formType);
            ilib_LogEvent.message('productInterest: ' + productInterest);
            ilib_LogEvent.message('questionsForRep: ' + questionsForRep);
            ilib_LogEvent.message('lastSubmissionUrl: ' + lastSubmissionUrl);

            // updating subject field with given format
            String subject = task.Subject + ' Form Type = ' + formType + ' - Product Interest = ' + productInterest;

            // if subject character length is greated than 255 then truncating it to 250 characters and
            // suffixing it with '...'
            Boolean longerSubjectString = subject.length() >= 255;

            if (longerSubjectString) {
                subject = subject.left(250) + '...';
            }

            task.Subject = subject;

            // updating desciption/comment field with given format
            task.Description = task.Description + '\n' 
                            + 'Form Type = ' + formType + '\n' 
                            + 'Product Interest = ' + productInterest + '\n' 
                            + 'Questions for Rep = ' + questionsForRep + '\n' 
                            + 'Last Form Submission URL = ' + lastSubmissionUrl;

        }

    }
}