/*
Simplified API to create emails
*/
public with sharing class EmailBuilder {

    private Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

    /* start here if you have a user to send to */
    public EmailBuilder(Id targetId)
    {
        setDefaults();
        email.setTargetObjectId(targetId);
    }

    /* start here if you have a user and template */
    public EmailBuilder(Id templateId, Id targetId)
    {
        setDefaults();
        email.setTemplateId(templateId);
        email.setTargetObjectId(targetId);
    }

    /* start here if you have a template and email recipient */
    public EmailBuilder(Id templateId, String to)
    {
        setDefaults();
        email.setTemplateId(templateId);
        email.setToAddresses(new List<String> {to});
    }

    /* start here if you have a tehmplate and email recipients */
    public EmailBuilder(Id templateId, List<String> to)
    {
        setDefaults();
        email.setTemplateId(templateId);
        email.setToAddresses(to);
    }

    private void setDefaults()
    {
        email.setSaveAsActivity(false);
        email.setUseSignature(false);
    }

    /* set the subject and return the builder */
    public EmailBuilder addSubject(String subject)
    {
        email.setSubject(subject);
        return this;
    }

    /* set the body and return the builder */
    public EmailBuilder addHtmlBody(String htmlBody)
    {
        email.setHTMLBody(htmlBody);
        return this;
    }

    /* set the recipients and return the builder */
    public EmailBuilder addTo(List<String> toEmail)
    {
        email.setToAddresses(toEmail);
        return this;
    }

    /* set cc recipients and return the builder */
    public EmailBuilder addCc(List<String> cc)
    {
        email.setCcAddresses(cc);
        return this;
    }

    /* set the related object and return the builder */
    public EmailBuilder addWhatId(Id whatId)
    {
        email.setWhatId(whatId);
        return this;
    }

    /* set this flag and return the builder */
    public EmailBuilder doNotSendToTargetId()
    {
        email.setTreatTargetObjectAsRecipient(false);
        return this;
    }

    /* set display name and return the builder */
    public EmailBuilder setSenderDisplayName(String senderDisplayName)
    {
        email.setSenderDisplayName(senderDisplayName);
        return this;
    }

    /* return the email object from this builder */
    public Messaging.SingleEmailMessage emailMessage()
    {
        return email;
    }

}