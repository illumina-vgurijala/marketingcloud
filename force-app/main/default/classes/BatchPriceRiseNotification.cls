/**
*    @author Rishi Sharma
*    @date   1 June 2021
*    @description  DCP-46194: Price Rise Notifications
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*       Developer            Date            Description
*    -----------------------------------------------------------------------------------------------------------------------------------
*
*/
public without sharing class BatchPriceRiseNotification extends ilib_ScheduledNotifications {

    private static final String TEMPLATE_NAME = 'Agreement_Price_Rise_Template';
    private Id emailTemplateId;
    private Map<String, String> regionToEmail = new Map<String, String>();

    // ************************************************************************************************
    // Scheduled Notification implementation
    // ************************************************************************************************

    /* query used for the record locator */
    public override String getQuery()
    {
        // agreements where today is the price rise date
        return 'SELECT Id, Name, Owner.Email, Apttus__Status__c, Apttus__FF_Agreement_Number__c, Apttus__Account__r.Territory_Region__c, '
            + 'Tenders_Status__c, TAMs_Deadline_to_Respond__c, Customer_Reference_Number__c, Country_On_Account_Approvals__c '
            + 'FROM Apttus__APTS_Agreement__c '
            + 'WHERE Price_Rise_Notification_Date__c = TODAY';
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

    /* email the agreement owner
     * CC regional reps found in Region_to_Email_Mapping
     */
    public override Messaging.SingleEmailMessage createEmail(SObject record)
    {
        Apttus__APTS_Agreement__c agreement = (Apttus__APTS_Agreement__c)record;

        // QUESTION: in the original class, the target ID is set
        // but so is the TO address and the target ID is not a recipient
        // Why was that done, isn't this simpler?

        return new EmailBuilder(emailTemplateId, agreement.OwnerId)
            .addCc(findCc(agreement))
            .addWhatId(agreement.Id)
            .emailMessage();
    }


    /* get CC from prepared map */
    private List<String> findCc(Apttus__APTS_Agreement__c agreement)
    {
        String emails = regionToEmail.get(agreement.Apttus__Account__r.Territory_Region__c);

        if (emails == null) // key not found, also works for null key
        {
            return new List<String>();
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