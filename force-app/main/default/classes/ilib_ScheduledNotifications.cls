/* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Nishan Shetty          13-June-2022          DCP-50962 user story changes.
*/
/* base class to support batches which send notification emails */
public inherited sharing abstract class ilib_ScheduledNotifications extends ilib_BatchDeferrable implements Schedulable {

    /* descendent can have constructors with arguments if needed */
    public ilib_ScheduledNotifications() { }

    // ************************************************************************************************
    // descendents must implement these methods
    // ************************************************************************************************

    /* returns query used for the record locator */
    public abstract String getQuery();

    /*
     * creates an email from a single record from the batch scope
     * return null if the record should not generate an email
    */
    public abstract Messaging.SingleEmailMessage createEmail(SObject record);

    // ************************************************************************************************
    // descendents can optionally implement these methods
    // ************************************************************************************************

    /* prepoares any collections needed to create email messages */
    public virtual void prepareSupportData(List<SObject> scope) { }

    /* collects information about each record in scope that can be used in finish() */
    public virtual void collectRecordInformation(SObject record) { }

    // ************************************************************************************************
    // descendents can optionally override these batchable/schedulable methods
    // ************************************************************************************************

    /* override if finalizing logic is needed */
    public override void finish(Database.BatchableContext bc) { }

    /* override if arguments need to go in the batch instance
    DCP-50962 Changes */
	public override void execute(SchedulableContext sc)
    {
        Database.executebatch((ilib_BatchDeferrable)Type.forName(getClassName()).newInstance());
    }



    // ************************************************************************************************
    // batchable methods
    // ************************************************************************************************

    /* if your query uses bind variables, override this method so they are in scope */
    public override virtual Database.QueryLocator start(Database.BatchableContext bc)
    {
        return Database.getQueryLocator(getQuery());
    }

    /* send notifications */
    public override void execute(Database.BatchableContext bc, List<SObject> scope)
    {
        ilib_LogEvent.setTitle(getClassName() + '.execute');

        // keep track of the record ID so it can be added to error messaging
        Id recordId = null;

        try
        {
            // any collections or values that are used over the course of the loop
            prepareSupportData(scope);

            List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();  
            for (SObject record : scope)
            {
                // any values our counts that need to be summed up for the finish method
                collectRecordInformation(record);

                recordId = record.Id;

                Messaging.SingleEmailMessage email = createEmail(record);
                if (email != null) {
                    emailMessages.add(email);
                }
            }

            recordId = null;

            // send the collected emails
            Messaging.sendEmail(emailMessages, false);
        }
        catch (Exception e)
        {
            ApexExceptions.emit(getClassName(), recordId, e);
        }

        ilib_LogEvent.emit();
    }


    // ************************************************************************************************
    // support methods
    // ************************************************************************************************

    private String getClassName()
    {
        return String.valueOf(this).split(':')[0];
    }

    /* automatic retrieval of template ID by name */
    @TestVisible
    protected Id getTemplateId(String templateName)
    {
        List<EmailTemplate> lstEmailTemplate = new EmailTemplatesSelector().selectByNameOrDeveloperName(new List<String> {templateName});
        return lstEmailTemplate.get(0).Id;
    }

}