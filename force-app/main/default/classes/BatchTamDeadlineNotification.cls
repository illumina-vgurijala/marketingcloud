/**
*    @author Rishi Sharma
*    @date   2 June 2021
*    @description  DCP-46376: TAM Deadline Notifications
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*       Developer            Date            Description
*    -----------------------------------------------------------------------------------------------------------------------------------
*       Todd                 02-Sep-2021     DCP-49395: add deferrable support
*
*/
public without sharing class BatchTamDeadlineNotification extends ilib_ScheduledNotifications {

    public final static String TEMPLATE_NAME = 'Agreement_TAM_Deadline';
    private Id emailTemplateId;
    private Map<String, String> regionToEmail = new Map<String, String>();

    // ************************************************************************************************
    // Scheduled Notification implementation
    // ************************************************************************************************

    /* overridden so bind variables are in scope */
    public override Database.QueryLocator start(Database.BatchableContext bc)
    {
        return Database.getQueryLocator(getQuery());
    }

    // bind variables for query
    private Id tenderRecordType = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Tender').getRecordTypeId();
    private String pendingStatus = 'Pending TAM decision';

    /* query used for the record locator */
    public override String getQuery()
    {
        // tenders in pending status where deadline to respond is in the future
        return 'SELECT Id, Name, Owner.Email, Apttus__Status__c, Apttus__FF_Agreement_Number__c, Apttus__Account__r.Territory_Region__c, '
            + 'Tenders_Status__c, TAMs_Deadline_to_Respond__c, Customer_Reference_Number__c, Country_On_Account_Approvals__c '
            + 'FROM Apttus__APTS_Agreement__c '
            + 'WHERE RecordTypeId = :tenderRecordType '
            + 'AND Tenders_Status__c = :pendingStatus '
            + 'AND TAMs_Deadline_to_Respond__c < TODAY';
    }

    /* prepares collections needed to create email messages */
    public override void prepareSupportData(List<SObject> scope)
    {
        // get email template ID
        emailTemplateId = getTemplateId(TEMPLATE_NAME);

        // email addresses by region that get a CC on emails sent
        List<Region_to_Email_Mapping__mdt> regionalEmailAddresses = new TenderRegiontoEmailSelector().selectAllRecords();
        regionToEmail = UtilsCollection.getMapOfStringToString(regionalEmailAddresses, 'Region__c', 'Email__c');
    }

    /* email the regional reps found in Region_to_Email_Mapping */
    public override Messaging.SingleEmailMessage createEmail(SObject record)
    {
        Apttus__APTS_Agreement__c agreement = (Apttus__APTS_Agreement__c)record;

        return new EmailBuilder(emailTemplateId, agreement.OwnerId)
            .addTo(findTo(agreement))
            .addWhatId(agreement.Id)
            .doNotSendToTargetId()
            .emailMessage();
    }


    /* get To from prepared map */
    private List<String> findTo(Apttus__APTS_Agreement__c agreement)
    {
        String emails = regionToEmail.get(agreement.Apttus__Account__r.Territory_Region__c);

        if (emails == null) // key not found, also works for null key
        {
            throw new EmailException('No recipient found for region ' + agreement.Apttus__Account__r.Territory_Region__c + ' found on agreement ' + agreement.Id);
        }
        else
        {
            return emails.split(';', 0);
        }
    }


    // ************************************************************************************************
    // Deferrable implementation
    // ************************************************************************************************

    /* no inputs, serialize dummy values */
    public override String serializeInputs()
    {
        return JSON.serialize('No input for this class');
    }

    /* noop intentional, no inputs */
    public override void restoreInputs(String serializedInputs) { }

}